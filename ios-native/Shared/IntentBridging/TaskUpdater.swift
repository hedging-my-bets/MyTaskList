import Foundation
import WidgetKit

public enum TaskUpdater {
    public static func complete(taskId: String, dayKey: String) async throws {
        guard let seriesUUID = UUID(uuidString: taskId) else { return }

        let shared = SharedStore()
        var state = (try? shared.loadState()) ?? AppState(
            schemaVersion: 2,
            dayKey: dayKey,
            tasks: [],
            pet: PetState(stageIndex: 0, stageXP: 0, lastCloseoutDayKey: dayKey),
            series: [],
            overrides: [],
            completions: [:],
            rolloverEnabled: false,
            graceMinutes: 60,
            resetTime: nil
        )

        // Find the next incomplete task for this day to ensure we only complete the "next" one
        let mats = materializeTasks(for: dayKey, in: state)
        let incomplete = mats.filter { task in
            let completions = state.completions[dayKey] ?? Set<UUID>()
            return !completions.contains(task.id)
        }

        // Find the actual next task (earliest incomplete)
        guard let nextTask = incomplete.min(by: { l, r in
            let lTime = (l.time.hour ?? 0) * 60 + (l.time.minute ?? 0)
            let rTime = (r.time.hour ?? 0) * 60 + (r.time.minute ?? 0)
            return lTime < rTime
        }) else {
            return // No incomplete tasks
        }

        // Only proceed if the taskId matches the next task
        guard nextTask.id == seriesUUID else {
            // Do not complete tasks that are not "next"
            return
        }

        // Mark task as complete
        var completed = state.completions[dayKey] ?? Set<UUID>()
        if completed.contains(seriesUUID) {
            return // Already completed
        }

        let now = Date()
        let gm = state.graceMinutes ?? 60
        let taskDate = dateFor(dayKey: dayKey, time: nextTask.time) ?? now
        let onTimeFlag: Bool = {
            let start = taskDate.addingTimeInterval(TimeInterval(-gm * 60))
            let end = taskDate.addingTimeInterval(TimeInterval(gm * 60))
            return now >= start && now <= end
        }()

        completed.insert(seriesUUID)
        state.completions[dayKey] = completed

        // Update pet based on on-time completion
        var pet = state.pet
        let cfg = (try? StageConfigLoader().load(bundle: .main)) ?? StageCfg.defaultConfig()
        PetEngine.onCheck(onTime: onTimeFlag, pet: &pet, cfg: cfg)
        state.pet = pet

        try? shared.saveState(state)
        WidgetCenter.shared.reloadTimelines(ofKind: "PetProgressWidget")
    }

    public static func markNextDone(dayKey: String) async throws {
        let shared = SharedStore()
        var state = (try? shared.loadState()) ?? AppState(
            schemaVersion: 2,
            dayKey: dayKey,
            tasks: [],
            pet: PetState(stageIndex: 0, stageXP: 0, lastCloseoutDayKey: dayKey),
            series: [],
            overrides: [],
            completions: [:],
            rolloverEnabled: false,
            graceMinutes: 60,
            resetTime: nil
        )

        // Find the next incomplete task for this day
        let mats = materializeTasks(for: dayKey, in: state)
        let incomplete = mats.filter { task in
            let completions = state.completions[dayKey] ?? Set<UUID>()
            return !completions.contains(task.id)
        }

        guard let next = incomplete.min(by: { l, r in
            let lTime = (l.time.hour ?? 0) * 60 + (l.time.minute ?? 0)
            let rTime = (r.time.hour ?? 0) * 60 + (r.time.minute ?? 0)
            return lTime < rTime
        }) else {
            return // No incomplete tasks
        }

        // Mark task as complete
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

        var pet = state.pet
        let cfg = (try? StageConfigLoader().load(bundle: .main)) ?? StageCfg.defaultConfig()
        PetEngine.onCheck(onTime: onTimeFlag, pet: &pet, cfg: cfg)
        state.pet = pet

        try? shared.saveState(state)
        WidgetCenter.shared.reloadTimelines(ofKind: "PetProgressWidget")
    }

    public static func snoozeNextTask(taskId: String, dayKey: String) async throws {
        guard let seriesUUID = UUID(uuidString: taskId) else { return }

        let shared = SharedStore()
        var state = (try? shared.loadState()) ?? AppState(
            schemaVersion: 2,
            dayKey: dayKey,
            tasks: [],
            pet: PetState(stageIndex: 0, stageXP: 0, lastCloseoutDayKey: dayKey),
            series: [],
            overrides: [],
            completions: [:],
            rolloverEnabled: false,
            graceMinutes: 60,
            resetTime: nil
        )

        // Find the next incomplete task to ensure we only snooze the "next" one
        let mats = materializeTasks(for: dayKey, in: state)
        let incomplete = mats.filter { task in
            let completions = state.completions[dayKey] ?? Set<UUID>()
            return !completions.contains(task.id)
        }

        guard let nextTask = incomplete.min(by: { l, r in
            let lTime = (l.time.hour ?? 0) * 60 + (l.time.minute ?? 0)
            let rTime = (r.time.hour ?? 0) * 60 + (r.time.minute ?? 0)
            return lTime < rTime
        }) else {
            return // No incomplete tasks
        }

        // Only proceed if the taskId matches the next task
        guard nextTask.id == seriesUUID else {
            return // Do not snooze tasks that are not "next"
        }

        // Create or update override to snooze the task
        let snoozeMinutes = 10 // Default snooze duration
        let currentTime = nextTask.time
        let newHour = (currentTime.hour ?? 0)
        let newMinute = (currentTime.minute ?? 0) + snoozeMinutes

        let finalHour = newHour + (newMinute / 60)
        let finalMinute = newMinute % 60

        let override = TaskInstanceOverride(
            seriesId: seriesUUID,
            dayKey: dayKey,
            time: DateComponents(hour: finalHour, minute: finalMinute),
            isDeleted: false
        )

        // Add or update the override
        var overrides = state.overrides
        overrides.removeAll { $0.seriesId == seriesUUID && $0.dayKey == dayKey }
        overrides.append(override)
        state.overrides = overrides

        try? shared.saveState(state)
        WidgetCenter.shared.reloadTimelines(ofKind: "PetProgressWidget")
    }
}