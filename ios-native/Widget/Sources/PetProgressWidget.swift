import WidgetKit
import SwiftUI
import SharedKit
import AppIntents
import os.log

/// Pet Progress Widget - Simple and Functional
@main
struct PetProgressWidgetBundle: WidgetBundle {
    var body: some Widget {
        PetProgressWidget()
    }
}

struct PetProgressWidget: Widget {
    let kind: String = "PetProgressWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            PetProgressWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Pet Progress")
        .description("Track your tasks and watch your pet evolve")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline, .systemSmall, .systemMedium])
    }
}

// MARK: - Configuration Intent

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Configuration"
    static var description = IntentDescription("This is an example widget.")
}

// MARK: - Timeline Provider

struct Provider: AppIntentTimelineProvider {
    private let logger = Logger(subsystem: "com.petprogress.Widget", category: "Provider")

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), dayModel: createPlaceholderModel())
    }

    func getSnapshot(for configuration: ConfigurationAppIntent, in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        // Respect widget preview constraints - limit execution time
        let startTime = CFAbsoluteTimeGetCurrent()
        let timeout: CFAbsoluteTime = 2.0 // Shorter timeout for snapshots

        let dayModel: DayModel
        if CFAbsoluteTimeGetCurrent() - startTime > timeout {
            logger.warning("Snapshot generation exceeded time budget, using placeholder")
            dayModel = createPlaceholderModel()
        } else {
            dayModel = loadOrCreateDayModel()
        }

        let entry = SimpleEntry(date: Date(), dayModel: dayModel)
        completion(entry)
    }

    func getTimeline(for configuration: ConfigurationAppIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let timeout: CFAbsoluteTime = 8.0 // Respect widget timeline budget

        let now = Date()

        // Calculate next top of hour for timeline alignment
        let nextHour = Calendar.current.nextDate(
            after: now,
            matching: DateComponents(minute: 0, second: 0),
            matchingPolicy: .nextTime,
            direction: .forward
        ) ?? now.addingTimeInterval(3600)

        logger.info("Building timeline from \(now) to next hour at \(nextHour)")

        // Build entries for next 12 hours, aligned to top of hour
        var entries: [SimpleEntry] = []
        var entryDate = nextHour

        for hourOffset in 0..<12 {
            // Check execution budget periodically
            if CFAbsoluteTimeGetCurrent() - startTime > timeout {
                logger.warning("Timeline generation exceeded time budget at hour \(hourOffset)")
                // Create minimal fallback timeline with current data
                let fallbackModel = loadOrCreateDayModel()
                let fallbackEntry = SimpleEntry(date: now, dayModel: fallbackModel)
                let fallbackTimeline = Timeline(entries: [fallbackEntry], policy: .after(nextHour))
                completion(fallbackTimeline)
                return
            }

            let dayModel = loadDayModelForDate(entryDate)
            let entry = SimpleEntry(date: entryDate, dayModel: dayModel)
            entries.append(entry)

            entryDate = Calendar.current.date(byAdding: .hour, value: 1, to: entryDate) ?? entryDate.addingTimeInterval(3600)
        }

        // Add current entry if we're not at top of hour yet
        if Calendar.current.component(.minute, from: now) != 0 || Calendar.current.component(.second, from: now) != 0 {
            let currentEntry = SimpleEntry(date: now, dayModel: loadOrCreateDayModel())
            entries.insert(currentEntry, at: 0)
        }

        let timeline = Timeline(entries: entries, policy: .after(nextHour))
        logger.info("Timeline built with \(entries.count) entries, next refresh at \(nextHour)")

        completion(timeline)
    }

    private func loadOrCreateDayModel() -> DayModel {
        let todayKey = TimeSlot.todayKey()
        return SharedStore.shared.getCurrentDayModel() ?? createPlaceholderModel()
    }

    private func loadDayModelForDate(_ date: Date) -> DayModel {
        let dayKey = TimeSlot.dayKey(for: date)
        return SharedStore.shared.loadDay(key: dayKey) ?? createPlaceholderModelForDate(date)
    }

    private func createPlaceholderModel() -> DayModel {
        return DayModel(
            key: TimeSlot.todayKey(),
            slots: [
                DayModel.Slot(hour: 9, title: "Morning task", isDone: false),
                DayModel.Slot(hour: 14, title: "Afternoon task", isDone: true),
                DayModel.Slot(hour: 18, title: "Evening task", isDone: false)
            ],
            points: 25
        )
    }

    private func createPlaceholderModelForDate(_ date: Date) -> DayModel {
        let dayKey = TimeSlot.dayKey(for: date)
        let hour = Calendar.current.component(.hour, from: date)

        // Create a single task for the current hour
        return DayModel(
            key: dayKey,
            slots: [
                DayModel.Slot(hour: hour, title: "Task at \(hour):00", isDone: false)
            ],
            points: 25
        )
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let dayModel: DayModel
}

// MARK: - Widget Views

struct PetProgressWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        switch widgetFamily {
        case .accessoryCircular:
            AccessoryCircularView(entry: entry)
                .widgetURL(deepLinkURL)
        case .accessoryRectangular:
            AccessoryRectangularView(entry: entry)
                .widgetURL(deepLinkURL)
        case .accessoryInline:
            AccessoryInlineView(entry: entry)
                .widgetURL(deepLinkURL)
        case .systemSmall, .systemMedium:
            StandardWidgetView(entry: entry)
                .widgetURL(deepLinkURL)
        default:
            StandardWidgetView(entry: entry)
                .widgetURL(deepLinkURL)
        }
    }

    private var deepLinkURL: URL? {
        guard let currentTask = nextIncompleteTask else { return nil }

        var components = URLComponents()
        components.scheme = "petprogress"
        components.host = "task"
        components.queryItems = [
            URLQueryItem(name: "dayKey", value: entry.dayModel.key),
            URLQueryItem(name: "hour", value: String(currentTask.hour)),
            URLQueryItem(name: "title", value: currentTask.title)
        ]
        return components.url
    }

    private var nextIncompleteTask: DayModel.Slot? {
        let currentHour = Calendar.current.component(.hour, from: entry.date)
        return entry.dayModel.slots.first { slot in
            slot.hour >= currentHour && !slot.isDone
        }
    }
}


// MARK: - Standard Widget

struct StandardWidgetView: View {
    let entry: SimpleEntry

    var body: some View {
        VStack {
            Text("Pet Progress")
                .font(.headline)
            Text("Stage \(currentStage + 1)")
                .font(.title2)
            Text("\(completedTasks)/\(totalTasks) tasks")
                .font(.caption)
        }
    }

    private var currentStage: Int {
        let engine = PetEvolutionEngine()
        return engine.stageIndex(for: entry.dayModel.points)
    }

    private var completedTasks: Int {
        entry.dayModel.slots.filter { $0.isDone }.count
    }

    private var totalTasks: Int {
        entry.dayModel.slots.count
    }
}

#Preview(as: .accessoryRectangular) {
    PetProgressWidget()
} timeline: {
    SimpleEntry(date: .now, dayModel: DayModel(
        key: "preview",
        slots: [
            DayModel.Slot(hour: 10, title: "Focus work", isDone: false),
            DayModel.Slot(hour: 14, title: "Lunch break", isDone: true)
        ],
        points: 35
    ))
}