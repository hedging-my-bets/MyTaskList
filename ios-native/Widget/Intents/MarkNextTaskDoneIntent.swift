import AppIntents
import WidgetKit

@available(iOS 17.0, *)
struct MarkNextTaskDoneIntent: AppIntent {
    static var title: LocalizedStringResource = "Mark Next Task Done"

    @Parameter(title: "Day Key") var dayKey: String

    static var openAppWhenRun: Bool = false

    init() { }
    init(dayKey: String) { self.dayKey = dayKey }

    func perform() async throws -> some IntentResult {
        // The store abstraction is intentionally tiny; see SharedStore below.
        // It must be visible to both App & Widget (place it in Shared/).
        guard var day = SharedStore.shared.loadDay(key: dayKey) else {
            return .result()
        }

        let now = Date()
        let tz  = TimeZone(identifier: "America/Vancouver") ?? .current
        let currentHour = TimeSlot.hourIndex(for: now, timeZone: tz)

        // Find the first slot that is >= current hour and not yet complete.
        if let idx = day.slots.firstIndex(where: { $0.hour >= currentHour && !$0.isDone }) {
            day.slots[idx].isDone = true
            SharedStore.shared.saveDay(day)
            WidgetCenter.shared.reloadTimelines(ofKind: "PetProgressWidget")
        }

        return .result()
    }
}