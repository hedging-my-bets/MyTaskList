import SwiftUI
import SharedKit

struct TaskFeedView: View {
    let tasks: [TaskFeedItem]
    let onComplete: (TaskFeedItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Next Tasks")
                .font(.headline)
                .padding(.horizontal)

            if tasks.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.green)

                    Text("All tasks completed!")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text("Great job! Your pet is happy.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            } else {
                LazyVStack(spacing: 6) {
                    ForEach(Array(tasks.enumerated()), id: \.offset) { index, task in
                        TaskRowView(
                            task: task,
                            isNext: index == 0,
                            onComplete: { onComplete(task) }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct TaskRowView: View {
    let task: TaskFeedItem
    let isNext: Bool
    let onComplete: () -> Void

    var statusColor: Color {
        switch task.status {
        case .completed: return .green
        case .current: return .blue
        case .overdue: return .red
        case .upcoming: return .gray
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            // Time
            Text(task.timeString)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .frame(minWidth: 40, alignment: .leading)

            // Title
            Text(task.title)
                .font(.subheadline)
                .strikethrough(task.isDone)
                .foregroundStyle(task.isDone ? .secondary : .primary)

            Spacer()

            // Action button
            if !task.isDone && isNext {
                Button(action: onComplete) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.green)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            isNext ? .thinMaterial : .clear,
            in: RoundedRectangle(cornerRadius: 8)
        )
        .animation(.easeInOut(duration: 0.3), value: task.isDone)
    }
}