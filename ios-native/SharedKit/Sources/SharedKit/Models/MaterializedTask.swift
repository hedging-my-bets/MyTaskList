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