import Foundation
import WidgetKit

public enum TaskUpdater {
    public static func markNextDone(dayKey: String) async throws {
        let shared = SharedStore()
        guard var state = try? shared.loadState() else { return }

        // Find the next incomplete task - first check TaskItems
        let incompleteTaskItems = state.tasks.filter { $0.dayKey == dayKey && !$0.isCompleted }

        // Sort by scheduled time to find the earliest
        let sortedTasks = incompleteTaskItems.sorted { l, r in
            let lTime = (l.scheduledAt.hour ?? 0) * 60 + (l.scheduledAt.minute ?? 0)
            let rTime = (r.scheduledAt.hour ?? 0) * 60 + (r.scheduledAt.minute ?? 0)
            return lTime < rTime
        }

        if let nextTask = sortedTasks.first {
            // Mark the TaskItem as complete directly
            if let index = state.tasks.firstIndex(where: { $0.id == nextTask.id }) {
                state.tasks[index].isCompleted = true
                state.tasks[index].completedAt = Date()

                // Update pet based on on-time completion
                let now = Date()
                let gm = state.graceMinutes ?? 60
                let taskDate = dateFor(dayKey: dayKey, time: nextTask.scheduledAt) ?? now
                let onTimeFlag: Bool = {
                    let start = taskDate.addingTimeInterval(TimeInterval(-gm * 60))
                    let end = taskDate.addingTimeInterval(TimeInterval(gm * 60))
                    return now >= start && now <= end
                }()

                var pet = state.pet
                let cfg = (try? StageConfigLoader().load(bundle: .main)) ?? StageCfg.defaultConfig()
                PetEngine.onCheck(onTime: onTimeFlag, pet: &pet, cfg: cfg)
                state.pet = pet

                try? shared.saveState(state)
                WidgetCenter.shared.reloadTimelines(ofKind: "PetProgressWidget")
                return
            }
        }

        // If no TaskItems, check materialized tasks (series)
        let mats = materializeTasks(for: dayKey, in: state)
        let incomplete = mats.filter { !$0.isCompleted }

        guard let next = incomplete.min(by: { l, r in
            let lTime = (l.time.hour ?? 0) * 60 + (l.time.minute ?? 0)
            let rTime = (r.time.hour ?? 0) * 60 + (r.time.minute ?? 0)
            return lTime < rTime
        }) else {
            return // No incomplete tasks
        }

        // Mark task as complete in completions map
        var completed = state.completions[dayKey] ?? Set<UUID>()
        if completed.contains(next.id) {
            return // Already completed
        }

        let now = Date()
        let gm = state.graceMinutes ?? 60
        let taskDate = dateFor(dayKey: dayKey, time: next.time) ?? now
        let onTimeFlag: Bool = {
            let start = taskDate.addingTimeInterval(TimeInterval(-gm * 60))
            let end = taskDate.addingTimeInterval(TimeInterval(gm * 60))
            return now >= start && now <= end
        }()

        completed.insert(next.id)
        state.completions[dayKey] = completed

        // Update pet based on on-time completion
        var pet = state.pet
        let cfg = (try? StageConfigLoader().load(bundle: .main)) ?? StageCfg.defaultConfig()
        PetEngine.onCheck(onTime: onTimeFlag, pet: &pet, cfg: cfg)
        state.pet = pet

        try? shared.saveState(state)
        WidgetCenter.shared.reloadTimelines(ofKind: "PetProgressWidget")
    }

    public static func complete(taskId: String, dayKey: String) async throws {
        guard let taskUUID = UUID(uuidString: taskId) else { return }

        let shared = SharedStore()
        guard var state = try? shared.loadState() else { return }

        // Find the specific task
        let mats = materializeTasks(for: dayKey, in: state)
        guard let task = mats.first(where: { $0.id == taskUUID }) else { return }

        // Mark task as complete
        var completed = state.completions[dayKey] ?? Set<UUID>()
        if completed.contains(taskUUID) {
            return // Already completed
        }

        let now = Date()
        let gm = state.graceMinutes ?? 60
        let taskDate = dateFor(dayKey: dayKey, time: task.time) ?? now
        let onTimeFlag: Bool = {
            let start = taskDate.addingTimeInterval(TimeInterval(-gm * 60))
            let end = taskDate.addingTimeInterval(TimeInterval(gm * 60))
            return now >= start && now <= end
        }()

        completed.insert(taskUUID)
        state.completions[dayKey] = completed

        // Update pet based on on-time completion
        var pet = state.pet
        let cfg = (try? StageConfigLoader().load(bundle: .main)) ?? StageCfg.defaultConfig()
        PetEngine.onCheck(onTime: onTimeFlag, pet: &pet, cfg: cfg)
        state.pet = pet

        try? shared.saveState(state)
        WidgetCenter.shared.reloadTimelines(ofKind: "PetProgressWidget")
    }

    public static func snoozeNextTask(taskId: String, dayKey: String) async throws {
        guard let taskUUID = UUID(uuidString: taskId) else { return }

        let shared = SharedStore()
        guard var state = try? shared.loadState() else { return }

        // Find the specific task to snooze
        let mats = materializeTasks(for: dayKey, in: state)
        guard let task = mats.first(where: { $0.id == taskUUID && !$0.isCompleted }) else { return }

        // Create snooze override based on task origin
        let snoozeMinutes = 15
        let currentTime = task.time
        let newHour = (currentTime.hour ?? 0)
        let newMinute = (currentTime.minute ?? 0) + snoozeMinutes

        let finalHour = min(23, newHour + (newMinute / 60))  // Clamp at 23
        let finalMinute = (finalHour == 23 && newMinute >= 60) ? 59 : (newMinute % 60)  // If clamped, set to 23:59

        switch task.origin {
        case .series(let seriesId):
            let override = TaskInstanceOverride(
                seriesId: seriesId,
                dayKey: dayKey,
                time: DateComponents(hour: finalHour, minute: finalMinute),
                isDeleted: false
            )

            // Remove existing override for this series/day, then add new one
            state.overrides.removeAll { $0.seriesId == seriesId && $0.dayKey == dayKey }
            state.overrides.append(override)

        case .oneOff(_):
            // For one-off tasks, update the task's scheduled time directly
            if let taskIndex = state.tasks.firstIndex(where: { $0.id == taskUUID }) {
                state.tasks[taskIndex].scheduledAt = DateComponents(hour: finalHour, minute: finalMinute)
            }
        }

        try? shared.saveState(state)
        WidgetCenter.shared.reloadTimelines(ofKind: "PetProgressWidget")
    }
}