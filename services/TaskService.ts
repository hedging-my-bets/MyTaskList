import AsyncStorage from '@react-native-async-storage/async-storage';
import { TaskItem, PetState, AppSettings, CompletionResult } from '../types';
import { getCurrentDayKey, createScheduledDate, getNextDayKey, formatTime, formatDateKey } from '../utils/dateUtils';
import { PetEngine } from '../engine/PetEngine';
import { STAGE_CONFIG } from '../data/stageConfig';

const TASKS_KEY = 'tasks';
const PET_STATE_KEY = 'petState';
const SETTINGS_KEY = 'settings';

/**
 * Task management service with local storage
 */
export class TaskService {
  
  // CRUD Operations
  
  /**
   * Get all tasks for a specific day
   */
  static async getTasksForDay(dayKey: string): Promise<TaskItem[]> {
    try {
      const tasks = await this.getAllTasks();
      return tasks
        .filter(task => task.dayKey === dayKey)
        .sort((a, b) => {
          const aTime = a.scheduledAt.hour * 60 + a.scheduledAt.minute;
          const bTime = b.scheduledAt.hour * 60 + b.scheduledAt.minute;
          return aTime - bTime;
        });
    } catch (error) {
      console.error('Error getting tasks for day:', error);
      return [];
    }
  }

  /**
   * Get all tasks from storage
   */
  static async getAllTasks(): Promise<TaskItem[]> {
    try {
      const tasksJson = await AsyncStorage.getItem(TASKS_KEY);
      if (!tasksJson) return [];
      
      const tasks = JSON.parse(tasksJson);
      // Convert date strings back to Date objects
      return tasks.map((task: any) => ({
        ...task,
        completedAt: task.completedAt ? new Date(task.completedAt) : undefined,
        snoozedUntil: task.snoozedUntil ? new Date(task.snoozedUntil) : undefined,
      }));
    } catch (error) {
      console.error('Error getting all tasks:', error);
      return [];
    }
  }

  /**
   * Save task to storage
   */
  static async saveTask(task: TaskItem): Promise<void> {
    try {
      const tasks = await this.getAllTasks();
      const existingIndex = tasks.findIndex(t => t.id === task.id);
      
      if (existingIndex >= 0) {
        tasks[existingIndex] = task;
      } else {
        tasks.push(task);
      }
      
      await AsyncStorage.setItem(TASKS_KEY, JSON.stringify(tasks));
    } catch (error) {
      console.error('Error saving task:', error);
      throw error;
    }
  }

  /**
   * Delete task from storage
   */
  static async deleteTask(taskId: string): Promise<void> {
    try {
      const tasks = await this.getAllTasks();
      const filteredTasks = tasks.filter(t => t.id !== taskId);
      await AsyncStorage.setItem(TASKS_KEY, JSON.stringify(filteredTasks));
    } catch (error) {
      console.error('Error deleting task:', error);
      throw error;
    }
  }

  /**
   * Create new task
   */
  static async createTask(
    title: string,
    hour: number,
    minute: number,
    dayKey: string = getCurrentDayKey()
  ): Promise<TaskItem> {
    const task: TaskItem = {
      id: Date.now().toString() + Math.random().toString(36).substr(2, 9),
      title,
      scheduledAt: { hour, minute },
      dayKey,
      isCompleted: false,
    };

    await this.saveTask(task);
    return task;
  }

  // Task Actions

  /**
   * Mark task as completed
   */
  static async completeTask(taskId: string): Promise<void> {
    try {
      const tasks = await this.getAllTasks();
      const task = tasks.find(t => t.id === taskId);
      
      if (!task || task.isCompleted) return;

      const now = new Date();
      const scheduledTime = createScheduledDate(task.dayKey, task.scheduledAt.hour, task.scheduledAt.minute);
      const settings = await this.getSettings();
      
      task.isCompleted = true;
      task.completedAt = now;
      
      await this.saveTask(task);

      // Update pet state
      const petState = await this.getPetState();
      const isOnTime = PetEngine.isOnTime(scheduledTime, now, settings.graceWindow);
      PetEngine.onCheck(isOnTime, petState, STAGE_CONFIG);
      await this.savePetState(petState);
      
    } catch (error) {
      console.error('Error completing task:', error);
      throw error;
    }
  }

  /**
   * Snooze task by specified minutes
   */
  static async snoozeTask(taskId: string, minutes: number = 15): Promise<void> {
    try {
      const tasks = await this.getAllTasks();
      const task = tasks.find(t => t.id === taskId);
      
      if (!task || task.isCompleted) return;

      const now = new Date();
      const newTime = new Date(now.getTime() + minutes * 60 * 1000);
      const newDayKey = formatDateKey(newTime);
      
      task.scheduledAt.hour = newTime.getHours();
      task.scheduledAt.minute = newTime.getMinutes();
      task.snoozedUntil = newTime;
      
      // Update dayKey if snooze crosses day boundary
      if (newDayKey !== task.dayKey) {
        task.dayKey = newDayKey;
      }
      
      await this.saveTask(task);
    } catch (error) {
      console.error('Error snoozing task:', error);
      throw error;
    }
  }

  // Daily Management

  /**
   * Get next uncompleted task for today
   */
  static async getNextTask(dayKey: string = getCurrentDayKey()): Promise<TaskItem | null> {
    const tasks = await this.getTasksForDay(dayKey);
    const now = new Date();
    
    return tasks.find(task => !task.isCompleted) || null;
  }

  /**
   * Calculate completion rate for a day
   */
  static async getCompletionRate(dayKey: string): Promise<CompletionResult> {
    const tasks = await this.getTasksForDay(dayKey);
    const completed = tasks.filter(t => t.isCompleted);
    
    return {
      wasOnTime: false, // This is per-task, not per-day
      completionRate: tasks.length > 0 ? completed.length / tasks.length : 0,
      tasksCompleted: completed.length,
      tasksTotal: tasks.length
    };
  }

  /**
   * Perform daily closeout (should be called once per day)
   */
  static async performDailyCloseout(dayKey: string): Promise<void> {
    try {
      const petState = await this.getPetState();
      
      // Skip if already done today
      if (petState.lastCloseoutDayKey === dayKey) return;

      const completionResult = await this.getCompletionRate(dayKey);
      const tasks = await this.getTasksForDay(dayKey);
      
      // Apply missed task penalties
      const missedTasks = tasks.filter(t => !t.isCompleted);
      for (const _ of missedTasks) {
        PetEngine.onMiss(petState, STAGE_CONFIG);
      }

      // Apply daily bonus/penalty
      PetEngine.onDailyCloseout(completionResult.completionRate, petState, STAGE_CONFIG);
      
      petState.lastCloseoutDayKey = dayKey;
      await this.savePetState(petState);

      // Handle rollover if enabled
      const settings = await this.getSettings();
      if (settings.rolloverEnabled) {
        await this.rolloverIncompleteTasks(dayKey);
      }
      
    } catch (error) {
      console.error('Error in daily closeout:', error);
      throw error;
    }
  }

  /**
   * Rollover incomplete tasks to tomorrow
   */
  private static async rolloverIncompleteTasks(fromDayKey: string): Promise<void> {
    const tasks = await this.getTasksForDay(fromDayKey);
    const incompleteTasks = tasks.filter(t => !t.isCompleted);
    const nextDayKey = getNextDayKey(fromDayKey);

    for (const task of incompleteTasks) {
      const newTask: TaskItem = {
        ...task,
        id: Date.now().toString() + Math.random().toString(36).substr(2, 9),
        dayKey: nextDayKey,
        isCompleted: false,
        completedAt: undefined,
        snoozedUntil: undefined,
      };
      await this.saveTask(newTask);
    }
  }

  // Pet State Management

  /**
   * Get current pet state
   */
  static async getPetState(): Promise<PetState> {
    try {
      const stateJson = await AsyncStorage.getItem(PET_STATE_KEY);
      if (!stateJson) {
        // Initialize with default state
        const defaultState: PetState = {
          stageIndex: 0,
          stageXP: 0,
          lastCloseoutDayKey: ''
        };
        await this.savePetState(defaultState);
        return defaultState;
      }
      return JSON.parse(stateJson);
    } catch (error) {
      console.error('Error getting pet state:', error);
      // Return default state on error
      return {
        stageIndex: 0,
        stageXP: 0,
        lastCloseoutDayKey: ''
      };
    }
  }

  /**
   * Save pet state
   */
  static async savePetState(petState: PetState): Promise<void> {
    try {
      await AsyncStorage.setItem(PET_STATE_KEY, JSON.stringify(petState));
    } catch (error) {
      console.error('Error saving pet state:', error);
      throw error;
    }
  }

  // Settings Management

  /**
   * Get app settings
   */
  static async getSettings(): Promise<AppSettings> {
    try {
      const settingsJson = await AsyncStorage.getItem(SETTINGS_KEY);
      if (!settingsJson) {
        const defaultSettings: AppSettings = {
          resetTime: { hour: 0, minute: 0 },
          graceWindow: 60,
          rolloverEnabled: true,
          hapticsEnabled: true
        };
        await this.saveSettings(defaultSettings);
        return defaultSettings;
      }
      return JSON.parse(settingsJson);
    } catch (error) {
      console.error('Error getting settings:', error);
      return {
        resetTime: { hour: 0, minute: 0 },
        graceWindow: 60,
        rolloverEnabled: true,
        hapticsEnabled: true
      };
    }
  }

  /**
   * Save app settings
   */
  static async saveSettings(settings: AppSettings): Promise<void> {
    try {
      await AsyncStorage.setItem(SETTINGS_KEY, JSON.stringify(settings));
    } catch (error) {
      console.error('Error saving settings:', error);
      throw error;
    }
  }
}