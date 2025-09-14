import WidgetKit
import SwiftUI
import SharedKit
import AppIntents

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), pet: PetState(stageIndex: 0, stageXP: 5, lastCloseoutDayKey: "2025-01-01"), tasksCompleted: 2, tasksTotal: 5, nextTask: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), pet: PetState(stageIndex: 0, stageXP: 5, lastCloseoutDayKey: "2025-01-01"), tasksCompleted: 2, tasksTotal: 5, nextTask: nil)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let currentDate = Date()
        let dayKey = SharedKit.dayKey(for: currentDate)

        // Load state
        let sharedStore = SharedStore()
        guard let state = try? sharedStore.loadState() else {
            let entry = SimpleEntry(date: currentDate, pet: PetState(stageIndex: 0, stageXP: 0, lastCloseoutDayKey: dayKey), tasksCompleted: 0, tasksTotal: 0, nextTask: nil)
            let timeline = Timeline(entries: [entry], policy: .atEnd)
            completion(timeline)
            return
        }

        // Materialize tasks
        let tasks = materializeTasks(for: dayKey, in: state)
        let completed = tasks.filter { $0.isCompleted }.count
        let total = tasks.count
        let nextTask = tasks.first { !$0.isCompleted }

        let entry = SimpleEntry(
            date: currentDate,
            pet: state.pet,
            tasksCompleted: completed,
            tasksTotal: total,
            nextTask: nextTask
        )

        // Update every 15 minutes
        let nextUpdateDate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdateDate))
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let pet: PetState
    let tasksCompleted: Int
    let tasksTotal: Int
    let nextTask: MaterializedTask?
}

struct PetProgressWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        switch widgetFamily {
        case .accessoryCircular:
            CircularLockScreenView(entry: entry)
        case .accessoryRectangular:
            RectangularLockScreenView(entry: entry)
        case .accessoryInline:
            InlineLockScreenView(entry: entry)
        default:
            StandardWidgetView(entry: entry)
        }
    }
}

struct CircularLockScreenView: View {
    let entry: Provider.Entry

    var body: some View {
        ZStack {
            // Progress ring
            Gauge(value: Double(entry.tasksCompleted), in: 0...Double(max(1, entry.tasksTotal))) {
                // Pet image in center based on current stage
                Image(petImageName(for: entry.pet.stageIndex))
                    .resizable()
                    .scaledToFit()
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )
            } currentValueLabel: {
                Text("\(entry.tasksCompleted)")
                    .font(.system(.caption2, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
            }
            .gaugeStyle(.accessoryCircular)

            // Interactive button overlay for next task completion
            if let nextTask = entry.nextTask, #available(iOS 16.0, *) {
                Button(intent: CompleteTaskIntent(
                    taskId: nextTask.id.uuidString,
                    dayKey: SharedKit.dayKey(for: entry.date)
                )) {
                    Circle()
                        .fill(.clear)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .accessibilityLabel("Pet at stage \(entry.pet.stageIndex). \(entry.tasksCompleted) of \(entry.tasksTotal) tasks completed. Tap to complete next task.")
    }

    private func petImageName(for stageIndex: Int) -> String {
        let stageAssets = [
            "pet_baby", "pet_toddler", "pet_frog", "pet_hermit", "pet_seahorse",
            "pet_dolphin", "pet_alligator", "pet_beaver", "pet_wolf", "pet_bear",
            "pet_bison", "pet_elephant", "pet_rhino", "pet_adult", "pet_ceo", "pet_gold"
        ]
        return stageAssets[safe: stageIndex] ?? "pet_frog"
    }
}

struct RectangularLockScreenView: View {
    let entry: Provider.Entry

    var body: some View {
        HStack(spacing: 10) {
            // Pet avatar with current stage
            ZStack {
                Image(petImageName(for: entry.pet.stageIndex))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(progressColor, lineWidth: 2)
                    )

                // Stage indicator
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("\(entry.pet.stageIndex)")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(progressColor, in: Capsule())
                            .offset(x: 4, y: 4)
                    }
                }
                .frame(width: 32, height: 32)
            }

            // Task info with interactive elements
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Text("\(entry.tasksCompleted)/\(entry.tasksTotal)")
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(progressColor)

                    if entry.tasksTotal > 0 {
                        ProgressView(value: Double(entry.tasksCompleted), total: Double(entry.tasksTotal))
                            .progressViewStyle(LinearProgressViewStyle())
                            .frame(width: 40)
                            .tint(progressColor)
                    }
                }

                if let nextTask = entry.nextTask {
                    Text("\(nextTask.title) • \(timeString(from: nextTask.time))")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                } else {
                    Text("All complete! 🎉")
                        .font(.system(size: 11))
                        .foregroundStyle(.green)
                }
            }

            Spacer()

            // Interactive completion button
            if let nextTask = entry.nextTask, #available(iOS 16.0, *) {
                VStack(spacing: 4) {
                    Button(intent: CompleteTaskIntent(
                        taskId: nextTask.id.uuidString,
                        dayKey: SharedKit.dayKey(for: entry.date)
                    )) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.green)
                    }
                    .buttonStyle(.plain)

                    Button(intent: SnoozeTaskIntent(
                        taskId: nextTask.id.uuidString,
                        dayKey: SharedKit.dayKey(for: entry.date)
                    )) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.orange)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Pet at stage \(entry.pet.stageIndex). \(entry.tasksCompleted) of \(entry.tasksTotal) tasks completed. \(nextTaskDescription)")
    }

    private var progressColor: Color {
        let progress = Double(entry.tasksCompleted) / Double(max(1, entry.tasksTotal))
        if progress >= 1.0 {
            return .green
        } else if progress >= 0.5 {
            return .blue
        } else {
            return .orange
        }
    }

    private var nextTaskDescription: String {
        if let nextTask = entry.nextTask {
            return "Next task: \(nextTask.title) at \(timeString(from: nextTask.time)). Tap checkmark to complete or clock to snooze."
        } else {
            return "All tasks completed!"
        }
    }

    private func petImageName(for stageIndex: Int) -> String {
        let stageAssets = [
            "pet_baby", "pet_toddler", "pet_frog", "pet_hermit", "pet_seahorse",
            "pet_dolphin", "pet_alligator", "pet_beaver", "pet_wolf", "pet_bear",
            "pet_bison", "pet_elephant", "pet_rhino", "pet_adult", "pet_ceo", "pet_gold"
        ]
        return stageAssets[safe: stageIndex] ?? "pet_frog"
    }

    private func timeString(from dateComponents: DateComponents) -> String {
        let hour = dateComponents.hour ?? 0
        let minute = dateComponents.minute ?? 0
        return String(format: "%02d:%02d", hour, minute)
    }
}

struct InlineLockScreenView: View {
    let entry: Provider.Entry

    var body: some View {
        HStack(spacing: 4) {
            // Pet emoji or icon
            Text(petEmoji(for: entry.pet.stageIndex))
                .font(.system(size: 14))

            // Compact progress info
            if let nextTask = entry.nextTask {
                Text("\(entry.tasksCompleted)/\(entry.tasksTotal) • \(nextTask.title) @ \(timeString(from: nextTask.time))")
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                    .truncationMode(.tail)
            } else if entry.tasksTotal > 0 {
                Text("\(entry.tasksCompleted)/\(entry.tasksTotal) tasks • All done! 🎉")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.green)
            } else {
                Text("Stage \(entry.pet.stageIndex) • No tasks today")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityLabel("Pet at stage \(entry.pet.stageIndex). \(entry.tasksCompleted) of \(entry.tasksTotal) tasks completed.")
    }

    private func petEmoji(for stageIndex: Int) -> String {
        let stageEmojis = [
            "🐣", "👶", "🐸", "🦀", "🐙", "🐬", "🐊", "🦫", "🐺", "🐻",
            "🦬", "🐘", "🦏", "👤", "👔", "👑"
        ]
        return stageEmojis[safe: stageIndex] ?? "🐸"
    }

    private func timeString(from dateComponents: DateComponents) -> String {
        let hour = dateComponents.hour ?? 0
        let minute = dateComponents.minute ?? 0
        return String(format: "%02d:%02d", hour, minute)
    }
}

struct StandardWidgetView: View {
    let entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Pet status
            HStack {
                Image(petImageName(for: entry.pet.stageIndex))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(.primary.opacity(0.2), lineWidth: 1)
                    )
                    .accessibilityLabel("Pet at stage \(entry.pet.stageIndex)")

                VStack(alignment: .leading, spacing: 2) {
                    Text("Stage \(entry.pet.stageIndex)")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text("XP: \(entry.pet.stageXP)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Pet status: Stage \(entry.pet.stageIndex), \(entry.pet.stageXP) experience points")
                Spacer()
            }

            // Progress
            VStack(alignment: .leading, spacing: 4) {
                Text("\(entry.tasksCompleted)/\(entry.tasksTotal) tasks")
                    .font(.caption)
                    .fontWeight(.medium)

                if entry.tasksTotal > 0 {
                    ProgressView(value: Double(entry.tasksCompleted), total: Double(entry.tasksTotal))
                        .progressViewStyle(LinearProgressViewStyle())
                        .accessibilityLabel("\(entry.tasksCompleted) of \(entry.tasksTotal) tasks completed")
                        .accessibilityValue(Text("\(Int((Double(entry.tasksCompleted) / Double(entry.tasksTotal)) * 100)) percent complete"))
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Task progress: \(entry.tasksCompleted) of \(entry.tasksTotal) tasks completed")

            // Next task with interactive buttons
            if let nextTask = entry.nextTask {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Next:")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(nextTask.title)
                                .font(.caption)
                                .lineLimit(1)
                            Text(timeString(from: nextTask.time))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        // Interactive buttons for iOS 16+
                        if #available(iOS 16.0, *) {
                            HStack(spacing: 8) {
                                Button(intent: CompleteTaskIntent(taskId: nextTask.id.uuidString, dayKey: SharedKit.dayKey(for: entry.date))) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                        .font(.caption)
                                }
                                .buttonStyle(.plain)

                                Button(intent: SnoozeTaskIntent(taskId: nextTask.id.uuidString, dayKey: SharedKit.dayKey(for: entry.date))) {
                                    Image(systemName: "clock.fill")
                                        .foregroundStyle(.orange)
                                        .font(.caption)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.top, 4)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Next task: \(nextTask.title) at \(timeString(from: nextTask.time)). Tap checkmark to complete or clock to snooze.")
            } else {
                HStack {
                    Text("All tasks completed!")
                        .font(.caption)
                        .foregroundColor(.green)

                    Spacer()

                    Image(systemName: "party.popper.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                }
                .padding(.top, 4)
                .accessibilityLabel("All tasks completed for today")
            }

            Spacer()
        }
        .padding()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Pet Progress Widget")
        .accessibilityHint("Shows your pet's progress and today's task completion status")
    }

    private func petImageName(for stageIndex: Int) -> String {
        let stageAssets = [
            "pet_baby", "pet_toddler", "pet_frog", "pet_hermit", "pet_seahorse",
            "pet_dolphin", "pet_alligator", "pet_beaver", "pet_wolf", "pet_bear",
            "pet_bison", "pet_elephant", "pet_rhino", "pet_adult", "pet_ceo", "pet_gold"
        ]
        return stageAssets[safe: stageIndex] ?? "pet_frog"
    }

    private func timeString(from dateComponents: DateComponents) -> String {
        let hour = dateComponents.hour ?? 0
        let minute = dateComponents.minute ?? 0
        return String(format: "%02d:%02d", hour, minute)
    }
}

struct PetProgressWidget: Widget {
    let kind: String = "PetProgressWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                PetProgressWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                PetProgressWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("Pet Progress")
        .description("Track your daily tasks and watch your pet grow!")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}