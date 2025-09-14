import Foundation
import AppIntents
import WidgetKit
import SharedKit

@available(iOS 16.0, *)
struct CompleteTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Complete Task"
    static var description = IntentDescription("Mark a task as completed and earn XP for your pet")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Task ID", description: "The unique identifier of the task to complete")
    var taskId: String

    @Parameter(title: "Day Key", description: "The day the task is scheduled for")
    var dayKey: String

    init() {
        self.taskId = ""
        self.dayKey = ""
    }

    init(taskId: String, dayKey: String) {
        self.taskId = taskId
        self.dayKey = dayKey
    }

    func perform() async throws -> some IntentResult {
        do {
            try await TaskUpdater.complete(taskId: taskId, dayKey: dayKey)

            // Reload all widgets to show updated progress
            WidgetCenter.shared.reloadAllTimelines()

            return .result(dialog: IntentDialog("Task completed! Your pet earned XP! 🎉"))
        } catch {
            return .result(dialog: IntentDialog("Unable to complete task: \(error.localizedDescription)"))
        }
    }
}

@available(iOS 16.0, *)
struct SnoozeTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Snooze Task"
    static var description = IntentDescription("Snooze a task for 15 minutes")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Task ID", description: "The unique identifier of the task to snooze")
    var taskId: String

    @Parameter(title: "Day Key", description: "The day the task is scheduled for")
    var dayKey: String

    init() {
        self.taskId = ""
        self.dayKey = ""
    }

    init(taskId: String, dayKey: String) {
        self.taskId = taskId
        self.dayKey = dayKey
    }

    func perform() async throws -> some IntentResult {
        do {
            try await TaskUpdater.snoozeNextTask(taskId: taskId, dayKey: dayKey)

            // Reload all widgets to show updated schedule
            WidgetCenter.shared.reloadAllTimelines()

            return .result(dialog: IntentDialog("Task snoozed for 15 minutes ⏰"))
        } catch {
            return .result(dialog: IntentDialog("Unable to snooze task: \(error.localizedDescription)"))
        }
    }
}

@available(iOS 16.0, *)
struct MarkNextTaskDoneIntent: AppIntent {
    static var title: LocalizedStringResource = "Complete Next Task"
    static var description = IntentDescription("Mark the next incomplete task as done")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Day Key", description: "The day to find the next task")
    var dayKey: String

    init() {
        self.dayKey = ""
    }

    init(dayKey: String) {
        self.dayKey = dayKey
    }

    func perform() async throws -> some IntentResult {
        do {
            try await TaskUpdater.markNextDone(dayKey: dayKey)

            // Reload all widgets to show updated progress
            WidgetCenter.shared.reloadAllTimelines()

            return .result(dialog: IntentDialog("Next task completed! Your pet is happy! 🐸✨"))
        } catch {
            return .result(dialog: IntentDialog("Unable to complete next task: \(error.localizedDescription)"))
        }
    }
}

@available(iOS 16.0, *)
struct OpenAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Pet Progress"
    static var description = IntentDescription("Open the Pet Progress app to manage tasks")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        return .result(dialog: IntentDialog("Opening Pet Progress app..."))
    }
}
