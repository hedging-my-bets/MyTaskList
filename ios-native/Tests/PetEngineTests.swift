import XCTest
@testable import SharedKit

final class PetEngineTests: XCTestCase {
    func testEvolutionLogic() {
        var pet = PetState(stageIndex: 0, stageXP: 9, lastCloseoutDayKey: "2025-01-01")
        let cfg = StageCfg.defaultConfig()

        // Should evolve from stage 0 to 1 (threshold is 10)
        PetEngine.onCheck(onTime: true, pet: &pet, cfg: cfg)
        XCTAssertEqual(pet.stageIndex, 1)
        XCTAssertEqual(pet.stageXP, 0)
    }

    func testDevolutionLogic() {
        var pet = PetState(stageIndex: 1, stageXP: 0, lastCloseoutDayKey: "2025-01-01")
        let cfg = StageCfg.defaultConfig()

        // Should devolve from stage 1 to 0
        PetEngine.onMiss(pet: &pet, cfg: cfg)
        PetEngine.onMiss(pet: &pet, cfg: cfg)
        XCTAssertEqual(pet.stageIndex, 0)
        XCTAssertGreaterThan(pet.stageXP, 0) // Should have XP from previous stage
    }

    func testFinalStageTerminal() {
        var pet = PetState(stageIndex: 15, stageXP: 0, lastCloseoutDayKey: "2025-01-01")
        let cfg = StageCfg.defaultConfig()

        // Should not evolve beyond final stage (Gold)
        PetEngine.onCheck(onTime: true, pet: &pet, cfg: cfg)
        XCTAssertEqual(pet.stageIndex, 15) // Should remain at final stage
    }

    func testBonusPenaltyMath() {
        var pet = PetState(stageIndex: 0, stageXP: 5, lastCloseoutDayKey: "2025-01-01")
        let cfg = StageCfg.defaultConfig()

        // 100% completion bonus (on new day)
        PetEngine.onDailyCloseout(rate: 1.0, pet: &pet, cfg: cfg, dayKey: "2025-01-02")
        XCTAssertEqual(pet.stageXP, 8) // 5 + 3 = 8

        // 30% completion penalty (on another new day)
        PetEngine.onDailyCloseout(rate: 0.3, pet: &pet, cfg: cfg, dayKey: "2025-01-03")
        XCTAssertEqual(pet.stageXP, 5) // 8 - 3 = 5
    }

    func testOnTimeVsLateScoring() {
        var pet = PetState(stageIndex: 0, stageXP: 0, lastCloseoutDayKey: "2025-01-01")
        let cfg = StageCfg.defaultConfig()

        // On-time check
        PetEngine.onCheck(onTime: true, pet: &pet, cfg: cfg)
        XCTAssertEqual(pet.stageXP, 2)

        // Late check
        PetEngine.onCheck(onTime: false, pet: &pet, cfg: cfg)
        XCTAssertEqual(pet.stageXP, 3) // 2 + 1 = 3
    }
}