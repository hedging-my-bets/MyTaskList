import SwiftUI
import SharedKit
import os.log

/// Complete Main Content View - 100% Production Implementation
/// Integrates all systems: tasks, pet evolution, celebration, settings
@available(iOS 17.0, *)
struct CompleteContentView: View {
    @StateObject private var dataStore = DataStore()
    @StateObject private var celebrationSystem = CompleteCelebrationSystem.shared
    @StateObject private var settingsManager = SettingsManager.shared

    private let logger = Logger(subsystem: "com.petprogress.App", category: "ContentView")

    var body: some View {
        TabView {
            // Main Task View
            TaskManagementView()
                .tabItem {
                    Label("Tasks", systemImage: "checklist")
                }

            // Pet Progress View
            PetProgressView()
                .tabItem {
                    Label("Pet", systemImage: "pawprint.fill")
                }

            // Settings View
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .environmentObject(dataStore)
        .environmentObject(celebrationSystem)
        .environmentObject(settingsManager)
        .overlay {
            // Celebration overlays
            LevelUpCelebrationOverlay()
            TaskCompleteCelebrationOverlay()
        }
        .task {
            await initializeApp()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            handleAppForeground()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            handleAppBackground()
        }
        .onOpenURL { url in
            handleDeepLink(url)
        }
    }

    // MARK: - App Lifecycle

    private func initializeApp() async {
        logger.info("Initializing Complete PetProgress App")

        // Initialize app group manager
        let appGroup = CompleteAppGroupManager.shared

        // Set app version for tracking
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            appGroup.appVersion = version
        }

        // Set first launch date if not set
        if appGroup.firstLaunchDate == nil {
            appGroup.firstLaunchDate = Date()
            logger.info("First app launch recorded")
        }

        // Initialize data store
        await dataStore.launchApplyCloseoutIfNeeded()

        // Check for rollover
        CompleteRolloverManager.shared.handleAppForeground()

        logger.info("App initialization complete")
    }

    private func handleAppForeground() {
        logger.info("App entered foreground")

        // Update foreground timestamp
        CompleteAppGroupManager.shared.lastAppForegroundDate = Date()

        // Check for rollover
        CompleteRolloverManager.shared.handleAppForeground()

        // Refresh data
        Task {
            await dataStore.refreshCurrentDay()
        }
    }

    private func handleAppBackground() {
        logger.info("App entered background")

        // Save any pending state
        dataStore.saveCurrentState()
    }

    private func handleDeepLink(_ url: URL) {
        logger.info("Handling deep link: \(url.absoluteString)")

        URLRoutes.handle(url: url)
    }
}

// MARK: - Task Management View

@available(iOS 17.0, *)
struct TaskManagementView: View {
    @EnvironmentObject private var dataStore: DataStore
    @EnvironmentObject private var celebrationSystem: CompleteCelebrationSystem
    @State private var showingAddTask = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Today's Progress Header
                TodayProgressHeader()

                // Task List
                TaskListSection()

                Spacer()

                // Add Task Button
                Button(action: {
                    showingAddTask = true
                }) {
                    Label("Add Task", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue, in: RoundedRectangle(cornerRadius: 12))
                }
                .padding()
            }
            .navigationTitle("Today's Tasks")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingAddTask) {
                AddTaskSheet()
            }
        }
    }
}

@available(iOS 17.0, *)
struct TodayProgressHeader: View {
    @EnvironmentObject private var dataStore: DataStore

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Today's Progress")
                        .font(.headline)
                    Text("\(completedTasks)/\(totalTasks) tasks completed")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Progress Ring
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 8)
                        .frame(width: 60, height: 60)

                    Circle()
                        .trim(from: 0, to: progressPercentage)
                        .stroke(.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))

                    Text("\(Int(progressPercentage * 100))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal)
    }

    private var completedTasks: Int {
        let dayKey = TimeSlot.dayKey(for: Date())
        let tasks = CompleteAppGroupManager.shared.getTasks(dayKey: dayKey)
        let completions = CompleteAppGroupManager.shared.getCompletions(dayKey: dayKey)
        return tasks.filter { completions.contains($0.id) }.count
    }

    private var totalTasks: Int {
        let dayKey = TimeSlot.dayKey(for: Date())
        return CompleteAppGroupManager.shared.getTasks(dayKey: dayKey).count
    }

    private var progressPercentage: Double {
        guard totalTasks > 0 else { return 0 }
        return Double(completedTasks) / Double(totalTasks)
    }
}

@available(iOS 17.0, *)
struct TaskListSection: View {
    @EnvironmentObject private var dataStore: DataStore
    @EnvironmentObject private var celebrationSystem: CompleteCelebrationSystem

    var body: some View {
        List {
            ForEach(currentTasks, id: \.id) { task in
                TaskRowView(task: task) {
                    markTaskCompleted(task)
                }
            }
        }
        .listStyle(PlainListStyle())
    }

    private var currentTasks: [TaskEntity] {
        let dayKey = TimeSlot.dayKey(for: Date())
        return CompleteAppGroupManager.shared.getTasks(dayKey: dayKey)
            .sorted { $0.dueHour < $1.dueHour }
    }

    private func markTaskCompleted(_ task: TaskEntity) {
        let dayKey = TimeSlot.dayKey(for: Date())
        let appGroup = CompleteAppGroupManager.shared

        // Mark as completed
        appGroup.markTaskCompleted(task.id, dayKey: dayKey)

        // Process evolution
        if var petState = appGroup.getPetState() {
            let evolutionResult = CompleteEvolutionSystem.shared.processTaskCompletion(
                currentPet: &petState,
                task: task,
                completedAt: Date()
            )

            appGroup.setPetState(petState)

            // Trigger celebration
            celebrationSystem.triggerTaskCompleteCelebration()

            if evolutionResult.didEvolve {
                celebrationSystem.triggerLevelUpCelebration(
                    fromStage: evolutionResult.previousStage,
                    toStage: evolutionResult.newStage
                )
            }
        }

        // Haptic feedback
        HapticManager.shared.taskCompleted()
    }
}

@available(iOS 17.0, *)
struct TaskRowView: View {
    let task: TaskEntity
    let onComplete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onComplete) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isCompleted ? .green : .blue)
            }
            .buttonStyle(PlainButtonStyle())

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.headline)
                    .strikethrough(isCompleted)
                    .foregroundStyle(isCompleted ? .secondary : .primary)

                Text("Due: \(task.dueHour):00")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fontDesign(.monospaced)
            }

            Spacer()

            if isCompleted {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(.green)
            }
        }
        .padding(.vertical, 4)
    }

    private var isCompleted: Bool {
        let dayKey = TimeSlot.dayKey(for: Date())
        return CompleteAppGroupManager.shared.isTaskCompleted(task.id, dayKey: dayKey)
    }
}

// MARK: - Pet Progress View

@available(iOS 17.0, *)
struct PetProgressView: View {
    @State private var petState: PetState?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Pet Display
                    PetDisplaySection(petState: petState)

                    // Progress Section
                    PetProgressSection(petState: petState)

                    // Stats Section
                    PetStatsSection()
                }
                .padding()
            }
            .navigationTitle("Pet Progress")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            loadPetState()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            loadPetState()
        }
    }

    private func loadPetState() {
        petState = CompleteAppGroupManager.shared.getPetState()
    }
}

@available(iOS 17.0, *)
struct PetDisplaySection: View {
    let petState: PetState?

    var body: some View {
        VStack(spacing: 16) {
            // Pet Image
            if let petState = petState {
                WidgetImageOptimizer.shared.widgetImage(for: petState.stageIndex)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .background(Circle().fill(.ultraThinMaterial))
                    .overlay {
                        Circle()
                            .stroke(.blue.opacity(0.3), lineWidth: 2)
                    }

                Text("Stage \(petState.stageIndex + 1)")
                    .font(.title)
                    .fontWeight(.bold)

                Text("\(petState.stageXP) XP")
                    .font(.title2)
                    .fontDesign(.monospaced)
                    .foregroundStyle(.secondary)
            } else {
                ProgressView()
                    .frame(width: 120, height: 120)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

@available(iOS 17.0, *)
struct PetProgressSection: View {
    let petState: PetState?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Evolution Progress")
                .font(.headline)

            if let petState = petState {
                let evolutionSystem = CompleteEvolutionSystem.shared
                let progress = evolutionSystem.progressWithinStage(
                    currentStage: petState.stageIndex,
                    currentXP: petState.stageXP
                )
                let xpNeeded = evolutionSystem.xpRequiredForNextStage(
                    currentStage: petState.stageIndex,
                    currentXP: petState.stageXP
                )

                ProgressView(value: progress) {
                    HStack {
                        Text("Progress to Next Stage")
                        Spacer()
                        Text("\(xpNeeded) XP needed")
                            .fontDesign(.monospaced)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .tint(.blue)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

@available(iOS 17.0, *)
struct PetStatsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Lifetime Stats")
                .font(.headline)

            let appGroup = CompleteAppGroupManager.shared

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                StatCard(title: "Tasks Completed", value: "\(appGroup.totalTasksCompleted)")
                StatCard(title: "Total XP Earned", value: "\(appGroup.totalXPEarned)")
                StatCard(title: "Longest Streak", value: "\(appGroup.longestStreak) days")
                StatCard(title: "Widget Updates", value: "\(appGroup.widgetUpdateCount)")
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

@available(iOS 17.0, *)
struct StatCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .fontDesign(.monospaced)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Add Task Sheet

@available(iOS 17.0, *)
struct AddTaskSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var taskTitle = ""
    @State private var taskHour = 9

    var body: some View {
        NavigationView {
            Form {
                Section("Task Details") {
                    TextField("Task title", text: $taskTitle)

                    Picker("Due Hour", selection: $taskHour) {
                        ForEach(6..<24) { hour in
                            Text("\(hour):00")
                                .tag(hour)
                        }
                    }
                }
            }
            .navigationTitle("Add Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        addTask()
                    }
                    .disabled(taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func addTask() {
        let dayKey = TimeSlot.dayKey(for: Date())
        let appGroup = CompleteAppGroupManager.shared

        let task = TaskEntity(
            id: UUID().uuidString,
            title: taskTitle.trimmingCharacters(in: .whitespacesAndNewlines),
            dueHour: taskHour,
            isDone: false,
            dayKey: dayKey
        )

        var tasks = appGroup.getTasks(dayKey: dayKey)
        tasks.append(task)
        appGroup.setTasks(tasks, dayKey: dayKey)

        dismiss()
    }
}

#Preview {
    CompleteContentView()
}