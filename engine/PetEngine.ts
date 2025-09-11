import { PetState, StageCfg } from '../types';

/**
 * PetEngine - Pure functions for pet evolution/de-evolution
 * Matches Swift specification exactly
 */
export class PetEngine {
  /**
   * Called when a task is completed
   * @param onTime - true if completed within grace window (+/- 60min)
   * @param pet - pet state to modify
   * @param cfg - stage configuration
   */
  static onCheck(onTime: boolean, pet: PetState, cfg: StageCfg): void {
    pet.stageXP += onTime ? 2 : 1;
    this.evolve(pet, cfg);
  }

  /**
   * Called when a task is missed (end of day)
   * @param pet - pet state to modify  
   * @param cfg - stage configuration
   */
  static onMiss(pet: PetState, cfg: StageCfg): void {
    pet.stageXP -= 2;
    this.deEvolve(pet, cfg);
  }

  /**
   * Called during daily closeout
   * @param rate - completion rate (0.0 to 1.0)
   * @param pet - pet state to modify
   * @param cfg - stage configuration
   */
  static onDailyCloseout(rate: number, pet: PetState, cfg: StageCfg): void {
    if (rate >= 0.8) {
      pet.stageXP += 3; // Daily bonus
    } else if (rate < 0.4) {
      pet.stageXP -= 3; // Daily penalty
    }
    
    this.evolve(pet, cfg);
    this.deEvolve(pet, cfg);
  }

  /**
   * Get threshold for a given stage index
   */
  private static thresh(stageIndex: number, cfg: StageCfg): number {
    return cfg.stages[stageIndex].threshold;
  }

  /**
   * Handle evolution - advance stages if XP threshold is met
   */
  private static evolve(pet: PetState, cfg: StageCfg): void {
    while (
      pet.stageIndex < cfg.stages.length - 1 && 
      pet.stageXP >= this.thresh(pet.stageIndex, cfg)
    ) {
      pet.stageIndex += 1;
      pet.stageXP = 0;
    }
  }

  /**
   * Handle de-evolution - drop stages if XP goes negative
   */
  private static deEvolve(pet: PetState, cfg: StageCfg): void {
    while (pet.stageXP < 0 && pet.stageIndex > 0) {
      pet.stageIndex -= 1;
      pet.stageXP = Math.max(0, this.thresh(pet.stageIndex, cfg) - 1 + pet.stageXP);
    }
    
    // Ensure XP never goes below 0 at stage 0
    if (pet.stageIndex === 0) {
      pet.stageXP = Math.max(0, pet.stageXP);
    }
  }

  /**
   * Get current stage info
   */
  static getCurrentStage(pet: PetState, cfg: StageCfg) {
    const stage = cfg.stages[pet.stageIndex];
    const progressRatio = stage.threshold > 0 ? pet.stageXP / stage.threshold : 1.0;
    
    return {
      stage,
      progressRatio: Math.min(1.0, progressRatio),
      isMaxStage: pet.stageIndex === cfg.stages.length - 1
    };
  }

  /**
   * Calculate if task completion was "on time" (within grace window)
   */
  static isOnTime(scheduledTime: Date, completedTime: Date, graceWindowMinutes = 60): boolean {
    const diffMinutes = Math.abs(completedTime.getTime() - scheduledTime.getTime()) / (1000 * 60);
    return diffMinutes <= graceWindowMinutes;
  }
}