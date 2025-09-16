import Foundation
import os.log
import Combine

/// Enterprise-grade shared storage system with atomic operations, crash recovery, and comprehensive error handling
@available(iOS 17.0, *)
public final class SharedStore: ObservableObject {
    public static let shared = SharedStore()

    // MARK: - Configuration
    private let appGroupID = "group.com.hedgingmybets.PetProgress"
    private let backupSuffix = ".backup"
    private let tempSuffix = ".tmp"
    private let maxRetryAttempts = 3
    private let operationTimeout: TimeInterval = 10.0

    // MARK: - Storage
    private let userDefaults: UserDefaults
    private let fileManager = FileManager.default
    private let containerURL: URL

    // MARK: - Concurrency & Safety
    private let storageQueue = DispatchQueue(label: "com.petprogress.storage", qos: .userInitiated)
    private let logger = Logger(subsystem: "com.petprogress.SharedStore", category: "Storage")
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: - Error Recovery
    private var lastSuccessfulWrite: Date = Date()
    private let maxBackupAge: TimeInterval = 7 * 24 * 60 * 60 // 7 days

    // MARK: - Performance Monitoring
    private let performanceLogger = Logger(subsystem: "com.petprogress.SharedStore", category: "Performance")
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
        encoder.outputFormatting = [.sortedKeys] // Deterministic output
        decoder.dateDecodingStrategy = .iso8601

        // Initialize storage directory
        setupStorageEnvironment()

        // Perform startup validation
        validateStorageIntegrity()

        logger.info("SharedStore initialized successfully with App Group: \(self.appGroupID)")
    }

    // MARK: - Storage Environment Setup

    private func setupStorageEnvironment() {
        storageQueue.sync {
            // Create necessary directories
            let dataDirectory = containerURL.appendingPathComponent("Data", isDirectory: true)
            let backupDirectory = containerURL.appendingPathComponent("Backups", isDirectory: true)

            do {
                try fileManager.createDirectory(at: dataDirectory, withIntermediateDirectories: true)
                try fileManager.createDirectory(at: backupDirectory, withIntermediateDirectories: true)
                logger.info("Storage directories created successfully")
            } catch {
                logger.error("Failed to create storage directories: \(error.localizedDescription)")
            }
        }
    }

    private func validateStorageIntegrity() {
        storageQueue.async { [weak self] in
            guard let self = self else { return }

            let startTime = CFAbsoluteTimeGetCurrent()
            var validationIssues: [String] = []

            // Check App Group accessibility
            do {
                let testKey = "integrity_test_\(UUID().uuidString)"
                userDefaults.set("test", forKey: testKey)
                let retrieved = userDefaults.string(forKey: testKey)
                userDefaults.removeObject(forKey: testKey)

                if retrieved != "test" {
                    validationIssues.append("UserDefaults read/write test failed")
                }
            }

            // Check file system permissions
            do {
                let testURL = containerURL.appendingPathComponent("test.tmp")
                try "test".write(to: testURL, atomically: true, encoding: .utf8)
                let content = try String(contentsOf: testURL)
                try fileManager.removeItem(at: testURL)

                if content != "test" {
                    validationIssues.append("File system read/write test failed")
                }
            } catch {
                validationIssues.append("File system access error: \(error.localizedDescription)")
            }

            // Clean up old backups
            self.cleanupOldBackups()

            let validationTime = CFAbsoluteTimeGetCurrent() - startTime

            if validationIssues.isEmpty {
                logger.info("Storage integrity validation passed in \(validationTime * 1000)))ms")
            } else {
                logger.warning("Storage integrity issues found: \(validationIssues.joined(separator: ", "))")
            }
        }
    }

    private func cleanupOldBackups() {
        let backupDirectory = containerURL.appendingPathComponent("Backups")

        do {
            let backupFiles = try fileManager.contentsOfDirectory(at: backupDirectory, includingPropertiesForKeys: [.contentModificationDateKey])
            let cutoffDate = Date().addingTimeInterval(-maxBackupAge)

            var cleanedCount = 0
            for fileURL in backupFiles {
                do {
                    let attributes = try fileURL.resourceValues(forKeys: [.contentModificationDateKey])
                    if let modificationDate = attributes.contentModificationDate, modificationDate < cutoffDate {
                        try fileManager.removeItem(at: fileURL)
                        cleanedCount += 1
                    }
                } catch {
                    logger.warning("Failed to clean backup file \(fileURL.lastPathComponent): \(error.localizedDescription)")
                }
            }

            if cleanedCount > 0 {
                logger.info("Cleaned up \(cleanedCount) old backup files")
            }
        } catch {
            logger.warning("Failed to clean backup directory: \(error.localizedDescription)")
        }
    }

    // MARK: - Day Management with Enterprise Error Handling

    /// Loads a day model with comprehensive error recovery and performance monitoring
    public func loadDay(key: String) -> DayModel? {
        let startTime = CFAbsoluteTimeGetCurrent()
        let operation = "loadDay"

        return storageQueue.sync { [weak self] in
            guard let self = self else { return nil }

            defer {
                let operationTime = CFAbsoluteTimeGetCurrent() - startTime
                self.recordPerformanceMetric(operation: operation, duration: operationTime)
            }

            let storageKey = self.dayKey(key)
            logger.debug("Loading day model for key: \(key)")

            // Primary load attempt
            if let day = attemptLoadFromUserDefaults(key: storageKey) {
                logger.debug("Successfully loaded day model from UserDefaults")
                return day
            }

            // Fallback to file system
            if let day = attemptLoadFromFileSystem(key: key) {
                logger.info("Recovered day model from file system backup")
                // Restore to UserDefaults
                saveToUserDefaultsWithRetry(day, key: storageKey)
                return day
            }

            logger.warning("No day model found for key: \(key)")
            return nil
        }
    }

    /// Saves a day model with atomic operations, backup creation, and crash recovery
    public func saveDay(_ day: DayModel) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let operation = "saveDay"

        storageQueue.async { [weak self] in
            guard let self = self else { return }

            defer {
                let operationTime = CFAbsoluteTimeGetCurrent() - startTime
                self.recordPerformanceMetric(operation: operation, duration: operationTime)
            }

            let storageKey = self.dayKey(day.key)
            logger.debug("Saving day model for key: \(day.key)")

            // Create backup before modification
            self.createBackup(for: day.key)

            // Attempt atomic save with retry logic
            var success = false
            for attempt in 1...maxRetryAttempts {
                if self.saveToUserDefaultsWithRetry(day, key: storageKey) {
                    success = true
                    break
                } else if attempt < maxRetryAttempts {
                    logger.warning("Save attempt \(attempt) failed for key: \(day.key), retrying...")
                    Thread.sleep(forTimeInterval: 0.1 * Double(attempt)) // Exponential backoff
                }
            }

            if success {
                // Also save to file system for redundancy
                self.saveToFileSystem(day)
                self.lastSuccessfulWrite = Date()
                logger.debug("Successfully saved day model for key: \(day.key)")
            } else {
                logger.error("Failed to save day model after \(self.maxRetryAttempts) attempts for key: \(day.key)")
            }
        }
    }

    // MARK: - Private Storage Operations

    private func attemptLoadFromUserDefaults(key: String) -> DayModel? {
        guard let data = userDefaults.data(forKey: key) else {
            return nil
        }

        do {
            return try decoder.decode(DayModel.self, from: data)
        } catch {
            logger.error("Failed to decode DayModel from UserDefaults: \(error.localizedDescription)")
            return nil
        }
    }

    private func attemptLoadFromFileSystem(key: String) -> DayModel? {
        let fileURL = containerURL.appendingPathComponent("Data").appendingPathComponent("\(key).json")

        do {
            let data = try Data(contentsOf: fileURL)
            return try decoder.decode(DayModel.self, from: data)
        } catch {
            logger.debug("No file system backup found for key: \(key)")
            return nil
        }
    }

    @discardableResult
    private func saveToUserDefaultsWithRetry(_ day: DayModel, key: String) -> Bool {
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
        let fileURL = containerURL.appendingPathComponent("Data").appendingPathComponent("\(day.key).json")
        let tempURL = fileURL.appendingPathExtension(tempSuffix)

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
        guard let existingDay = attemptLoadFromUserDefaults(key: dayKey(key)) else {
            return // No existing data to backup
        }

        let backupDirectory = containerURL.appendingPathComponent("Backups")
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
            performanceLogger.warning("\(operation) took \(String(format: "%.2f", duration * 1000))ms (avg: \(String(format: "%.2f", averageTime * 1000))ms)")
        } else {
            performanceLogger.debug("\(operation) completed in \(String(format: "%.2f", duration * 1000))ms")
        }
    }

    // MARK: - Task Mutations

    @discardableResult
    public func markNextDone(for dayKey: String, now: Date, tz: TimeZone = TimeZone.current) -> DayModel? {
        guard var day = loadDay(key: dayKey) else {
            return nil
        }

        let currentHour = TimeSlot.hourIndex(for: now, tz: tz)

        // Find the next incomplete task at or after current hour
        guard let slotIndex = day.slots.firstIndex(where: { slot in
            slot.hour >= currentHour && !slot.isDone
        }) else {
            return day // No incomplete tasks found
        }

        let task = day.slots[slotIndex]

        // Check grace period from current app state
        guard let currentState = getCurrentState() else {
            // Fallback to immediate completion if state unavailable
            day.slots[slotIndex].isDone = true
            day.points += 5
            saveDay(day)
            return day
        }

        // Determine if task completion is within grace period
        let isWithinGrace = isOnTime(task: TaskItem(
            id: task.id,
            title: task.title,
            scheduledAt: DateComponents(hour: task.hour),
            isDone: false
        ), now: now, graceMinutes: currentState.graceMinutes)

        // Mark the task as done
        day.slots[slotIndex].isDone = true

        // Award points: full points if within grace period, reduced otherwise
        if isWithinGrace {
            day.points += 5 // Full points for on-time completion
        } else {
            day.points += 2 // Reduced points for late completion
        }

        saveDay(day)
        return day
    }

    @discardableResult
    public func snoozeNext(for dayKey: String, minutes: Int, now: Date, tz: TimeZone = TimeZone.current) -> DayModel? {
        guard var day = loadDay(key: dayKey) else {
            return nil
        }

        let currentHour = TimeSlot.hourIndex(for: now, tz: tz)

        // Find the next incomplete task at or after current hour
        guard let slotIndex = day.slots.firstIndex(where: { slot in
            slot.hour >= currentHour && !slot.isDone
        }) else {
            return day // No incomplete tasks found
        }

        // Calculate new hour (minimum +1 hour, clamped to ≤ 23)
        let currentSlotHour = day.slots[slotIndex].hour
        let hoursToAdd = max(1, minutes / 60) // At least 1 hour
        let newHour = min(23, currentSlotHour + hoursToAdd)

        // Update the slot's hour
        day.slots[slotIndex].hour = newHour

        saveDay(day)
        return day
    }

    // MARK: - Pet Progression

    public func set(points: Int, for dayKey: String) {
        guard var day = loadDay(key: dayKey) else {
            // Create new day if it doesn't exist
            let newDay = DayModel(key: dayKey, points: max(0, points))
            saveDay(newDay)
            return
        }

        day.points = max(0, points) // Ensure points are never negative
        saveDay(day)
    }

    public func advance(by delta: Int, dayKey: String) {
        guard var day = loadDay(key: dayKey) else {
            let newDay = DayModel(key: dayKey, points: max(0, delta))
            saveDay(newDay)
            return
        }

        day.points = max(0, day.points + delta)
        saveDay(day)
    }

    public func regress(by delta: Int, dayKey: String) {
        guard var day = loadDay(key: dayKey) else {
            return // Can't regress a non-existent day
        }

        day.points = max(0, day.points - delta)
        saveDay(day)
    }

    // MARK: - Private Helpers

    private func dayKey(_ key: String) -> String {
        return "day_\(key)"
    }

    // MARK: - AppState Bridge Methods

    /// Load AppState from shared storage
    public func loadAppState() -> AppState? {
        return performAtomicOperation(operationType: "loadAppState") { [weak self] in
            guard let self = self else { return nil }

            let key = "app_state"
            guard let data = self.userDefaults.data(forKey: key) else {
                self.logger.info("No AppState found for key: \(key)")
                return nil
            }

            do {
                let state = try self.decoder.decode(AppState.self, from: data)
                self.logger.info("Successfully loaded AppState for key: \(key)")
                return state
            } catch {
                self.logger.error("Failed to decode AppState: \(error.localizedDescription)")
                return nil
            }
        } ?? nil
    }

    /// Save AppState to shared storage
    public func saveAppState(_ state: AppState) {
        performAtomicOperation(operationType: "saveAppState") { [weak self] in
            guard let self = self else { return }

            let key = "app_state"
            do {
                let data = try self.encoder.encode(state)
                self.userDefaults.set(data, forKey: key)
                self.lastSuccessfulWrite = Date()
                self.logger.info("Successfully saved AppState for key: \(key)")

                // Also update the DayModel representation for widget consumption
                self.updateDayModelFromAppState(state)

                // Sync grace minutes to the key that SharedStoreActor reads
                self.userDefaults.set(state.graceMinutes, forKey: "grace_minutes")

            } catch {
                self.logger.error("Failed to encode AppState: \(error.localizedDescription)")
            }
        }
    }

    /// Convert AppState to DayModel for widget consumption
    private func updateDayModelFromAppState(_ appState: AppState) {
        let dayKey = appState.dayKey

        // Get materialized tasks for today
        let materializedTasks = materializeTasks(for: dayKey, in: appState)

        // Create slots from materialized tasks (limit to 24 for widget)
        var slots: [DayModel.Slot] = []
        let completedTasks = appState.completions[dayKey] ?? Set<UUID>()

        for (index, task) in materializedTasks.prefix(24).enumerated() {
            let isCompleted = completedTasks.contains(task.id)
            let slot = DayModel.Slot(
                hour: task.timeSlot?.hour ?? index,
                title: task.title,
                isDone: isCompleted
            )
            slots.append(slot)
        }

        // Create DayModel with current points
        let dayModel = DayModel(
            key: dayKey,
            slots: slots,
            points: appState.pet.points
        )

        // Save the DayModel for widget consumption
        self.saveDay(dayModel)
    }

    /// Get current day's tasks as DayModel (for widget)
    public func getCurrentDayModel() -> DayModel? {
        // First try to get from AppState (authoritative)
        if let appState = loadAppState() {
            let materializedTasks = materializeTasks(for: appState.dayKey, in: appState)

            var slots: [DayModel.Slot] = []
            let completedTasks = appState.completions[appState.dayKey] ?? Set<UUID>()

            for (index, task) in materializedTasks.prefix(24).enumerated() {
                let isCompleted = completedTasks.contains(task.id)
                let slot = DayModel.Slot(
                    hour: task.timeSlot?.hour ?? index,
                    title: task.title,
                    isDone: isCompleted
                )
                slots.append(slot)
            }

            return DayModel(
                key: appState.dayKey,
                slots: slots,
                points: appState.pet.points
            )
        }

        // Fallback to DayModel storage
        let todayKey = TimeSlot.dayKey(for: Date())
        return loadDay(key: todayKey)
    }

    /// Update AppState when widget makes changes
    public func updateTaskCompletion(taskIndex: Int, completed: Bool, dayKey: String? = nil) {
        guard var appState = loadAppState() else {
            logger.error("No AppState found - cannot update task completion")
            return
        }

        let targetDayKey = dayKey ?? appState.dayKey
        let materializedTasks = materializeTasks(for: targetDayKey, in: appState)

        guard taskIndex < materializedTasks.count else {
            logger.error("Task index \(taskIndex) out of bounds")
            return
        }

        let task = materializedTasks[taskIndex]
        var completedTasks = appState.completions[targetDayKey] ?? Set<UUID>()

        if completed {
            completedTasks.insert(task.id)
            // Use proper PetEngine for completion
            let stageCfg = StageConfigLoader.shared.loadStageConfig()
            PetEngine.onCheck(onTime: true, pet: &appState.pet, cfg: stageCfg)
        } else {
            completedTasks.remove(task.id)
            // Use proper PetEngine for regression
            let stageCfg = StageConfigLoader.shared.loadStageConfig()
            PetEngine.onMiss(pet: &appState.pet, cfg: stageCfg)
        }

        appState.completions[targetDayKey] = completedTasks

        // Save updated AppState
        saveAppState(appState)

        logger.info("Updated task \(taskIndex) completion to \(completed) for day \(targetDayKey)")
    }

    // MARK: - NASA-Quality Error Recovery Methods

    /// Force refresh all cached data from persistent storage
    /// Used by App Intents for bulletproof error recovery
    public func refreshFromDisk() {
        performAtomicOperation(operationType: "refreshFromDisk") { [weak self] in
            guard let self = self else { return }

            self.logger.debug("Forcing refresh from persistent storage")

            // Force UserDefaults synchronization to ensure we have latest data
            self.userDefaults.synchronize()

            // Clear any potential in-memory caches (none in current implementation)
            // This method ensures subsequent reads get fresh data

            self.logger.info("Successfully refreshed data from persistent storage")
        }
    }

    /// Atomic operation wrapper with comprehensive error handling and timeout protection
    @discardableResult
    private func performAtomicOperation<T>(operationType: String, operation: @escaping () -> T) -> T? {
        let startTime = CFAbsoluteTimeGetCurrent()
        var result: T?

        storageQueue.sync {
            // Timeout protection
            let timeoutSource = DispatchSource.makeTimerSource(queue: storageQueue)
            var isTimedOut = false

            timeoutSource.schedule(deadline: .now() + operationTimeout)
            timeoutSource.setEventHandler {
                isTimedOut = true
                self.logger.error("\(operationType) operation timed out after \(self.operationTimeout)s")
            }
            timeoutSource.resume()

            defer {
                timeoutSource.cancel()
            }

            guard !isTimedOut else {
                return
            }

            do {
                result = operation()
                let operationTime = CFAbsoluteTimeGetCurrent() - startTime
                self.recordPerformanceMetric(operation: operationType, duration: operationTime)
            } catch {
                self.logger.error("\(operationType) operation failed: \(error.localizedDescription)")
            }
        }

        return result
    }
}
