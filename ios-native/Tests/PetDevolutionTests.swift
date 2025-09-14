import XCTest
@testable import SharedKit

final class PetDevolutionTests: XCTestCase {

    func testPetCanLoseStagesFromMissedTasks() {
        var pet = PetState(stageIndex: 5, stageXP: 10, lastCloseoutDayKey: "2025-01-01")
        let cfg = StageCfg.defaultConfig()

        // Simulate missing multiple tasks
        PetEngine.onMiss(pet: &pet, cfg: cfg)  // -2 XP -> 8 XP
        PetEngine.onMiss(pet: &pet, cfg: cfg)  // -2 XP -> 6 XP
        PetEngine.onMiss(pet: &pet, cfg: cfg)  // -2 XP -> 4 XP
        PetEngine.onMiss(pet: &pet, cfg: cfg)  // -2 XP -> 2 XP
        PetEngine.onMiss(pet: &pet, cfg: cfg)  // -2 XP -> 0 XP
        PetEngine.onMiss(pet: &pet, cfg: cfg)  // -2 XP -> -2 XP, should trigger devolution

        XCTAssertEqual(pet.stageIndex, 4, "Pet should have devolved from stage 5 to stage 4")
        XCTAssertTrue(pet.stageXP >= 0, "Pet XP should never be negative after devolution")
    }

    func testPetCanLoseStagesFromPoorDailyPerformance() {
        var pet = PetState(stageIndex: 3, stageXP: 2, lastCloseoutDayKey: "2025-01-01")
        let cfg = StageCfg.defaultConfig()

        // Simulate poor daily completion (less than 40%)
        PetEngine.onDailyCloseout(rate: 0.2, pet: &pet, cfg: cfg, dayKey: "2025-01-02")  // -3 XP -> -1 XP

        XCTAssertEqual(pet.stageIndex, 2, "Pet should have devolved from stage 3 to stage 2")
        XCTAssertTrue(pet.stageXP >= 0, "Pet XP should be non-negative after devolution")
    }

    func testPetCannotGobelowStageZero() {
        var pet = PetState(stageIndex: 0, stageXP: 0, lastCloseoutDayKey: "2025-01-01")
        let cfg = StageCfg.defaultConfig()

        // Try to make pet go below stage 0
        PetEngine.onMiss(pet: &pet, cfg: cfg)
        PetEngine.onMiss(pet: &pet, cfg: cfg)
        PetEngine.onMiss(pet: &pet, cfg: cfg)

        XCTAssertEqual(pet.stageIndex, 0, "Pet should stay at stage 0")
        XCTAssertEqual(pet.stageXP, 0, "Pet XP should stay at 0 when at minimum stage")
    }

    func testDevolutionSetsXPNearThreshold() {
        var pet = PetState(stageIndex: 5, stageXP: 1, lastCloseoutDayKey: "2025-01-01")
        let cfg = StageCfg.defaultConfig()

        let oldThreshold = PetEngine.threshold(for: 4, cfg: cfg)  // Get threshold for stage 4

        // Miss enough tasks to trigger devolution
        PetEngine.onMiss(pet: &pet, cfg: cfg)  // -2 XP -> -1 XP, should devolve

        XCTAssertEqual(pet.stageIndex, 4, "Pet should devolve to stage 4")
        XCTAssertEqual(pet.stageXP, max(0, oldThreshold - 1), "XP should be set near the threshold of the new stage")
    }

    func testCombinedEvolutionAndDevolution() {
        var pet = PetState(stageIndex: 2, stageXP: 15, lastCloseoutDayKey: "2025-01-01")
        let cfg = StageCfg.defaultConfig()

        // First evolve by completing task on time
        PetEngine.onCheck(onTime: true, pet: &pet, cfg: cfg)  // +2 XP

        let stageAfterEvolution = pet.stageIndex
        XCTAssertGreaterThanOrEqual(stageAfterEvolution, 2, "Pet should maintain or gain stage")

        // Then devolve by missing tasks
        PetEngine.onMiss(pet: &pet, cfg: cfg)
        PetEngine.onMiss(pet: &pet, cfg: cfg)
        PetEngine.onMiss(pet: &pet, cfg: cfg)

        // Should show that pets can both evolve and devolve
        XCTAssertTrue(pet.stageIndex >= 0, "Pet should never go below stage 0")
    }

    func testDailyCloseoutRewardAndPenalty() {
        var pet = PetState(stageIndex: 1, stageXP: 10, lastCloseoutDayKey: "2025-01-01")
        let cfg = StageCfg.defaultConfig()

        // Good performance (80%+) should give rewards
        PetEngine.onDailyCloseout(rate: 0.9, pet: &pet, cfg: cfg, dayKey: "2025-01-02")
        let xpAfterReward = pet.stageXP

        // Reset for penalty test
        pet.stageXP = 2

        // Poor performance (<40%) should give penalties
        PetEngine.onDailyCloseout(rate: 0.3, pet: &pet, cfg: cfg, dayKey: "2025-01-03")

        XCTAssertTrue(xpAfterReward > 10, "Good performance should increase XP")
        XCTAssertTrue(pet.stageXP < 2 || pet.stageIndex < 1, "Poor performance should decrease XP or stage")
    }
}
