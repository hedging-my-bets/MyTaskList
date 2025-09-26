import Foundation
import AppIntents
import SharedKit

// MARK: - App Intent Provider

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct PetProgressAppIntentProvider: AppIntentsPackage {
    static var appIntents: [any AppIntent.Type] {
        return [
            // Legacy app intents (for backwards compatibility)
            CompleteTaskIntent.self,
            SnoozeTaskIntent.self,
            MarkNextIntent.self,
            AdminRegressIntent.self,
            // Widget Lock Screen intents (CRITICAL for widget functionality)
            MarkNextTaskDoneIntent.self,
            SkipCurrentTaskIntent.self,
            GoToNextTaskIntent.self,
            GoToPreviousTaskIntent.self
        ]
    }
}

// MARK: - Complete Task Intent

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct CompleteTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Complete Task"
    static var description = IntentDescription("Marks the next scheduled task as complete")

    func perform() async throws -> some IntentResult {
        let now = Date()
        let dayKey = TimeSlot.dayKey(for: now)

        if SharedStore.shared.markNextDone(for: dayKey, now: now) != nil {
            return .result()
        } else {
            throw IntentError.noTasksAvailable
        }
    }
}

// MARK: - Snooze Task Intent

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct SnoozeTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Snooze Task"
    static var description = IntentDescription("Snoozes the next task by 1 hour")

    func perform() async throws -> some IntentResult {
        let now = Date()
        let dayKey = TimeSlot.dayKey(for: now)

        if SharedStore.shared.snoozeNext(for: dayKey, minutes: 60, now: now) != nil {
            return .result()
        } else {
            throw IntentError.noTasksAvailable
        }
    }
}

// MARK: - Mark Next Intent

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct MarkNextIntent: AppIntent {
    static var title: LocalizedStringResource = "Mark Next"
    static var description = IntentDescription("Marks the current task as done and advances to next")

    func perform() async throws -> some IntentResult {
        let now = Date()
        let dayKey = TimeSlot.dayKey(for: now)

        if SharedStore.shared.markNextDone(for: dayKey, now: now) != nil {
            return .result()
        } else {
            throw IntentError.noTasksAvailable
        }
    }
}

// MARK: - Admin Regress Intent (Optional)

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct AdminRegressIntent: AppIntent {
    static var title: LocalizedStringResource = "Regress Pet"
    static var description = IntentDescription("Admin: Reduces pet points by 10")

    func perform() async throws -> some IntentResult {
        let now = Date()
        let dayKey = TimeSlot.dayKey(for: now)

        SharedStore.shared.regress(by: 10, dayKey: dayKey)
        return .result()
    }
}

// MARK: - Intent Errors

enum IntentError: Error, LocalizedError {
    case noTasksAvailable

    var errorDescription: String? {
        switch self {
        case .noTasksAvailable:
            return "No tasks available to complete or snooze"
        }
    }
}
