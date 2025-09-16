import Foundation

/// Task planning and scheduling system
public struct TaskPlanner {
    public static let shared = TaskPlanner()

    private init() {}

    /// Creates a daily schedule with 3 evenly spaced tasks
    public func createDailySchedule(
        startHour: Int = 9,
        endHour: Int = 17,
        taskCount: Int = 3,
        for date: Date = Date()
    ) -> DayModel {
        let dayKey = TimeSlot.dayKey(for: date)

        // Calculate evenly distributed hours
        let hours = distributeHours(start: startHour, end: endHour, count: taskCount)

        // Create default task slots
        let slots = hours.enumerated().map { index, hour in
            DayModel.Slot(
                hour: hour,
                title: defaultTaskTitle(for: index),
                isDone: false
            )
        }

        return DayModel(key: dayKey, slots: slots, points: 0)
    }

    /// Gets the next 3 tasks from the current day model
    public func getNext3Tasks(from dayModel: DayModel, currentTime: Date = Date()) -> [TaskFeedItem] {
        let currentHour = TimeSlot.hourIndex(for: currentTime)

        // Get all remaining tasks (incomplete + future)
        let remainingTasks = dayModel.slots.compactMap { slot -> TaskFeedItem? in
            // Include incomplete tasks and future tasks
            if !slot.isDone || slot.hour > currentHour {
                return TaskFeedItem(
                    hour: slot.hour,
                    title: slot.title,
                    isDone: slot.isDone,
                    status: taskStatus(for: slot, currentHour: currentHour)
                )
            }
            return nil
        }

        // Sort by hour and take first 3
        return Array(remainingTasks.sorted { $0.hour < $1.hour }.prefix(3))
    }

    /// Updates an existing day with additional tasks if needed
    public func ensureMinimumTasks(dayModel: DayModel, minimumCount: Int = 3) -> DayModel {
        if dayModel.slots.count >= minimumCount {
            return dayModel
        }

        var updatedModel = dayModel
        let existingHours = Set(dayModel.slots.map { $0.hour })
        let currentCount = dayModel.slots.count

        // Add additional tasks to reach minimum
        for i in currentCount..<minimumCount {
            var newHour = 9 + (i * 3) // Default spacing: 9, 12, 15, 18, etc.

            // Avoid conflicts with existing hours
            while existingHours.contains(newHour) && newHour < 23 {
                newHour += 1
            }

            if newHour <= 23 {
                let newSlot = DayModel.Slot(
                    hour: newHour,
                    title: defaultTaskTitle(for: i),
                    isDone: false
                )
                updatedModel.slots.append(newSlot)
            }
        }

        // Re-sort by hour
        updatedModel.slots.sort { $0.hour < $1.hour }
        return updatedModel
    }

    // MARK: - Private Helpers

    private func distributeHours(start: Int, end: Int, count: Int) -> [Int] {
        guard count > 0 else { return [] }
        guard count > 1 else { return [start] }

        let range = end - start
        let interval = Double(range) / Double(count - 1)

        return (0..<count).map { index in
            let hour = start + Int(Double(index) * interval)
            return min(max(hour, start), end) // Clamp to range
        }
    }

    private func defaultTaskTitle(for index: Int) -> String {
        let titles = [
            "Morning focus session",
            "Midday check-in",
            "Afternoon deep work",
            "Evening review",
            "Late task cleanup"
        ]
        return titles[safe: index] ?? "Task \(index + 1)"
    }

    private func taskStatus(for slot: DayModel.Slot, currentHour: Int) -> TaskStatus {
        if slot.isDone {
            return .completed
        } else if slot.hour < currentHour {
            return .overdue
        } else if slot.hour == currentHour {
            return .current
        } else {
            return .upcoming
        }
    }
}

/// Represents a task item in the feed
public struct TaskFeedItem {
    public let hour: Int
    public let title: String
    public let isDone: Bool
    public let status: TaskStatus

    public var timeString: String {
        return String(format: "%02d:00", hour)
    }
}

/// Task status for UI display
public enum TaskStatus {
    case completed
    case current
    case overdue
    case upcoming

    public var displayColor: String {
        switch self {
        case .completed: return "green"
        case .current: return "blue"
        case .overdue: return "red"
        case .upcoming: return "gray"
        }
    }
}

// Array extension moved to Extensions.swift to avoid duplicates
