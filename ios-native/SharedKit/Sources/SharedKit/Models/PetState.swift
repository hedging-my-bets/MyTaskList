import Foundation

public struct PetState: Codable, Hashable {
    public var stageIndex: Int
    public var stageXP: Int
    public var lastCloseoutDayKey: String

    public init(stageIndex: Int, stageXP: Int, lastCloseoutDayKey: String) {
        self.stageIndex = stageIndex
        self.stageXP = stageXP
        self.lastCloseoutDayKey = lastCloseoutDayKey
    }

    /// Computed property for compatibility with widget point system
    /// Converts stageIndex + stageXP to total points for PetEvolutionEngine
    public var points: Int {
        get {
            // Calculate total points based on stage progression
            // Each stage represents progression through the 16-stage system
            let basePoints = stageIndex * 50  // 50 points per stage roughly
            return basePoints + stageXP
        }
        set {
            // Convert points back to stage system
            let newStageIndex = min(newValue / 50, 15) // Max 15 stages (0-15)
            let newStageXP = newValue % 50

            self.stageIndex = newStageIndex
            self.stageXP = newStageXP
        }
    }
}
