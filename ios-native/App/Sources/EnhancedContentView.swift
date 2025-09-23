import SwiftUI
import SharedKit

/// Award-winning main interface with cinematic animations and fluid interactions
@available(iOS 17.0, *)
struct EnhancedContentView: View {
    @StateObject private var viewModel = AppViewModel()
    @StateObject private var assetPipeline = AssetPipeline.shared

    @State private var showingSettings = false
    @State private var animationPhase: AnimationPhase = .idle
    @State private var heroAnimationTrigger = false
    @State private var sparkleAnimationTrigger = false

    @Namespace private var heroNamespace

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    LazyVStack(spacing: 24) {
                        // Hero Pet Display with Cinematic Animations
                        heroSection(geometry: geometry)
                            .id("hero")


                        // Interactive Task Management
                        taskManagementSection
                            .animation(.interactiveSpring(response: 0.6, dampingFraction: 0.7), value: viewModel.next3Tasks.count)

                        // Performance Analytics
                        performanceSection
                            .animation(.easeInOut(duration: 0.5), value: viewModel.completedTasks)


                        // Bottom spacing for tab bar
                        Color.clear.frame(height: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
                .refreshable {
                    await refreshData()
                }
            }
            .background(backgroundGradient)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    settingsButton
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .onAppear {
                startupSequence()
            }
        }
    }

    // MARK: - Hero Section

    @ViewBuilder
    private func heroSection(geometry: GeometryProxy) -> some View {
        VStack(spacing: 16) {
            ZStack {
                // Background glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.blue.opacity(0.3),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 20,
                            endRadius: 150
                        )
                    )
                    .frame(width: 300, height: 300)
                    .scaleEffect(heroAnimationTrigger ? 1.2 : 1.0)
                    .opacity(heroAnimationTrigger ? 0.8 : 0.4)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: heroAnimationTrigger)

                // Pet Display with Hero Animation
                EnhancedPetDisplayView(
                    stage: viewModel.petStage,
                    points: viewModel.petPoints,
                    emotionalState: viewModel.petEvolutionEngine.currentEmotionalState,
                    animationTrigger: $heroAnimationTrigger
                )
                .matchedGeometryEffect(id: "petHero", in: heroNamespace)
                .scaleEffect(animationPhase == .celebrating ? 1.3 : 1.0)
                .rotationEffect(.degrees(animationPhase == .celebrating ? 5 : 0))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animationPhase)

                // Sparkle effects for task completions
                if sparkleAnimationTrigger {
                    SparkleEffectView()
                        .allowsHitTesting(false)
                }
            }
            .frame(height: min(geometry.size.width * 0.8, 280))

            // Pet status with smooth transitions
            PetStatusIndicator(
                stage: viewModel.petStage,
                emotionalState: viewModel.petEvolutionEngine.currentEmotionalState,
                nextEvolutionProgress: viewModel.nextEvolutionProgress
            )
        }
        .onTapGesture {
            triggerPetInteraction()
        }
    }


    // MARK: - Task Management Section

    @ViewBuilder
    private var taskManagementSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header with progress
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Focus")
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text("\(viewModel.completedTasks) of \(viewModel.totalTasks) completed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Circular progress indicator
                CircularProgressView(
                    progress: viewModel.totalTasks > 0 ? Double(viewModel.completedTasks) / Double(viewModel.totalTasks) : 0,
                    lineWidth: 4
                )
                .frame(width: 40, height: 40)
            }

            // Enhanced task feed
            EnhancedTaskFeedView(tasks: viewModel.next3Tasks) { task in
                handleTaskCompletion(task)
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Performance Section

    @ViewBuilder
    private var performanceSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Performance Analytics")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                Button("View All") {
                    // Navigate to detailed analytics
                }
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.blue)
            }

            HStack(spacing: 20) {
                PerformanceMetricCard(
                    title: "Streak",
                    value: "0",
                    subtitle: "days",
                    color: .orange,
                    icon: "flame.fill"
                )

                PerformanceMetricCard(
                    title: "Efficiency",
                    value: "\(Int(viewModel.efficiency * 100))%",
                    subtitle: "avg",
                    color: .green,
                    icon: "chart.line.uptrend.xyaxis"
                )

                PerformanceMetricCard(
                    title: "Stage",
                    value: "\(viewModel.petStage)",
                    subtitle: "level",
                    color: .blue,
                    icon: "star.fill"
                )
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }


    // MARK: - UI Components

    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(.systemBackground),
                Color(.systemGroupedBackground).opacity(0.8)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }


    private var settingsButton: some View {
        Button(action: { showingSettings = true }) {
            Image(systemName: "gear")
                .font(.title3)
        }
        .accessibilityLabel("Settings")
    }

    // MARK: - Actions & Animations

    private func startupSequence() {
        Task {
            await viewModel.loadTodaysData()


            // Delayed hero animation trigger
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            withAnimation(.easeOut(duration: 0.8)) {
                heroAnimationTrigger = true
            }
        }
    }

    private func refreshData() async {
        await viewModel.refreshData()

        // Refresh animations
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            heroAnimationTrigger.toggle()
        }
    }

    private func handleTaskCompletion(_ task: MaterializedTask) {
        // Trigger celebration animation
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            animationPhase = .celebrating
            sparkleAnimationTrigger = true
        }

        // Complete the task
        viewModel.completeTask(task)

        // Reset animation after celebration
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.5)) {
                animationPhase = .idle
                sparkleAnimationTrigger = false
            }
        }

    }

    private func triggerPetInteraction() {
        withAnimation(.interpolatingSpring(stiffness: 300, damping: 15)) {
            heroAnimationTrigger.toggle()
        }

        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }

}

// MARK: - Animation Phase

enum AnimationPhase {
    case idle
    case celebrating
    case transitioning
}

// MARK: - Enhanced Pet Display View

@available(iOS 17.0, *)
struct EnhancedPetDisplayView: View {
    let stage: Int
    let points: Int
    let emotionalState: PetEvolutionEngine.EmotionalState
    @Binding var animationTrigger: Bool

    @State private var petImageName: String = ""
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                // Pet image with loading state
                Group {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(1.5)
                    } else {
                        AsyncImage(url: AssetPipeline.shared.cdnURL(for: stage)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            AssetPipeline.shared.placeholderImage(for: stage)
                                .font(.system(size: 60))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(width: 120, height: 120)
                .background(emotionalState.color.opacity(0.1), in: Circle())
                .overlay(
                    Circle()
                        .stroke(emotionalState.color.opacity(0.3), lineWidth: 2)
                        .scaleEffect(animationTrigger ? 1.1 : 1.0)
                        .opacity(animationTrigger ? 0.0 : 1.0)
                        .animation(.easeOut(duration: 1.0), value: animationTrigger)
                )

                // Emotional state indicator
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text(emotionalState.emoji)
                            .font(.title2)
                            .background(Circle().fill(.ultraThinMaterial).frame(width: 32, height: 32))
                    }
                }
                .frame(width: 120, height: 120)
            }

            // Pet info with points
            VStack(spacing: 4) {
                Text("Stage \(stage)")
                    .font(.headline)
                    .fontWeight(.semibold)

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .font(.caption)

                    Text("\(points) points")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .task {
            await loadPetAsset()
        }
    }

    private func loadPetAsset() async {
        isLoading = true
        defer { isLoading = false }

        // Preload the pet image
        _ = await AssetPipeline.shared.loadImage(for: stage, quality: .high)
    }
}

// MARK: - Pet Status Indicator

@available(iOS 17.0, *)
struct PetStatusIndicator: View {
    let stage: Int
    let emotionalState: PetEvolutionEngine.EmotionalState
    let nextEvolutionProgress: Double

    var body: some View {
        HStack(spacing: 12) {
            // Emotional state
            HStack(spacing: 4) {
                Text(emotionalState.emoji)
                    .font(.caption)

                Text(emotionalState.rawValue.capitalized)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(emotionalState.color)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(emotionalState.color.opacity(0.1), in: Capsule())

            Spacer()

            // Evolution progress
            if nextEvolutionProgress > 0 {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Next Evolution")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 4) {
                        ProgressView(value: nextEvolutionProgress)
                            .frame(width: 60)
                            .tint(.blue)

                        Text("\(Int(nextEvolutionProgress * 100))%")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - Enhanced Task Feed View

@available(iOS 17.0, *)
struct EnhancedTaskFeedView: View {
    let tasks: [MaterializedTask]
    let onTaskComplete: (MaterializedTask) -> Void

    var body: some View {
        VStack(spacing: 12) {
            if tasks.isEmpty {
                EmptyStateView()
            } else {
                ForEach(tasks.prefix(3), id: \.id) { task in
                    EnhancedTaskRowView(task: task) {
                        onTaskComplete(task)
                    }
                }
            }
        }
    }
}

// MARK: - Enhanced Task Row View

@available(iOS 17.0, *)
struct EnhancedTaskRowView: View {
    let task: MaterializedTask
    let onComplete: () -> Void

    @State private var isCompleting = false
    @State private var showingDetails = false

    var body: some View {
        HStack(spacing: 16) {
            // Completion button
            Button(action: handleCompletion) {
                ZStack {
                    Circle()
                        .stroke(task.difficulty.color, lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isCompleting {
                        Circle()
                            .fill(task.difficulty.color)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.white)
                            )
                    }
                }
            }
            .disabled(isCompleting)

            // Task content
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)

                HStack {
                    // Time slot
                    Label(task.scheduledTime.displayTime, systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    // Difficulty indicator
                    Text(task.difficulty.rawValue.capitalized)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(task.difficulty.color.opacity(0.2))
                        .foregroundStyle(task.difficulty.color)
                        .clipShape(Capsule())
                }
            }

            // More options
            Button(action: { showingDetails = true }) {
                Image(systemName: "ellipsis")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .scaleEffect(isCompleting ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isCompleting)
        .sheet(isPresented: $showingDetails) {
            TaskDetailView(task: task)
        }
    }

    private func handleCompletion() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isCompleting = true
        }

        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

        // Delay completion for animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onComplete()
        }
    }
}

// MARK: - Supporting Views

@available(iOS 17.0, *)
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)

            Text("All tasks completed!")
                .font(.headline)
                .fontWeight(.semibold)

            Text("Great job! You've finished all your tasks for now.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 32)
    }
}

@available(iOS 17.0, *)
struct CircularProgressView: View {
    let progress: Double
    let lineWidth: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(.quaternary, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(.blue, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)

            Text("\(Int(progress * 100))%")
                .font(.caption2)
                .fontWeight(.medium)
        }
    }
}

@available(iOS 17.0, *)
struct PerformanceMetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            VStack(spacing: 2) {
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)

                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Text(title)
                .font(.caption)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Extensions

extension PetEvolutionEngine.EmotionalState {
    var color: Color {
        switch self {
        case .ecstatic, .happy: return .green
        case .content: return .blue
        case .neutral: return .gray
        case .worried: return .orange
        case .sad, .frustrated: return .red
        }
    }

    var emoji: String {
        switch self {
        case .ecstatic: return "🤩"
        case .happy: return "😊"
        case .content: return "😌"
        case .neutral: return "😐"
        case .worried: return "😟"
        case .sad: return "😢"
        case .frustrated: return "😤"
        }
    }
}

// TaskDifficulty extension removed - type not defined
