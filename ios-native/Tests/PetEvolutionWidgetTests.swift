import XCTest
import Foundation
@testable import SharedKit

/// Tests for pet evolution XP rules and thresholds in widget context
final class PetEvolutionWidgetTests: XCTestCase {

    func testXPThresholdLogic() {
        let engine = PetEvolutionEngine()

        // Test threshold method for all stages
        XCTAssertEqual(engine.threshold(for: 0), 0, "Stage 0 should start at 0 XP")
        XCTAssertEqual(engine.threshold(for: 1), 5, "Stage 1 should start at 5 XP")
        XCTAssertEqual(engine.threshold(for: 2), 15, "Stage 2 should start at 15 XP")

        // Test progression calculation that widgets use
        let testXP = 25
        let stageIndex = engine.stageIndex(for: testXP)
        let currentThreshold = engine.threshold(for: stageIndex)
        let nextThreshold = engine.threshold(for: stageIndex + 1)

        XCTAssertTrue(testXP >= currentThreshold, "XP should be >= current stage threshold")
        XCTAssertTrue(testXP < nextThreshold, "XP should be < next stage threshold")

        // Test progress calculation used in AccessoryCircularTaskView
        let progressInStage = testXP - currentThreshold
        let totalNeededForStage = nextThreshold - currentThreshold
        let progressPercent = Double(progressInStage) / Double(totalNeededForStage)

        XCTAssertTrue(progressPercent >= 0.0 && progressPercent <= 1.0,
                     "Progress percentage should be between 0 and 1")
    }

    func testWidgetProgressRing() {
        let engine = PetEvolutionEngine()

        // Test scenarios that widgets encounter
        struct TestCase {
            let xp: Int
            let expectedStage: Int
            let shouldHaveProgress: Bool
        }

        let testCases = [
            TestCase(xp: 0, expectedStage: 0, shouldHaveProgress: true),   // Baby stage start
            TestCase(xp: 7, expectedStage: 1, shouldHaveProgress: true),   // Mid stage 1
            TestCase(xp: 25, expectedStage: 2, shouldHaveProgress: true),  // Stage 2 start
            TestCase(xp: 500, expectedStage: 15, shouldHaveProgress: false) // Max stage (CEO)
        ]

        for testCase in testCases {
            let stageIndex = engine.stageIndex(for: testCase.xp)
            XCTAssertEqual(stageIndex, testCase.expectedStage,
                          "XP \(testCase.xp) should be stage \(testCase.expectedStage)")

            // Test max stage handling (used in AccessoryCircularTaskView)
            if stageIndex >= 15 {
                XCTAssertFalse(testCase.shouldHaveProgress, "Max stage should not show progress")
            } else {
                let currentThreshold = engine.threshold(for: stageIndex)
                let nextThreshold = engine.threshold(for: stageIndex + 1)
                let hasValidProgress = nextThreshold > currentThreshold
                XCTAssertEqual(hasValidProgress, testCase.shouldHaveProgress,
                              "Progress availability should match expected")
            }
        }
    }

    func testPetImageNameMapping() {
        let engine = PetEvolutionEngine()

        // Test that all stages have valid image names
        for stage in 0...15 {
            let minXP = engine.threshold(for: stage)
            if let imageName = engine.imageName(for: minXP) {
                XCTAssertTrue(imageName.hasPrefix("pet_"),
                             "Stage \(stage) image name should start with 'pet_': \(imageName)")
                XCTAssertFalse(imageName.isEmpty,
                              "Stage \(stage) should have non-empty image name")
            }
        }

        // Test specific key stages that widgets commonly display
        XCTAssertNotNil(engine.imageName(for: 0), "Baby stage should have image")
        XCTAssertNotNil(engine.imageName(for: 25), "Early stage should have image")
        XCTAssertNotNil(engine.imageName(for: 100), "Mid-game stage should have image")
        XCTAssertNotNil(engine.imageName(for: 500), "End-game stage should have image")
    }

    func testEdgeCaseHandling() {
        let engine = PetEvolutionEngine()

        // Test boundary conditions that widgets might encounter
        XCTAssertEqual(engine.threshold(for: -1), 0, "Invalid stage index should return 0")
        XCTAssertEqual(engine.threshold(for: 999), 0, "Out-of-bounds stage should return 0")

        // Test negative XP handling
        XCTAssertEqual(engine.stageIndex(for: -10), 0, "Negative XP should map to stage 0")

        // Test extremely high XP
        XCTAssertEqual(engine.stageIndex(for: 999999), 15, "Very high XP should cap at max stage")
    }
}