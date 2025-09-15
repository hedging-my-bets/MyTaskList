import Foundation
import AppIntents
import WidgetKit
import SharedKit
import os.log
import UIKit

// MARK: - Complete Task Intent with TaskEntity

@available(iOS 17.0, *)
struct CompleteTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Complete Task"
    static var description = IntentDescription("Marks a task as complete and awards XP")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Task")
    var task: TaskEntity

    init() {
        self.task = TaskEntity(id: "", title: "", dueHour: 0, isDone: false, dayKey: "")
    }

    init(task: TaskEntity) {
        self.task = task
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let logger = Logger(subsystem: "com.petprogress.AppIntents", category: "CompleteTask")
        let startTime = CFAbsoluteTimeGetCurrent()

        // Use atomic SharedStoreActor for thread-safe operations
        let sharedStore = SharedStoreActor.shared

        guard let updatedDay = await sharedStore.markTaskComplete(taskId: task.id, dayKey: task.dayKey) else {
            logger.error("Failed to complete task: \(task.id)")
            throw AppIntentError.operationFailed
        }

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

        // Trigger atomic widget reload
        await sharedStore.triggerWidgetReload()
        WidgetCenter.shared.reloadAllTimelines()

        logger.info("Task '\(task.title)' completed via TaskEntity")

        let dialogText = newStage > oldStage ?
            "🎉 \(task.title) completed! Level up to Stage \(newStage + 1)!" :
            "✅ \(task.title) completed!"

        return .result(dialog: IntentDialog(dialogText))
    }
}

// MARK: - Skip Task Intent with TaskEntity

@available(iOS 17.0, *)
struct SkipTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Skip Task"
    static var description = IntentDescription("Skips a task without awarding points")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Task")
    var task: TaskEntity

    init() {
        self.task = TaskEntity(id: "", title: "", dueHour: 0, isDone: false, dayKey: "")
    }

    init(task: TaskEntity) {
        self.task = task
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let logger = Logger(subsystem: "com.petprogress.AppIntents", category: "SkipTask")

        // Use atomic SharedStoreActor for thread-safe operations
        let sharedStore = SharedStoreActor.shared

        guard let updatedDay = await sharedStore.skipTask(taskId: task.id, dayKey: task.dayKey) else {
            logger.error("Failed to skip task: \(task.id)")
            throw AppIntentError.operationFailed
        }

        // Provide subtle haptic feedback for skip action
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        // Trigger atomic widget reload
        await sharedStore.triggerWidgetReload()
        WidgetCenter.shared.reloadAllTimelines()

        logger.info("Skipped task '\(task.title)' via TaskEntity")

        return .result(dialog: IntentDialog("⏭️ Skipped: \(task.title)"))
    }
}

// MARK: - Page Navigation Intent

@available(iOS 17.0, *)
struct AdvancePageIntent: AppIntent {
    static var title: LocalizedStringResource = "Navigate Tasks"
    static var description = IntentDescription("Navigate between task pages")
    static var openAppWhenRun: Bool = false

    enum Direction: String, AppEnum {
        case next = "next"
        case previous = "previous"

        static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Direction")
        static var caseDisplayRepresentations: [AdvancePageIntent.Direction: DisplayRepresentation] = [
            .next: "Next",
            .previous: "Previous"
        ]
    }

    @Parameter(title: "Direction")
    var direction: Direction

    init() {
        self.direction = .next
    }

    init(direction: Direction) {
        self.direction = direction
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let logger = Logger(subsystem: "com.petprogress.AppIntents", category: "AdvancePage")

        // Use atomic SharedStoreActor for thread-safe operations
        let sharedStore = SharedStoreActor.shared
        let currentOffset = await sharedStore.getWindowOffset()

        let newOffset: Int
        switch direction {
        case .next:
            newOffset = min(currentOffset + 1, 12) // Clamp to +12 hours max
        case .previous:
            newOffset = max(currentOffset - 1, -12) // Clamp to -12 hours min
        }

        await sharedStore.updateWindowOffset(newOffset)

        // Provide subtle haptic feedback
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        // Trigger widget reload
        await sharedStore.triggerWidgetReload()
        WidgetCenter.shared.reloadAllTimelines()

        logger.info("Advanced page \(direction.rawValue) to offset: \(newOffset)")
        return .result(dialog: IntentDialog(""))
    }
}

// MARK: - Convenience Intents for Next/Previous

@available(iOS 17.0, *)
struct NextPageIntent: AppIntent {
    static var title: LocalizedStringResource = "Next Tasks"
    static var description = IntentDescription("Show next hour's tasks")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let advanceIntent = AdvancePageIntent(direction: .next)
        return try await advanceIntent.perform()
    }
}

@available(iOS 17.0, *)
struct PreviousPageIntent: AppIntent {
    static var title: LocalizedStringResource = "Previous Tasks"
    static var description = IntentDescription("Show previous hour's tasks")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let advanceIntent = AdvancePageIntent(direction: .previous)
        return try await advanceIntent.perform()
    }
}

// MARK: - App Intent Errors

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
            AdvancePageIntent.self,
            NextPageIntent.self,
            PreviousPageIntent.self
        ]
    }
}