import SwiftUI
import SharedKit

struct EditTaskView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) private var dismiss

    let task: TaskItem

    @State private var title: String
    @State private var selectedHour: Int
    @State private var selectedMinute: Int
    @State private var showDeleteConfirmation: Bool = false

    init(task: TaskItem) {
        self.task = task
        self._title = State(initialValue: task.title)
        self._selectedHour = State(initialValue: task.scheduledAt.hour ?? 9)
        self._selectedMinute = State(initialValue: task.scheduledAt.minute ?? 0)
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Task Details") {
                    TextField("Task title", text: $title)
                        .textInputAutocapitalization(.sentences)
                }
                .listRowBackground(Color(.secondarySystemGroupedBackground))

                Section("Scheduled Time") {
                    HStack {
                        Text("Time:")
                            .foregroundStyle(.primary)
                        Spacer()

                        Picker("Hour", selection: $selectedHour) {
                            ForEach(0..<24, id: \.self) { hour in
                                Text(String(format: "%02d", hour)).tag(hour)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 60)

                        Text(":")
                            .font(.title2)
                            .foregroundStyle(.primary)

                        Picker("Minute", selection: $selectedMinute) {
                            ForEach([0, 15, 30, 45], id: \.self) { minute in
                                Text(String(format: "%02d", minute)).tag(minute)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 60)
                    }
                }
                .listRowBackground(Color(.secondarySystemGroupedBackground))

                Section {
                    Button("Save Changes") {
                        updateTask()
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .foregroundStyle(.blue)
                }
                .listRowBackground(Color(.secondarySystemGroupedBackground))

                Section {
                    Button("Delete Task") {
                        showDeleteConfirmation = true
                    }
                    .foregroundStyle(.red)
                }
                .listRowBackground(Color(.secondarySystemGroupedBackground))
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Delete Task", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    dataStore.deleteTask(task.id)
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to delete '\(task.title)'? This action cannot be undone.")
            }
        }
    }

    private func updateTask() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        let updatedTask = TaskItem(
            id: task.id,
            title: trimmedTitle,
            scheduledAt: DateComponents(hour: selectedHour, minute: selectedMinute),
            dayKey: task.dayKey,
            isCompleted: task.isCompleted,
            completedAt: task.completedAt,
            snoozedUntil: task.snoozedUntil
        )

        dataStore.updateTask(updatedTask)
    }
}

#Preview {
    let sampleTask = TaskItem(
        title: "Sample Task",
        scheduledAt: DateComponents(hour: 10, minute: 30),
        dayKey: "2025-01-01"
    )

    return EditTaskView(task: sampleTask)
}