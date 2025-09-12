import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    private let shared = SharedStore()
    private let loader = StageConfigLoader()

    func placeholder(in context: Context) -> PetEntry {
        PetEntry(date: Date(), stageIndex: 0, stageXP: 0, threshold: 10, tasksDone: 0, tasksTotal: 0, rows: [], dayKey: dayKey(for: Date()))
    }

    func getSnapshot(in context: Context, completion: @escaping (PetEntry) -> ()) {
        let entry = buildEntry(for: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PetEntry>) -> ()) {
        let now = Date()
        var entries: [PetEntry] = []
        let calendar = Calendar.current
        let firstTopOfHour = calendar.date(bySetting: .minute, value: 0, of: now) ?? now
        let start = firstTopOfHour <= now ? calendar.date(byAdding: .hour, value: 1, to: firstTopOfHour)! : firstTopOfHour
        for offset in 0..<24 {
            if let date = calendar.date(byAdding: .hour, value: offset, to: start) {
                entries.append(buildEntry(for: date))
            }
        }
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }

    private func buildEntry(for date: Date) -> PetEntry {
        let cfg = (try? loader.load(bundle: .main)) ?? StageCfg.defaultConfig()
        let dk = dayKey(for: date)
        let state = (try? shared.loadState()) ?? AppState(schemaVersion: 2, dayKey: dk, tasks: [], pet: PetState(stageIndex: 0, stageXP: 0, lastCloseoutDayKey: dk), series: [], overrides: [], completions: [:], rolloverEnabled: false, graceMinutes: 60, resetTime: nil)

        let mats = materializeTasks(for: dk, in: state)
        let rows = threeTasksAround(now: date, tasks: mats)
        let total = mats.count
        let done = (state.completions[dk] ?? []).count
        let threshold = PetEngine.threshold(for: state.pet.stageIndex, cfg: cfg)
        return PetEntry(date: date, stageIndex: state.pet.stageIndex, stageXP: state.pet.stageXP, threshold: threshold, tasksDone: done, tasksTotal: total, rows: rows, dayKey: dk)
    }
}

