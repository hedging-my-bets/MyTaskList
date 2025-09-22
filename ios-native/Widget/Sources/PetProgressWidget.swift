import WidgetKit
import SwiftUI
import SharedKit
import AppIntents
import os.log

/// Pet Progress Widget Bundle - All Widgets in One Bundle (Steve Jobs Architecture)
@main
struct PetProgressWidgetBundle: WidgetBundle {
    var body: some Widget {
        if #available(iOS 17.0, *) {
            PetProgressWidget()
            PetProgressInteractiveLockScreenWidget()
        }
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

struct ConfigurationAppIntent: WidgetConfigurationIntent, Sendable {
    static var title: LocalizedStringResource = "Configuration"
    static var description = IntentDescription("This is an example widget.")
}

// MARK: - Timeline Provider

struct Provider: AppIntentTimelineProvider {
    private let logger = Logger(subsystem: "com.petprogress.Widget", category: "Provider")

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), dayModel: createPlaceholderModel())
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context, completion: @escaping (SimpleEntry) -> ()) {
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

    func timeline(for configuration: ConfigurationAppIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let timeout: CFAbsoluteTime = 8.0 // Respect widget timeline budget

        let now = Date()
        let topOfCurrentHour = now.topOfHour
        let topOfNextHour = topOfCurrentHour.addingTimeInterval(3600)

        logger.info("Building hourly timeline: current hour \(topOfCurrentHour), next hour \(topOfNextHour)")

        // Build exactly 2 entries: current hour and next hour
        var entries: [SimpleEntry] = []

        // Entry for current hour (shows nearest-hour filtered tasks)
        let currentHourModel = loadNearestHourDayModel(for: topOfCurrentHour)
        entries.append(SimpleEntry(date: topOfCurrentHour, dayModel: currentHourModel))

        // Entry for next hour
        let nextHourModel = loadNearestHourDayModel(for: topOfNextHour)
        entries.append(SimpleEntry(date: topOfNextHour, dayModel: nextHourModel))

        // Timeline policy: refresh at top of next hour
        let timeline = Timeline(entries: entries, policy: .after(topOfNextHour))

        let duration = CFAbsoluteTimeGetCurrent() - startTime
        logger.info("Hourly timeline built with \(entries.count) entries in \(String(format: "%.3f", duration))s, next refresh at \(topOfNextHour)")

        completion(timeline)
    }

    private func loadOrCreateDayModel() -> DayModel {
        let todayKey = TimeSlot.dayKey(for: Date())
        return SharedStore.shared.getCurrentDayModel() ?? createPlaceholderModel()
    }

    private func loadDayModelForDate(_ date: Date) -> DayModel {
        let dayKey = TimeSlot.dayKey(for: date)
        return SharedStore.shared.loadDay(key: dayKey) ?? createPlaceholderModelForDate(date)
    }

    private func loadNearestHourDayModel(for date: Date) -> DayModel {
        let dayKey = TimeSlot.dayKey(for: date)
        let calendar = Calendar.current
        let targetHour = calendar.component(.hour, from: date)
        let targetMinute = calendar.component(.minute, from: date)

        // Load full day model
        guard let fullDayModel = SharedStore.shared.loadDay(key: dayKey) ?? SharedStore.shared.getCurrentDayModel() else {
            return createPlaceholderModelForDate(date)
        }

        // Get grace minutes from App Group storage
        let graceMinutes = AppGroupDefaults.shared.graceMinutes

        // Compute active slot with grace period
        let activeSlots = fullDayModel.slots.filter { slot in
            let slotHour = slot.hour
            let hourDiff = abs(slotHour - targetHour)

            // Current hour tasks are always active
            if slotHour == targetHour {
                return true
            }

            // Previous hour tasks active if within grace period
            if slotHour == targetHour - 1 || (targetHour == 0 && slotHour == 23) {
                // Grace period extends into next hour
                return targetMinute <= graceMinutes
            }

            return false
        }

        return DayModel(
            key: fullDayModel.key,
            slots: activeSlots,
            points: fullDayModel.points
        )
    }

    private func createPlaceholderModel() -> DayModel {
        return DayModel(
            key: TimeSlot.dayKey(for: Date()),
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

struct SimpleEntry: TimelineEntry, Sendable {
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

// MARK: - Date Extensions

extension Date {
    var topOfHour: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour], from: self)
        return calendar.date(from: components) ?? self
    }
}