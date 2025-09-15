import Foundation

/// World-class empty state management with contextual, time-aware messaging
/// Provides intelligent copy that guides users naturally through their day
public struct EmptyStateManager {

    /// Generate contextual empty state message based on current time and next scheduled task
    public static func generateEmptyStateMessage(
        currentHour: Int,
        nextTaskHour: Int?,
        graceMinutes: Int,
        totalTasksToday: Int
    ) -> EmptyStateMessage {

        // No tasks at all today
        if totalTasksToday == 0 {
            return EmptyStateMessage(
                title: "Ready to start",
                subtitle: "Add your first task to begin your journey",
                icon: "plus.circle"
            )
        }

        // Has tasks, but nothing in current window
        guard let nextHour = nextTaskHour else {
            return allTasksCompletedMessage(currentHour: currentHour)
        }

        // Calculate time to next task
        let hoursUntilNext = calculateHoursUntilNext(from: currentHour, to: nextHour)

        return generateTimeContextualMessage(
            currentHour: currentHour,
            nextTaskHour: nextHour,
            hoursUntilNext: hoursUntilNext,
            graceMinutes: graceMinutes
        )
    }

    // MARK: - Contextual Message Generation

    private static func generateTimeContextualMessage(
        currentHour: Int,
        nextTaskHour: Int,
        hoursUntilNext: Int,
        graceMinutes: Int
    ) -> EmptyStateMessage {

        if hoursUntilNext == 0 {
            // Next task is this hour but outside grace window
            if graceMinutes <= 30 {
                return EmptyStateMessage(
                    title: "Almost time",
                    subtitle: "Next task at \(formatHour(nextTaskHour))",
                    icon: "clock"
                )
            } else {
                return EmptyStateMessage(
                    title: "Coming up",
                    subtitle: "Next task at \(formatHour(nextTaskHour))",
                    icon: "clock.arrow.circlepath"
                )
            }
        }

        if hoursUntilNext == 1 {
            return EmptyStateMessage(
                title: "One hour free",
                subtitle: "Next task at \(formatHour(nextTaskHour))",
                icon: "hourglass"
            )
        }

        if hoursUntilNext <= 3 {
            return EmptyStateMessage(
                title: "\(hoursUntilNext) hours free",
                subtitle: "Next task at \(formatHour(nextTaskHour))",
                icon: "clock.badge.checkmark"
            )
        }

        // Long break - provide contextual guidance
        return generateLongBreakMessage(
            currentHour: currentHour,
            nextTaskHour: nextTaskHour,
            hoursUntilNext: hoursUntilNext
        )
    }

    private static func generateLongBreakMessage(
        currentHour: Int,
        nextTaskHour: Int,
        hoursUntilNext: Int
    ) -> EmptyStateMessage {

        let timeOfDay = getTimeOfDay(hour: currentHour)

        switch timeOfDay {
        case .earlyMorning:
            return EmptyStateMessage(
                title: "Good morning",
                subtitle: "Next task at \(formatHour(nextTaskHour))",
                icon: "sunrise"
            )

        case .morning:
            return EmptyStateMessage(
                title: "Morning break",
                subtitle: "Next task at \(formatHour(nextTaskHour))",
                icon: "cup.and.saucer"
            )

        case .midday:
            return EmptyStateMessage(
                title: "Lunch break",
                subtitle: "Next task at \(formatHour(nextTaskHour))",
                icon: "fork.knife"
            )

        case .afternoon:
            return EmptyStateMessage(
                title: "Afternoon free",
                subtitle: "Next task at \(formatHour(nextTaskHour))",
                icon: "sun.max"
            )

        case .evening:
            return EmptyStateMessage(
                title: "Evening ahead",
                subtitle: "Next task at \(formatHour(nextTaskHour))",
                icon: "moon.stars"
            )

        case .night:
            return EmptyStateMessage(
                title: "Rest well",
                subtitle: "Next task tomorrow at \(formatHour(nextTaskHour))",
                icon: "bed.double"
            )
        }
    }

    private static func allTasksCompletedMessage(currentHour: Int) -> EmptyStateMessage {
        let timeOfDay = getTimeOfDay(hour: currentHour)

        switch timeOfDay {
        case .earlyMorning, .morning:
            return EmptyStateMessage(
                title: "All caught up",
                subtitle: "Great start to your day",
                icon: "checkmark.circle"
            )

        case .midday, .afternoon:
            return EmptyStateMessage(
                title: "All done",
                subtitle: "Enjoy your free time",
                icon: "checkmark.circle.fill"
            )

        case .evening:
            return EmptyStateMessage(
                title: "Day complete",
                subtitle: "Well done today",
                icon: "star.circle"
            )

        case .night:
            return EmptyStateMessage(
                title: "Rest earned",
                subtitle: "Perfect day completed",
                icon: "moon.circle"
            )
        }
    }

    // MARK: - Utilities

    private static func calculateHoursUntilNext(from currentHour: Int, to nextHour: Int) -> Int {
        if nextHour >= currentHour {
            return nextHour - currentHour
        } else {
            // Next day
            return (24 - currentHour) + nextHour
        }
    }

    private static func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"

        let calendar = Calendar.current
        let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()

        return formatter.string(from: date).lowercased()
    }

    private static func getTimeOfDay(hour: Int) -> TimeOfDay {
        switch hour {
        case 5..<8: return .earlyMorning
        case 8..<12: return .morning
        case 12..<14: return .midday
        case 14..<18: return .afternoon
        case 18..<22: return .evening
        default: return .night
        }
    }
}

// MARK: - Models

public struct EmptyStateMessage {
    public let title: String
    public let subtitle: String
    public let icon: String

    public init(title: String, subtitle: String, icon: String) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
    }
}

private enum TimeOfDay {
    case earlyMorning, morning, midday, afternoon, evening, night
}

// MARK: - Widget Integration

extension EmptyStateManager {

    /// Generate empty state specifically for Lock Screen widget constraints
    public static func generateLockScreenEmptyState(
        currentHour: Int,
        nextTaskHour: Int?,
        family: String // "circular", "rectangular", "inline"
    ) -> LockScreenEmptyState {

        guard let nextHour = nextTaskHour else {
            return LockScreenEmptyState(
                text: "All done",
                icon: "checkmark.circle"
            )
        }

        let hoursUntilNext = calculateHoursUntilNext(from: currentHour, to: nextHour)

        switch family {
        case "circular":
            return LockScreenEmptyState(
                text: hoursUntilNext == 0 ? "Soon" : "\(hoursUntilNext)h",
                icon: "clock"
            )

        case "rectangular":
            if hoursUntilNext == 0 {
                return LockScreenEmptyState(
                    text: "Next at \(formatHour(nextHour))",
                    icon: "clock"
                )
            } else {
                return LockScreenEmptyState(
                    text: "\(hoursUntilNext)h free · Next \(formatHour(nextHour))",
                    icon: "hourglass"
                )
            }

        case "inline":
            return LockScreenEmptyState(
                text: hoursUntilNext == 0 ? "Next \(formatHour(nextHour))" : "\(hoursUntilNext)h free",
                icon: "clock"
            )

        default:
            return LockScreenEmptyState(
                text: "Ready",
                icon: "circle"
            )
        }
    }
}

public struct LockScreenEmptyState {
    public let text: String
    public let icon: String

    public init(text: String, icon: String) {
        self.text = text
        self.icon = icon
    }
}

// MARK: - Edge Case Handling

extension EmptyStateManager {

    /// Handle edge cases with graceful degradation
    public static func handleEdgeCase(_ condition: EmptyStateEdgeCase) -> EmptyStateMessage {
        switch condition {
        case .allTasksOverdue:
            return EmptyStateMessage(
                title: "Catch up time",
                subtitle: "Some tasks need attention",
                icon: "exclamationmark.circle"
            )

        case .systemClockIssue:
            return EmptyStateMessage(
                title: "Time sync needed",
                subtitle: "Check device time settings",
                icon: "clock.arrow.2.circlepath"
            )

        case .dataCorruption:
            return EmptyStateMessage(
                title: "Refreshing",
                subtitle: "Loading your tasks",
                icon: "arrow.clockwise.circle"
            )

        case .firstLaunch:
            return EmptyStateMessage(
                title: "Welcome",
                subtitle: "Ready to boost your productivity",
                icon: "sparkles"
            )
        }
    }
}

public enum EmptyStateEdgeCase {
    case allTasksOverdue
    case systemClockIssue
    case dataCorruption
    case firstLaunch
}