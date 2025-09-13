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
}