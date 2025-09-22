import AppIntents
import Foundation
import WidgetKit
import os.log
#if canImport(UIKit)
import UIKit
#endif

/// Enterprise-grade App Intents for Lock Screen widget interactivity
/// Built by world-class engineers for sub-1-second Lock Screen response
@available(iOS 17.0, *)
public struct MarkNextTaskDoneIntent: AppIntent, Sendable {
    public static let title: LocalizedStringResource = "Mark Next Task Done"
    public static let description = IntentDescription("Mark the next upcoming task as complete")

    public init() {}

    private let logger = Logger(subsystem: "com.petprogress.Intents", category: "MarkNextTaskDone")

    public func perform() async throws -> some IntentResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        logger.info("Executing MarkNextTaskDoneIntent")

        defer {
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            logger.info("MarkNextTaskDoneIntent completed in \(String(format: "%.3f", duration))s")
            ProductionTelemetry.shared.trackWidgetAction("MarkNextTaskDone", duration: duration)
        }

        // Check for rollover before performing action
        TaskRolloverHandler.shared.handleIntentExecution()

        // Get the next upcoming task
        let store = AppGroupStore.shared
        let currentTasks = store.getCurrentTasks()
        let dayKey = TimeSlot.dayKey(for: Date())

        guard let nextTask = currentTasks.first(where: { !store.isTaskCompleted($0.id, dayKey: dayKey) }) else {
            logger.info("No incomplete tasks available")
            return .result(dialog: IntentDialog("No tasks to complete right now."))
        }

        // Mark task as completed (includes XP calculation)
        store.markTaskCompleted(nextTask.id, dayKey: dayKey)

        // Trigger haptic feedback with enterprise-grade system
        #if canImport(UIKit)
        await MainActor.run {
            HapticManager.shared.taskCompleted()
        }
        #endif

        // Force widget timeline reload for immediate visual update
        WidgetCenter.shared.reloadAllTimelines()

        // Also force immediate timeline update with current date
        WidgetCenter.shared.getCurrentConfigurations { result in
            if case .success(let configs) = result {
                for config in configs {
                    WidgetCenter.shared.reloadTimelines(ofKind: config.kind)
                }
            }
        }

        logger.info("Task \(nextTask.id) completed successfully with XP reward")

        return .result(dialog: IntentDialog("\(nextTask.title) completed! Pet gained XP."))
    }
}

@available(iOS 17.0, *)
public struct SkipCurrentTaskIntent: AppIntent, Sendable {
    public static let title: LocalizedStringResource = "Skip Current Task"
    public static let description = IntentDescription("Skip the current task without XP penalty")

    public init() {}

    private let logger = Logger(subsystem: "com.petprogress.Intents", category: "SkipCurrentTask")

    public func perform() async throws -> some IntentResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        logger.info("Executing SkipCurrentTaskIntent")

        defer {
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            logger.info("SkipCurrentTaskIntent completed in \(String(format: "%.3f", duration))s")
            ProductionTelemetry.shared.trackWidgetAction("SkipCurrentTask", duration: duration)
        }

        // Check for rollover before performing action
        TaskRolloverHandler.shared.handleIntentExecution()

        // Get the current task that's within grace window
        let store = AppGroupStore.shared
        let currentTasks = store.getCurrentTasks()
        let dayKey = TimeSlot.dayKey(for: Date())

        guard let currentTask = currentTasks.first(where: { !store.isTaskCompleted($0.id, dayKey: dayKey) }) else {
            logger.info("No current task to skip")
            return .result(dialog: IntentDialog("No current task to skip."))
        }

        // Skip task (no XP reward)
        store.skipTask(currentTask.id, dayKey: dayKey)

        // Subtle haptic feedback for skip action
        #if canImport(UIKit)
        await MainActor.run {
            HapticManager.shared.taskSkipped()
        }
        #endif

        // Force widget timeline reload
        WidgetCenter.shared.reloadAllTimelines()

        // Also force immediate timeline update
        WidgetCenter.shared.getCurrentConfigurations { result in
            if case .success(let configs) = result {
                for config in configs {
                    WidgetCenter.shared.reloadTimelines(ofKind: config.kind)
                }
            }
        }

        logger.info("Task \(currentTask.id) skipped successfully")

        return .result(dialog: IntentDialog("\(currentTask.title) skipped."))
    }
}

@available(iOS 17.0, *)
public struct GoToNextTaskIntent: AppIntent, Sendable {
    public static let title: LocalizedStringResource = "Go To Next Task"
    public static let description = IntentDescription("Navigate to next task in widget")

    public init() {}

    private let logger = Logger(subsystem: "com.petprogress.Intents", category: "GoToNextTask")

    public func perform() async throws -> some IntentResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        logger.info("Executing GoToNextTaskIntent")

        defer {
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            logger.info("GoToNextTaskIntent completed in \(String(format: "%.3f", duration))s")
            ProductionTelemetry.shared.trackWidgetAction("GoToNextTask", duration: duration)
        }

        // Check for rollover before performing action
        TaskRolloverHandler.shared.handleIntentExecution()

        let store = AppGroupStore.shared
        let currentPage = store.state.currentPage
        let totalTasks = store.getCurrentTasks().count
        let pageSize = 3 // Tasks per page

        let maxPages = max(0, (totalTasks - 1) / pageSize)
        let newPage = (currentPage + 1) % (maxPages + 1) // Wrap around

        // Update current page
        store.updateCurrentPage(newPage)

        // Navigation haptic feedback
        #if canImport(UIKit)
        await MainActor.run {
            HapticManager.shared.taskNavigation()
        }
        #endif

        // Force widget timeline reload
        WidgetCenter.shared.reloadAllTimelines()

        // Also force immediate timeline update
        WidgetCenter.shared.getCurrentConfigurations { result in
            if case .success(let configs) = result {
                for config in configs {
                    WidgetCenter.shared.reloadTimelines(ofKind: config.kind)
                }
            }
        }

        logger.info("Page advanced from \(currentPage) to \(newPage)")

        return .result(dialog: IntentDialog("Next tasks"))
    }
}

@available(iOS 17.0, *)
public struct GoToPreviousTaskIntent: AppIntent, Sendable {
    public static let title: LocalizedStringResource = "Go To Previous Task"
    public static let description = IntentDescription("Navigate to previous task in widget")

    public init() {}

    private let logger = Logger(subsystem: "com.petprogress.Intents", category: "GoToPreviousTask")

    public func perform() async throws -> some IntentResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        logger.info("Executing GoToPreviousTaskIntent")

        defer {
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            logger.info("GoToPreviousTaskIntent completed in \(String(format: "%.3f", duration))s")
            ProductionTelemetry.shared.trackWidgetAction("GoToPreviousTask", duration: duration)
        }

        // Check for rollover before performing action
        TaskRolloverHandler.shared.handleIntentExecution()

        let store = AppGroupStore.shared
        let currentPage = store.state.currentPage
        let totalTasks = store.getCurrentTasks().count
        let pageSize = 3 // Tasks per page

        let maxPages = max(0, (totalTasks - 1) / pageSize)
        let newPage = currentPage > 0 ? currentPage - 1 : maxPages // Wrap around

        // Update current page
        store.updateCurrentPage(newPage)

        // Navigation haptic feedback
        #if canImport(UIKit)
        await MainActor.run {
            HapticManager.shared.taskNavigation()
        }
        #endif

        // Force widget timeline reload
        WidgetCenter.shared.reloadAllTimelines()

        // Also force immediate timeline update
        WidgetCenter.shared.getCurrentConfigurations { result in
            if case .success(let configs) = result {
                for config in configs {
                    WidgetCenter.shared.reloadTimelines(ofKind: config.kind)
                }
            }
        }

        logger.info("Page advanced from \(currentPage) to \(newPage)")

        return .result(dialog: IntentDialog("Previous tasks"))
    }
}

// MARK: - Task Entity for App Intents

@available(iOS 17.0, *)
public struct PetProgressTaskEntity: AppEntity, Identifiable, Sendable {
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
    public init() {}

    public func entities(for identifiers: [UUID]) async throws -> [PetProgressTaskEntity] {
        let store = AppGroupStore.shared
        let dayKey = TimeSlot.dayKey(for: Date())

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
        let dayKey = TimeSlot.dayKey(for: Date())

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
        let dayKey = TimeSlot.dayKey(for: Date())

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
    @AppShortcutsBuilder
    public static var appShortcuts: [AppShortcut] {
        AppShortcut(
                intent: MarkNextTaskDoneIntent(),
                phrases: [
                    "Mark next task done in \(.applicationName)",
                    "Complete next task in \(.applicationName)",
                    "Finish next task in \(.applicationName)"
                ],
                shortTitle: "Mark Next Done",
                systemImageName: "checkmark.circle"
            ),
            AppShortcut(
                intent: SkipCurrentTaskIntent(),
                phrases: [
                    "Skip current task in \(.applicationName)",
                    "Skip task in \(.applicationName)"
                ],
                shortTitle: "Skip Current",
                systemImageName: "xmark.circle"
            ),
            AppShortcut(
                intent: GoToNextTaskIntent(),
                phrases: [
                    "Go to next task in \(.applicationName)",
                    "Next task in \(.applicationName)"
                ],
                shortTitle: "Next Task",
                systemImageName: "chevron.right.circle"
            ),
            AppShortcut(
                intent: GoToPreviousTaskIntent(),
                phrases: [
                    "Go to previous task in \(.applicationName)",
                    "Previous task in \(.applicationName)"
                ],
                shortTitle: "Previous Task",
                systemImageName: "chevron.left.circle"
            )
    }
}