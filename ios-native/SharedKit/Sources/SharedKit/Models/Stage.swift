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
}

public struct StageCfg: Codable {
    public let stages: [Stage]

    public init(stages: [Stage]) {
        self.stages = stages
    }

    public static func defaultConfig() -> StageCfg {
        let stageData: [(String, Int, String)] = [
            ("Frog", 10, "pet_frog"),
            ("Hermit Crab", 25, "pet_hermit"),
            ("Seahorse", 40, "pet_seahorse"),
            ("Dolphin", 55, "pet_dolphin"),
            ("Alligator", 75, "pet_alligator"),
            ("Beaver", 95, "pet_beaver"),
            ("Wolf", 120, "pet_wolf"),
            ("Bear", 145, "pet_bear"),
            ("Bison", 175, "pet_bison"),
            ("Elephant", 205, "pet_elephant"),
            ("Rhino", 240, "pet_rhino"),
            ("Baby", 285, "pet_baby"),
            ("Toddler", 335, "pet_toddler"),
            ("Adult", 390, "pet_adult"),
            ("CEO", 450, "pet_ceo"),
            ("Gold", 0, "pet_gold")
        ]

        let stages = stageData.enumerated().map { index, data in
            Stage(index: index, name: data.0, threshold: data.1, asset: data.2)
        }

        return StageCfg(stages: stages)
    }
}