import Foundation

public struct TaskSeries: Identifiable, Codable, Hashable {
    public let id: UUID
    public var title: String
    public var scheduledAt: DateComponents
    public var frequency: TaskFrequency
    public var isActive: Bool

    public init(
        id: UUID = UUID(),
        title: String,
        scheduledAt: DateComponents,
        frequency: TaskFrequency,
        isActive: Bool = true
    ) {
        self.id = id
        self.title = title
        self.scheduledAt = scheduledAt
        self.frequency = frequency
        self.isActive = isActive
    }
}

public enum TaskFrequency: String, Codable, CaseIterable {
    case daily = "daily"
    case weekdays = "weekdays"
    case weekly = "weekly"
    case monthly = "monthly"

    public var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekdays: return "Weekdays"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        }
    }
}