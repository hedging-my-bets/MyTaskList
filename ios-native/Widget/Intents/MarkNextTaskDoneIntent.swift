import AppIntents

struct MarkNextTaskDoneIntent: AppIntent {
    static var title: LocalizedStringResource = "Mark Next Task Done"

    func perform() async throws -> some IntentResult {
        let shared = SharedStore()
        let loader = StageConfigLoader()
        var state = (try? shared.loadState()) ?? State(tasks: [], pet: PetState(stageIndex: 0, stageXP: 0, lastCloseoutDayKey: dayKey(for: Date())), dayKey: dayKey(for: Date()), schemaVersion: 1, rolloverEnabled: false)
        let today = state.dayKey
        if let nextIdx = state.tasks.enumerated().filter({ $0.element.dayKey == today && !$0.element.isCompleted }).sorted(by: { (l, r) in
            (l.element.scheduledAt.hour ?? 0, l.element.scheduledAt.minute ?? 0) < (r.element.scheduledAt.hour ?? 0, r.element.scheduledAt.minute ?? 0)
        }).first?.offset {
            var task = state.tasks[nextIdx]
            if !task.isCompleted { // idempotent guard
                let now = Date()
                let onTimeFlag = isOnTime(task: task, now: now)
                task.isCompleted = true
                task.completedAt = now
                state.tasks[nextIdx] = task
                var petCopy = state.pet
                let cfg = (try? loader.load(bundle: .main)) ?? StageCfg.defaultConfig()
                PetEngine.onCheck(onTime: onTimeFlag, pet: &petCopy, cfg: cfg)
                state.pet = petCopy
                try? shared.saveState(state)
            }
        }
        return .result()
    }
}


