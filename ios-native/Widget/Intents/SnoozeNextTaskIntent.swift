import AppIntents
import Foundation
import PetProgressShared
import WidgetKit

@available(iOS 17.0, *)
struct SnoozeNextTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Snooze Next Task 15m"
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Task ID") var taskId: String
    @Parameter(title: "Day Key") var dayKey: String

    init() { }
    init(taskId: String, dayKey: String) {
        self.taskId = taskId
        self.dayKey = dayKey
    }

    func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: taskId), !dayKey.isEmpty else { return .result() }
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

        // Find the task to snooze
        let mats = materializeTasks(for: dayKey, in: state)
        guard let task = mats.first(where: { $0.id == uuid }) else {
            return .result() // Task not found
        }

        // Check if already completed
        let completed = state.completions[dayKey] ?? Set<UUID>()
        if completed.contains(uuid) {
            return .result() // Already completed, can't snooze
        }

        // Create or update override to snooze the task by 15 minutes
        let cal = Calendar.current
        let now = Date()
        let originalTime = dateFor(dayKey: dayKey, time: task.time) ?? now
        let snoozeTime = originalTime.addingTimeInterval(15 * 60)
        let newComps = cal.dateComponents([.hour, .minute], from: snoozeTime)

        // Find or create override for this task
        var overrides = state.overrides
        if let existingIndex = overrides.firstIndex(where: { $0.seriesId == uuid && $0.dayKey == dayKey }) {
            overrides[existingIndex].time = newComps
        } else {
            let override = TaskInstanceOverride(
                seriesId: uuid,
                dayKey: dayKey,
                time: newComps
            )
            overrides.append(override)
        }
        state.overrides = overrides

        try? shared.saveState(state)
        WidgetCenter.shared.reloadTimelines(ofKind: "PetProgressWidget")
        return .result()
    }
}


