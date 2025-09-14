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

        // Use SharedStore's proper method for marking next task done
        guard let updatedDay = SharedStore.shared.markNextDone(for: dayKey, now: now) else {
            logger.warning("No tasks available to complete")
            throw AppIntentError.noTasksAvailable
        }

        // Find the completed task for feedback
        let completedTasks = updatedDay.slots.filter { $0.isDone }
        let taskName = completedTasks.last?.title ?? "Task"

        // Refresh widgets immediately
        WidgetCenter.shared.reloadAllTimelines()

        logger.info("Task '\(taskName)' completed via SharedStore.markNextDone")

        return .result(dialog: IntentDialog("✅ \(taskName) completed!"))
    }
}

// MARK: - Skip Task Intent

@available(iOS 17.0, *)
struct SkipTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Skip Task"
    static var description = IntentDescription("Skips the current task without marking it done")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let logger = Logger(subsystem: "com.petprogress.AppIntents", category: "SkipTask")

        let now = Date()
        let dayKey = TimeSlot.dayKey(for: now)

        guard let currentDay = SharedStore.shared.getCurrentDayModel(),
              !currentDay.slots.isEmpty else {
            logger.warning("No tasks available to skip")
            throw AppIntentError.noTasksAvailable
        }

        let currentHour = TimeSlot.hourIndex(for: now)
        guard let taskToSkip = currentDay.slots.first(where: { slot in
            slot.hour >= currentHour && !slot.isDone
        }) else {
            logger.info("No incomplete tasks to skip")
            throw AppIntentError.allTasksComplete
        }

        // Advance the widget focus index to skip this task
        let currentIndex = getCurrentWidgetIndex()
        setCurrentWidgetIndex(currentIndex + 1)

        // Refresh widgets to show next task
        WidgetCenter.shared.reloadAllTimelines()

        logger.info("Skipped task '\(taskToSkip.title)' by advancing widget index")

        return .result(dialog: IntentDialog("⏭️ Skipped: \(taskToSkip.title)"))
    }
}

// MARK: - Navigation Intents

@available(iOS 17.0, *)
struct ShowNextTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Next Task"
    static var description = IntentDescription("Shows the next task")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let logger = Logger(subsystem: "com.petprogress.AppIntents", category: "NextTask")

        let now = Date()

        guard let currentDay = SharedStore.shared.getCurrentDayModel(),
              !currentDay.slots.isEmpty else {
            logger.warning("No tasks available")
            throw AppIntentError.noTasksAvailable
        }

        // Get available tasks for bounds checking
        let currentHour = TimeSlot.hourIndex(for: now)
        let availableTasks = currentDay.slots.filter { slot in
            slot.hour >= currentHour && !slot.isDone
        }

        guard !availableTasks.isEmpty else {
            logger.info("No incomplete tasks available")
            throw AppIntentError.allTasksComplete
        }

        // Get current index and advance with bounds checking
        let currentIndex = getCurrentWidgetIndex()
        let newIndex = min(currentIndex + 1, availableTasks.count - 1)

        setCurrentWidgetIndex(newIndex)
        WidgetCenter.shared.reloadAllTimelines()

        logger.info("Advanced to next task (index: \(newIndex)/\(availableTasks.count))")

        return .result(dialog: IntentDialog("➡️ Next task"))
    }
}

@available(iOS 17.0, *)
struct ShowPreviousTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Previous Task"
    static var description = IntentDescription("Shows the previous task")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let logger = Logger(subsystem: "com.petprogress.AppIntents", category: "PrevTask")

        let now = Date()

        guard let currentDay = SharedStore.shared.getCurrentDayModel(),
              !currentDay.slots.isEmpty else {
            logger.warning("No tasks available")
            throw AppIntentError.noTasksAvailable
        }

        // Get available tasks for bounds checking
        let currentHour = TimeSlot.hourIndex(for: now)
        let availableTasks = currentDay.slots.filter { slot in
            slot.hour >= currentHour && !slot.isDone
        }

        guard !availableTasks.isEmpty else {
            logger.info("No incomplete tasks available")
            throw AppIntentError.allTasksComplete
        }

        // Get current index and go back with bounds checking
        let currentIndex = getCurrentWidgetIndex()
        let newIndex = max(0, currentIndex - 1)

        setCurrentWidgetIndex(newIndex)
        WidgetCenter.shared.reloadAllTimelines()

        logger.info("Moved to previous task (index: \(newIndex)/\(availableTasks.count))")

        return .result(dialog: IntentDialog("⬅️ Previous task"))
    }
}

// MARK: - Widget Focus Index Helpers

private func getCurrentWidgetIndex() -> Int {
    let sharedDefaults = UserDefaults(suiteName: "group.hedging-my-bets.mytasklist")
    return sharedDefaults?.integer(forKey: "widget_focus_index") ?? 0
}

private func setCurrentWidgetIndex(_ index: Int) {
    let sharedDefaults = UserDefaults(suiteName: "group.hedging-my-bets.mytasklist")
    sharedDefaults?.set(index, forKey: "widget_focus_index")
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