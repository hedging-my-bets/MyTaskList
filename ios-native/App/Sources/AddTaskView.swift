import SwiftUI
import SharedKit

struct AddTaskView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var selectedHour: Int = 9
    @State private var selectedMinute: Int = 0

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
                    Button("Add Task") {
                        addTask()
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .foregroundStyle(.blue)
                }
                .listRowBackground(Color(.secondarySystemGroupedBackground))
            }
            .navigationTitle("Add Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .background(Color(.systemGroupedBackground))
    }

    private func addTask() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        let scheduledAt = DateComponents(hour: selectedHour, minute: selectedMinute)
        let newTask = TaskItem(
            title: trimmedTitle,
            scheduledAt: scheduledAt,
            dayKey: dataStore.state.dayKey
        )

        dataStore.addTask(newTask)
    }
}

#Preview {
    AddTaskView()
}
