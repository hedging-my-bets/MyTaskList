import SwiftUI

struct PlannerView: View {
    @EnvironmentObject var store: DataStore
    @State private var showNewSeries = false
    @State private var selectedDate = Date()
    @State private var showOverrideEditor = false
    @State private var showOneOffEditor = false
    @State private var editingSeriesId: UUID?
    @State private var editingTaskId: UUID?
    @State private var editingDayKey: String?
    @State private var editingTitle: String = ""
    @State private var editingHour: Int = 9
    @State private var editingMinute: Int = 0

    var body: some View {
        NavigationStack {
            List {
                Section("Recurring Tasks") {
                    if store.state.series.filter({ $0.isActive }).isEmpty {
                        EmptyStateView(
                            title: "No Recurring Tasks",
                            subtitle: "Create tasks that repeat on specific days",
                            systemImage: "repeat.circle",
                            actionTitle: "Add Recurring Task"
                        ) {
                            showNewSeries = true
                        }
                    } else {
                        ForEach(store.state.series.filter { $0.isActive }, id: \.id) { s in
                            NavigationLink(destination: EditSeriesView(series: s)) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(s.title)
                                            .font(.body)
                                        Text(daysString(s.daysOfWeek))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Text(timeString(s.time))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        Button("New Recurring Task") { showNewSeries = true }
                    }
                }

                Section("Specific Day") {
                    DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                    let dk = dayKey(for: selectedDate)
                    let mats = materializeTasks(for: dk, in: store.state)

                    if mats.isEmpty {
                        Text("No tasks scheduled")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    } else {
                        ForEach(mats, id: \.id) { mt in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(mt.title)
                                        .font(.body)
                                        .strikethrough(mt.isCompleted)
                                    Text(timeString(mt.time))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()

                                if case let .series(seriesId) = mt.origin {
                                    // Check if this series instance has overrides
                                    let hasOverride = store.state.overrides.contains(where: {
                                        $0.seriesId == seriesId && $0.dayKey == dk
                                    })

                                    Menu {
                                        if hasOverride {
                                            Button("Edit Override") {
                                                showOverrideEditor(seriesId: seriesId, dayKey: dk, currentTitle: mt.title, currentTime: mt.time)
                                            }
                                            Button("Remove Override") {
                                                removeOverride(seriesId: seriesId, dayKey: dk)
                                            }
                                        } else {
                                            Button("Override Title/Time") {
                                                showOverrideEditor(seriesId: seriesId, dayKey: dk, currentTitle: mt.title, currentTime: mt.time)
                                            }
                                        }
                                        Button("Delete this occurrence") {
                                            addOrUpdateOverride(seriesId: seriesId, dayKey: dk, isDeleted: true)
                                        }
                                    } label: {
                                        Image(systemName: hasOverride ? "pencil.circle.fill" : "ellipsis.circle")
                                            .foregroundColor(hasOverride ? .blue : .secondary)
                                    }
                                } else if case let .oneOff(taskId) = mt.origin {
                                    Button {
                                        showOneOffEditor(taskId: taskId, currentTitle: mt.title, currentTime: mt.time)
                                    } label: {
                                        Image(systemName: "pencil.circle")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                    }
                    Button("Add One-off Task") { addOneOff(to: dk) }
                }
            }
            .navigationTitle("Planner")
        }
        .sheet(isPresented: $showNewSeries) {
            NewSeriesView()
                .environmentObject(store)
        }
        .sheet(isPresented: $showOverrideEditor) {
            OverrideEditorView(
                seriesId: editingSeriesId,
                dayKey: editingDayKey,
                initialTitle: editingTitle,
                initialHour: editingHour,
                initialMinute: editingMinute,
                onSave: saveOverride,
                onCancel: { showOverrideEditor = false }
            )
            .environmentObject(store)
        }
        .sheet(isPresented: $showOneOffEditor) {
            OneOffEditorView(
                taskId: editingTaskId,
                initialTitle: editingTitle,
                initialHour: editingHour,
                initialMinute: editingMinute,
                onSave: saveOneOff,
                onCancel: { showOneOffEditor = false }
            )
            .environmentObject(store)
        }
    }

    private func timeString(_ comps: DateComponents) -> String { String(format: "%02d:%02d", comps.hour ?? 0, comps.minute ?? 0) }
    
    private func daysString(_ days: Set<Int>) -> String {
        let dayNames = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return days.sorted().map { dayNames[$0] }.joined(separator: ", ")
    }

    private func addOrUpdateOverride(seriesId: UUID, dayKey: String, isDeleted: Bool) {
        var st = store.state
        if let idx = st.overrides.firstIndex(where: { $0.seriesId == seriesId && $0.dayKey == dayKey }) {
            st.overrides[idx].isDeleted = isDeleted
        } else {
            st.overrides.append(TaskInstanceOverride(seriesId: seriesId, dayKey: dayKey, isDeleted: isDeleted))
        }
        store.state = st
        let _ = store
        // persist
        try? SharedStore().saveState(st)
    }

    private func addOneOff(to dayKey: String) {
        var st = store.state
        let comps = Calendar.current.dateComponents([.hour, .minute], from: Date())
        let newTaskId = UUID()
        st.tasks.append(TaskItem(id: newTaskId, title: "New Task", scheduledAt: comps, dayKey: dayKey, isCompleted: false, completedAt: nil, snoozedUntil: nil))
        store.state = st
        try? SharedStore().saveState(st)

        // Open editor for the newly created task
        showOneOffEditor(taskId: newTaskId, currentTitle: "New Task", currentTime: comps)
    }

    private func showOverrideEditor(seriesId: UUID?, dayKey: String?, currentTitle: String, currentTime: DateComponents) {
        editingSeriesId = seriesId
        editingDayKey = dayKey
        editingTitle = currentTitle
        editingHour = currentTime.hour ?? 9
        editingMinute = currentTime.minute ?? 0
        showOverrideEditor = true
    }

    private func showOneOffEditor(taskId: UUID?, currentTitle: String, currentTime: DateComponents) {
        editingTaskId = taskId
        editingTitle = currentTitle
        editingHour = currentTime.hour ?? 9
        editingMinute = currentTime.minute ?? 0
        showOneOffEditor = true
    }

    private func saveOverride() {
        guard let seriesId = editingSeriesId, let dayKey = editingDayKey else { return }

        var st = store.state
        let time = DateComponents(hour: editingHour, minute: editingMinute)

        if let idx = st.overrides.firstIndex(where: { $0.seriesId == seriesId && $0.dayKey == dayKey }) {
            st.overrides[idx].title = editingTitle
            st.overrides[idx].time = time
        } else {
            st.overrides.append(TaskInstanceOverride(seriesId: seriesId, dayKey: dayKey, title: editingTitle, time: time, isDeleted: false))
        }

        store.state = st
        try? SharedStore().saveState(st)
        showOverrideEditor = false
    }

    private func saveOneOff() {
        guard let taskId = editingTaskId else { return }

        var st = store.state
        if let idx = st.tasks.firstIndex(where: { $0.id == taskId }) {
            st.tasks[idx].title = editingTitle
            st.tasks[idx].scheduledAt = DateComponents(hour: editingHour, minute: editingMinute)
        }

        store.state = st
        try? SharedStore().saveState(st)
        showOneOffEditor = false
    }

    private func removeOverride(seriesId: UUID?, dayKey: String?) {
        guard let seriesId = seriesId, let dayKey = dayKey else { return }

        var st = store.state
        st.overrides.removeAll(where: { $0.seriesId == seriesId && $0.dayKey == dayKey })
        store.state = st
        try? SharedStore().saveState(st)
    }
}

struct NewSeriesView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var hour: Int = 9
    @State private var minute: Int = 0
    @State private var dow: Set<Int> = []

    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $title)
                HStack {
                    Stepper("Hour: \(hour)", value: $hour, in: 0...23)
                    Stepper("Min: \(minute)", value: $minute, in: 0...59)
                }
                VStack(alignment: .leading) {
                    Text("Days")
                    HStack {
                        ForEach(1...7, id: \.self) { d in
                            let sel = dow.contains(d)
                            Button(sel ? "●" : "○") { if sel { dow.remove(d) } else { dow.insert(d) } }
                        }
                    }
                }
            }
            .navigationTitle("New Series")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        var st = store.state
                        let comps = DateComponents(hour: hour, minute: minute)
                        st.series.append(TaskSeries(title: title, daysOfWeek: dow, time: comps))
                        store.state = st
                        try? SharedStore().saveState(st)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
    }
}

struct EditSeriesView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) private var dismiss
    var series: TaskSeries
    @State private var title: String = ""
    @State private var hour: Int = 9
    @State private var minute: Int = 0
    @State private var dow: Set<Int> = []

    var body: some View {
        Form {
            TextField("Title", text: $title)
            HStack {
                Stepper("Hour: \(hour)", value: $hour, in: 0...23)
                Stepper("Min: \(minute)", value: $minute, in: 0...59)
            }
            VStack(alignment: .leading) {
                Text("Days")
                HStack {
                    ForEach(1...7, id: \.self) { d in
                        let sel = dow.contains(d)
                        Button(sel ? "●" : "○") { if sel { dow.remove(d) } else { dow.insert(d) } }
                    }
                }
            }
            Button("Delete Series") { deleteSeries() }.foregroundColor(.red)
        }
        .onAppear {
            title = series.title
            hour = series.time.hour ?? 9
            minute = series.time.minute ?? 0
            dow = series.daysOfWeek
        }
        .navigationTitle("Edit Series")
        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Save") { save() } } }
    }

    private func save() {
        var st = store.state
        if let idx = st.series.firstIndex(where: { $0.id == series.id }) {
            st.series[idx].title = title
            st.series[idx].time = DateComponents(hour: hour, minute: minute)
            st.series[idx].daysOfWeek = dow
            store.state = st
            try? SharedStore().saveState(st)
        }
        dismiss()
    }

    private func deleteSeries() {
        var st = store.state
        if let idx = st.series.firstIndex(where: { $0.id == series.id }) {
            st.series[idx].isActive = false
            store.state = st
            try? SharedStore().saveState(st)
        }
        dismiss()
    }
}

struct OverrideEditorView: View {
    @EnvironmentObject var store: DataStore
    let seriesId: UUID?
    let dayKey: String?
    @State private var title: String
    @State private var hour: Int
    @State private var minute: Int
    let onSave: () -> Void
    let onCancel: () -> Void

    init(seriesId: UUID?, dayKey: String?, initialTitle: String, initialHour: Int, initialMinute: Int, onSave: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.seriesId = seriesId
        self.dayKey = dayKey
        self._title = State(initialValue: initialTitle)
        self._hour = State(initialValue: initialHour)
        self._minute = State(initialValue: initialMinute)
        self.onSave = onSave
        self.onCancel = onCancel
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Task Details") {
                    TextField("Title", text: $title)
                    HStack {
                        Text("Time")
                        Spacer()
                        HStack {
                            Picker("", selection: $hour) {
                                ForEach(0...23, id: \.self) { h in
                                    Text(String(format: "%02d", h)).tag(h)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 50, height: 100)
                            .clipped()

                            Text(":")

                            Picker("", selection: $minute) {
                                ForEach(0...59, id: \.self) { m in
                                    Text(String(format: "%02d", m)).tag(m)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 50, height: 100)
                            .clipped()
                        }
                    }
                }

                Section {
                    Button("Save Override") {
                        // Update the editing values in parent view before saving
                        editingTitle = title
                        editingHour = hour
                        editingMinute = minute
                        onSave()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle("Override Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
            }
        }
    }
}

struct OneOffEditorView: View {
    @EnvironmentObject var store: DataStore
    let taskId: UUID?
    @State private var title: String
    @State private var hour: Int
    @State private var minute: Int
    let onSave: () -> Void
    let onCancel: () -> Void

    init(taskId: UUID?, initialTitle: String, initialHour: Int, initialMinute: Int, onSave: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.taskId = taskId
        self._title = State(initialValue: initialTitle)
        self._hour = State(initialValue: initialHour)
        self._minute = State(initialValue: initialMinute)
        self.onSave = onSave
        self.onCancel = onCancel
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Task Details") {
                    TextField("Title", text: $title)
                    HStack {
                        Text("Time")
                        Spacer()
                        HStack {
                            Picker("", selection: $hour) {
                                ForEach(0...23, id: \.self) { h in
                                    Text(String(format: "%02d", h)).tag(h)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 50, height: 100)
                            .clipped()

                            Text(":")

                            Picker("", selection: $minute) {
                                ForEach(0...59, id: \.self) { m in
                                    Text(String(format: "%02d", m)).tag(m)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 50, height: 100)
                            .clipped()
                        }
                    }
                }

                Section {
                    Button("Delete Task", role: .destructive) {
                        deleteOneOff()
                    }
                }

                Section {
                    Button("Save Changes") {
                        editingTitle = title
                        editingHour = hour
                        editingMinute = minute
                        onSave()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle("Edit One-off Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
            }
        }
    }

    private func deleteOneOff() {
        guard let taskId = taskId else { return }

        var st = store.state
        st.tasks.removeAll(where: { $0.id == taskId })
        store.state = st
        try? SharedStore().saveState(st)
        onCancel()
    }
}

