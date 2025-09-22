import Foundation
import os.log

/// Complete App Group Manager - 100% Production Implementation
/// Manages all shared storage between app and widget with enterprise-grade reliability
@available(iOS 17.0, *)
public final class CompleteAppGroupManager: @unchecked Sendable {
    public static let shared = CompleteAppGroupManager()

    private let logger = Logger(subsystem: "com.petprogress.SharedKit", category: "AppGroup")
    private let appGroupID = "group.com.hedgingmybets.PetProgress"

    private lazy var userDefaults: UserDefaults = {
        guard let defaults = UserDefaults(suiteName: appGroupID) else {
            fatalError("Failed to initialize UserDefaults with App Group ID: \(appGroupID)")
        }
        return defaults
    }()

    // Storage keys
    private enum StorageKey: String, CaseIterable {
        // Settings
        case graceMinutes = "settings.graceMinutes"
        case hapticsEnabled = "settings.hapticsEnabled"
        case rolloverEnabled = "settings.rolloverEnabled"

        // Pet state
        case petState = "pet.state"
        case lastCelebrationDate = "pet.lastCelebrationDate"

        // Task management
        case currentPage = "tasks.currentPage"
        case lastProcessedDayKey = "tasks.lastProcessedDayKey"

        // App state
        case appVersion = "app.version"
        case firstLaunchDate = "app.firstLaunchDate"
        case lastAppForegroundDate = "app.lastForegroundDate"

        // Widget state
        case lastWidgetUpdate = "widget.lastUpdate"
        case widgetUpdateCount = "widget.updateCount"

        // Performance metrics
        case totalTasksCompleted = "metrics.totalTasksCompleted"
        case totalXPEarned = "metrics.totalXPEarned"
        case longestStreak = "metrics.longestStreak"

        // Dynamic keys for daily data
        static func tasksKey(dayKey: String) -> String { "tasks.\(dayKey)" }
        static func indexKey(dayKey: String) -> String { "index.\(dayKey)" }
        static func completionsKey(dayKey: String) -> String { "completions.\(dayKey)" }
    }

    private init() {
        logger.info("Complete App Group Manager initialized with ID: \(appGroupID)")
        validateAppGroupAccess()
    }

    // MARK: - Settings Management

    public var graceMinutes: Int {
        get {
            let value = userDefaults.integer(forKey: StorageKey.graceMinutes.rawValue)
            return value > 0 ? value : 30 // Default 30 minutes
        }
        set {
            userDefaults.set(newValue, forKey: StorageKey.graceMinutes.rawValue)
            synchronize()
            logger.info("Grace minutes updated to \(newValue)")
        }
    }

    public func getGraceMinutes() -> Int {
        return graceMinutes
    }

    public func setGraceMinutes(_ minutes: Int) {
        graceMinutes = minutes
    }

    public var hapticsEnabled: Bool {
        get {
            if userDefaults.object(forKey: StorageKey.hapticsEnabled.rawValue) == nil {
                return true // Default enabled
            }
            return userDefaults.bool(forKey: StorageKey.hapticsEnabled.rawValue)
        }
        set {
            userDefaults.set(newValue, forKey: StorageKey.hapticsEnabled.rawValue)
            synchronize()
            logger.info("Haptics \(newValue ? "enabled" : "disabled")")
        }
    }

    public var rolloverEnabled: Bool {
        get {
            if userDefaults.object(forKey: StorageKey.rolloverEnabled.rawValue) == nil {
                return true // Default enabled
            }
            return userDefaults.bool(forKey: StorageKey.rolloverEnabled.rawValue)
        }
        set {
            userDefaults.set(newValue, forKey: StorageKey.rolloverEnabled.rawValue)
            synchronize()
            logger.info("Rollover \(newValue ? "enabled" : "disabled")")
        }
    }

    // MARK: - Pet State Management

    public func getPetState() -> PetState? {
        guard let data = userDefaults.data(forKey: StorageKey.petState.rawValue) else {
            logger.info("No pet state found, returning default")
            return PetState(stageIndex: 0, stageXP: 0, lastCloseoutDayKey: "", lastCelebratedStage: -1)
        }

        do {
            let petState = try JSONDecoder().decode(PetState.self, from: data)
            logger.debug("Pet state loaded: Stage \(petState.stageIndex), XP \(petState.stageXP)")
            return petState
        } catch {
            logger.error("Failed to decode pet state: \(error.localizedDescription)")
            return PetState(stageIndex: 0, stageXP: 0, lastCloseoutDayKey: "", lastCelebratedStage: -1)
        }
    }

    public func setPetState(_ petState: PetState) {
        do {
            let data = try JSONEncoder().encode(petState)
            userDefaults.set(data, forKey: StorageKey.petState.rawValue)
            synchronize()
            logger.info("Pet state saved: Stage \(petState.stageIndex), XP \(petState.stageXP)")
        } catch {
            logger.error("Failed to encode pet state: \(error.localizedDescription)")
        }
    }

    // MARK: - Task Management

    public func getTasks(dayKey: String) -> [TaskEntity] {
        let key = StorageKey.tasksKey(dayKey: dayKey)

        guard let data = userDefaults.data(forKey: key) else {
            logger.debug("No tasks found for day \(dayKey)")
            return []
        }

        do {
            let tasks = try JSONDecoder().decode([TaskEntity].self, from: data)
            logger.debug("Loaded \(tasks.count) tasks for day \(dayKey)")
            return tasks
        } catch {
            logger.error("Failed to decode tasks for \(dayKey): \(error.localizedDescription)")
            return []
        }
    }

    public func setTasks(_ tasks: [TaskEntity], dayKey: String) {
        let key = StorageKey.tasksKey(dayKey: dayKey)

        do {
            let data = try JSONEncoder().encode(tasks)
            userDefaults.set(data, forKey: key)
            synchronize()
            logger.info("Saved \(tasks.count) tasks for day \(dayKey)")
        } catch {
            logger.error("Failed to encode tasks for \(dayKey): \(error.localizedDescription)")
        }
    }

    public func getCompletions(dayKey: String) -> Set<String> {
        let key = StorageKey.completionsKey(dayKey: dayKey)
        let completionIds = userDefaults.stringArray(forKey: key) ?? []
        return Set(completionIds)
    }

    public func setCompletions(_ completions: Set<String>, dayKey: String) {
        let key = StorageKey.completionsKey(dayKey: dayKey)
        userDefaults.set(Array(completions), forKey: key)
        synchronize()
        logger.debug("Saved \(completions.count) completions for day \(dayKey)")
    }

    public func markTaskCompleted(_ taskId: String, dayKey: String) {
        var completions = getCompletions(dayKey: dayKey)
        completions.insert(taskId)
        setCompletions(completions, dayKey: dayKey)

        // Update metrics
        incrementTotalTasksCompleted()

        logger.info("Task \(taskId) marked completed for \(dayKey)")
    }

    public func isTaskCompleted(_ taskId: String, dayKey: String) -> Bool {
        let completions = getCompletions(dayKey: dayKey)
        return completions.contains(taskId)
    }

    // MARK: - Page Management

    public var currentPage: Int {
        get {
            return userDefaults.integer(forKey: StorageKey.currentPage.rawValue)
        }
        set {
            userDefaults.set(newValue, forKey: StorageKey.currentPage.rawValue)
            synchronize()
            logger.debug("Current page updated to \(newValue)")
        }
    }

    public func getCurrentPage() -> Int {
        return currentPage
    }

    public func updateCurrentPage(_ page: Int) {
        currentPage = page
    }

    // MARK: - Rollover Management

    public var lastProcessedDayKey: String? {
        get {
            return userDefaults.string(forKey: StorageKey.lastProcessedDayKey.rawValue)
        }
        set {
            userDefaults.set(newValue, forKey: StorageKey.lastProcessedDayKey.rawValue)
            synchronize()
            if let dayKey = newValue {
                logger.info("Last processed day key updated to \(dayKey)")
            }
        }
    }

    // MARK: - App State Tracking

    public var appVersion: String? {
        get {
            return userDefaults.string(forKey: StorageKey.appVersion.rawValue)
        }
        set {
            userDefaults.set(newValue, forKey: StorageKey.appVersion.rawValue)
            synchronize()
        }
    }

    public var firstLaunchDate: Date? {
        get {
            guard userDefaults.object(forKey: StorageKey.firstLaunchDate.rawValue) != nil else { return nil }
            return userDefaults.object(forKey: StorageKey.firstLaunchDate.rawValue) as? Date
        }
        set {
            userDefaults.set(newValue, forKey: StorageKey.firstLaunchDate.rawValue)
            synchronize()
        }
    }

    public var lastAppForegroundDate: Date? {
        get {
            guard userDefaults.object(forKey: StorageKey.lastAppForegroundDate.rawValue) != nil else { return nil }
            return userDefaults.object(forKey: StorageKey.lastAppForegroundDate.rawValue) as? Date
        }
        set {
            userDefaults.set(newValue, forKey: StorageKey.lastAppForegroundDate.rawValue)
            synchronize()
        }
    }

    // MARK: - Widget State

    public var lastWidgetUpdate: Date? {
        get {
            guard userDefaults.object(forKey: StorageKey.lastWidgetUpdate.rawValue) != nil else { return nil }
            return userDefaults.object(forKey: StorageKey.lastWidgetUpdate.rawValue) as? Date
        }
        set {
            userDefaults.set(newValue, forKey: StorageKey.lastWidgetUpdate.rawValue)
            synchronize()
        }
    }

    public var widgetUpdateCount: Int {
        get {
            return userDefaults.integer(forKey: StorageKey.widgetUpdateCount.rawValue)
        }
        set {
            userDefaults.set(newValue, forKey: StorageKey.widgetUpdateCount.rawValue)
            synchronize()
        }
    }

    public func incrementWidgetUpdateCount() {
        widgetUpdateCount += 1
        lastWidgetUpdate = Date()
    }

    // MARK: - Performance Metrics

    public var totalTasksCompleted: Int {
        get {
            return userDefaults.integer(forKey: StorageKey.totalTasksCompleted.rawValue)
        }
        set {
            userDefaults.set(newValue, forKey: StorageKey.totalTasksCompleted.rawValue)
            synchronize()
        }
    }

    public var totalXPEarned: Int {
        get {
            return userDefaults.integer(forKey: StorageKey.totalXPEarned.rawValue)
        }
        set {
            userDefaults.set(newValue, forKey: StorageKey.totalXPEarned.rawValue)
            synchronize()
        }
    }

    public var longestStreak: Int {
        get {
            return userDefaults.integer(forKey: StorageKey.longestStreak.rawValue)
        }
        set {
            userDefaults.set(newValue, forKey: StorageKey.longestStreak.rawValue)
            synchronize()
        }
    }

    private func incrementTotalTasksCompleted() {
        totalTasksCompleted += 1
    }

    public func addXPEarned(_ xp: Int) {
        totalXPEarned += xp
    }

    // MARK: - Data Management

    public func clearDay(dayKey: String) {
        let tasksKey = StorageKey.tasksKey(dayKey: dayKey)
        let indexKey = StorageKey.indexKey(dayKey: dayKey)
        let completionsKey = StorageKey.completionsKey(dayKey: dayKey)

        userDefaults.removeObject(forKey: tasksKey)
        userDefaults.removeObject(forKey: indexKey)
        userDefaults.removeObject(forKey: completionsKey)
        synchronize()

        logger.info("Cleared all data for day \(dayKey)")
    }

    public func clearAllData() {
        for key in StorageKey.allCases {
            userDefaults.removeObject(forKey: key.rawValue)
        }

        // Clear dynamic keys (this is destructive, use carefully)
        let calendar = Calendar.current
        let today = Date()

        for i in 0..<30 { // Clear last 30 days
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                let dayKey = TimeSlot.dayKey(for: date)
                clearDay(dayKey: dayKey)
            }
        }

        synchronize()
        logger.warning("ALL App Group data cleared")
    }

    // MARK: - Validation & Diagnostics

    private func validateAppGroupAccess() {
        // Test write/read to ensure App Group is working
        let testKey = "appgroup.test"
        let testValue = "validation-\(Date().timeIntervalSince1970)"

        userDefaults.set(testValue, forKey: testKey)
        synchronize()

        let retrievedValue = userDefaults.string(forKey: testKey)
        userDefaults.removeObject(forKey: testKey)

        if retrievedValue == testValue {
            logger.info("App Group validation successful")
        } else {
            logger.error("App Group validation failed - check entitlements")
        }
    }

    public func generateDiagnosticReport() -> [String: Any] {
        let petState = getPetState()

        return [
            "appGroupID": appGroupID,
            "graceMinutes": graceMinutes,
            "hapticsEnabled": hapticsEnabled,
            "rolloverEnabled": rolloverEnabled,
            "currentPage": currentPage,
            "petStage": petState?.stageIndex ?? -1,
            "petXP": petState?.stageXP ?? -1,
            "totalTasksCompleted": totalTasksCompleted,
            "totalXPEarned": totalXPEarned,
            "longestStreak": longestStreak,
            "widgetUpdateCount": widgetUpdateCount,
            "lastWidgetUpdate": lastWidgetUpdate?.timeIntervalSince1970 ?? 0,
            "appVersion": appVersion ?? "unknown",
            "firstLaunchDate": firstLaunchDate?.timeIntervalSince1970 ?? 0
        ]
    }

    // MARK: - Private Utilities

    private func synchronize() {
        userDefaults.synchronize()
    }
}

// MARK: - Backward Compatibility

@available(iOS 17.0, *)
public extension AppGroupDefaults {
    /// Migration to CompleteAppGroupManager
    static var shared: CompleteAppGroupManager {
        return CompleteAppGroupManager.shared
    }
}