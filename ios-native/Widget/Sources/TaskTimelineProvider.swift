import WidgetKit
import AppIntents
import SharedKit
import os.log

/// Dedicated timeline provider for interactive Lock Screen widgets
/// Steve Jobs-level architecture: Separate providers for different performance requirements
@available(iOS 17.0, *)
struct TaskTimelineProvider: AppIntentTimelineProvider {
    private let logger = Logger(subsystem: "com.petprogress.Widget", category: "TaskTimelineProvider")

    func placeholder(in context: Context) -> TaskTimelineEntry {
        TaskTimelineEntry(
            date: Date(),
            currentTask: createPlaceholderCurrentTask(),
            nextTask: createPlaceholderNextTask(),
            petState: createPlaceholderPetState(),
            graceMinutes: 30,
            emptyStateMessage: nil
        )
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context, completion: @escaping (TaskTimelineEntry) -> ()) {
        // For widget gallery - return immediately with placeholder
        let entry = TaskTimelineEntry(
            date: Date(),
            currentTask: createPlaceholderCurrentTask(),
            nextTask: createPlaceholderNextTask(),
            petState: createPlaceholderPetState(),
            graceMinutes: 30,
            emptyStateMessage: nil
        )
        completion(entry)
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context, completion: @escaping (Timeline<TaskTimelineEntry>) -> ()) {
        let startTime = CFAbsoluteTimeGetCurrent()
        logger.info("Building Lock Screen timeline")

        // Lock Screen widgets have 2-second strict budget - optimize aggressively
        Task {
            do {
                let timeline = try await buildLockScreenTimeline()
                let duration = CFAbsoluteTimeGetCurrent() - startTime
                logger.info("Lock Screen timeline built in \(String(format: "%.3f", duration))s")
                completion(timeline)
            } catch {
                logger.error("Lock Screen timeline failed: \(error.localizedDescription)")
                let fallbackTimeline = createLockScreenFallbackTimeline()
                completion(fallbackTimeline)
            }
        }
    }

    // MARK: - Lock Screen Optimized Timeline

    private func buildLockScreenTimeline() async throws -> Timeline<TaskTimelineEntry> {
        let now = Date()
        // Steve Jobs-level responsiveness: Refresh every 5 minutes for Lock Screen widgets
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: now) ?? now.addingTimeInterval(300)

        // Load data from App Group store (faster than SharedStoreActor for Lock Screen)
        let store = AppGroupStore.shared
        let currentTasks = store.getCurrentTasks(now: now)
        let graceMinutes = store.state.graceMinutes

        // Find current and next tasks based on grace window
        let (currentTask, nextTask) = categorizeTasksForLockScreen(currentTasks, now: now, graceMinutes: graceMinutes)

        // Create timeline entry
        let entry = TaskTimelineEntry(
            date: now,
            currentTask: currentTask,
            nextTask: nextTask,
            petState: store.state.pet,
            graceMinutes: graceMinutes,
            emptyStateMessage: currentTasks.isEmpty ? "Add tasks in app" : nil
        )

        // Lock Screen widgets refresh more frequently (every 5 min) for better user experience
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))

        logger.debug("Lock Screen timeline: current=\(currentTask?.title ?? "none"), next=\(nextTask?.title ?? "none")")
        return timeline
    }

    private func categorizeTasksForLockScreen(_ tasks: [TaskItem], now: Date, graceMinutes: Int) -> (current: TaskItem?, next: TaskItem?) {
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)

        // Find current task (within grace window)
        let currentTask = tasks.first { task in
            guard let taskHour = task.scheduledAt.hour else { return false }
            return isTaskWithinGraceWindow(
                taskHour: taskHour,
                currentHour: currentHour,
                currentMinute: currentMinute,
                graceMinutes: graceMinutes
            )
        }

        // Find next upcoming task (after current time)
        let nextTask = tasks.first { task in
            guard let taskHour = task.scheduledAt.hour else { return false }
            return taskHour > currentHour || (taskHour == currentHour && task != currentTask)
        }

        return (currentTask, nextTask)
    }

    private func isTaskWithinGraceWindow(taskHour: Int, currentHour: Int, currentMinute: Int, graceMinutes: Int) -> Bool {
        // Steve Jobs-quality grace period logic matching AppGroupStore implementation
        let taskMinutes = taskHour * 60
        let currentMinutes = currentHour * 60 + currentMinute

        // Calculate grace window boundaries
        let graceWindowStart = taskMinutes
        let graceWindowEnd = taskMinutes + graceMinutes

        // Special handling for midnight crossing
        if graceWindowEnd >= 24 * 60 {
            // Grace window crosses midnight (e.g., task at 23:30 with 60 min grace)
            let nextDayEnd = graceWindowEnd - 24 * 60

            // Current time is either late tonight or early tomorrow
            return (currentMinutes >= graceWindowStart) || (currentMinutes <= nextDayEnd)
        } else {
            // Normal case: grace window doesn't cross midnight
            return currentMinutes >= graceWindowStart && currentMinutes <= graceWindowEnd
        }
    }

    private func createLockScreenFallbackTimeline() -> Timeline<TaskTimelineEntry> {
        let now = Date()
        let retryDate = now.addingTimeInterval(300) // Retry in 5 minutes

        let entry = TaskTimelineEntry(
            date: now,
            currentTask: nil,
            nextTask: nil,
            petState: PetState(stageIndex: 0, stageXP: 0, lastCloseoutDayKey: "", lastCelebratedStage: -1),
            graceMinutes: 30,
            emptyStateMessage: "Add tasks in app"
        )

        return Timeline(entries: [entry], policy: .after(retryDate))
    }

    // MARK: - Placeholder Data

    private func createPlaceholderCurrentTask() -> TaskItem {
        TaskItem(
            id: UUID(),
            title: "Focus session",
            scheduledAt: DateComponents(hour: Calendar.current.component(.hour, from: Date())),
            isDone: false
        )
    }

    private func createPlaceholderNextTask() -> TaskItem {
        let nextHour = (Calendar.current.component(.hour, from: Date()) + 1) % 24
        return TaskItem(
            id: UUID(),
            title: "Break time",
            scheduledAt: DateComponents(hour: nextHour),
            isDone: false
        )
    }

    private func createPlaceholderPetState() -> PetState {
        PetState(stageIndex: 2, stageXP: 25, lastCloseoutDayKey: "", lastCelebratedStage: 1)
    }
}

// MARK: - TaskTimelineEntry Model

struct TaskTimelineEntry: TimelineEntry {
    let date: Date
    let currentTask: TaskItem?
    let nextTask: TaskItem?
    let petState: PetState
    let graceMinutes: Int
    let emptyStateMessage: String?
}

// Configuration intent moved to PetProgressWidget.swift to avoid duplicates