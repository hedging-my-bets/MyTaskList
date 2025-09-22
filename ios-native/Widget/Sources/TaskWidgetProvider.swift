import WidgetKit
import AppIntents
import SharedKit
import os.log

/// Timeline provider for Task widgets using TaskEntity and hourly refresh policy
@available(iOS 17.0, *)
struct TaskWidgetProvider: AppIntentTimelineProvider {
    private let logger = Logger(subsystem: "com.petprogress.Widget", category: "TaskProvider")

    func placeholder(in context: Context) -> TaskEntry {
        TaskEntry(
            date: Date(),
            tasks: createPlaceholderTasks(),
            petStage: PetStage(points: 25, stageIndex: 2)
        )
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context, completion: @escaping (TaskEntry) -> ()) {
        // For widget gallery and preview - use placeholder data
        let entry = TaskEntry(
            date: Date(),
            tasks: createPlaceholderTasks(),
            petStage: PetStage(points: 25, stageIndex: 2)
        )
        completion(entry)
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context, completion: @escaping (Timeline<TaskEntry>) -> ()) {
        let startTime = CFAbsoluteTimeGetCurrent()
        logger.info("Building task timeline")

        Task {
            do {
                let timeline = try await buildHourlyTimeline()
                let duration = CFAbsoluteTimeGetCurrent() - startTime
                logger.info("Task timeline built in \(String(format: "%.3f", duration))s")
                completion(timeline)
            } catch {
                logger.error("Failed to build timeline: \(error.localizedDescription)")
                let fallbackTimeline = createFallbackTimeline()
                completion(fallbackTimeline)
            }
        }
    }

    // MARK: - Hourly Timeline Implementation

    private func buildHourlyTimeline() async throws -> Timeline<TaskEntry> {
        let now = Date()
        let current = now.topOfHour
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: current)!

        logger.debug("Building hourly timeline: current=\(current), next=\(next)")

        // Use AppGroupStore for optimal Lock Screen widget performance
        let store = AppGroupStore.shared

        // Load current tasks and pet stage
        let currentTasks = store.getCurrentTasks(now: current)
        let tasks = convertTaskItemsToTaskEntities(currentTasks)
        let petStage = PetStage(
            points: store.state.pet.stageXP,
            stageIndex: store.state.pet.stageIndex
        )

        // Create single entry for current hour
        let entry = TaskEntry(
            date: current,
            tasks: tasks,
            petStage: petStage
        )

        // Timeline policy: refresh at top of next hour
        let timeline = Timeline(entries: [entry], policy: .after(next))

        logger.debug("Created hourly timeline with \(tasks.count) tasks, next refresh at \(next)")
        return timeline
    }

    private func createFallbackTimeline() -> Timeline<TaskEntry> {
        let now = Date()
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: now.topOfHour) ?? now.addingTimeInterval(3600)

        let entry = TaskEntry(
            date: now,
            tasks: createPlaceholderTasks(),
            petStage: PetStage(points: 25, stageIndex: 2)
        )

        // Retry in 5 minutes for fallback
        let retryDate = now.addingTimeInterval(300)
        return Timeline(entries: [entry], policy: .after(retryDate))
    }

    private func convertTaskItemsToTaskEntities(_ taskItems: [TaskItem]) -> [TaskEntity] {
        let todayKey = TimeSlot.dayKey(for: Date())
        return taskItems.compactMap { taskItem in
            guard let hour = taskItem.scheduledAt.hour else { return nil }
            return TaskEntity(
                id: taskItem.id.uuidString,
                title: taskItem.title,
                dueHour: hour,
                isDone: taskItem.isDone,
                dayKey: todayKey
            )
        }
    }

    private func createPlaceholderTasks() -> [TaskEntity] {
        let todayKey = TimeSlot.dayKey(for: Date())
        return [
            TaskEntity(id: "placeholder1", title: "Add tasks in app", dueHour: 9, isDone: false, dayKey: todayKey),
            TaskEntity(id: "placeholder2", title: "Check your progress", dueHour: 14, isDone: false, dayKey: todayKey),
            TaskEntity(id: "placeholder3", title: "Review your day", dueHour: 18, isDone: false, dayKey: todayKey)
        ]
    }
}

// MARK: - Date Extension for Hourly Alignment

// Note: Date.topOfHour extension is defined in PetProgressWidget.swift

// Configuration intent moved to PetProgressWidget.swift to avoid duplicates