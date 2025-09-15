import Foundation
import AppIntents
import SharedKit
import os.log
import WidgetKit
import UIKit

// MARK: - Complete Task Intent

@available(iOS 17.0, *)
struct CompleteTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Complete Task"
    static var description = IntentDescription("Marks the next scheduled task as complete")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let logger = Logger(subsystem: "com.petprogress.AppIntents", category: "CompleteTask")

        // Respect system execution budgets - timeout after 5 seconds
        let startTime = CFAbsoluteTimeGetCurrent()
        let timeout: CFAbsoluteTime = 5.0

        let now = Date()
        let dayKey = TimeSlot.dayKey(for: now)

        // Check execution time budget
        if CFAbsoluteTimeGetCurrent() - startTime > timeout {
            logger.error("CompleteTask execution exceeded time budget")
            throw AppIntentError.executionTimeout
        }

        // Use SharedStore's proper method for marking next task done
        guard let updatedDay = SharedStore.shared.markNextDone(for: dayKey, now: now) else {
            logger.warning("No tasks available to complete")
            throw AppIntentError.noTasksAvailable
        }

        // Find the completed task for feedback
        let completedTasks = updatedDay.slots.filter { $0.isDone }
        let taskName = completedTasks.last?.title ?? "Task"

        // Check for level up and provide appropriate feedback
        let oldPoints = updatedDay.points - 5  // Points before this completion
        let oldStage = PetEvolutionEngine().stageIndex(for: oldPoints)
        let newStage = PetEvolutionEngine().stageIndex(for: updatedDay.points)

        // Provide haptic feedback
        if newStage > oldStage {
            // Level up! Celebration haptic
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        } else {
            // Regular completion haptic
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }

        // Refresh widgets immediately
        WidgetCenter.shared.reloadAllTimelines()

        logger.info("Task '\(taskName)' completed via SharedStore.markNextDone")

        let dialogText = newStage > oldStage ?
            "🎉 \(taskName) completed! Level up to Stage \(newStage + 1)!" :
            "✅ \(taskName) completed!"

        return .result(dialog: IntentDialog(dialogText))
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

        // Respect system execution budgets - timeout after 5 seconds
        let startTime = CFAbsoluteTimeGetCurrent()
        let timeout: CFAbsoluteTime = 5.0

        let now = Date()
        let dayKey = TimeSlot.dayKey(for: now)

        // Check execution time budget
        if CFAbsoluteTimeGetCurrent() - startTime > timeout {
            logger.error("SkipTask execution exceeded time budget")
            throw AppIntentError.executionTimeout
        }

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

        // Check execution time budget before operations
        if CFAbsoluteTimeGetCurrent() - startTime > timeout {
            logger.error("SkipTask execution exceeded time budget")
            throw AppIntentError.executionTimeout
        }

        // Advance the widget focus index to skip this task
        let currentIndex = getCurrentWidgetIndex()
        setCurrentWidgetIndex(currentIndex + 1)

        // Provide subtle haptic feedback for skip action
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

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

        // Respect system execution budgets - timeout after 5 seconds
        let startTime = CFAbsoluteTimeGetCurrent()
        let timeout: CFAbsoluteTime = 5.0

        let now = Date()

        // Check execution time budget
        if CFAbsoluteTimeGetCurrent() - startTime > timeout {
            logger.error("NextTask execution exceeded time budget")
            throw AppIntentError.executionTimeout
        }

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

        // Check execution time budget before operations
        if CFAbsoluteTimeGetCurrent() - startTime > timeout {
            logger.error("NextTask execution exceeded time budget")
            throw AppIntentError.executionTimeout
        }

        // Get current index and advance with bounds checking
        let currentIndex = getCurrentWidgetIndex()
        let newIndex = min(currentIndex + 1, availableTasks.count - 1)

        setCurrentWidgetIndex(newIndex)

        // Provide subtle haptic feedback for navigation
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

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

        // Respect system execution budgets - timeout after 5 seconds
        let startTime = CFAbsoluteTimeGetCurrent()
        let timeout: CFAbsoluteTime = 5.0

        let now = Date()

        // Check execution time budget
        if CFAbsoluteTimeGetCurrent() - startTime > timeout {
            logger.error("PrevTask execution exceeded time budget")
            throw AppIntentError.executionTimeout
        }

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

        // Check execution time budget before operations
        if CFAbsoluteTimeGetCurrent() - startTime > timeout {
            logger.error("PrevTask execution exceeded time budget")
            throw AppIntentError.executionTimeout
        }

        // Get current index and go back with bounds checking
        let currentIndex = getCurrentWidgetIndex()
        let newIndex = max(0, currentIndex - 1)

        setCurrentWidgetIndex(newIndex)

        // Provide subtle haptic feedback for navigation
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

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
    case executionTimeout
    case operationFailed

    var errorDescription: String? {
        switch self {
        case .noTasksAvailable:
            return "No tasks scheduled"
        case .allTasksComplete:
            return "All tasks completed"
        case .executionTimeout:
            return "Operation timed out. Try again."
        case .operationFailed:
            return "Something went wrong. Try again."
        }
    }
}

// MARK: - App Intents Provider

@available(iOS 17.0, *)
struct PetProgressAppIntentsProvider: AppIntentsProvider {
    static var appIntents: [any AppIntent.Type] {
        return [
            CompleteTaskIntent.self,
            SkipTaskIntent.self,
            ShowNextTaskIntent.self,
            ShowPreviousTaskIntent.self
        ]
    }
}