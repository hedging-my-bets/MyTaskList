import Foundation
import os.log

/// Task rollover handler with grace period support
/// Implements proper day boundary transitions with XP penalties for missed tasks
@available(iOS 17.0, *)
public final class TaskRolloverHandler {
    public static let shared = TaskRolloverHandler()

    private let logger = Logger(subsystem: "com.petprogress.TaskRollover", category: "Rollover")
    private let defaults = AppGroupDefaults.shared
    private let store = AppGroupStore.shared

    private init() {
        logger.info("TaskRolloverHandler initialized")
    }

    /// Check and perform rollover if needed
    /// Should be called on app foreground and in App Intents
    public func checkAndPerformRollover() {
        let now = Date()
        let currentDayKey = TimeSlot.dayKey(for: now)
        let lastProcessedDayKey = UserDefaults.standard.string(forKey: "lastProcessedDayKey")

        // Skip if we already processed today
        if lastProcessedDayKey == currentDayKey {
            logger.debug("Already processed rollover for \(currentDayKey)")
            return
        }

        // Check if we're past the grace period for the previous day
        if let previousDayKey = getPreviousDayKey(from: currentDayKey),
           shouldPerformRollover(for: previousDayKey, currentDate: now) {

            logger.info("Performing rollover from \(previousDayKey) to \(currentDayKey)")
            performRollover(from: previousDayKey, to: currentDayKey)

            // Mark as processed
            UserDefaults.standard.set(currentDayKey, forKey: "lastProcessedDayKey")
        }
    }

    /// Determine if rollover should happen based on grace period
    private func shouldPerformRollover(for dayKey: String, currentDate: Date) -> Bool {
        // Parse the day key to get the date
        guard let dayDate = dayDate(from: dayKey) else {
            logger.error("Invalid day key: \(dayKey)")
            return false
        }

        // Get grace minutes setting
        let graceMinutes = defaults.graceMinutes

        // Calculate day boundary + grace period
        let calendar = Calendar.current
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayDate) ?? dayDate
        let graceEnd = calendar.date(byAdding: .minute, value: graceMinutes, to: dayEnd) ?? dayEnd

        // Check if we're past the grace period
        let isPastGrace = currentDate > graceEnd

        logger.debug("Rollover check: dayEnd=\(dayEnd), graceEnd=\(graceEnd), current=\(currentDate), isPastGrace=\(isPastGrace)")

        return isPastGrace
    }

    /// Perform the actual rollover
    private func performRollover(from previousDayKey: String, to currentDayKey: String) {
        let startTime = CFAbsoluteTimeGetCurrent()

        // Get tasks from previous day
        let previousTasks = defaults.getTasks(dayKey: previousDayKey)

        // Count completed and missed tasks
        let completedCount = previousTasks.filter { $0.isDone }.count
        let missedCount = previousTasks.filter { !$0.isDone }.count
        let totalCount = previousTasks.count

        logger.info("Rollover stats: completed=\(completedCount), missed=\(missedCount), total=\(totalCount)")

        // Update pet state based on performance
        if var petState = defaults.getPetState() {
            let cfg = StageCfg.standard()

            // Call PetEngine's daily closeout
            PetEngine.onDailyCloseout(
                completedTasks: completedCount,
                missedTasks: missedCount,
                totalTasks: totalCount,
                pet: &petState,
                cfg: cfg,
                dayKey: currentDayKey
            )

            // Save updated pet state
            defaults.setPetState(petState)

            logger.info("Pet state updated after rollover - Stage: \(petState.stageIndex), XP: \(petState.stageXP)")
        }

        // Handle task rollover if enabled
        let rolloverEnabled = store.state.rolloverEnabled

        if rolloverEnabled {
            // Carry incomplete tasks to today
            let incompleteTasks = previousTasks.filter { !$0.isDone }
            var todayTasks = defaults.getTasks(dayKey: currentDayKey)

            for task in incompleteTasks {
                // Create new task entity for today
                let rolledTask = TaskEntity(
                    id: UUID().uuidString,
                    title: task.title + " (rolled)",
                    dueHour: task.dueHour,
                    isDone: false,
                    dayKey: currentDayKey
                )
                todayTasks.append(rolledTask)

                logger.debug("Rolled task: \(task.title) to \(currentDayKey)")
            }

            // Save updated tasks for today
            defaults.setTasks(todayTasks, dayKey: currentDayKey)

            logger.info("Rolled \(incompleteTasks.count) incomplete tasks to \(currentDayKey)")
        }

        // Clear previous day data if not rolling over
        if !rolloverEnabled {
            defaults.clearDay(dayKey: previousDayKey)
            logger.info("Cleared data for \(previousDayKey) (rollover disabled)")
        }

        // Force scoped widget refresh
        #if canImport(WidgetKit)
        import WidgetKit
        WidgetCenter.shared.reloadTimelines(ofKind: "PetProgressWidget")
        #endif

        let duration = CFAbsoluteTimeGetCurrent() - startTime
        logger.info("Rollover completed in \(String(format: "%.2f", duration * 1000))ms")
    }

    /// Get the previous day key
    private func getPreviousDayKey(from dayKey: String) -> String? {
        guard let date = dayDate(from: dayKey) else { return nil }

        let calendar = Calendar.current
        guard let previousDate = calendar.date(byAdding: .day, value: -1, to: date) else {
            return nil
        }

        return TimeSlot.dayKey(for: previousDate)
    }

    /// Convert day key to Date
    private func dayDate(from dayKey: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dayKey)
    }
}

// MARK: - App Lifecycle Integration

@available(iOS 17.0, *)
public extension TaskRolloverHandler {
    /// Call this on app foreground (in SceneDelegate or App)
    func handleAppForeground() {
        logger.info("App foregrounded - checking for rollover")
        checkAndPerformRollover()
    }

    /// Call this in App Intents before performing actions
    func handleIntentExecution() {
        logger.debug("Intent executed - checking for rollover")
        checkAndPerformRollover()
    }
}