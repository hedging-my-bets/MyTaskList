import Foundation
import os.log

/// UserDefaults(suiteName:) wrapper for App Group shared storage
/// Implements the exact key structure required for Lock Screen widget interactivity
@available(iOS 17.0, *)
public final class AppGroupDefaults {
    public static let shared = AppGroupDefaults()

    // MARK: - Configuration
    private let appGroupID = "group.com.hedgingmybets.PetProgress"
    private let userDefaults: UserDefaults
    private let logger = Logger(subsystem: "com.petprogress.AppGroupDefaults", category: "SharedStorage")

    // MARK: - JSON Encoder/Decoder
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }()

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    private init() {
        guard let groupDefaults = UserDefaults(suiteName: appGroupID) else {
            logger.fault("Critical failure: Unable to create UserDefaults for App Group: \(self.appGroupID)")
            fatalError("Failed to create UserDefaults with suite name: \(appGroupID)")
        }
        self.userDefaults = groupDefaults
        logger.info("AppGroupDefaults initialized with App Group: \(self.appGroupID)")
    }

    // MARK: - Settings

    /// Grace Minutes setting (0-30 minutes)
    public var graceMinutes: Int {
        get {
            return userDefaults.integer(forKey: "settings.graceMinutes")
        }
        set {
            userDefaults.set(newValue, forKey: "settings.graceMinutes")
            logger.info("Grace minutes updated to: \(newValue)")
        }
    }

    // MARK: - Tasks Storage

    /// Store tasks for a specific day
    public func setTasks(_ tasks: [TaskEntity], dayKey: String) {
        do {
            let data = try encoder.encode(tasks)
            userDefaults.set(data, forKey: "tasks.\(dayKey)")
            logger.info("Stored \(tasks.count) tasks for day: \(dayKey)")
        } catch {
            logger.error("Failed to encode tasks for \(dayKey): \(error.localizedDescription)")
        }
    }

    /// Retrieve tasks for a specific day
    public func getTasks(dayKey: String) -> [TaskEntity] {
        guard let data = userDefaults.data(forKey: "tasks.\(dayKey)") else {
            return []
        }

        do {
            let tasks = try decoder.decode([TaskEntity].self, from: data)
            logger.debug("Retrieved \(tasks.count) tasks for day: \(dayKey)")
            return tasks
        } catch {
            logger.error("Failed to decode tasks for \(dayKey): \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Current Index Storage

    /// Current task index for a specific day
    public func getCurrentIndex(dayKey: String) -> Int {
        return userDefaults.integer(forKey: "index.\(dayKey)")
    }

    /// Update current task index for a specific day
    public func setCurrentIndex(_ index: Int, dayKey: String) {
        userDefaults.set(index, forKey: "index.\(dayKey)")
        logger.debug("Updated current index to \(index) for day: \(dayKey)")
    }

    // MARK: - Pet State Storage

    /// Store pet state
    public func setPetState(_ petState: PetState) {
        do {
            let data = try encoder.encode(petState)
            userDefaults.set(data, forKey: "pet.state")
            logger.info("Stored pet state - Stage: \(petState.stageIndex), XP: \(petState.stageXP)")
        } catch {
            logger.error("Failed to encode pet state: \(error.localizedDescription)")
        }
    }

    /// Retrieve pet state
    public func getPetState() -> PetState? {
        guard let data = userDefaults.data(forKey: "pet.state") else {
            logger.debug("No pet state found, returning nil")
            return nil
        }

        do {
            let petState = try decoder.decode(PetState.self, from: data)
            logger.debug("Retrieved pet state - Stage: \(petState.stageIndex), XP: \(petState.stageXP)")
            return petState
        } catch {
            logger.error("Failed to decode pet state: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Utility Methods

    /// Remove all data for a specific day
    public func clearDay(dayKey: String) {
        userDefaults.removeObject(forKey: "tasks.\(dayKey)")
        userDefaults.removeObject(forKey: "index.\(dayKey)")
        logger.info("Cleared all data for day: \(dayKey)")
    }

    /// Force synchronization with disk
    public func synchronize() -> Bool {
        let success = userDefaults.synchronize()
        if success {
            logger.debug("UserDefaults synchronized successfully")
        } else {
            logger.warning("UserDefaults synchronization failed")
        }
        return success
    }

    /// Get all stored day keys
    public func getAllDayKeys() -> [String] {
        let allKeys = userDefaults.dictionaryRepresentation().keys
        let taskKeys = allKeys.filter { $0.hasPrefix("tasks.") }
        let dayKeys = taskKeys.map { String($0.dropFirst(6)) } // Remove "tasks." prefix
        return Array(Set(dayKeys)).sorted() // Remove duplicates and sort
    }
}

