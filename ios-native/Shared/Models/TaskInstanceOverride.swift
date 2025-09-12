import Foundation

public struct TaskInstanceOverride: Codable, Identifiable, Hashable {
    public var id: UUID
    public var seriesId: UUID?
    public var dayKey: String
    public var title: String?
    public var time: DateComponents?
    public var isDeleted: Bool
    public var createdAt: Date

    public init(id: UUID = UUID(), seriesId: UUID?, dayKey: String, title: String? = nil, time: DateComponents? = nil, isDeleted: Bool = false, createdAt: Date = Date()) {
        self.id = id
        self.seriesId = seriesId
        self.dayKey = dayKey
        self.title = title
        self.time = time
        self.isDeleted = isDeleted
        self.createdAt = createdAt
    }
}



