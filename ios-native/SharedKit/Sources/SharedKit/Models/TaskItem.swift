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
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)

        // Validate and normalize scheduledAt
        var normalizedScheduledAt = scheduledAt
        if let hour = scheduledAt.hour {
            normalizedScheduledAt.hour = max(0, min(23, hour))
        }
        if let minute = scheduledAt.minute {
            normalizedScheduledAt.minute = max(0, min(59, minute))
        }
        self.scheduledAt = normalizedScheduledAt

        self.dayKey = dayKey
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.snoozedUntil = snoozedUntil
    }

    public var isValid: Bool {
        return !title.isEmpty &&
               dayKey.count == 10 && // Expected format: YYYY-MM-DD
               (scheduledAt.hour ?? 0) >= 0 && (scheduledAt.hour ?? 0) <= 23 &&
               (scheduledAt.minute ?? 0) >= 0 && (scheduledAt.minute ?? 0) <= 59
    }
}
