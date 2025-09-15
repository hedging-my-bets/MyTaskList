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

        // Get shared store
        let sharedStore = SharedStoreActor.shared

        // Load current tasks and pet stage
        let tasks = await sharedStore.getNearestHourTasks()
        let currentDay = await sharedStore.getCurrentDayModel()
        let petStage = PetStage(
            points: currentDay?.points ?? 0,
            stageIndex: PetEvolutionEngine().stageIndex(for: currentDay?.points ?? 0)
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

    private func createPlaceholderTasks() -> [TaskEntity] {
        let todayKey = TimeSlot.todayKey()
        return [
            TaskEntity(id: "placeholder1", title: "Add tasks in app", dueHour: 9, isDone: false, dayKey: todayKey),
            TaskEntity(id: "placeholder2", title: "Check your progress", dueHour: 14, isDone: false, dayKey: todayKey),
            TaskEntity(id: "placeholder3", title: "Review your day", dueHour: 18, isDone: false, dayKey: todayKey)
        ]
    }
}

// MARK: - Date Extension for Hourly Alignment

extension Date {
    var topOfHour: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour], from: self)
        return calendar.date(from: components) ?? self
    }
}

// MARK: - Configuration Intent

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Configuration"
    static var description = IntentDescription("Configure your PetProgress widget")

    init() {}
}