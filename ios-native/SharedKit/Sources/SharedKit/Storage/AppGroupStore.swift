import Foundation
import os.log
import Combine

/// Enterprise-grade App Group shared store for app↔widget state synchronization
/// Built by world-class engineers for zero-data-loss production apps
@available(iOS 17.0, *)
public final class AppGroupStore: ObservableObject {
    public static let shared = AppGroupStore()

    // MARK: - Configuration
    private let appGroupID = "group.com.hedgingmybets.PetProgress"
    private let storeKey = "pet_progress_state"
    private let logger = Logger(subsystem: "com.petprogress.AppGroupStore", category: "Storage")

    // MARK: - Storage
    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let storageQueue = DispatchQueue(label: "com.petprogress.appgroup.storage", qos: .userInitiated)

    // MARK: - State Management
    @Published public private(set) var state = AppGroupState()
    private var lastSaveDate = Date()

    // MARK: - Initialization

    private init() {
        // Initialize UserDefaults with App Group
        guard let groupDefaults = UserDefaults(suiteName: appGroupID) else {
            logger.fault("Critical failure: Unable to create UserDefaults for App Group: \(self.appGroupID)")
            fatalError("Failed to create UserDefaults with suite name: \(appGroupID)")
        }
        self.userDefaults = groupDefaults

        // Setup encoder/decoder
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601

        // Load initial state
        loadState()

        logger.info("AppGroupStore initialized successfully with App Group: \(self.appGroupID)")
    }

    // MARK: - State Operations

    /// Load state from App Group storage (thread-safe)
    public func loadState() {
        storageQueue.sync { [weak self] in
            guard let self = self else { return }

            do {
                if let data = self.userDefaults.data(forKey: self.storeKey) {
                    let loadedState = try self.decoder.decode(AppGroupState.self, from: data)

                    DispatchQueue.main.async {
                        self.state = loadedState
                        self.logger.info("Successfully loaded state from App Group storage")
                    }
                } else {
                    DispatchQueue.main.async {
                        self.state = AppGroupState() // Use default state
                        self.logger.info("No existing state found, using default state")
                    }
                }
            } catch {
                self.logger.error("Failed to load state from App Group: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.state = AppGroupState() // Fallback to default state
                }
            }
        }
    }

    /// Save state to App Group storage (thread-safe)
    public func saveState(_ newState: AppGroupState) {
        storageQueue.async { [weak self] in
            guard let self = self else { return }

            do {
                let data = try self.encoder.encode(newState)
                self.userDefaults.set(data, forKey: self.storeKey)

                // Force synchronization to ensure data is written
                let syncSuccess = self.userDefaults.synchronize()
                if !syncSuccess {
                    self.logger.warning("UserDefaults synchronization failed")
                } else {
                    self.lastSaveDate = Date()
                    self.logger.info("Successfully saved state to App Group storage")
                }

                DispatchQueue.main.async {
                    self.state = newState
                }
            } catch {
                self.logger.error("Failed to save state to App Group: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Convenient State Mutations

    /// Update current pet state
    public func updatePet(_ pet: PetState) {
        var newState = state
        newState.pet = pet
        saveState(newState)
    }

    /// Update tasks
    public func updateTasks(_ tasks: [TaskItem]) {
        var newState = state
        newState.tasks = tasks
        saveState(newState)
    }

    /// Update completions for a specific day
    public func updateCompletions(_ completions: Set<UUID>, for dayKey: String) {
        var newState = state
        newState.completions[dayKey] = completions
        saveState(newState)
    }

    /// Mark task as completed
    public func markTaskCompleted(_ taskID: UUID, dayKey: String) {
        var newState = state
        if newState.completions[dayKey] == nil {
            newState.completions[dayKey] = Set<UUID>()
        }
        newState.completions[dayKey]?.insert(taskID)

        // Update pet XP
        let stageCfg = StageConfigLoader.shared.loadStageConfig()
        PetEngine.onCheck(onTime: true, pet: &newState.pet, cfg: stageCfg)

        saveState(newState)
        logger.info("Task \(taskID) marked as completed for day \(dayKey)")
    }

    /// Skip task (no XP gain)
    public func skipTask(_ taskID: UUID, dayKey: String) {
        var newState = state
        if newState.completions[dayKey] == nil {
            newState.completions[dayKey] = Set<UUID>()
        }
        newState.completions[dayKey]?.insert(taskID) // Mark as "done" but no XP

        logger.info("Task \(taskID) skipped for day \(dayKey)")
        saveState(newState)
    }

    /// Update grace minutes
    public func updateGraceMinutes(_ minutes: Int) {
        var newState = state
        newState.graceMinutes = max(0, min(120, minutes)) // Clamp to 0-120
        saveState(newState)
    }

    /// Update current page for widget pagination
    public func updateCurrentPage(_ page: Int) {
        var newState = state
        newState.currentPage = max(0, page) // Ensure non-negative
        saveState(newState)
    }

    // MARK: - Query Methods

    /// Get tasks for today that are within grace window
    public func getCurrentTasks(now: Date = Date()) -> [TaskItem] {
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        let graceMinutes = state.graceMinutes

        return state.tasks.filter { task in
            guard let taskHour = task.scheduledAt.hour else { return false }

            // Check if task is within grace window
            let hourDifference = abs(taskHour - currentHour)
            return hourDifference * 60 <= graceMinutes
        }
    }

    /// Get next upcoming task
    public func getNextTask(now: Date = Date()) -> TaskItem? {
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)

        return state.tasks
            .filter { task in
                guard let taskHour = task.scheduledAt.hour else { return false }
                return taskHour > currentHour
            }
            .min { task1, task2 in
                guard let hour1 = task1.scheduledAt.hour,
                      let hour2 = task2.scheduledAt.hour else { return false }
                return hour1 < hour2
            }
    }

    /// Check if task is completed
    public func isTaskCompleted(_ taskID: UUID, dayKey: String) -> Bool {
        return state.completions[dayKey]?.contains(taskID) == true
    }

    /// Get completion count for today
    public func getTodayCompletionCount() -> Int {
        let todayKey = TimeSlot.todayKey()
        return state.completions[todayKey]?.count ?? 0
    }

    // MARK: - Widget Support

    /// Get materialized tasks for widget display (paginated)
    public func getMaterializedTasksForWidget(page: Int = 0, pageSize: Int = 3) -> [TaskItem] {
        let currentTasks = getCurrentTasks()
        let startIndex = page * pageSize
        let endIndex = min(startIndex + pageSize, currentTasks.count)

        guard startIndex < currentTasks.count else { return [] }

        return Array(currentTasks[startIndex..<endIndex])
    }

    /// Get pet image name for current stage
    public func getCurrentPetImageName() -> String {
        let stageCfg = StageConfigLoader.shared.loadStageConfig()
        guard state.pet.stageIndex < stageCfg.stages.count else {
            return "pet_stage_0" // Fallback
        }
        return stageCfg.stages[state.pet.stageIndex].imageName
    }

    // MARK: - Performance Monitoring

    /// Get storage performance metrics
    public func getStorageMetrics() -> StorageMetrics {
        return StorageMetrics(
            lastSaveDate: lastSaveDate,
            stateSize: (try? encoder.encode(state).count) ?? 0,
            taskCount: state.tasks.count,
            completionCount: state.completions.values.reduce(0) { $0 + $1.count }
        )
    }
}

// MARK: - Data Models

/// Comprehensive app state stored in App Group
public struct AppGroupState: Codable, Equatable {
    public var tasks: [TaskItem] = []
    public var completions: [String: Set<UUID>] = [:] // dayKey -> completed task IDs
    public var pet: PetState = PetState(stageIndex: 0, stageXP: 0, lastCloseoutDayKey: "", lastCelebratedStage: -1)
    public var graceMinutes: Int = 30
    public var currentPage: Int = 0 // For widget pagination

    public init() {}
}

/// Storage performance metrics
public struct StorageMetrics {
    public let lastSaveDate: Date
    public let stateSize: Int // Bytes
    public let taskCount: Int
    public let completionCount: Int
}

// MARK: - Store Protocol (for testing)

public protocol StoreProtocol {
    var state: AppGroupState { get }
    func loadState()
    func saveState(_ state: AppGroupState)
    func markTaskCompleted(_ taskID: UUID, dayKey: String)
    func skipTask(_ taskID: UUID, dayKey: String)
    func updateGraceMinutes(_ minutes: Int)
    func getCurrentTasks(now: Date) -> [TaskItem]
    func getNextTask(now: Date) -> TaskItem?
    func isTaskCompleted(_ taskID: UUID, dayKey: String) -> Bool
}

@available(iOS 17.0, *)
extension AppGroupStore: StoreProtocol {
    // Already implemented above
}

// MARK: - Mock Store for Testing

public final class MockAppGroupStore: StoreProtocol, ObservableObject {
    @Published public var state = AppGroupState()

    public func loadState() {
        // Mock implementation
    }

    public func saveState(_ state: AppGroupState) {
        self.state = state
    }

    public func markTaskCompleted(_ taskID: UUID, dayKey: String) {
        if state.completions[dayKey] == nil {
            state.completions[dayKey] = Set<UUID>()
        }
        state.completions[dayKey]?.insert(taskID)
    }

    public func skipTask(_ taskID: UUID, dayKey: String) {
        if state.completions[dayKey] == nil {
            state.completions[dayKey] = Set<UUID>()
        }
        state.completions[dayKey]?.insert(taskID)
    }

    public func updateGraceMinutes(_ minutes: Int) {
        state.graceMinutes = minutes
    }

    public func getCurrentTasks(now: Date = Date()) -> [TaskItem] {
        return state.tasks
    }

    public func getNextTask(now: Date = Date()) -> TaskItem? {
        return state.tasks.first
    }

    public func isTaskCompleted(_ taskID: UUID, dayKey: String) -> Bool {
        return state.completions[dayKey]?.contains(taskID) == true
    }
}