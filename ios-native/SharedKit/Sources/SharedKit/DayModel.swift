import Foundation

public struct DayModel: Codable, Equatable {
    public struct Slot: Codable, Equatable, Identifiable {
        public var id: String
        public var hour: Int
        public var title: String
        public var isDone: Bool

        public init(id: String? = nil, title: String, hour: Int, isDone: Bool = false) {
            self.id = id ?? UUID().uuidString
            self.hour = hour
            self.title = title
            self.isDone = isDone
        }

        // Legacy constructor for backward compatibility
        public init(hour: Int, title: String, isDone: Bool = false) {
            self.id = UUID().uuidString
            self.hour = hour
            self.title = title
            self.isDone = isDone
        }
    }

    public var key: String
    public var slots: [Slot] // 0..24 hour slots
    public var points: Int   // pet progression points (non-negative)

    public init(key: String, slots: [Slot] = [], points: Int = 0) {
        self.key = key
        self.slots = slots
        self.points = max(0, points) // Ensure points are never negative
    }
}
