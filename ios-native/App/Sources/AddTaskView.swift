import SwiftUI
import SharedKit
import WidgetKit

struct AddTaskView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var selectedHour: Int = 9
    @State private var selectedMinute: Int = 0
    @State private var showingTemplates = false

    private let templates = [
        TaskTemplate(name: "Morning Routine", tasks: [
            ("Morning meditation", 6, 0),
            ("Exercise/workout", 7, 0),
            ("Healthy breakfast", 8, 0),
            ("Plan daily priorities", 9, 0)
        ]),
        TaskTemplate(name: "Deep Work Session", tasks: [
            ("Clear workspace", 9, 0),
            ("Focus block 1", 10, 0),
            ("Short break", 12, 0),
            ("Focus block 2", 13, 0)
        ]),
        TaskTemplate(name: "Wind-down Evening", tasks: [
            ("Review day's progress", 18, 0),
            ("Prepare for tomorrow", 19, 0),
            ("Relax/unwind", 20, 0),
            ("Read before bed", 21, 0)
        ])
    ]

    private struct TaskTemplate {
        let name: String
        let tasks: [(title: String, hour: Int, minute: Int)]
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Quick Templates") {
                    Button("Use Template") {
                        showingTemplates = true
                    }
                    .foregroundStyle(.blue)
                }
                .listRowBackground(Color(.secondarySystemGroupedBackground))

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
            .sheet(isPresented: $showingTemplates) {
                TemplateSelectionView(templates: templates) { template in
                    applyTemplate(template)
                    showingTemplates = false
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

        // CRITICAL FIX: Sync to SharedStore for widget visibility
        if let currentState = dataStore.state {
            SharedStore.shared.saveAppState(currentState)
        }

        // Refresh widget timeline immediately
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func applyTemplate(_ template: TaskTemplate) {
        for taskInfo in template.tasks {
            let newTask = TaskItem(
                title: taskInfo.title,
                scheduledAt: DateComponents(hour: taskInfo.hour, minute: taskInfo.minute),
                dayKey: dataStore.state.dayKey
            )
            dataStore.addTask(newTask)
        }

        // Sync to SharedStore for widget visibility
        if let currentState = dataStore.state {
            SharedStore.shared.saveAppState(currentState)
        }

        // Refresh widget timeline immediately
        WidgetCenter.shared.reloadAllTimelines()
    }
}

struct TemplateSelectionView: View {
    let templates: [AddTaskView.TaskTemplate]
    let onSelect: (AddTaskView.TaskTemplate) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List(templates, id: \.name) { template in
                VStack(alignment: .leading, spacing: 8) {
                    Text(template.name)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(template.tasks, id: \.title) { task in
                            HStack {
                                Text(String(format: "%02d:%02d", task.hour, task.minute))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 40)
                                Text(task.title)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                        }
                    }
                    .padding(.leading, 8)
                }
                .padding(.vertical, 4)
                .contentShape(Rectangle())
                .onTapGesture {
                    onSelect(template)
                }
            }
            .navigationTitle("Task Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    AddTaskView()
}
