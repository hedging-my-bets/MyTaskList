import Foundation

public struct MaterializedTask: Identifiable, Hashable {
    public let id: UUID
    public let title: String
    public let time: DateComponents
    public let isCompleted: Bool
    public let origin: TaskOrigin

    public init(
        id: UUID,
        title: String,
        time: DateComponents,
        isCompleted: Bool,
        origin: TaskOrigin
    ) {
        self.id = id
        self.title = title
        self.time = time
        self.isCompleted = isCompleted
        self.origin = origin
    }
}

public enum TaskOrigin: Hashable {
    case oneOff(UUID)
    case series(UUID)
}

// MARK: - Compatibility Shims

extension MaterializedTask {
    /// Create MaterializedTask from TaskItem for compatibility
    public init(from taskItem: TaskItem) {
        self.init(
            id: taskItem.id,
            title: taskItem.title,
            time: taskItem.scheduledAt,
            isCompleted: taskItem.isCompleted,
            origin: .oneOff(taskItem.id)
        )
    }

    /// Create MaterializedTask from DayModel.Slot for compatibility
    public init(from slot: DayModel.Slot, dayKey: String) {
        var timeComponents = DateComponents()
        timeComponents.hour = slot.hour

        self.init(
            id: UUID(uuidString: slot.id) ?? UUID(),
            title: slot.title,
            time: timeComponents,
            isCompleted: slot.isDone,
            origin: .oneOff(UUID(uuidString: slot.id) ?? UUID())
        )
    }

    /// Convert to TaskItem for compatibility
    public func toTaskItem(dayKey: String) -> TaskItem {
        return TaskItem(
            id: self.id,
            title: self.title,
            scheduledAt: self.time,
            dayKey: dayKey,
            isCompleted: self.isCompleted
        )
    }

    /// TimeSlot compatibility property
    public var timeSlot: TimeSlot {
        return TimeSlot(hour: time.hour ?? 0)
    }

    /// Scheduled hour compatibility property
    public var scheduledHour: Int {
        return time.hour ?? 0
    }
}
