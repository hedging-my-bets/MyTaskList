import AppIntents
import Foundation
import WidgetKit

@available(iOS 17.0, *)
public struct SnoozeNextTaskIntent: AppIntent {
    public static var title: LocalizedStringResource = "Snooze Next Task 15m"
    public static var openAppWhenRun: Bool = false

    @Parameter(title: "Task ID") public var taskId: String
    @Parameter(title: "Day Key") public var dayKey: String

    public init() { }
    public init(taskId: String, dayKey: String) {
        self.taskId = taskId
        self.dayKey = dayKey
    }

    public func perform() async throws -> some IntentResult {
        try await TaskUpdater.snoozeNextTask(taskId: taskId, dayKey: dayKey)
        return .result()
    }
}