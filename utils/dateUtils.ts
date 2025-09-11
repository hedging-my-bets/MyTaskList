/**
 * Date utilities for task scheduling and day management
 */

/**
 * Get current day key in YYYY-MM-DD format (local timezone)
 */
export function getCurrentDayKey(): string {
  const now = new Date();
  return formatDateKey(now);
}

/**
 * Format date as YYYY-MM-DD string
 */
export function formatDateKey(date: Date): string {
  return date.toLocaleDateString('en-CA'); // ISO format YYYY-MM-DD
}

/**
 * Parse day key back to date
 */
export function parseDayKey(dayKey: string): Date {
  return new Date(dayKey + 'T00:00:00');
}

/**
 * Create scheduled date from day key and time components
 */
export function createScheduledDate(dayKey: string, hour: number, minute: number): Date {
  const date = parseDayKey(dayKey);
  date.setHours(hour, minute, 0, 0);
  return date;
}

/**
 * Get next day key
 */
export function getNextDayKey(dayKey: string): string {
  const date = parseDayKey(dayKey);
  date.setDate(date.getDate() + 1);
  return formatDateKey(date);
}

/**
 * Get previous day key
 */
export function getPreviousDayKey(dayKey: string): string {
  const date = parseDayKey(dayKey);
  date.setDate(date.getDate() - 1);
  return formatDateKey(date);
}

/**
 * Check if it's a new day (for daily closeout)
 */
export function isNewDay(lastDayKey: string, currentDayKey: string): boolean {
  return lastDayKey !== currentDayKey;
}

/**
 * Check if time has passed reset time
 */
export function hasPassedResetTime(resetHour: number, resetMinute: number): boolean {
  const now = new Date();
  const currentMinutes = now.getHours() * 60 + now.getMinutes();
  const resetMinutes = resetHour * 60 + resetMinute;
  return currentMinutes >= resetMinutes;
}

/**
 * Get time string for display (HH:MM)
 */
export function formatTime(hour: number, minute: number): string {
  return `${hour.toString().padStart(2, '0')}:${minute.toString().padStart(2, '0')}`;
}

/**
 * Parse time string to hour/minute
 */
export function parseTime(timeString: string): { hour: number; minute: number } {
  const [hourStr, minuteStr] = timeString.split(':');
  return {
    hour: parseInt(hourStr, 10),
    minute: parseInt(minuteStr, 10)
  };
}