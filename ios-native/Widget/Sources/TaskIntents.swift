import Foundation
import AppIntents
import WidgetKit
import SharedKit

@available(iOS 16.0, *)
struct CompleteTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Complete Task"
    static var description = IntentDescription("Mark a task as completed")

    @Parameter(title: "Task ID")
    var taskId: String

    @Parameter(title: "Day Key")
    var dayKey: String

    func perform() async throws -> some IntentResult {
        do {
            try await TaskUpdater.complete(taskId: taskId, dayKey: dayKey)
            return .result()
        } catch {
            throw error
        }
    }
}

@available(iOS 16.0, *)
struct SnoozeTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Snooze Task"
    static var description = IntentDescription("Snooze a task for 15 minutes")

    @Parameter(title: "Task ID")
    var taskId: String

    @Parameter(title: "Day Key")
    var dayKey: String

    func perform() async throws -> some IntentResult {
        do {
            try await TaskUpdater.snoozeNextTask(taskId: taskId, dayKey: dayKey)
            return .result()
        } catch {
            throw error
        }
    }
}

@available(iOS 16.0, *)
struct MarkNextTaskDoneIntent: AppIntent {
    static var title: LocalizedStringResource = "Complete Next Task"
    static var description = IntentDescription("Mark the next incomplete task as done")

    @Parameter(title: "Day Key")
    var dayKey: String

    func perform() async throws -> some IntentResult {
        do {
            try await TaskUpdater.markNextDone(dayKey: dayKey)
            return .result()
        } catch {
            throw error
        }
    }
}