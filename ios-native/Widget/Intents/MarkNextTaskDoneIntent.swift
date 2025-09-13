import AppIntents
import PetProgressShared
import WidgetKit

@available(iOS 17.0, *)
struct MarkNextTaskDoneIntent: AppIntent {
    static var title: LocalizedStringResource = "Mark Next Task Done"
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Day Key") var dayKey: String

    init() { }
    init(dayKey: String) {
        self.dayKey = dayKey
    }

    func perform() async throws -> some IntentResult {
        guard !dayKey.isEmpty else { return .result() }
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
        let incomplete = mats.filter { !($0.isCompleted) }
        guard let next = incomplete.min(by: { l, r in
            let lTime = (l.time.hour ?? 0, l.time.minute ?? 0)
            let rTime = (r.time.hour ?? 0, r.time.minute ?? 0)
            return lTime < rTime
        }) else {
            return .result() // No incomplete tasks
        }

        // Mark task as complete
        var completed = state.completions[dayKey] ?? Set<UUID>()
        if completed.contains(next.id) {
            return .result() // Already completed
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
        return .result()
    }
}


