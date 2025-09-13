import Foundation

public struct TaskItem: Identifiable, Codable, Hashable {
    public let id: UUID
    public var title: String
    public var scheduledAt: DateComponents
    public var dayKey: String
    public var isCompleted: Bool
    public var completedAt: Date?
    public var snoozedUntil: Date?

    public init(
        id: UUID = UUID(),
        title: String,
        scheduledAt: DateComponents,
        dayKey: String,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        snoozedUntil: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.scheduledAt = scheduledAt
        self.dayKey = dayKey
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.snoozedUntil = snoozedUntil
    }
}