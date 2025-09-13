import AppIntents
import WidgetKit

@available(iOS 17.0, *)
public struct MarkNextTaskDoneIntent: AppIntent {
    public static var title: LocalizedStringResource = "Mark Next Task Done"
    public static var openAppWhenRun: Bool = false

    @Parameter(title: "Day Key") public var dayKey: String

    public init() { }
    public init(dayKey: String) {
        self.dayKey = dayKey
    }

    public func perform() async throws -> some IntentResult {
        try await TaskUpdater.markNextDone(dayKey: dayKey)
        return .result()
    }
}