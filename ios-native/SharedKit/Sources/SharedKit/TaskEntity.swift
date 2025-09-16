import Foundation
import AppIntents

/// Task entity for App Intents system - represents a task that can be used in widgets and shortcuts
@available(iOS 17.0, *)
public struct TaskEntity: AppEntity, Identifiable {
    public static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Task")
    public static var defaultQuery = TaskQuery()

    public var id: String
    public var title: String
    public var dueHour: Int
    public var isDone: Bool
    public var dayKey: String

    public init(id: String, title: String, dueHour: Int, isDone: Bool, dayKey: String) {
        self.id = id
        self.title = title
        self.dueHour = dueHour
        self.isDone = isDone
        self.dayKey = dayKey
    }

    /// Convert from DayModel.Slot to TaskEntity
    public init(from slot: DayModel.Slot, dayKey: String) {
        self.id = slot.id
        self.title = slot.title
        self.dueHour = slot.hour
        self.isDone = slot.isDone
        self.dayKey = dayKey
    }

    public var displayRepresentation: DisplayRepresentation {
        let subtitle = isDone ? "✅ Completed" : "⏳ \(String(format: "%02d:00", dueHour))"
        return DisplayRepresentation(
            title: "\(title)",
            subtitle: "\(subtitle)"
        )
    }
}

/// Query provider for Task entities - provides task discovery and suggestions
@available(iOS 17.0, *)
public struct TaskQuery: EntityQuery {

    public init() {}

    public func entities(for identifiers: [TaskEntity.ID]) async throws -> [TaskEntity] {
        // Load tasks by specific IDs
        let sharedStore = SharedStoreActor.shared

        var tasks: [TaskEntity] = []

        for id in identifiers {
            if let task = await sharedStore.findTask(withId: id) {
                tasks.append(task)
            }
        }

        return tasks
    }

    public func suggestedEntities() async throws -> [TaskEntity] {
        // Provide nearest-hour tasks for suggestions
        let sharedStore = SharedStoreActor.shared

        return await sharedStore.getNearestHourTasks()
    }

    public func defaultResult() async -> TaskEntity? {
        // Return the most relevant current task
        let tasks = try? await suggestedEntities()
        return tasks?.first { !$0.isDone }
    }
}