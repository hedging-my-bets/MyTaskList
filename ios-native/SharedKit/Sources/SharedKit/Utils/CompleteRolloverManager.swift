import Foundation
import os.log
#if canImport(WidgetKit)
import WidgetKit
#endif

/// Complete Rollover Manager - 100% Production Implementation
/// Handles day boundaries, grace periods, and task transitions with enterprise precision
@available(iOS 17.0, *)
public final class CompleteRolloverManager: @unchecked Sendable {
    public static let shared = CompleteRolloverManager()

    private let logger = Logger(subsystem: "com.petprogress.SharedKit", category: "Rollover")
    private let appGroup = CompleteAppGroupManager.shared
    private let evolutionSystem = CompleteEvolutionSystem.shared

    // Rollover configuration
    private struct RolloverConfig {
        static let maxDaysToProcess = 7 // Process up to 1 week of missed days
        static let rolloverCheckInterval: TimeInterval = 300 // 5 minutes
    }

    private var lastRolloverCheck: Date?

    private init() {
        logger.info("Complete Rollover Manager initialized")
        setupAutomaticRolloverChecks()
    }

    // MARK: - Public Interface

    /// Primary rollover entry point - call from app foreground
    public func handleAppForeground() {
        logger.info("App foregrounded - initiating rollover check")

        Task {
            await performRolloverCheck(trigger: .appForeground)
        }

        // Update app state
        appGroup.lastAppForegroundDate = Date()
    }

    /// Rollover check for App Intents
    public func handleIntentExecution() {
        logger.debug("Intent executed - checking for rollover")

        Task {
            await performRolloverCheck(trigger: .intentExecution)
        }
    }

    /// Manual rollover trigger (for testing or force refresh)
    public func forceRollover() {
        logger.info("Manual rollover triggered")

        Task {
            await performRolloverCheck(trigger: .manual, force: true)
        }
    }

    // MARK: - Core Rollover Logic

    private func performRolloverCheck(trigger: RolloverTrigger, force: Bool = false) async {
        let startTime = CFAbsoluteTimeGetCurrent()

        // Rate limiting (except for force)
        if !force, let lastCheck = lastRolloverCheck,
           Date().timeIntervalSince(lastCheck) < RolloverConfig.rolloverCheckInterval {
            logger.debug("Rollover check skipped - too recent")
            return
        }

        lastRolloverCheck = Date()

        let now = Date()
        let currentDayKey = TimeSlot.dayKey(for: now)
        let lastProcessedDayKey = appGroup.lastProcessedDayKey

        logger.info("Rollover check: current=\(currentDayKey), lastProcessed=\(lastProcessedDayKey ?? "none")")

        // Skip if already processed today
        if !force && lastProcessedDayKey == currentDayKey {
            logger.debug("Already processed rollover for \(currentDayKey)")
            return
        }

        // Determine what days need processing
        let daysToProcess = calculateDaysToProcess(currentDayKey: currentDayKey, lastProcessedDayKey: lastProcessedDayKey)

        if daysToProcess.isEmpty {
            logger.debug("No days require rollover processing")
            appGroup.lastProcessedDayKey = currentDayKey
            return
        }

        logger.info("Processing rollover for \(daysToProcess.count) days: \(daysToProcess)")

        // Process each day in chronological order
        for dayKey in daysToProcess {
            await processDay(dayKey: dayKey, currentDate: now)
        }

        // Mark current day as processed
        appGroup.lastProcessedDayKey = currentDayKey

        // Force widget refresh after rollover
        await refreshWidgets()

        let duration = CFAbsoluteTimeGetCurrent() - startTime
        logger.info("Rollover check completed in \(String(format: "%.3f", duration))s")
    }

    private func calculateDaysToProcess(currentDayKey: String, lastProcessedDayKey: String?) -> [String] {
        let calendar = Calendar.current

        guard let currentDate = dayDate(from: currentDayKey) else {
            logger.error("Invalid current day key: \(currentDayKey)")
            return []
        }

        var daysToProcess: [String] = []

        if let lastProcessedKey = lastProcessedDayKey,
           let lastProcessedDate = dayDate(from: lastProcessedKey) {

            // Find gap between last processed and current
            var date = lastProcessedDate
            var iteration = 0

            while date < currentDate && iteration < RolloverConfig.maxDaysToProcess {
                if let nextDay = calendar.date(byAdding: .day, value: 1, to: date) {
                    let nextDayKey = TimeSlot.dayKey(for: nextDay)
                    if shouldProcessDay(dayKey: nextDayKey, currentDate: Date()) {
                        daysToProcess.append(nextDayKey)
                    }
                    date = nextDay
                } else {
                    break
                }
                iteration += 1
            }
        } else {
            // No last processed day - check if we should process current day
            if shouldProcessDay(dayKey: currentDayKey, currentDate: Date()) {
                daysToProcess.append(currentDayKey)
            }
        }

        return daysToProcess
    }

    private func shouldProcessDay(dayKey: String, currentDate: Date) -> Bool {
        guard let dayDate = dayDate(from: dayKey) else { return false }

        let graceMinutes = appGroup.graceMinutes
        let calendar = Calendar.current

        // Calculate day end + grace period
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayDate) ?? dayDate
        let graceEnd = calendar.date(byAdding: .minute, value: graceMinutes, to: dayEnd) ?? dayEnd

        // Process if current time is past grace period
        let shouldProcess = currentDate > graceEnd

        logger.debug("Day \(dayKey): dayEnd=\(dayEnd), graceEnd=\(graceEnd), shouldProcess=\(shouldProcess)")

        return shouldProcess
    }

    private func processDay(dayKey: String, currentDate: Date) async {
        logger.info("Processing day: \(dayKey)")

        let tasks = appGroup.getTasks(dayKey: dayKey)
        let completions = appGroup.getCompletions(dayKey: dayKey)

        // Categorize tasks
        let completedTasks = tasks.filter { completions.contains($0.id) }
        let missedTasks = tasks.filter { !completions.contains($0.id) }

        logger.info("Day \(dayKey): \(completedTasks.count) completed, \(missedTasks.count) missed")

        // Process pet evolution based on day performance
        if var petState = appGroup.getPetState() {
            let evolutionResult: EvolutionResult

            if !missedTasks.isEmpty {
                // Process missed tasks
                evolutionResult = evolutionSystem.processMissedTasks(
                    currentPet: &petState,
                    missedTasks: missedTasks,
                    rolloverDate: currentDate
                )
            } else {
                // Process successful day
                evolutionResult = evolutionSystem.processDailyCloseout(
                    currentPet: &petState,
                    completedTasks: completedTasks.count,
                    totalTasks: tasks.count,
                    dayKey: dayKey
                )
            }

            // Save updated pet state
            appGroup.setPetState(petState)

            // Log evolution changes
            if evolutionResult.stageChanged {
                logger.info("Pet evolution: Stage \(evolutionResult.previousStage) → \(evolutionResult.newStage) (\(evolutionResult.xpChange) XP)")

                // Trigger celebration for evolution (but not de-evolution during rollover)
                if evolutionResult.didEvolve {
                    await triggerEvolutionCelebration(result: evolutionResult)
                }
            }

            // Update metrics
            appGroup.addXPEarned(evolutionResult.xpChange)
        }

        // Handle task rollover if enabled
        if appGroup.rolloverEnabled && !missedTasks.isEmpty {
            await rolloverMissedTasks(missedTasks: missedTasks, fromDay: dayKey, toDay: TimeSlot.dayKey(for: currentDate))
        }

        // Clean up old day if rollover is disabled
        if !appGroup.rolloverEnabled {
            // Keep data for metrics but mark as processed
            logger.debug("Rollover disabled - keeping data for \(dayKey)")
        }
    }

    private func rolloverMissedTasks(missedTasks: [TaskEntity], fromDay: String, toDay: String) async {
        guard fromDay != toDay else { return }

        logger.info("Rolling over \(missedTasks.count) missed tasks from \(fromDay) to \(toDay)")

        var todayTasks = appGroup.getTasks(dayKey: toDay)

        for missedTask in missedTasks {
            // Create rolled-over task
            let rolledTask = TaskEntity(
                id: UUID().uuidString,
                title: missedTask.title + " (rolled)",
                dueHour: missedTask.dueHour,
                isDone: false,
                dayKey: toDay
            )

            todayTasks.append(rolledTask)
            logger.debug("Rolled task: \(missedTask.title) → \(rolledTask.title)")
        }

        // Save updated today's tasks
        appGroup.setTasks(todayTasks, dayKey: toDay)

        logger.info("Successfully rolled \(missedTasks.count) tasks to \(toDay)")
    }

    private func triggerEvolutionCelebration(result: EvolutionResult) async {
        #if canImport(UIKit)
        await MainActor.run {
            if result.didEvolve {
                CompleteCelebrationSystem.shared.triggerLevelUpCelebration(
                    fromStage: result.previousStage,
                    toStage: result.newStage
                )
            }
        }
        #endif
    }

    // MARK: - Widget Management

    private func refreshWidgets() async {
        #if canImport(WidgetKit)
        await MainActor.run {
            WidgetCenter.shared.reloadTimelines(ofKind: "PetProgressInteractiveLockScreenWidget")
            WidgetCenter.shared.reloadTimelines(ofKind: "PetProgressWidget")

            // Update widget metrics
            appGroup.incrementWidgetUpdateCount()

            logger.info("Widgets refreshed after rollover")
        }
        #endif
    }

    // MARK: - Automatic Rollover Checks

    private func setupAutomaticRolloverChecks() {
        // Set up timer for periodic checks (when app is active)
        Timer.scheduledTimer(withTimeInterval: RolloverConfig.rolloverCheckInterval, repeats: true) { [weak self] _ in
            Task {
                await self?.performRolloverCheck(trigger: .automatic)
            }
        }
    }

    // MARK: - Utilities

    private func dayDate(from dayKey: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter.date(from: dayKey)
    }

    // MARK: - Diagnostics

    public func generateRolloverReport() -> [String: Any] {
        let currentDayKey = TimeSlot.dayKey(for: Date())
        let lastProcessedDayKey = appGroup.lastProcessedDayKey
        let graceMinutes = appGroup.graceMinutes

        return [
            "currentDayKey": currentDayKey,
            "lastProcessedDayKey": lastProcessedDayKey ?? "none",
            "graceMinutes": graceMinutes,
            "rolloverEnabled": appGroup.rolloverEnabled,
            "lastRolloverCheck": lastRolloverCheck?.timeIntervalSince1970 ?? 0,
            "checkInterval": RolloverConfig.rolloverCheckInterval
        ]
    }
}

// MARK: - Supporting Types

private enum RolloverTrigger: String {
    case appForeground = "app_foreground"
    case intentExecution = "intent_execution"
    case automatic = "automatic"
    case manual = "manual"
}

// MARK: - Backward Compatibility

@available(iOS 17.0, *)
public extension TaskRolloverHandler {
    /// Migration to CompleteRolloverManager
    static var shared: CompleteRolloverManager {
        return CompleteRolloverManager.shared
    }
}