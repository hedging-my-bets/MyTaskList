import SwiftUI
import WidgetKit
import SharedKit

struct AccessoryInlineView: View {
    let entry: SimpleEntry

    var body: some View {
        HStack(spacing: 4) {
            if let nextTask = nextTask {
                Text("Next:")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)

                Text(nextTask.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text("•")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)

                Text(nextTask.timeLabel)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            } else {
                Text("No upcoming tasks")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }

    private var nextTask: TaskDisplayItem? {
        let now = entry.date
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)

        // Get window offset from SharedStore
        let windowOffset = getCurrentWindowOffset()
        let targetHour = currentHour + windowOffset

        // Filter to nearest-hour tasks only (±2 hour window)
        let nearestSlots = entry.dayModel.slots.filter { slot in
            let hourDiff = abs(slot.hour - targetHour)
            return hourDiff <= 2 || hourDiff >= 22  // Handle 24-hour wrap-around
        }.sorted { $0.hour < $1.hour }

        // Find the next incomplete task from filtered nearest tasks
        for offset in 0..<24 {
            let checkHour = (targetHour + offset) % 24
            if let task = nearestSlots.first(where: { $0.hour == checkHour && !$0.isDone }) {
                return TaskDisplayItem(
                    task: task,
                    timeLabel: String(format: "%02d:00", checkHour),
                    position: .current
                )
            }
        }

        return nil
    }

    private func findTaskForHour(_ hour: Int) -> DayModel.Slot? {
        let normalizedHour = (hour + 24) % 24
        return entry.dayModel.slots.first { $0.hour == normalizedHour }
    }

    private func getCurrentWindowOffset() -> Int {
        let sharedDefaults = UserDefaults(suiteName: "group.com.hedgingmybets.PetProgress")
        return sharedDefaults?.integer(forKey: "widget_window_offset") ?? 0
    }
}

#Preview {
    AccessoryInlineView(entry: SimpleEntry(
        date: Date(),
        dayModel: DayModel(
            key: "2024-09-14",
            slots: [
                DayModel.Slot(id: "1", title: "Deep Work Session", hour: 9, isDone: false),
                DayModel.Slot(id: "2", title: "Team Meeting", hour: 10, isDone: false),
                DayModel.Slot(id: "3", title: "Review Time", hour: 14, isDone: false)
            ],
            points: 15
        )
    ))
    .previewContext(WidgetPreviewContext(family: .accessoryInline))
}