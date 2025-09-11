import { TaskService } from './TaskService';
import { getCurrentDayKey, isNewDay, hasPassedResetTime, getPreviousDayKey } from '../utils/dateUtils';

/**
 * Daily Closeout Service
 * Handles the once-per-day closeout process with pet evolution
 */
export class DailyCloseoutService {
  
  /**
   * Check if daily closeout should run and execute it
   * Should be called on app launch
   */
  static async checkAndRunCloseout(): Promise<boolean> {
    try {
      const currentDayKey = getCurrentDayKey();
      const petState = await TaskService.getPetState();
      const settings = await TaskService.getSettings();
      
      // Check if it's a new day since last closeout
      const isNewDayFlag = isNewDay(petState.lastCloseoutDayKey, currentDayKey);
      
      // Check if we've passed the reset time
      const passedResetTime = hasPassedResetTime(settings.resetTime.hour, settings.resetTime.minute);
      
      // Only run closeout if it's a new day and we haven't run it yet
      if (isNewDayFlag && passedResetTime && petState.lastCloseoutDayKey !== currentDayKey) {
        // Close out the PREVIOUS day, not the current day
        const previousDay = getPreviousDayKey(currentDayKey);
        console.log(`Running daily closeout for ${previousDay}`);
        await TaskService.performDailyCloseout(previousDay);
        return true;
      }
      
      return false;
    } catch (error) {
      console.error('Error in daily closeout check:', error);
      return false;
    }
  }

  /**
   * Get stats for yesterday's performance (for display)
   */
  static async getYesterdayStats(): Promise<{
    dayKey: string;
    completionRate: number;
    tasksCompleted: number;
    tasksTotal: number;
  } | null> {
    try {
      const currentDayKey = getCurrentDayKey();
      const yesterday = new Date();
      yesterday.setDate(yesterday.getDate() - 1);
      const yesterdayKey = yesterday.toLocaleDateString('en-CA');
      
      if (yesterdayKey === currentDayKey) return null;
      
      const result = await TaskService.getCompletionRate(yesterdayKey);
      return {
        dayKey: yesterdayKey,
        ...result
      };
    } catch (error) {
      console.error('Error getting yesterday stats:', error);
      return null;
    }
  }

  /**
   * Force run daily closeout (for testing/manual trigger)
   * Runs closeout for the previous day to avoid penalizing current day tasks
   */
  static async forceCloseout(): Promise<void> {
    const currentDayKey = getCurrentDayKey();
    const previousDayKey = getPreviousDayKey(currentDayKey);
    console.log(`Force running daily closeout for ${previousDayKey}`);
    await TaskService.performDailyCloseout(previousDayKey);
  }
}