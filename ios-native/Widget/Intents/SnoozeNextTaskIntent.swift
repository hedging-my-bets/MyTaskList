import AppIntents
import Foundation

struct SnoozeNextTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Snooze Next Task 15m"

    func perform() async throws -> some IntentResult {
        let shared = SharedStore()
        var state = (try? shared.loadState()) ?? State(tasks: [], pet: PetState(stageIndex: 0, stageXP: 0, lastCloseoutDayKey: dayKey(for: Date())), dayKey: dayKey(for: Date()), schemaVersion: 1, rolloverEnabled: false)
        let today = state.dayKey
        if let nextIdx = state.tasks.enumerated().filter({ $0.element.dayKey == today && !$0.element.isCompleted }).sorted(by: { (l, r) in
            (l.element.scheduledAt.hour ?? 0, l.element.scheduledAt.minute ?? 0) < (r.element.scheduledAt.hour ?? 0, r.element.scheduledAt.minute ?? 0)
        }).first?.offset {
            var task = state.tasks[nextIdx]
            if !task.isCompleted { // idempotent
                let cal = Calendar.current
                let now = Date()
                let due = cal.date(bySettingHour: task.scheduledAt.hour ?? 0, minute: task.scheduledAt.minute ?? 0, second: 0, of: now) ?? now
                let midnight = cal.date(bySettingHour: 23, minute: 59, second: 0, of: now) ?? now
                let snoozed = min(due.addingTimeInterval(15 * 60), midnight)
                let comps = cal.dateComponents([.hour, .minute], from: snoozed)
                task.snoozedUntil = snoozed
                task.scheduledAt = comps
                state.tasks[nextIdx] = task
                try? shared.saveState(state)
            }
        }
        return .result()
    }
}


