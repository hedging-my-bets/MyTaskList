import WidgetKit
import SwiftUI
import SharedKit

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

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Pet status
            HStack {
                Image("pet_frog") // Fallback image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Stage \(entry.pet.stageIndex)")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text("XP: \(entry.pet.stageXP)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
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
                }
            }

            // Next task
            if let nextTask = entry.nextTask {
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
                .padding(.top, 4)
            }

            Spacer()
        }
        .padding()
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
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}