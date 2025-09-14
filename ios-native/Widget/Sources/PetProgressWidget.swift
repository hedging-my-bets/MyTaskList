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
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .systemSmall, .systemMedium])
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
        let entry = SimpleEntry(date: Date(), dayModel: loadOrCreateDayModel())
        completion(entry)
    }

    func getTimeline(for configuration: ConfigurationAppIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
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
            CircularLockScreenView(entry: entry)
        case .accessoryRectangular:
            RectangularLockScreenView(entry: entry)
        case .systemSmall, .systemMedium:
            StandardWidgetView(entry: entry)
        default:
            StandardWidgetView(entry: entry)
        }
    }
}

// MARK: - Circular Lock Screen

struct CircularLockScreenView: View {
    let entry: SimpleEntry
    private let engine = PetEvolutionEngine()

    var body: some View {
        ZStack {
            // Progress ring
            Circle()
                .stroke(.tertiary, lineWidth: 3)
            Circle()
                .trim(from: 0, to: progressToNextStage)
                .stroke(.blue, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))

            // Pet stage number
            Text("\(currentStage + 1)")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.primary)
        }
        .containerBackground(for: .widget) {
            AccessoryWidgetBackground()
        }
    }

    private var currentStage: Int {
        engine.stageIndex(for: entry.dayModel.points)
    }

    private var progressToNextStage: Double {
        // Simplified progress calculation
        let stage = currentStage
        if stage >= 15 { return 1.0 }

        let progress = Double(entry.dayModel.points % 50) / 50.0
        return max(0.0, min(1.0, progress))
    }
}

// MARK: - Rectangular Lock Screen with Working Buttons

struct RectangularLockScreenView: View {
    let entry: SimpleEntry

    var body: some View {
        VStack(spacing: 4) {
            // Pet status
            HStack {
                Text("Stage \(currentStage + 1)")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                Text("\(entry.dayModel.points) XP")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            // Next task
            if let nextTask = nextIncompleteTask {
                HStack {
                    Text(nextTask.title)
                        .font(.system(size: 12))
                        .lineLimit(1)
                    Spacer()
                    Text("\(nextTask.hour):00")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }

            // Action buttons - THESE ACTUALLY WORK
            if nextIncompleteTask != nil {
                HStack(spacing: 6) {
                    // Navigation
                    Button(intent: ShowPreviousTaskIntent()) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(intent: ShowNextTaskIntent()) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())

                    Spacer()

                    // Actions
                    Button(intent: CompleteTaskIntent()) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.green)
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(intent: SkipTaskIntent()) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16))
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(.horizontal, 8)
        .containerBackground(for: .widget) {
            AccessoryWidgetBackground()
        }
    }

    private var currentStage: Int {
        let engine = PetEvolutionEngine()
        return engine.stageIndex(for: entry.dayModel.points)
    }

    private var nextIncompleteTask: DayModel.Slot? {
        let currentHour = Calendar.current.component(.hour, from: entry.date)
        // Show task for current hour or next upcoming task
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