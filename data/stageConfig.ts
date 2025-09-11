import { StageCfg } from '../types';

/**
 * Stage configuration with 20 pet forms
 * Progression: Ocean -> Land -> Final form
 * Thresholds increase difficulty as specified
 */
export const STAGE_CONFIG: StageCfg = {
  stages: [
    { i: 0, name: "Tadpole", threshold: 10, asset: "pet_tadpole.png" },
    { i: 1, name: "Minnow", threshold: 20, asset: "pet_minnow.png" },
    { i: 2, name: "Frog", threshold: 30, asset: "pet_frog.png" },
    { i: 3, name: "Hermit Crab", threshold: 40, asset: "pet_hermit.png" },
    { i: 4, name: "Starfish", threshold: 50, asset: "pet_starfish.png" },
    { i: 5, name: "Jellyfish", threshold: 60, asset: "pet_jellyfish.png" },
    { i: 6, name: "Squid", threshold: 75, asset: "pet_squid.png" },
    { i: 7, name: "Seahorse", threshold: 90, asset: "pet_seahorse.png" },
    { i: 8, name: "Dolphin", threshold: 110, asset: "pet_dolphin.png" },
    { i: 9, name: "Shark", threshold: 135, asset: "pet_shark.png" },
    { i: 10, name: "Otter", threshold: 165, asset: "pet_otter.png" },
    { i: 11, name: "Fox", threshold: 200, asset: "pet_fox.png" },
    { i: 12, name: "Lynx", threshold: 240, asset: "pet_lynx.png" },
    { i: 13, name: "Wolf", threshold: 285, asset: "pet_wolf.png" },
    { i: 14, name: "Bear", threshold: 335, asset: "pet_bear.png" },
    { i: 15, name: "Bison", threshold: 390, asset: "pet_bison.png" },
    { i: 16, name: "Elephant", threshold: 450, asset: "pet_elephant.png" },
    { i: 17, name: "Rhino", threshold: 515, asset: "pet_rhino.png" },
    { i: 18, name: "Lion", threshold: 585, asset: "pet_lion.png" },
    { i: 19, name: "Floating God", threshold: 0, asset: "pet_god.png" } // Final stage, no further evolution
  ]
};

/**
 * Get stage by index
 */
export function getStage(index: number) {
  return STAGE_CONFIG.stages[index];
}

/**
 * Get all stage names for debugging/display
 */
export function getAllStageNames(): string[] {
  return STAGE_CONFIG.stages.map(stage => stage.name);
}

/**
 * Check if stage is final (no further evolution)
 */
export function isFinalStage(index: number): boolean {
  return index === STAGE_CONFIG.stages.length - 1;
}