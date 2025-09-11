// Core data models matching SwiftData specification

export interface TaskItem {
  id: string;
  title: string;
  scheduledAt: {
    hour: number;
    minute: number;
  };
  dayKey: string; // "YYYY-MM-DD" local
  isCompleted: boolean;
  completedAt?: Date;
  snoozedUntil?: Date;
}

export interface PetState {
  stageIndex: number; // 0..19
  stageXP: number; // progress within current stage
  lastCloseoutDayKey: string;
}

export interface StageConfig {
  i: number;
  name: string;
  threshold: number;
  asset: string;
}

export interface StageCfg {
  stages: StageConfig[];
}

// Widget data for timeline entries
export interface WidgetEntry {
  stageIndex: number;
  stageXP: number;
  threshold: number;
  progressRatio: number;
  tasksDone: number;
  tasksTotal: number;
  nextTaskTitle: string;
  nextTaskTime: string;
  timestamp: Date;
}

// Settings
export interface AppSettings {
  resetTime: {
    hour: number;
    minute: number;
  };
  graceWindow: number; // minutes +/-
  rolloverEnabled: boolean;
  hapticsEnabled: boolean;
}

// Task completion result
export interface CompletionResult {
  wasOnTime: boolean;
  completionRate: number;
  tasksCompleted: number;
  tasksTotal: number;
}