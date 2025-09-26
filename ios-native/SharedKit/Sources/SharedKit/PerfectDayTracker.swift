import Foundation
import os.log

/// Steve Jobs-quality perfect day detection system
/// Tracks task completion perfection and triggers celebrations
@available(iOS 17.0, *)
public final class PerfectDayTracker {
    public static let shared = PerfectDayTracker()

    private let logger = Logger(subsystem: "com.petprogress.PerfectDay", category: "Tracker")
    private let userDefaults: UserDefaults

    // Keys for persistence
    private let perfectDayCountKey = "perfectDayCount"
    private let lastPerfectDayKey = "lastPerfectDay"
    private let currentStreakKey = "currentStreak"
    private let bestStreakKey = "bestStreak"
    private let lastCheckedDayKey = "lastCheckedDay"

    // Perfect day thresholds
    private let minimumTasksForPerfectDay = 3
    private let bonusXPForPerfectDay = 50
    private let streakBonusMultiplier = 1.5

    private init() {
        guard let groupDefaults = UserDefaults(suiteName: "group.com.hedgingmybets.PetProgress") else {
            logger.fault("Failed to access App Group UserDefaults")
            fatalError("App Group configuration error")
        }
        self.userDefaults = groupDefaults
    }

    /// Check if today was a perfect day and trigger celebrations
    public func checkPerfectDay(for dayKey: String) -> PerfectDayResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        defer {
            let duration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
            logger.info("Perfect day check completed in \(String(format: "%.2f", duration))ms")
        }

        // Prevent duplicate checking for the same day
        if userDefaults.string(forKey: lastCheckedDayKey) == dayKey {
            logger.debug("Day \(dayKey) already checked")
            return PerfectDayResult(
                isPerfect: false,
                reason: .alreadyChecked,
                tasksCompleted: 0,
                totalTasks: 0,
                bonusXP: 0,
                streakDays: getCurrentStreak()
            )
        }

        // Get day's task completion data
        let store = AppGroupStore.shared
        let dayTasks = store.state.tasks.filter { task in
            task.dayKey == dayKey
        }

        let completedTasks = dayTasks.filter { task in
            store.isTaskCompleted(task.id, dayKey: dayKey)
        }

        let totalTasks = dayTasks.count
        let completedCount = completedTasks.count

        // Determine if it's a perfect day
        let isPerfect = totalTasks >= minimumTasksForPerfectDay &&
                       completedCount == totalTasks

        // Calculate bonus XP
        let bonusXP = isPerfect ? calculateBonusXP(tasksCompleted: completedCount) : 0

        // Update streak if perfect
        if isPerfect {
            updateStreak(for: dayKey)
            recordPerfectDay(dayKey: dayKey)
        } else if totalTasks > 0 && completedCount < totalTasks {
            // Break streak if tasks were incomplete
            resetStreak()
        }

        // Mark as checked
        userDefaults.set(dayKey, forKey: lastCheckedDayKey)

        let reason: PerfectDayReason
        if isPerfect {
            reason = .allTasksCompleted
        } else if totalTasks < minimumTasksForPerfectDay {
            reason = .tooFewTasks
        } else {
            reason = .incompleteTasks
        }

        logger.info("Perfect day check: \(isPerfect ? "YES" : "NO") - \(completedCount)/\(totalTasks) tasks, bonus: \(bonusXP) XP")

        return PerfectDayResult(
            isPerfect: isPerfect,
            reason: reason,
            tasksCompleted: completedCount,
            totalTasks: totalTasks,
            bonusXP: bonusXP,
            streakDays: getCurrentStreak()
        )
    }

    /// Calculate bonus XP for perfect day with streak multiplier
    private func calculateBonusXP(tasksCompleted: Int) -> Int {
        let baseBonus = bonusXPForPerfectDay
        let taskBonus = tasksCompleted * 5 // Extra 5 XP per task
        let streakMultiplier = 1.0 + (Double(getCurrentStreak()) * 0.1) // 10% per streak day

        let totalBonus = Int(Double(baseBonus + taskBonus) * min(streakMultiplier, 3.0)) // Cap at 3x

        return totalBonus
    }

    /// Update streak tracking
    private func updateStreak(for dayKey: String) {
        let lastPerfectDay = userDefaults.string(forKey: lastPerfectDayKey)

        // Check if this continues a streak
        if let lastDay = lastPerfectDay, isConsecutiveDay(from: lastDay, to: dayKey) {
            // Continue streak
            let currentStreak = getCurrentStreak() + 1
            userDefaults.set(currentStreak, forKey: currentStreakKey)

            // Update best streak if needed
            let bestStreak = getBestStreak()
            if currentStreak > bestStreak {
                userDefaults.set(currentStreak, forKey: bestStreakKey)
                logger.info("New best streak: \(currentStreak) days!")
            }
        } else {
            // Start new streak
            userDefaults.set(1, forKey: currentStreakKey)
        }

        userDefaults.set(dayKey, forKey: lastPerfectDayKey)
    }

    /// Reset streak on missed day
    private func resetStreak() {
        let currentStreak = getCurrentStreak()
        if currentStreak > 0 {
            logger.info("Streak broken after \(currentStreak) days")
            userDefaults.set(0, forKey: currentStreakKey)
        }
    }

    /// Record a perfect day
    private func recordPerfectDay(dayKey: String) {
        let count = userDefaults.integer(forKey: perfectDayCountKey) + 1
        userDefaults.set(count, forKey: perfectDayCountKey)
        logger.info("Perfect day #\(count) recorded for \(dayKey)")
    }

    /// Check if two day keys are consecutive
    private func isConsecutiveDay(from lastDay: String, to currentDay: String) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        guard let lastDate = formatter.date(from: lastDay),
              let currentDate = formatter.date(from: currentDay) else {
            return false
        }

        let calendar = Calendar.current
        let dayDifference = calendar.dateComponents([.day], from: lastDate, to: currentDate).day ?? 0

        return dayDifference == 1
    }

    // MARK: - Public Accessors

    public func getCurrentStreak() -> Int {
        return userDefaults.integer(forKey: currentStreakKey)
    }

    public func getBestStreak() -> Int {
        return userDefaults.integer(forKey: bestStreakKey)
    }

    public func getTotalPerfectDays() -> Int {
        return userDefaults.integer(forKey: perfectDayCountKey)
    }

    public func getLastPerfectDay() -> String? {
        return userDefaults.string(forKey: lastPerfectDayKey)
    }

    /// Check if we should show end-of-day summary
    public func shouldShowDaySummary(for date: Date = Date()) -> Bool {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)

        // Show summary between 9 PM and midnight
        return hour >= 21 && hour <= 23
    }

    /// Get motivational message based on completion
    public func getMotivationalMessage(tasksCompleted: Int, totalTasks: Int) -> String {
        let completionRate = totalTasks > 0 ? Double(tasksCompleted) / Double(totalTasks) : 0

        switch completionRate {
        case 1.0:
            let streak = getCurrentStreak()
            if streak > 1 {
                return "🔥 Perfect day! \(streak) day streak!"
            } else {
                return "⭐ Perfect day! All tasks completed!"
            }
        case 0.8..<1.0:
            return "💪 Almost there! Just \(totalTasks - tasksCompleted) task\(totalTasks - tasksCompleted == 1 ? "" : "s") left!"
        case 0.5..<0.8:
            return "👍 Good progress! Keep going!"
        case 0.25..<0.5:
            return "🌱 You've started! Every task counts!"
        case 0..<0.25 where totalTasks > 0:
            return "💫 Let's get started! Your pet believes in you!"
        default:
            return "📝 Add some tasks to start your journey!"
        }
    }
}

// MARK: - Perfect Day Result

public struct PerfectDayResult {
    public let isPerfect: Bool
    public let reason: PerfectDayReason
    public let tasksCompleted: Int
    public let totalTasks: Int
    public let bonusXP: Int
    public let streakDays: Int

    public var completionPercentage: Int {
        guard totalTasks > 0 else { return 0 }
        return Int((Double(tasksCompleted) / Double(totalTasks)) * 100)
    }
}

public enum PerfectDayReason {
    case allTasksCompleted
    case incompleteTasks
    case tooFewTasks
    case alreadyChecked
}

// MARK: - Streak Achievement Levels

public enum StreakAchievement {
    case none
    case bronze(days: Int)    // 3+ days
    case silver(days: Int)    // 7+ days
    case gold(days: Int)      // 14+ days
    case platinum(days: Int)  // 30+ days
    case diamond(days: Int)   // 100+ days

    public init(streakDays: Int) {
        switch streakDays {
        case 100...:
            self = .diamond(days: streakDays)
        case 30...:
            self = .platinum(days: streakDays)
        case 14...:
            self = .gold(days: streakDays)
        case 7...:
            self = .silver(days: streakDays)
        case 3...:
            self = .bronze(days: streakDays)
        default:
            self = .none
        }
    }

    public var emoji: String {
        switch self {
        case .none: return ""
        case .bronze: return "🥉"
        case .silver: return "🥈"
        case .gold: return "🥇"
        case .platinum: return "💎"
        case .diamond: return "💠"
        }
    }

    public var title: String {
        switch self {
        case .none: return ""
        case .bronze(let days): return "\(days) day streak!"
        case .silver(let days): return "\(days) day streak!"
        case .gold(let days): return "\(days) day streak!"
        case .platinum(let days): return "\(days) day streak!"
        case .diamond(let days): return "\(days) day streak!"
        }
    }
}