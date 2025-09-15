import SwiftUI
import WidgetKit
import SharedKit

struct AccessoryRectangularView: View {
    let entry: SimpleEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Header with navigation arrows
            HStack {
                Button(intent: PrevWindowIntent()) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(PlainButtonStyle())

                Spacer()

                Text("Tasks")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)

                Spacer()

                Button(intent: NextWindowIntent()) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }

            // Task rows (up to 3)
            ForEach(nearestHourTasks.indices, id: \.self) { index in
                if index < 3 {
                    TaskRowView(
                        task: nearestHourTasks[index],
                        isCurrentHour: index == 1,
                        dayKey: entry.dayModel.key
                    )
                }
            }

            // Fill empty rows if needed
            ForEach(nearestHourTasks.count..<3, id: \.self) { _ in
                EmptyTaskRowView()
            }
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }

    private var nearestHourTasks: [TaskDisplayItem] {
        let now = entry.date
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)

        // Get window offset from SharedStore
        let windowOffset = getCurrentWindowOffset()
        let targetHour = currentHour + windowOffset

        var tasks: [TaskDisplayItem] = []

        // Previous hour task
        if let prevTask = findTaskForHour(targetHour - 1) {
            tasks.append(TaskDisplayItem(
                task: prevTask,
                timeLabel: String(format: "%02d:00", (targetHour - 1 + 24) % 24),
                position: .previous
            ))
        } else {
            tasks.append(TaskDisplayItem.empty(
                timeLabel: String(format: "%02d:00", (targetHour - 1 + 24) % 24),
                position: .previous
            ))
        }

        // Current hour task
        if let currentTask = findTaskForHour(targetHour) {
            tasks.append(TaskDisplayItem(
                task: currentTask,
                timeLabel: String(format: "%02d:00", targetHour % 24),
                position: .current
            ))
        } else {
            tasks.append(TaskDisplayItem.empty(
                timeLabel: String(format: "%02d:00", targetHour % 24),
                position: .current
            ))
        }

        // Next hour task
        if let nextTask = findTaskForHour(targetHour + 1) {
            tasks.append(TaskDisplayItem(
                task: nextTask,
                timeLabel: String(format: "%02d:00", (targetHour + 1) % 24),
                position: .next
            ))
        } else {
            tasks.append(TaskDisplayItem.empty(
                timeLabel: String(format: "%02d:00", (targetHour + 1) % 24),
                position: .next
            ))
        }

        return tasks
    }

    private func findTaskForHour(_ hour: Int) -> DayModel.Slot? {
        let normalizedHour = (hour + 24) % 24
        return entry.dayModel.slots.first { $0.hour == normalizedHour }
    }

    private func getCurrentWindowOffset() -> Int {
        let sharedDefaults = UserDefaults(suiteName: "group.hedging-my-bets.mytasklist")
        return sharedDefaults?.integer(forKey: "widget_window_offset") ?? 0
    }
}

struct TaskDisplayItem {
    let task: DayModel.Slot?
    let timeLabel: String
    let position: Position

    enum Position {
        case previous, current, next
    }

    static func empty(timeLabel: String, position: Position) -> TaskDisplayItem {
        TaskDisplayItem(task: nil, timeLabel: timeLabel, position: position)
    }
}

struct TaskRowView: View {
    let task: TaskDisplayItem
    let isCurrentHour: Bool
    let dayKey: String

    var body: some View {
        HStack(spacing: 4) {
            // Time label
            Text(task.timeLabel)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(isCurrentHour ? .primary : .secondary)
                .frame(width: 32, alignment: .leading)

            // Task title or empty indicator
            if let taskSlot = task.task {
                Text(taskSlot.title)
                    .font(.system(size: 9))
                    .foregroundStyle(isCurrentHour ? .primary : .secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer()

                // Action buttons only for current hour and incomplete tasks
                if isCurrentHour && !taskSlot.isDone {
                    HStack(spacing: 2) {
                        Button(intent: CompleteTaskIntent(taskId: taskSlot.id, dayKey: dayKey)) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(.green)
                        }
                        .buttonStyle(PlainButtonStyle())

                        Button(intent: SkipTaskIntent(taskId: taskSlot.id, dayKey: dayKey)) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                } else if taskSlot.isDone {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.green)
                }
            } else {
                Text("—")
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)

                Spacer()
            }
        }
        .frame(height: 16)
    }
}

struct EmptyTaskRowView: View {
    var body: some View {
        HStack {
            Text("—")
                .font(.system(size: 9))
                .foregroundStyle(.tertiary)
                .frame(width: 32, alignment: .leading)

            Text("—")
                .font(.system(size: 9))
                .foregroundStyle(.tertiary)

            Spacer()
        }
        .frame(height: 16)
    }
}

#Preview {
    AccessoryRectangularView(entry: SimpleEntry(
        date: Date(),
        dayModel: DayModel(
            key: "2024-09-14",
            slots: [
                DayModel.Slot(id: "1", title: "Morning Routine", hour: 8, isDone: true),
                DayModel.Slot(id: "2", title: "Deep Work Session", hour: 9, isDone: false),
                DayModel.Slot(id: "3", title: "Team Meeting", hour: 10, isDone: false)
            ],
            points: 15
        )
    ))
    .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
}