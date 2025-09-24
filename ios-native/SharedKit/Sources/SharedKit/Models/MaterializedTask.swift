import Foundation
import SwiftUI

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

    /// Hour index for TimeSlot compatibility
    public var hourIndex: Int {
        return time.hour ?? 0
    }

    /// Scheduled hour compatibility property
    public var scheduledHour: Int {
        return time.hour ?? 0
    }

    /// Difficulty property for compatibility
    public var difficulty: TaskDifficulty {
        return .medium
    }

    /// Scheduled time with display time property
    public var scheduledTime: ScheduledTimeDisplay {
        return ScheduledTimeDisplay(hour: time.hour ?? 0, minute: time.minute ?? 0)
    }

    /// Category property for compatibility
    public var category: TaskCategory {
        return .personal
    }

    /// Notes property for compatibility
    public var notes: String? {
        return nil
    }

    /// Keywords property for compatibility
    public var keywords: [String]? {
        return nil
    }

    /// AI estimated difficulty for compatibility
    public var aiEstimatedDifficulty: TaskDifficulty? {
        return nil
    }
}

// MARK: - Supporting Types

public enum TaskDifficulty: String, CaseIterable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"

    public var color: Color {
        switch self {
        case .easy: return .green
        case .medium: return .blue
        case .hard: return .red
        }
    }

    public var rawValue: String {
        switch self {
        case .easy: return "easy"
        case .medium: return "medium"
        case .hard: return "hard"
        }
    }
}

public enum TaskCategory: String, CaseIterable {
    case work = "Work"
    case personal = "Personal"
    case health = "Health"

    public var icon: String {
        switch self {
        case .work: return "briefcase.fill"
        case .personal: return "person.fill"
        case .health: return "heart.fill"
        }
    }

    public var color: Color {
        switch self {
        case .work: return .blue
        case .personal: return .green
        case .health: return .red
        }
    }

    public var displayName: String {
        return rawValue
    }
}

public struct ScheduledTimeDisplay {
    public let hour: Int
    public let minute: Int

    public var displayTime: String {
        return String(format: "%02d:%02d", hour, minute)
    }

    public init(hour: Int, minute: Int) {
        self.hour = hour
        self.minute = minute
    }
}
