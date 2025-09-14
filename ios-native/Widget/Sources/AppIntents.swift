import Foundation
import AppIntents
import SharedKit
import os.log
import WidgetKit

// MARK: - Complete Task Intent

@available(iOS 17.0, *)
struct CompleteTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Complete Task"
    static var description = IntentDescription("Marks the next scheduled task as complete")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let logger = Logger(subsystem: "com.petprogress.AppIntents", category: "CompleteTask")

        let now = Date()
        let dayKey = TimeSlot.dayKey(for: now)

        guard let currentDay = SharedStore.shared.getCurrentDayModel(),
              !currentDay.slots.isEmpty else {
            logger.warning("No tasks available")
            throw AppIntentError.noTasksAvailable
        }

        let currentHour = TimeSlot.hourIndex(for: now)
        guard let nextTaskIndex = currentDay.slots.firstIndex(where: { slot in
            slot.hour >= currentHour && !slot.isDone
        }) else {
            logger.info("All tasks completed")
            throw AppIntentError.allTasksComplete
        }

        let task = currentDay.slots[nextTaskIndex]

        // Complete the task
        SharedStore.shared.updateTaskCompletion(taskIndex: nextTaskIndex, completed: true, dayKey: dayKey)

        // Refresh widgets
        WidgetCenter.shared.reloadAllTimelines()

        logger.info("Task '\(task.title)' completed")

        return .result(dialog: IntentDialog("✅ Task '\(task.title)' completed!"))
    }
}

// MARK: - Skip Task Intent

@available(iOS 17.0, *)
struct SkipTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Skip Task"
    static var description = IntentDescription("Skips the current task")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let logger = Logger(subsystem: "com.petprogress.AppIntents", category: "SkipTask")

        let now = Date()

        guard let currentDay = SharedStore.shared.getCurrentDayModel(),
              !currentDay.slots.isEmpty else {
            logger.warning("No tasks available")
            throw AppIntentError.noTasksAvailable
        }

        let currentHour = TimeSlot.hourIndex(for: now)
        guard let nextTask = currentDay.slots.first(where: { slot in
            slot.hour >= currentHour && !slot.isDone
        }) else {
            logger.info("No tasks to skip")
            throw AppIntentError.allTasksComplete
        }

        // Refresh widgets to move to next task
        WidgetCenter.shared.reloadAllTimelines()

        logger.info("Task '\(nextTask.title)' skipped")

        return .result(dialog: IntentDialog("⏭️ Task '\(nextTask.title)' skipped"))
    }
}

// MARK: - Errors

enum AppIntentError: Error, LocalizedError {
    case noTasksAvailable
    case allTasksComplete

    var errorDescription: String? {
        switch self {
        case .noTasksAvailable:
            return "No tasks scheduled"
        case .allTasksComplete:
            return "All tasks completed"
        }
    }
}