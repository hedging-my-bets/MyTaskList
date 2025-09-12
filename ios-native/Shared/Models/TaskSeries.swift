import Foundation

public struct TaskSeries: Codable, Identifiable, Hashable {
    public var id: UUID
    public var title: String
    // 1=Sun ... 7=Sat (Calendar.current.weekday)
    public var daysOfWeek: Set<Int>
    public var time: DateComponents
    public var isActive: Bool
    public var createdAt: Date

    public init(id: UUID = UUID(), title: String, daysOfWeek: Set<Int>, time: DateComponents, isActive: Bool = true, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.daysOfWeek = daysOfWeek
        self.time = time
        self.isActive = isActive
        self.createdAt = createdAt
    }
}



