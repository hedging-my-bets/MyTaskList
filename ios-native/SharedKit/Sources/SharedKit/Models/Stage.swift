import Foundation

public struct Stage: Codable, Equatable, Hashable {
    public let index: Int
    public let name: String
    public let threshold: Int
    public let asset: String

    public init(index: Int, name: String, threshold: Int, asset: String) {
        self.index = index
        self.name = name
        self.threshold = threshold
        self.asset = asset
    }

    // Shim for older call sites that expect imageName
    public var imageName: String { asset }
}

public struct StageCfg: Codable {
    public let stages: [Stage]

    public init(stages: [Stage]) {
        self.stages = stages
    }

    public static func defaultConfig() -> StageCfg {
        let stageData: [(String, Int, String)] = [
            ("Frog", 0, "pet_frog"),
            ("Hermit Crab", 25, "pet_hermit"),
            ("Seahorse", 60, "pet_seahorse"),
            ("Dolphin", 110, "pet_dolphin"),
            ("Alligator", 175, "pet_alligator"),
            ("Beaver", 255, "pet_beaver"),
            ("Wolf", 350, "pet_wolf"),
            ("Bear", 460, "pet_bear"),
            ("Bison", 585, "pet_bison"),
            ("Elephant", 725, "pet_elephant"),
            ("Rhino", 880, "pet_rhino"),
            ("Baby", 1050, "pet_baby"),
            ("Toddler", 1235, "pet_toddler"),
            ("Adult", 1435, "pet_adult"),
            ("CEO", 1650, "pet_ceo"),
            ("Gold", 1880, "pet_gold")
        ]

        let stages = stageData.enumerated().map { index, data in
            Stage(index: index, name: data.0, threshold: data.1, asset: data.2)
        }

        return StageCfg(stages: stages)
    }

    public static func standard() -> StageCfg {
        return defaultConfig()
    }

    public func threshold(for stage: Int) -> Int {
        guard stage >= 0 && stage < stages.count else { return 0 }
        return stages[stage].threshold
    }
}
