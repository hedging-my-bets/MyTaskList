import Foundation

public struct TaskInstanceOverride: Identifiable, Codable, Hashable {
    public let id: UUID
    public let seriesId: UUID
    public let dayKey: String
    public var time: DateComponents?
    public var isDeleted: Bool

    public init(
        id: UUID = UUID(),
        seriesId: UUID,
        dayKey: String,
        time: DateComponents? = nil,
        isDeleted: Bool = false
    ) {
        self.id = id
        self.seriesId = seriesId
        self.dayKey = dayKey
        self.time = time
        self.isDeleted = isDeleted
    }
}