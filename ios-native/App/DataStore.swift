import Foundation
import SwiftUI

@MainActor
final class DataStore: ObservableObject {
    @Published private(set) var state: AppState
    @Published var showPlanner: Bool = false
    @Published var showWidgetInstructions: Bool = false
    @Published var showSettings: Bool = false
    @Published var showResetConfirmation: Bool = false

    private let sharedStore = SharedStore()
    private let stageLoader = StageConfigLoader()

    init() {
        // Load or initialize
        if let loaded = try? sharedStore.loadState() {
            self.state = loaded
        } else {
            let today = dayKey(for: Date())
            self.state = AppState(schemaVersion: 2, dayKey: today, tasks: [], pet: PetState(stageIndex: 0, stageXP: 0, lastCloseoutDayKey: today), series: [], overrides: [], completions: [:], rolloverEnabled: false, graceMinutes: 60, resetTime: DateComponents(hour: 0, minute: 0))
            try? sharedStore.saveState(state)
        }
    }

    var pet: PetState { state.pet }
    var tasksTotal: Int { 
        let mats = materializeTasks(for: state.dayKey, in: state)
        return mats.count
    }
    var tasksDone: Int { 
        let mats = materializeTasks(for: state.dayKey, in: state)
        return mats.filter { $0.isCompleted }.count
    }
    var todayTasksSorted: [MaterializedTask] {
        materializeTasks(for: state.dayKey, in: state)
    }
    var currentThreshold: Int {
        let cfg = (try? stageLoader.load()) ?? StageCfg.defaultConfig()
        return PetEngine.threshold(for: state.pet.stageIndex, cfg: cfg)
    }

    func petImage() -> UIImage {
        let cfg = (try? stageLoader.load()) ?? StageCfg.defaultConfig()
        let asset = cfg.stages[safe: state.pet.stageIndex]?.asset ?? "pet_tadpole"
        if let ui = UIImage(named: asset) {
            return ui
        }
        return UIImage(systemName: "leaf") ?? UIImage()
    }

    func markDone(taskID: UUID) {
        let now = Date()
        let dayKey = state.dayKey
        var completed = state.completions[dayKey] ?? Set<UUID>()
        guard !completed.contains(taskID) else { return }
        
        // Find the materialized task to determine on-time status
        let mats = materializeTasks(for: dayKey, in: state)
        guard let mt = mats.first(where: { $0.id == taskID }) else { return }
        
        let onTime = isOnTime(task: TaskItem(id: taskID, title: mt.title, scheduledAt: mt.time, dayKey: dayKey, isCompleted: false, completedAt: nil, snoozedUntil: nil), now: now)
        
        completed.insert(taskID)
        state.completions[dayKey] = completed
        
        var petCopy = state.pet
        let cfg = (try? stageLoader.load()) ?? StageCfg.defaultConfig()
        PetEngine.onCheck(onTime: onTime, pet: &petCopy, cfg: cfg)
        state.pet = petCopy
        persist()
    }

    func snooze(taskID: UUID, minutes: Int) {
        let dayKey = state.dayKey
        let mats = materializeTasks(for: dayKey, in: state)
        guard let mt = mats.first(where: { $0.id == taskID }) else { return }
        guard !mt.isCompleted else { return }
        
        // For series tasks, create an override with new time
        if case .series(let seriesId) = mt.origin {
            let calendar = Calendar.current
            let now = Date()
            let scheduled = calendar.date(bySettingHour: mt.time.hour ?? 0, minute: mt.time.minute ?? 0, second: 0, of: now) ?? now
            let snoozed = min(scheduled.addingTimeInterval(TimeInterval(minutes * 60)), calendar.date(bySettingHour: 23, minute: 59, second: 0, of: now) ?? scheduled)
            let comps = calendar.dateComponents([.hour, .minute], from: snoozed)
            
            if let idx = state.overrides.firstIndex(where: { $0.seriesId == seriesId && $0.dayKey == dayKey }) {
                state.overrides[idx].time = comps
            } else {
                state.overrides.append(TaskInstanceOverride(seriesId: seriesId, dayKey: dayKey, time: comps))
            }
        } else {
            // For one-off tasks, update the original task
            guard let idx = state.tasks.firstIndex(where: { $0.id == taskID }) else { return }
            var task = state.tasks[idx]
            let calendar = Calendar.current
            let now = Date()
            let scheduled = calendar.date(bySettingHour: task.scheduledAt.hour ?? 0, minute: task.scheduledAt.minute ?? 0, second: 0, of: now) ?? now
            let snoozed = min(scheduled.addingTimeInterval(TimeInterval(minutes * 60)), calendar.date(bySettingHour: 23, minute: 59, second: 0, of: now) ?? scheduled)
            task.snoozedUntil = snoozed
            let comps = calendar.dateComponents([.hour, .minute], from: snoozed)
            task.scheduledAt = comps
            state.tasks[idx] = task
        }
        persist()
    }

    func launchApplyCloseoutIfNeeded() async {
        await applyCloseoutIfNeeded(now: Date())
    }

    func applyCloseoutIfNeeded(now: Date) async {
        let today = dayKey(for: now)
        guard state.pet.lastCloseoutDayKey != today else { return }

        // Compute yesterday completion rate
        let yesterdayKey = state.pet.lastCloseoutDayKey
        let yesterdayTasks = state.tasks.filter { $0.dayKey == yesterdayKey }
        let total = yesterdayTasks.count
        let done = yesterdayTasks.filter { $0.isCompleted }.count
        let rate = total == 0 ? 1.0 : Double(done) / Double(total)

        var petCopy = state.pet
        let cfg = (try? stageLoader.load()) ?? StageCfg.defaultConfig()
        PetEngine.onDailyCloseout(rate: rate, pet: &petCopy, cfg: cfg)
        state.pet = petCopy

        // Archive yesterday (no-op here) and seed today (no rollover by default)
        state.pet.lastCloseoutDayKey = today
        state.dayKey = today
        if state.rolloverEnabled {
            let carry = yesterdayTasks.filter { !$0.isCompleted }
            let calendar = Calendar.current
            let seed = carry.map { old -> TaskItem in
                let comps = DateComponents(hour: old.scheduledAt.hour, minute: old.scheduledAt.minute)
                return TaskItem(id: UUID(), title: old.title, scheduledAt: comps, dayKey: today, isCompleted: false, completedAt: nil, snoozedUntil: nil)
            }
            state.tasks.append(contentsOf: seed)
        }

        persist()
    }

    private func persist() {
        objectWillChange.send()
        try? sharedStore.saveState(state)
    }

    func routeToPlanner() { showPlanner = true }
    
    func updateGraceMinutes(_ minutes: Int) {
        state.graceMinutes = minutes
        persist()
    }
    
    func updateResetTime(_ time: DateComponents) {
        state.resetTime = time
        persist()
    }
    
    func updateRolloverEnabled(_ enabled: Bool) {
        state.rolloverEnabled = enabled
        persist()
    }
    
    func resetAllData() {
        let today = dayKey(for: Date())
        state = AppState(schemaVersion: 2, dayKey: today, tasks: [], pet: PetState(stageIndex: 0, stageXP: 0, lastCloseoutDayKey: today), series: [], overrides: [], completions: [:], rolloverEnabled: false, graceMinutes: 60, resetTime: DateComponents(hour: 0, minute: 0))
        persist()
    }
}

