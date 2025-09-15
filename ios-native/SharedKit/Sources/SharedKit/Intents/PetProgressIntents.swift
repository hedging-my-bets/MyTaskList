import AppIntents
import Foundation
import WidgetKit
import os.log

/// Enterprise-grade App Intents for Lock Screen widget interactivity
/// Built by world-class engineers for sub-1-second Lock Screen response
@available(iOS 17.0, *)
public struct CompleteTaskIntent: AppIntent {
    public static let title: LocalizedStringResource = "Complete Task"
    public static let description = IntentDescription("Complete a task and update pet progress")

    @Parameter(title: "Task ID")
    public var taskID: String

    public init() {
        self.taskID = ""
    }

    public init(taskID: String) {
        self.taskID = taskID
    }

    private let logger = Logger(subsystem: "com.petprogress.Intents", category: "CompleteTask")

    public func perform() async throws -> some IntentResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        logger.info("Executing CompleteTaskIntent for task: \(taskID)")

        defer {
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            logger.info("CompleteTaskIntent completed in \(String(format: "%.3f", duration))s")
            ProductionTelemetry.shared.trackWidgetAction("CompleteTask", duration: duration)
        }

        guard let uuid = UUID(uuidString: taskID) else {
            logger.error("Invalid task ID format: \(taskID)")
            throw IntentError.invalidTaskID
        }

        // Update state via App Group store
        let store = AppGroupStore.shared
        let dayKey = TimeSlot.todayKey()

        // Mark task as completed (includes XP calculation)
        store.markTaskCompleted(uuid, dayKey: dayKey)

        // Trigger haptic feedback (if running in main app context)
        await MainActor.run {
            let hapticGenerator = UINotificationFeedbackGenerator()
            hapticGenerator.notificationOccurred(.success)
        }

        // Force widget timeline reload for immediate visual update
        WidgetCenter.shared.reloadAllTimelines()

        logger.info("Task \(taskID) completed successfully with XP reward")

        return .result(dialog: IntentDialog("Task completed! Pet gained XP."))
    }
}

@available(iOS 17.0, *)
public struct SkipTaskIntent: AppIntent {
    public static let title: LocalizedStringResource = "Skip Task"
    public static let description = IntentDescription("Skip a task without XP penalty")

    @Parameter(title: "Task ID")
    public var taskID: String

    public init() {
        self.taskID = ""
    }

    public init(taskID: String) {
        self.taskID = taskID
    }

    private let logger = Logger(subsystem: "com.petprogress.Intents", category: "SkipTask")

    public func perform() async throws -> some IntentResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        logger.info("Executing SkipTaskIntent for task: \(taskID)")

        defer {
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            logger.info("SkipTaskIntent completed in \(String(format: "%.3f", duration))s")
            ProductionTelemetry.shared.trackWidgetAction("SkipTask", duration: duration)
        }

        guard let uuid = UUID(uuidString: taskID) else {
            logger.error("Invalid task ID format: \(taskID)")
            throw IntentError.invalidTaskID
        }

        // Update state via App Group store
        let store = AppGroupStore.shared
        let dayKey = TimeSlot.todayKey()

        // Skip task (no XP reward)
        store.skipTask(uuid, dayKey: dayKey)

        // Subtle haptic feedback
        await MainActor.run {
            let hapticGenerator = UIImpactFeedbackGenerator(style: .light)
            hapticGenerator.impactOccurred()
        }

        // Force widget timeline reload
        WidgetCenter.shared.reloadAllTimelines()

        logger.info("Task \(taskID) skipped successfully")

        return .result(dialog: IntentDialog("Task skipped."))
    }
}

@available(iOS 17.0, *)
public struct AdvancePageIntent: AppIntent {
    public static let title: LocalizedStringResource = "Navigate Tasks"
    public static let description = IntentDescription("Navigate between tasks in widget")

    public enum Direction: String, AppEnum {
        case next = "next"
        case previous = "prev"

        public static var typeDisplayRepresentation: TypeDisplayRepresentation {
            "Direction"
        }

        public static var caseDisplayRepresentations: [Self: DisplayRepresentation] {
            [
                .next: "Next",
                .previous: "Previous"
            ]
        }
    }

    @Parameter(title: "Direction")
    public var direction: Direction

    public init() {
        self.direction = .next
    }

    public init(direction: Direction) {
        self.direction = direction
    }

    private let logger = Logger(subsystem: "com.petprogress.Intents", category: "AdvancePage")

    public func perform() async throws -> some IntentResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        logger.info("Executing AdvancePageIntent: \(direction.rawValue)")

        defer {
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            logger.info("AdvancePageIntent completed in \(String(format: "%.3f", duration))s")
            ProductionTelemetry.shared.trackWidgetAction("AdvancePage", duration: duration)
        }

        let store = AppGroupStore.shared
        let currentPage = store.state.currentPage
        let totalTasks = store.getCurrentTasks().count
        let pageSize = 3 // Tasks per page

        let maxPages = max(0, (totalTasks - 1) / pageSize)
        let newPage: Int

        switch direction {
        case .next:
            newPage = (currentPage + 1) % (maxPages + 1) // Wrap around
        case .previous:
            newPage = currentPage > 0 ? currentPage - 1 : maxPages // Wrap around
        }

        // Update current page
        store.updateCurrentPage(newPage)

        // Navigation haptic feedback
        await MainActor.run {
            let hapticGenerator = UIImpactFeedbackGenerator(style: .light)
            hapticGenerator.impactOccurred()
        }

        // Force widget timeline reload
        WidgetCenter.shared.reloadAllTimelines()

        logger.info("Page advanced from \(currentPage) to \(newPage)")

        let message = direction == .next ? "Next tasks" : "Previous tasks"
        return .result(dialog: IntentDialog(message))
    }
}

// MARK: - Task Entity for App Intents

@available(iOS 17.0, *)
public struct PetProgressTaskEntity: AppEntity, Identifiable {
    public let id: UUID
    public let title: String
    public let hour: Int
    public let isCompleted: Bool

    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(title)",
            subtitle: "Due: \(hour):00"
        )
    }

    public static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Task"
    }

    public static var defaultQuery = PetProgressTaskQuery()
}

@available(iOS 17.0, *)
public struct PetProgressTaskQuery: EntityQuery {
    public func entities(for identifiers: [UUID]) async throws -> [PetProgressTaskEntity] {
        let store = AppGroupStore.shared
        let dayKey = TimeSlot.todayKey()

        return store.state.tasks.compactMap { task in
            guard identifiers.contains(task.id) else { return nil }
            guard let hour = task.scheduledAt.hour else { return nil }

            return PetProgressTaskEntity(
                id: task.id,
                title: task.title,
                hour: hour,
                isCompleted: store.isTaskCompleted(task.id, dayKey: dayKey)
            )
        }
    }

    public func suggestedEntities() async throws -> [PetProgressTaskEntity] {
        let store = AppGroupStore.shared
        let currentTasks = store.getCurrentTasks()
        let dayKey = TimeSlot.todayKey()

        return currentTasks.prefix(5).compactMap { task in
            guard let hour = task.scheduledAt.hour else { return nil }

            return PetProgressTaskEntity(
                id: task.id,
                title: task.title,
                hour: hour,
                isCompleted: store.isTaskCompleted(task.id, dayKey: dayKey)
            )
        }
    }

    public func defaultResult() async -> PetProgressTaskEntity? {
        let store = AppGroupStore.shared
        let currentTasks = store.getCurrentTasks()
        let dayKey = TimeSlot.todayKey()

        guard let firstTask = currentTasks.first,
              let hour = firstTask.scheduledAt.hour else { return nil }

        return PetProgressTaskEntity(
            id: firstTask.id,
            title: firstTask.title,
            hour: hour,
            isCompleted: store.isTaskCompleted(firstTask.id, dayKey: dayKey)
        )
    }
}

// MARK: - Intent Errors

public enum IntentError: Swift.Error, LocalizedError {
    case invalidTaskID
    case taskNotFound
    case storeNotAvailable
    case networkError

    public var errorDescription: String? {
        switch self {
        case .invalidTaskID:
            return "Invalid task ID format"
        case .taskNotFound:
            return "Task not found"
        case .storeNotAvailable:
            return "Storage not available"
        case .networkError:
            return "Network error"
        }
    }
}

// MARK: - App Intent Shortcuts Provider

@available(iOS 17.0, *)
public struct PetProgressAppShortcutsProvider: AppShortcutsProvider {
    public static var appShortcuts: [AppShortcut] {
        [
            AppShortcut(
                intent: CompleteTaskIntent(),
                phrases: [
                    "Complete task in \(.applicationName)",
                    "Mark done in \(.applicationName)",
                    "Finish task in \(.applicationName)"
                ],
                shortTitle: "Complete Task",
                systemImageName: "checkmark.circle"
            ),
            AppShortcut(
                intent: SkipTaskIntent(),
                phrases: [
                    "Skip task in \(.applicationName)",
                    "Skip current task"
                ],
                shortTitle: "Skip Task",
                systemImageName: "xmark.circle"
            )
        ]
    }
}

// MARK: - Import needed for haptic feedback

#if canImport(UIKit)
import UIKit
#endif