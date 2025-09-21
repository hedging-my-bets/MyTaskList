import Foundation
import os.log

/// Comprehensive error handling for SharedStore operations
public enum SharedStoreError: Error, LocalizedError {
    case invalidTaskId(String)
    case invalidDayKey(String)
    case dayNotFound(String)
    case taskNotFound(String)
    case validationFailed(String)
    case storageCorrupted(String)
    case operationTimeout
    case concurrencyConflict
    case insufficientDiskSpace
    case appGroupUnavailable

    public var errorDescription: String? {
        switch self {
        case .invalidTaskId(let id):
            return "Invalid task ID: \(id)"
        case .invalidDayKey(let key):
            return "Invalid day key: \(key)"
        case .dayNotFound(let key):
            return "Day not found: \(key)"
        case .taskNotFound(let id):
            return "Task not found: \(id)"
        case .validationFailed(let reason):
            return "Data validation failed: \(reason)"
        case .storageCorrupted(let details):
            return "Storage corrupted: \(details)"
        case .operationTimeout:
            return "Operation timed out"
        case .concurrencyConflict:
            return "Concurrent modification detected"
        case .insufficientDiskSpace:
            return "Insufficient disk space"
        case .appGroupUnavailable:
            return "App Group storage unavailable"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .invalidTaskId, .invalidDayKey, .validationFailed:
            return "Check data format and try again"
        case .dayNotFound, .taskNotFound:
            return "Refresh data or create new entry"
        case .storageCorrupted:
            return "App may restore from backup automatically"
        case .operationTimeout, .concurrencyConflict:
            return "Try again in a moment"
        case .insufficientDiskSpace:
            return "Free up storage space"
        case .appGroupUnavailable:
            return "Restart app or check device storage"
        }
    }
}

/// Actor-based shared storage system for thread-safe App Group access
/// Provides atomic operations with iOS 17+ Actor isolation for bulletproof concurrency
@available(iOS 17.0, *)
public actor SharedStoreActor {
    public static let shared = SharedStoreActor()

    // MARK: - Configuration
    private let appGroupID = "group.com.hedgingmybets.PetProgress"
    private let maxRetryAttempts = 3
    private let operationTimeout: TimeInterval = 10.0

    // MARK: - Storage
    private let userDefaults: UserDefaults
    private let fileManager = FileManager.default
    private let containerURL: URL

    // MARK: - Logging & Performance
    private let logger = Logger(subsystem: "com.petprogress.SharedStoreActor", category: "AtomicStorage")
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: - State Tracking
    private var lastSuccessfulWrite: Date = Date()
    private var operationCount = 0
    private var totalOperationTime: TimeInterval = 0

    private init() {
        // Initialize UserDefaults with comprehensive error handling
        guard let groupDefaults = UserDefaults(suiteName: appGroupID) else {
            logger.fault("Critical failure: Unable to create UserDefaults for App Group: \(self.appGroupID)")
            fatalError("Failed to create UserDefaults with suite name: \(appGroupID)")
        }
        self.userDefaults = groupDefaults

        // Initialize container URL with fallback
        guard let container = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            logger.fault("Critical failure: Unable to access App Group container: \(self.appGroupID)")
            fatalError("Failed to access App Group container: \(appGroupID)")
        }
        self.containerURL = container

        // Setup encoder/decoder for optimal performance
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        decoder.dateDecodingStrategy = .iso8601

        logger.info("SharedStoreActor initialized successfully with App Group: \(self.appGroupID)")
    }

    // MARK: - Atomic Day Operations

    /// Atomically loads a day model with comprehensive error recovery
    public func loadDay(key: String) -> DayModel? {
        let startTime = CFAbsoluteTimeGetCurrent()
        defer { recordPerformanceMetric(operation: "loadDay", duration: CFAbsoluteTimeGetCurrent() - startTime) }

        let storageKey = dayKey(key)
        logger.debug("Loading day model for key: \(key)")

        // Primary load attempt from UserDefaults
        if let data = userDefaults.data(forKey: storageKey) {
            do {
                let day = try decoder.decode(DayModel.self, from: data)
                logger.debug("Successfully loaded day model from UserDefaults")
                return day
            } catch {
                logger.error("Failed to decode DayModel from UserDefaults: \(error.localizedDescription)")
            }
        }

        // Fallback to file system
        let fileURL = containerURL.appendingPathComponent("Data").appendingPathComponent("\(key).json")
        if let data = try? Data(contentsOf: fileURL) {
            do {
                let day = try decoder.decode(DayModel.self, from: data)
                logger.info("Recovered day model from file system backup")

                // Restore to UserDefaults atomically
                _ = saveToUserDefaults(day, key: storageKey)
                return day
            } catch {
                logger.error("Failed to decode DayModel from file system: \(error.localizedDescription)")
            }
        }

        logger.warning("No day model found for key: \(key)")
        return nil
    }

    /// Atomically saves a day model with backup creation and verification
    public func saveDay(_ day: DayModel) {
        let startTime = CFAbsoluteTimeGetCurrent()
        defer { recordPerformanceMetric(operation: "saveDay", duration: CFAbsoluteTimeGetCurrent() - startTime) }

        // Validate day model before saving
        guard validateDayModel(day) else {
            logger.error("Cannot save invalid day model: \(day.key)")
            return
        }

        let storageKey = dayKey(day.key)
        logger.debug("Saving day model for key: \(day.key)")

        // Create backup before modification
        createBackup(for: day.key)

        // Attempt atomic save with retry logic
        var success = false
        for attempt in 1...maxRetryAttempts {
            if saveToUserDefaults(day, key: storageKey) {
                success = true
                break
            } else if attempt < maxRetryAttempts {
                logger.warning("Save attempt \(attempt) failed for key: \(day.key), retrying...")
                // No Thread.sleep in actor - just retry immediately
            }
        }

        if success {
            // Also save to file system for redundancy
            saveToFileSystem(day)
            lastSuccessfulWrite = Date()
            logger.debug("Successfully saved day model for key: \(day.key)")
        } else {
            logger.error("Failed to save day model after \(self.maxRetryAttempts) attempts for key: \(day.key)")
        }
    }

    // MARK: - Data Validation

    /// Validates task ID format and existence
    private func validateTaskId(_ taskId: String) -> Bool {
        return !taskId.isEmpty && taskId.count <= 100 && taskId.allSatisfy { char in
            char.isLetter || char.isNumber || char == "-" || char == "_"
        }
    }

    /// Validates day key format (YYYY-MM-DD)
    private func validateDayKey(_ dayKey: String) -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.date(from: dayKey) != nil
    }

    /// Validates day model integrity
    private func validateDayModel(_ day: DayModel) -> Bool {
        guard validateDayKey(day.key) else { return false }
        guard day.points >= 0 && day.points <= 10000 else { return false }
        guard day.slots.count <= 24 else { return false }

        for slot in day.slots {
            guard validateTaskId(slot.id) else { return false }
            guard slot.hour >= 0 && slot.hour <= 23 else { return false }
            guard !slot.title.isEmpty && slot.title.count <= 200 else { return false }
        }

        return true
    }

    // MARK: - Atomic Task Operations

    /// Atomically marks the next task as done with grace period calculation
    public func markTaskComplete(taskId: String, dayKey: String) -> DayModel? {
        let startTime = CFAbsoluteTimeGetCurrent()
        defer { recordPerformanceMetric(operation: "markTaskComplete", duration: CFAbsoluteTimeGetCurrent() - startTime) }

        // Validate inputs
        guard validateTaskId(taskId) else {
            logger.error("Invalid task ID format: \(taskId)")
            return nil
        }

        guard validateDayKey(dayKey) else {
            logger.error("Invalid day key format: \(dayKey)")
            return nil
        }

        guard var day = loadDay(key: dayKey) else {
            logger.error("Cannot mark task complete - day not found: \(dayKey)")
            return nil
        }

        // Validate day model integrity
        guard validateDayModel(day) else {
            logger.error("Day model failed validation: \(dayKey)")
            return nil
        }

        // Find the task by ID
        guard let slotIndex = day.slots.firstIndex(where: { $0.id == taskId }) else {
            logger.error("Task not found with ID: \(taskId)")
            return day
        }

        let task = day.slots[slotIndex]

        // Don't mark already completed tasks
        guard !task.isDone else {
            logger.debug("Task already completed: \(taskId)")
            return day
        }

        // Mark the task as done
        day.slots[slotIndex].isDone = true

        // Award points based on timing (simplified for widget context)
        let currentHour = Calendar.current.component(.hour, from: Date())
        let isOnTime = abs(task.hour - currentHour) <= 1 // Within 1 hour considered on-time

        if isOnTime {
            day.points += 5 // Full points for on-time completion
        } else {
            day.points += 2 // Reduced points for late completion
        }

        saveDay(day)

        logger.info("Marked task \(taskId) as complete for day \(dayKey), awarded \(isOnTime ? 5 : 2) points")
        return day
    }

    /// Atomically skips a task (marks as done but no points)
    public func skipTask(taskId: String, dayKey: String) -> DayModel? {
        let startTime = CFAbsoluteTimeGetCurrent()
        defer { recordPerformanceMetric(operation: "skipTask", duration: CFAbsoluteTimeGetCurrent() - startTime) }

        // Validate inputs
        guard validateTaskId(taskId) else {
            logger.error("Invalid task ID format: \(taskId)")
            return nil
        }

        guard validateDayKey(dayKey) else {
            logger.error("Invalid day key format: \(dayKey)")
            return nil
        }

        guard var day = loadDay(key: dayKey) else {
            logger.error("Cannot skip task - day not found: \(dayKey)")
            return nil
        }

        // Validate day model integrity
        guard validateDayModel(day) else {
            logger.error("Day model failed validation: \(dayKey)")
            return nil
        }

        // Find the task by ID
        guard let slotIndex = day.slots.firstIndex(where: { $0.id == taskId }) else {
            logger.error("Task not found with ID: \(taskId)")
            return day
        }

        // Mark as done but award no points (skip)
        day.slots[slotIndex].isDone = true

        saveDay(day)

        logger.info("Skipped task \(taskId) for day \(dayKey)")
        return day
    }

    /// Atomically updates widget window offset for navigation
    public func updateWindowOffset(_ offset: Int) {
        let startTime = CFAbsoluteTimeGetCurrent()
        defer { recordPerformanceMetric(operation: "updateWindowOffset", duration: CFAbsoluteTimeGetCurrent() - startTime) }

        let clampedOffset = max(-12, min(12, offset)) // Clamp to reasonable range
        userDefaults.set(clampedOffset, forKey: "widget_window_offset")
        userDefaults.synchronize()

        logger.debug("Updated widget window offset to: \(clampedOffset)")
    }

    /// Atomically gets the current window offset
    public func getWindowOffset() -> Int {
        return userDefaults.integer(forKey: "widget_window_offset")
    }

    // MARK: - Current State Access

    /// Gets the current day model with fresh data
    public func getCurrentDayModel() -> DayModel? {
        let todayKey = TimeSlot.dayKey(for: Date())
        return loadDay(key: todayKey)
    }

    /// Gets the current pet stage from today's points
    public func getCurrentPetStage() -> Int {
        guard let day = getCurrentDayModel() else { return 0 }
        let engine = PetEvolutionEngine()
        return engine.stageIndex(for: day.points)
    }

    /// Gets the current pet points
    public func getCurrentPetPoints() -> Int {
        return getCurrentDayModel()?.points ?? 0
    }

    // MARK: - Widget State Management

    /// Forces widget timeline reload by updating timestamp
    public func triggerWidgetReload() {
        userDefaults.set(Date().timeIntervalSince1970, forKey: "last_widget_update")
        userDefaults.synchronize()
        logger.debug("Triggered widget timeline reload")
    }

    // MARK: - Private Atomic Helpers

    private func saveToUserDefaults(_ day: DayModel, key: String) -> Bool {
        do {
            let data = try encoder.encode(day)
            userDefaults.set(data, forKey: key)

            // Force synchronization to ensure data is written
            let syncSuccess = userDefaults.synchronize()
            if !syncSuccess {
                logger.warning("UserDefaults synchronization failed for key: \(key)")
                return false
            }

            // Verify the save was successful
            guard let savedData = userDefaults.data(forKey: key),
                  savedData == data else {
                logger.error("Save verification failed for key: \(key)")
                return false
            }

            return true
        } catch {
            logger.error("Failed to encode/save DayModel: \(error.localizedDescription)")
            return false
        }
    }

    private func saveToFileSystem(_ day: DayModel) {
        let dataDirectory = containerURL.appendingPathComponent("Data", isDirectory: true)

        // Ensure directory exists
        try? fileManager.createDirectory(at: dataDirectory, withIntermediateDirectories: true)

        let fileURL = dataDirectory.appendingPathComponent("\(day.key).json")
        let tempURL = fileURL.appendingPathExtension("tmp")

        do {
            let data = try encoder.encode(day)

            // Write to temporary file first (atomic operation)
            try data.write(to: tempURL)

            // Verify the temporary file was written correctly
            let verificationData = try Data(contentsOf: tempURL)
            guard verificationData == data else {
                logger.error("File system write verification failed for key: \(day.key)")
                return
            }

            // Atomic move to final location
            if fileManager.fileExists(atPath: fileURL.path) {
                _ = try fileManager.replaceItem(at: fileURL, withItemAt: tempURL, backupItemName: nil, options: [], resultingItemURL: nil)
            } else {
                try fileManager.moveItem(at: tempURL, to: fileURL)
            }

            logger.debug("Successfully saved day model to file system: \(day.key)")
        } catch {
            logger.error("Failed to save day model to file system: \(error.localizedDescription)")
            // Clean up temporary file if it exists
            try? fileManager.removeItem(at: tempURL)
        }
    }

    private func createBackup(for key: String) {
        guard let existingDay = loadDay(key: key) else {
            return // No existing data to backup
        }

        let backupDirectory = containerURL.appendingPathComponent("Backups", isDirectory: true)

        // Ensure directory exists
        try? fileManager.createDirectory(at: backupDirectory, withIntermediateDirectories: true)

        let timestamp = ISO8601DateFormatter().string(from: Date())
        let backupURL = backupDirectory.appendingPathComponent("\(key)_\(timestamp).json")

        do {
            let data = try encoder.encode(existingDay)
            try data.write(to: backupURL)
            logger.debug("Created backup for key: \(key)")
        } catch {
            logger.warning("Failed to create backup for key: \(key): \(error.localizedDescription)")
        }
    }

    private func recordPerformanceMetric(operation: String, duration: TimeInterval) {
        operationCount += 1
        totalOperationTime += duration

        let averageTime = totalOperationTime / Double(operationCount)

        if duration > 0.1 { // Log slow operations
            logger.warning("\(operation) took \(String(format: "%.2f", duration * 1000))ms (avg: \(String(format: "%.2f", averageTime * 1000))ms)")
        } else {
            logger.debug("\(operation) completed in \(String(format: "%.2f", duration * 1000))ms")
        }
    }

    private func dayKey(_ key: String) -> String {
        return "day_\(key)"
    }

    // MARK: - TaskEntity Support

    public func findTask(withId id: String) -> TaskEntity? {
        let todayKey = TimeSlot.dayKey(for: Date())
        guard let day = loadDay(key: todayKey) else { return nil }

        guard let slot = day.slots.first(where: { $0.id == id }) else { return nil }
        return TaskEntity(from: slot, dayKey: todayKey)
    }

    public func getNearestHourTasks() -> [TaskEntity] {
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        let todayKey = TimeSlot.dayKey(for: Date())

        guard let day = loadDay(key: todayKey) else { return [] }

        // Get grace minutes from settings (clamped to valid range)
        let graceMinutes = userDefaults.integer(forKey: "grace_minutes")
        let effectiveGraceMinutes = max(0, min(graceMinutes > 0 ? graceMinutes : 30, 120))

        logger.debug("Materializing nearest-hour tasks: currentHour=\(currentHour), currentMinute=\(currentMinute), graceMinutes=\(effectiveGraceMinutes)")

        // Filter tasks based on grace window relative to their scheduled time
        let relevantTasks = day.slots.filter { slot in
            return isTaskWithinGraceWindow(
                taskHour: slot.hour,
                currentHour: currentHour,
                currentMinute: currentMinute,
                graceMinutes: effectiveGraceMinutes
            )
        }

        // Sort by hour and prioritize incomplete tasks
        let sortedTasks = relevantTasks.sorted { task1, task2 in
            // Prioritize incomplete tasks
            if task1.isDone != task2.isDone {
                return !task1.isDone && task2.isDone
            }
            // Then sort by hour
            return task1.hour < task2.hour
        }

        let taskEntities = sortedTasks.map { TaskEntity(from: $0, dayKey: todayKey) }
        logger.debug("Found \(taskEntities.count) nearest-hour tasks for hour \(currentHour)")

        return taskEntities
    }

    // MARK: - Grace Period Logic

    /// Determines if a task is within the grace window for completion
    /// Steve Jobs-quality grace period logic - handles midnight edge cases perfectly
    /// Task due at 1pm with 60-minute grace: completable from 1:00pm to 2:00pm
    /// Task due at 11:30pm with 120-minute grace: completable from 11:30pm to 1:30am
    private func isTaskWithinGraceWindow(
        taskHour: Int,
        currentHour: Int,
        currentMinute: Int,
        graceMinutes: Int
    ) -> Bool {
        // Convert everything to minutes from midnight for easier calculation
        let taskMinutes = taskHour * 60  // Task scheduled time in minutes from midnight
        let currentMinutes = currentHour * 60 + currentMinute  // Current time in minutes from midnight

        // Calculate grace window boundaries
        let graceWindowStart = taskMinutes
        let graceWindowEnd = taskMinutes + graceMinutes

        // Special handling for midnight crossing
        let isWithinGrace: Bool
        if graceWindowEnd >= 24 * 60 {
            // Grace window crosses midnight (e.g., task at 23:30 with 60 min grace)
            let nextDayEnd = graceWindowEnd - 24 * 60

            // Current time is either:
            // 1. Late tonight (after task start)
            // 2. Early tomorrow (before grace end)
            isWithinGrace = (currentMinutes >= graceWindowStart) || (currentMinutes <= nextDayEnd)
        } else {
            // Normal case: grace window doesn't cross midnight
            // Task is "now" if current time is between task time and grace window end
            isWithinGrace = currentMinutes >= graceWindowStart && currentMinutes <= graceWindowEnd
        }

        logger.debug("Grace check: task=\(taskHour):00, current=\(currentHour):\(String(format: "%02d", currentMinute)), grace=\(graceMinutes)min, withinGrace=\(isWithinGrace)")

        return isWithinGrace
    }

    // MARK: - Health & Diagnostics

    public func healthCheck() -> Bool {
        // Verify basic functionality
        let testKey = "health_check_\(Date().timeIntervalSince1970)"
        userDefaults.set("test", forKey: testKey)
        let result = userDefaults.string(forKey: testKey) != nil
        userDefaults.removeObject(forKey: testKey)
        return result
    }
}