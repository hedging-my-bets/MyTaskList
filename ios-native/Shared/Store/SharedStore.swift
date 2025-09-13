import Foundation

// Keep the model intentionally simple so tests don't rely on CoreData/SwiftData.
// You can replace this later with SwiftData + App Group storage.
// Tests will pass as long as semantics match.

struct DayModel: Codable {
    struct Slot: Codable {
        var hour: Int       // 0...23
        var isDone: Bool
    }
    var key: String        // "YYYY-MM-DD"
    var slots: [Slot]      // exactly 24 slots, hour == index by convention
}

final class SharedStore {
    static let shared = SharedStore()

    private let defaults: UserDefaults
    private let keyPrefix = "DayModel."

    // Use suite for extension/test determinism; harmless if the suite isn't present.
    private init() {
        self.defaults = UserDefaults(suiteName: "group.hedging-my-bets.mytasklist") ?? .standard
    }

    func loadDay(key: String) -> DayModel? {
        guard let data = defaults.data(forKey: keyPrefix + key) else { return nil }
        return try? JSONDecoder().decode(DayModel.self, from: data)
    }

    func saveDay(_ day: DayModel) {
        if let data = try? JSONEncoder().encode(day) {
            defaults.set(data, forKey: keyPrefix + day.key)
        }
    }
}