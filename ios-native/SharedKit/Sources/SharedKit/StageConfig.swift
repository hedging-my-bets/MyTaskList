import Foundation

public struct StageConfig: Codable {
    public struct Entry: Codable {
        public let name: String
        public let threshold: Int

        public init(name: String, threshold: Int) {
            self.name = name
            self.threshold = threshold
        }
    }

    public let stages: [Entry]

    public init(stages: [Entry]) {
        self.stages = stages
    }

    /// Default configuration with 16 stages and increasing thresholds
    public static func defaultConfig() -> StageConfig {
        return StageConfig(stages: [
            Entry(name: "pet_baby", threshold: 0),      // Stage 0
            Entry(name: "pet_toddler", threshold: 10),   // Stage 1
            Entry(name: "pet_frog", threshold: 25),      // Stage 2
            Entry(name: "pet_hermit", threshold: 45),    // Stage 3
            Entry(name: "pet_seahorse", threshold: 70),  // Stage 4
            Entry(name: "pet_dolphin", threshold: 100),  // Stage 5
            Entry(name: "pet_alligator", threshold: 135), // Stage 6
            Entry(name: "pet_beaver", threshold: 175),   // Stage 7
            Entry(name: "pet_wolf", threshold: 220),     // Stage 8
            Entry(name: "pet_bear", threshold: 270),     // Stage 9
            Entry(name: "pet_bison", threshold: 325),    // Stage 10
            Entry(name: "pet_elephant", threshold: 385), // Stage 11
            Entry(name: "pet_rhino", threshold: 450),    // Stage 12
            Entry(name: "pet_adult", threshold: 520),    // Stage 13
            Entry(name: "pet_ceo", threshold: 595),      // Stage 14
            Entry(name: "pet_gold", threshold: 675)      // Stage 15
        ])
    }
}
