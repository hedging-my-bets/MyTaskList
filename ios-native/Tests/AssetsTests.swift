import XCTest
@testable import PetProgress

final class AssetsTests: XCTestCase {
    func testStageConfigAssetsExist() {
        // Load StageConfig from bundle (not default)
        let loader = StageConfigLoader()
        guard let cfg = try? loader.load() else {
            XCTFail("Could not load StageConfig from bundle")
            return
        }

        for (index, stage) in cfg.stages.enumerated() {
            // Test that each stage asset can be loaded from bundle
            let image = UIImage(named: stage.asset)
            XCTAssertNotNil(image, "Asset '\(stage.asset)' for stage \(index) (\(stage.name)) should exist in bundle")
        }
    }

    func testAllPetAssetsLoadable() {
        // Load expected assets from actual StageConfig
        let loader = StageConfigLoader()
        guard let cfg = try? loader.load() else {
            // Fallback to hardcoded list if bundle loading fails in test
            let fallbackAssets = [
                "pet_tadpole", "pet_frog", "pet_hermit", "pet_seahorse", "pet_dolphin", "pet_shark",
                "pet_alligator", "pet_beaver", "pet_wolf", "pet_bear", "pet_bison", "pet_elephant",
                "pet_rhino", "pet_lion", "pet_baby", "pet_toddler", "pet_teenager",
                "pet_adult", "pet_ceo", "pet_gold"
            ]
            for assetName in fallbackAssets {
                let image = UIImage(named: assetName)
                XCTAssertNotNil(image, "Pet asset '\(assetName)' should be loadable")
            }
            return
        }

        // Test all assets referenced in StageConfig
        for stage in cfg.stages {
            let image = UIImage(named: stage.asset)
            XCTAssertNotNil(image, "Pet asset '\(stage.asset)' for '\(stage.name)' should be loadable")
        }
    }

    func testStageConfigCompleteness() {
        // Load StageConfig from bundle
        let loader = StageConfigLoader()
        guard let cfg = try? loader.load() else {
            XCTFail("Could not load StageConfig from bundle")
            return
        }

        // Verify we have exactly 16 stages
        XCTAssertEqual(cfg.stages.count, 16, "StageConfig should contain exactly 16 stages")

        // Verify final stage (Gold) has threshold 0 (terminal)
        if let finalStage = cfg.stages.last {
            XCTAssertEqual(finalStage.threshold, 0, "Final stage (Gold) should have threshold 0")
            XCTAssertEqual(finalStage.asset, "pet_gold", "Final stage should use pet_gold asset")
        }

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
