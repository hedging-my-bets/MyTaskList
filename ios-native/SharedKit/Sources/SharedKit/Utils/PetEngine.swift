import Foundation

public enum PetEngine {
    public static func threshold(for stageIndex: Int, cfg: StageCfg) -> Int {
        guard stageIndex < cfg.stages.count else { return 0 }
        return cfg.stages[stageIndex].threshold
    }

    public static func onCheck(onTime: Bool, pet: inout PetState, cfg: StageCfg) {
        pet.stageXP += onTime ? 2 : 1
        evolveIfNeeded(&pet, cfg: cfg)
    }

    public static func onMiss(pet: inout PetState, cfg: StageCfg) {
        pet.stageXP -= 2
        deEvolveIfNeeded(&pet, cfg: cfg)
    }

    public static func onDailyCloseout(rate: Double, pet: inout PetState, cfg: StageCfg, dayKey: String) {
        // Only run closeout once per day
        if pet.lastCloseoutDayKey == dayKey {
            return
        }

        if rate >= 0.8 {
            pet.stageXP += 3
            evolveIfNeeded(&pet, cfg: cfg)
        } else if rate < 0.4 {
            pet.stageXP -= 3
            deEvolveIfNeeded(&pet, cfg: cfg)
        }

        // Update last closeout day
        pet.lastCloseoutDayKey = dayKey
    }

    public static func evolveIfNeeded(_ pet: inout PetState, cfg: StageCfg) {
        guard pet.stageIndex < cfg.stages.count - 1 else { return }
        let thresholdValue = threshold(for: pet.stageIndex, cfg: cfg)
        guard thresholdValue > 0 else { return }
        if pet.stageXP >= thresholdValue {
            pet.stageIndex = min(pet.stageIndex + 1, cfg.stages.count - 1)
            pet.stageXP = 0
        }
    }

    public static func deEvolveIfNeeded(_ pet: inout PetState, cfg: StageCfg) {
        if pet.stageXP < 0 {
            if pet.stageIndex > 0 {
                pet.stageIndex -= 1
                let newThreshold = max(0, threshold(for: pet.stageIndex, cfg: cfg))
                pet.stageXP = max(0, newThreshold - 1)
            } else {
                pet.stageXP = 0
            }
        }
    }
}