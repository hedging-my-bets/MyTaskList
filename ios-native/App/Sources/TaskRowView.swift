import SwiftUI
import SharedKit

struct TaskRowView: View {
    let task: MaterializedTask
    @EnvironmentObject var dataStore: DataStore
    @State private var showEditSheet: Bool = false

    var body: some View {
        HStack {
            Button(action: {
                if !task.isCompleted {
                    dataStore.markDone(taskID: task.id)
                }
            }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(task.isCompleted ? .green : .secondary)
                    .font(.title2)
            }
            .buttonStyle(PlainButtonStyle())

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.body)
                    .strikethrough(task.isCompleted, color: .primary)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)

                Text(timeString(from: task.time))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if !task.isCompleted {
                Menu {
                    Button("Snooze 15 min") {
                        dataStore.snooze(taskID: task.id, minutes: 15)
                    }
                    Button("Snooze 30 min") {
                        dataStore.snooze(taskID: task.id, minutes: 30)
                    }
                    Button("Snooze 1 hour") {
                        dataStore.snooze(taskID: task.id, minutes: 60)
                    }
                } label: {
                    Image(systemName: "clock")
                        .foregroundStyle(.blue)
                }
            }
        }
        .padding(.vertical, 4)
        .listRowBackground(Color(.systemBackground))
        .onLongPressGesture {
            if !task.isCompleted {
                showEditSheet = true
            }
        }
        .sheet(isPresented: $showEditSheet) {
            if let originalTask = dataStore.state.tasks.first(where: { $0.id == task.id }) {
                EditTaskView(task: originalTask)
                    .environmentObject(dataStore)
            }
        }
    }

    private func timeString(from dateComponents: DateComponents) -> String {
        let hour = dateComponents.hour ?? 0
        let minute = dateComponents.minute ?? 0
        return String(format: "%02d:%02d", hour, minute)
    }
}