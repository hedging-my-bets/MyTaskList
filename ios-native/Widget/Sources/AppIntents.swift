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
    static var description = IntentDescription("Marks a task as complete")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Task ID")
    var taskId: String?

    @Parameter(title: "Day Key")
    var dayKey: String?

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let logger = Logger(subsystem: "com.petprogress.AppIntents", category: "CompleteTask")

        // Respect system execution budgets - timeout after 5 seconds
        let startTime = CFAbsoluteTimeGetCurrent()
        let timeout: CFAbsoluteTime = 5.0

        let now = Date()
        let targetDayKey = dayKey ?? TimeSlot.dayKey(for: now)

        // Check execution time budget
        if CFAbsoluteTimeGetCurrent() - startTime > timeout {
            logger.error("CompleteTask execution exceeded time budget")
            throw AppIntentError.executionTimeout
        }

        // Use atomic SharedStoreActor for thread-safe operations
        let sharedStore = SharedStoreActor.shared

        let updatedDay: DayModel?
        if let specificTaskId = taskId {
            // Complete specific task by ID
            updatedDay = await sharedStore.markTaskComplete(taskId: specificTaskId, dayKey: targetDayKey)
        } else {
            // Fallback to completing next available task
            guard let currentDay = await sharedStore.getCurrentDayModel() else {
                logger.warning("No day model available")
                throw AppIntentError.noTasksAvailable
            }

            let currentHour = Calendar.current.component(.hour, from: now)
            guard let nextTask = currentDay.slots.first(where: { $0.hour >= currentHour && !$0.isDone }) else {
                logger.warning("No tasks available to complete")
                throw AppIntentError.allTasksComplete
            }

            updatedDay = await sharedStore.markTaskComplete(taskId: nextTask.id, dayKey: targetDayKey)
        }

        guard let day = updatedDay else {
            logger.error("Failed to complete task")
            throw AppIntentError.operationFailed
        }

        // Find the completed task for feedback
        let taskName = day.slots.first(where: { $0.id == taskId })?.title ?? "Task"

        // Check for level up and provide appropriate feedback
        let oldPoints = day.points - 5  // Points before this completion
        let oldStage = PetEvolutionEngine().stageIndex(for: oldPoints)
        let newStage = PetEvolutionEngine().stageIndex(for: day.points)

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

        // Trigger atomic widget reload
        await sharedStore.triggerWidgetReload()
        WidgetCenter.shared.reloadAllTimelines()

        logger.info("Task '\(taskName)' completed via SharedStoreActor.markTaskComplete")

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
    static var description = IntentDescription("Skips a task without awarding points")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Task ID")
    var taskId: String?

    @Parameter(title: "Day Key")
    var dayKey: String?

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let logger = Logger(subsystem: "com.petprogress.AppIntents", category: "SkipTask")

        // Respect system execution budgets - timeout after 5 seconds
        let startTime = CFAbsoluteTimeGetCurrent()
        let timeout: CFAbsoluteTime = 5.0

        let now = Date()
        let targetDayKey = dayKey ?? TimeSlot.dayKey(for: now)

        // Check execution time budget
        if CFAbsoluteTimeGetCurrent() - startTime > timeout {
            logger.error("SkipTask execution exceeded time budget")
            throw AppIntentError.executionTimeout
        }

        // Use atomic SharedStoreActor for thread-safe operations
        let sharedStore = SharedStoreActor.shared

        let updatedDay: DayModel?
        if let specificTaskId = taskId {
            // Skip specific task by ID
            updatedDay = await sharedStore.skipTask(taskId: specificTaskId, dayKey: targetDayKey)
        } else {
            // Fallback to skipping next available task
            guard let currentDay = await sharedStore.getCurrentDayModel() else {
                logger.warning("No day model available")
                throw AppIntentError.noTasksAvailable
            }

            let currentHour = Calendar.current.component(.hour, from: now)
            guard let nextTask = currentDay.slots.first(where: { $0.hour >= currentHour && !$0.isDone }) else {
                logger.warning("No tasks available to skip")
                throw AppIntentError.allTasksComplete
            }

            updatedDay = await sharedStore.skipTask(taskId: nextTask.id, dayKey: targetDayKey)
        }

        guard let day = updatedDay else {
            logger.error("Failed to skip task")
            throw AppIntentError.operationFailed
        }

        // Find the skipped task for feedback
        let taskName = day.slots.first(where: { $0.id == taskId })?.title ?? "Task"

        // Provide subtle haptic feedback for skip action
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        // Trigger atomic widget reload
        await sharedStore.triggerWidgetReload()
        WidgetCenter.shared.reloadAllTimelines()

        logger.info("Skipped task '\(taskName)' via SharedStoreActor.skipTask")

        return .result(dialog: IntentDialog("⏭️ Skipped: \(taskName)"))
    }
}

// MARK: - Navigation Intents

@available(iOS 17.0, *)
struct NextWindowIntent: AppIntent {
    static var title: LocalizedStringResource = "Next Hour Window"
    static var description = IntentDescription("Move widget view to next hour window")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let logger = Logger(subsystem: "com.petprogress.AppIntents", category: "NextWindow")

        // Use atomic SharedStoreActor for thread-safe operations
        let sharedStore = SharedStoreActor.shared
        let currentOffset = await sharedStore.getWindowOffset()
        let newOffset = min(currentOffset + 1, 12) // Clamp to +12 hours max

        await sharedStore.updateWindowOffset(newOffset)

        // Provide subtle haptic feedback
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        // Trigger widget reload
        await sharedStore.triggerWidgetReload()
        WidgetCenter.shared.reloadAllTimelines()

        logger.info("Advanced window offset to: \(newOffset)")
        return .result(dialog: IntentDialog(""))
    }
}

@available(iOS 17.0, *)
struct PrevWindowIntent: AppIntent {
    static var title: LocalizedStringResource = "Previous Hour Window"
    static var description = IntentDescription("Move widget view to previous hour window")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let logger = Logger(subsystem: "com.petprogress.AppIntents", category: "PrevWindow")

        // Use atomic SharedStoreActor for thread-safe operations
        let sharedStore = SharedStoreActor.shared
        let currentOffset = await sharedStore.getWindowOffset()
        let newOffset = max(currentOffset - 1, -12) // Clamp to -12 hours min

        await sharedStore.updateWindowOffset(newOffset)

        // Provide subtle haptic feedback
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        // Trigger widget reload
        await sharedStore.triggerWidgetReload()
        WidgetCenter.shared.reloadAllTimelines()

        logger.info("Moved window offset to: \(newOffset)")
        return .result(dialog: IntentDialog(""))
    }
}

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

        // Use atomic SharedStoreActor for thread-safe operations
        let sharedStore = SharedStoreActor.shared
        let currentOffset = await sharedStore.getWindowOffset()
        let newOffset = min(currentOffset + 1, 12)

        await sharedStore.updateWindowOffset(newOffset)

        // Provide subtle haptic feedback for navigation
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        // Trigger widget reload
        await sharedStore.triggerWidgetReload()
        WidgetCenter.shared.reloadAllTimelines()

        logger.info("Advanced task view window offset to: \(newOffset)")

        return .result(dialog: IntentDialog(""))
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

        // Use atomic SharedStoreActor for thread-safe operations
        let sharedStore = SharedStoreActor.shared
        let currentOffset = await sharedStore.getWindowOffset()
        let newOffset = max(currentOffset - 1, -12)

        await sharedStore.updateWindowOffset(newOffset)

        // Provide subtle haptic feedback for navigation
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        // Trigger widget reload
        await sharedStore.triggerWidgetReload()
        WidgetCenter.shared.reloadAllTimelines()

        logger.info("Moved task view window offset to: \(newOffset)")

        return .result(dialog: IntentDialog(""))
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
            NextWindowIntent.self,
            PrevWindowIntent.self,
            ShowNextTaskIntent.self,
            ShowPreviousTaskIntent.self
        ]
    }
}