import XCTest
@testable import SharedKit

final class AssetsTests: XCTestCase {
    func testStageConfigDefaults() {
        let cfg = StageCfg.defaultConfig()

        // Should have exactly 16 stages
        XCTAssertEqual(cfg.stages.count, 16)

        // Test first stage (Frog)
        let firstStage = cfg.stages[0]
        XCTAssertEqual(firstStage.index, 0)
        XCTAssertEqual(firstStage.name, "Frog")
        XCTAssertEqual(firstStage.threshold, 10)
        XCTAssertEqual(firstStage.asset, "pet_frog")

        // Test final stage (Gold)
        let finalStage = cfg.stages[15]
        XCTAssertEqual(finalStage.index, 15)
        XCTAssertEqual(finalStage.name, "Gold")
        XCTAssertEqual(finalStage.threshold, 0) // Terminal stage
        XCTAssertEqual(finalStage.asset, "pet_gold")

        // Test that all stages have valid thresholds (non-negative)
        for stage in cfg.stages {
            XCTAssertGreaterThanOrEqual(stage.threshold, 0)
        }

        // Test that asset names don't contain .png
        for stage in cfg.stages {
            XCTAssertFalse(stage.asset.contains(".png"), "Asset name should not contain .png extension")
        }
    }

    func testStageConfigLoadFromFile() throws {
        let loader = StageConfigLoader()

        // Should not crash when loading from bundle (even if file doesn't exist)
        let cfg = try loader.load()
        XCTAssertGreaterThan(cfg.stages.count, 0, "Should load default config if file not found")
    }

    func testStageConfigSerialization() throws {
        let originalConfig = StageCfg.defaultConfig()

        // Test JSON encoding/decoding
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(originalConfig)
        let decodedConfig = try decoder.decode(StageCfg.self, from: data)

        XCTAssertEqual(originalConfig.stages.count, decodedConfig.stages.count)

        // Test that all stages round-trip correctly
        for (original, decoded) in zip(originalConfig.stages, decodedConfig.stages) {
            XCTAssertEqual(original.index, decoded.index)
            XCTAssertEqual(original.name, decoded.name)
            XCTAssertEqual(original.threshold, decoded.threshold)
            XCTAssertEqual(original.asset, decoded.asset)
        }
    }

    func testStageProgressionThresholds() {
        let cfg = StageCfg.defaultConfig()

        // Test that thresholds generally increase (except for final stage)
        for i in 0..<(cfg.stages.count - 2) {
            let current = cfg.stages[i].threshold
            let next = cfg.stages[i + 1].threshold
            XCTAssertLessThan(current, next, "Stage \(i) threshold (\(current)) should be less than stage \(i + 1) threshold (\(next))")
        }

        // Final stage should have threshold 0 (terminal)
        XCTAssertEqual(cfg.stages.last?.threshold, 0)
    }

    func testStageConfigCompleteness() {
        let cfg = StageCfg.defaultConfig()

        // Verify stage order and assets match the 16-stage specification
        let expectedStages = [
            ("Frog", "pet_frog"),
            ("Hermit Crab", "pet_hermit"),
            ("Seahorse", "pet_seahorse"),
            ("Dolphin", "pet_dolphin"),
            ("Alligator", "pet_alligator"),
            ("Beaver", "pet_beaver"),
            ("Wolf", "pet_wolf"),
            ("Bear", "pet_bear"),
            ("Bison", "pet_bison"),
            ("Elephant", "pet_elephant"),
            ("Rhino", "pet_rhino"),
            ("Baby", "pet_baby"),
            ("Toddler", "pet_toddler"),
            ("Adult", "pet_adult"),
            ("CEO", "pet_ceo"),
            ("Gold", "pet_gold")
        ]

        for (index, (expectedName, expectedAsset)) in expectedStages.enumerated() {
            XCTAssertLessThan(index, cfg.stages.count, "Stage \(index) should exist")
            let stage = cfg.stages[index]
            XCTAssertEqual(stage.name, expectedName, "Stage \(index) should be named '\(expectedName)'")
            XCTAssertEqual(stage.asset, expectedAsset, "Stage \(index) should use asset '\(expectedAsset)'")
        }
    }
}