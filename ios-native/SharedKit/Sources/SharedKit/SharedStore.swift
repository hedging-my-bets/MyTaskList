import Foundation
import os.log
import Combine

/// Enterprise-grade shared storage system with atomic operations, crash recovery, and comprehensive error handling
@available(iOS 17.0, *)
public final class SharedStore: ObservableObject {
    public static let shared = SharedStore()

    // MARK: - Configuration
    private let appGroupID = "group.hedging-my-bets.mytasklist"
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
                logger.info("Storage integrity validation passed in \(validationTime * 1000, specifier: "%.2f")ms")
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
            performanceLogger.warning("\(operation) took \(duration * 1000, specifier: "%.2f")ms (avg: \(averageTime * 1000, specifier: "%.2f")ms)")
        } else {
            performanceLogger.debug("\(operation) completed in \(duration * 1000, specifier: "%.2f")ms")
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

        // Mark the task as done
        day.slots[slotIndex].isDone = true

        // Award points for completion (basic +5 points)
        day.points += 5

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
}
