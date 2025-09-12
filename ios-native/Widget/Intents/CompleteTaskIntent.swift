import AppIntents
import Foundation

struct CompleteTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Complete Task"

    @Parameter(title: "Task ID") var taskId: String
    @Parameter(title: "Day Key") var dayKey: String

    func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: taskId) else { return .result() }
        let shared = SharedStore()
        var state = (try? shared.loadState()) ?? AppState(schemaVersion: 2, dayKey: dayKey, tasks: [], pet: PetState(stageIndex: 0, stageXP: 0, lastCloseoutDayKey: dayKey), series: [], overrides: [], completions: [:], rolloverEnabled: false, graceMinutes: 60, resetTime: nil)

        var completed = state.completions[dayKey] ?? Set<UUID>()
        if completed.contains(uuid) {
            return .result() // idempotent
        }

        // Find materialized to compute on-time
        let mats = materializeTasks(for: dayKey, in: state)
        guard let mt = mats.first(where: { $0.id == uuid }) else {
            // allow completion for known one-offs as fallback
            completed.insert(uuid)
            state.completions[dayKey] = completed
            try? shared.saveState(state)
            return .result()
        }
        let now = Date()
        let gm = state.graceMinutes ?? 60
        let taskDate = dateFor(dayKey: dayKey, time: mt.time) ?? now
        let onTimeFlag: Bool = {
            let start = taskDate.addingTimeInterval(TimeInterval(-gm * 60))
            let end = taskDate.addingTimeInterval(TimeInterval(gm * 60))
            return now >= start && now <= end
        }()
        completed.insert(uuid)
        state.completions[dayKey] = completed
        var pet = state.pet
        let cfg = (try? StageConfigLoader().load(bundle: .main)) ?? StageCfg.defaultConfig()
        PetEngine.onCheck(onTime: onTimeFlag, pet: &pet, cfg: cfg)
        state.pet = pet
        try? shared.saveState(state)
        return .result()
    }
}



