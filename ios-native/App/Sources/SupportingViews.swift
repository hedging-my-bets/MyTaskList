import SwiftUI
import SharedKit

/// Supporting views for the award-winning app interface
@available(iOS 17.0, *)

// MARK: - AI Insights View

struct AIInsightsView: View {
    let insights: [TaskInsight]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(insights, id: \.id) { insight in
                        InsightCard(insight: insight)
                            .padding(.horizontal)
                    }
                }
                .padding(.top)
            }
            .navigationTitle("AI Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Insight Card

struct InsightCard: View {
    let insight: TaskInsight

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: insight.category.icon)
                    .foregroundStyle(insight.severity.color)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text(insight.title)
                        .font(.headline)
                        .fontWeight(.semibold)

                    HStack {
                        Text("\(Int(insight.confidence * 100))% confidence")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text(insight.severity.rawValue.capitalized)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(insight.severity.color.opacity(0.2))
                            .foregroundStyle(insight.severity.color)
                            .clipShape(Capsule())
                    }
                }

                Spacer()
            }

            Text(insight.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(insight.severity.color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Recommendation Card

struct RecommendationCard: View {
    let recommendation: TaskRecommendation
    let onAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: recommendation.type.icon)
                    .foregroundStyle(recommendation.priority.color)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text(recommendation.title)
                        .font(.headline)
                        .fontWeight(.semibold)

                    HStack {
                        Text("\(Int(recommendation.estimatedImpact * 100))% improvement")
                            .font(.caption)
                            .foregroundStyle(.green)
                            .fontWeight(.medium)

                        Spacer()

                        Text(recommendation.priority.rawValue.capitalized)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(recommendation.priority.color.opacity(0.2))
                            .foregroundStyle(recommendation.priority.color)
                            .clipShape(Capsule())
                    }
                }

                Spacer()
            }

            Text(recommendation.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if recommendation.actionable {
                HStack {
                    Spacer()

                    Button("Apply") {
                        onAction()
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(recommendation.priority.color)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Task Detail View

struct TaskDetailView: View {
    let task: Task
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Task Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(task.title)
                            .font(.title2)
                            .fontWeight(.bold)

                        HStack {
                            Label(task.scheduledTime.displayTime, systemImage: "clock")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Spacer()

                            Text(task.difficulty.rawValue.capitalized)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(task.difficulty.color.opacity(0.2))
                                .foregroundStyle(task.difficulty.color)
                                .clipShape(Capsule())
                        }
                    }

                    // Task Description
                    if let notes = task.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.headline)
                                .fontWeight(.semibold)

                            Text(notes)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 16)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }

                    // Task Category
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .font(.headline)
                            .fontWeight(.semibold)

                        HStack {
                            Image(systemName: task.category.icon)
                                .foregroundStyle(task.category.color)

                            Text(task.category.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)

                            Spacer()
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }

                    // AI Analysis (if available)
                    if let aiDifficulty = task.aiEstimatedDifficulty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("AI Analysis")
                                .font(.headline)
                                .fontWeight(.semibold)

                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Estimated Difficulty")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)

                                    Spacer()

                                    Text(aiDifficulty.rawValue.capitalized)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(aiDifficulty.color)
                                }

                                if let keywords = task.keywords, !keywords.isEmpty {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Keywords")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)

                                        HStack {
                                            ForEach(keywords.prefix(3), id: \.self) { keyword in
                                                Text(keyword)
                                                    .font(.caption)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(.blue.opacity(0.2))
                                                    .foregroundStyle(.blue)
                                                    .clipShape(Capsule())
                                            }
                                            Spacer()
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        }
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Task Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Enhanced Settings View

struct EnhancedSettingsView: View {
    @StateObject private var assetPipeline = AssetPipeline.shared
    @StateObject private var taskPlanningEngine = TaskPlanningEngine.shared
    @State private var assetValidationResult: AssetValidationResult?
    @State private var isValidatingAssets = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Performance") {
                    NavigationLink("Asset Pipeline") {
                        AssetPipelineView(assetPipeline: assetPipeline)
                    }

                    NavigationLink("AI Planning Engine") {
                        TaskPlanningView(engine: taskPlanningEngine)
                    }
                }

                Section("Analytics") {
                    NavigationLink("Performance Metrics") {
                        PerformanceMetricsView()
                    }

                    NavigationLink("Usage Statistics") {
                        UsageStatisticsView()
                    }
                }

                Section("Personalization") {
                    NavigationLink("AI Preferences") {
                        AIPreferencesView()
                    }

                    NavigationLink("Notification Settings") {
                        NotificationSettingsView()
                    }
                }

                Section("Developer") {
                    Button("Validate Assets") {
                        validateAssets()
                    }
                    .disabled(isValidatingAssets)

                    if let result = assetValidationResult {
                        AssetValidationResultView(result: result)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }

    private func validateAssets() {
        isValidatingAssets = true
        Task {
            let result = await assetPipeline.validate()
            await MainActor.run {
                assetValidationResult = result
                isValidatingAssets = false
            }
        }
    }
}

// MARK: - Asset Pipeline View

struct AssetPipelineView: View {
    @ObservedObject var assetPipeline: AssetPipeline
    @State private var validationResult: AssetValidationResult?
    @State private var optimizationResult: OptimizationResult?

    var body: some View {
        List {
            Section("Status") {
                if let result = validationResult {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Health Score")
                            Spacer()
                            Text("\(Int(result.healthScore))%")
                                .fontWeight(.semibold)
                                .foregroundStyle(result.healthScore > 80 ? .green : .orange)
                        }

                        HStack {
                            Text("Completion")
                            Spacer()
                            Text("\(Int(result.completionPercentage))%")
                                .fontWeight(.semibold)
                        }

                        if !result.optimizationOpportunities.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Optimization Potential")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Text("\(result.totalOptimizationPotential) bytes")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                }
            }

            Section("Actions") {
                Button("Validate Assets") {
                    Task {
                        validationResult = await assetPipeline.validate()
                    }
                }

                Button("Optimize All Assets") {
                    Task {
                        optimizationResult = await assetPipeline.optimizeAllAssets()
                    }
                }

                Button("Preload Critical Assets") {
                    Task {
                        await assetPipeline.preloadCriticalAssets()
                    }
                }
            }

            if let result = optimizationResult {
                Section("Optimization Results") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Assets Optimized")
                            Spacer()
                            Text("\(result.optimizedAssets)")
                        }

                        HStack {
                            Text("Bytes Saved")
                            Spacer()
                            Text("\(result.totalBytesSaved)")
                        }

                        HStack {
                            Text("Processing Time")
                            Spacer()
                            Text("\(Int(result.optimizationTimeMs))ms")
                        }
                    }
                }
            }
        }
        .navigationTitle("Asset Pipeline")
        .task {
            validationResult = await assetPipeline.validate()
        }
    }
}

// MARK: - Asset Validation Result View

struct AssetValidationResultView: View {
    let result: AssetValidationResult

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Health Score")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(Int(result.healthScore))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(result.healthScore > 80 ? .green : .orange)
            }

            HStack {
                Text("Available/Total")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(result.availableAssets.count)/\(result.totalStages)")
                    .font(.caption)
                    .fontWeight(.medium)
            }

            if !result.missingAssets.isEmpty {
                HStack {
                    Text("Missing")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("\(result.missingAssets.count)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.red)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Extensions

extension InsightCategory {
    var icon: String {
        switch self {
        case .productivity: return "chart.line.uptrend.xyaxis"
        case .difficulty: return "brain.head.profile"
        case .energy: return "bolt.fill"
        case .timing: return "clock.fill"
        case .patterns: return "waveform.path"
        }
    }
}

extension InsightSeverity {
    var color: Color {
        switch self {
        case .info: return .blue
        case .warning: return .orange
        case .critical: return .red
        }
    }
}

extension RecommendationType {
    var icon: String {
        switch self {
        case .timeOptimization: return "clock.badge.checkmark"
        case .batching: return "square.3.layers.3d"
        case .breaks: return "pause.circle"
        case .reordering: return "arrow.up.arrow.down"
        case .timeBlocking: return "calendar.badge.clock"
        case .energyAlignment: return "bolt.heart"
        }
    }
}

extension RecommendationPriority {
    var color: Color {
        switch self {
        case .low: return .gray
        case .medium: return .blue
        case .high: return .orange
        case .critical: return .red
        }
    }
}

extension TaskCategory {
    var icon: String {
        switch self {
        case .work: return "briefcase.fill"
        case .personal: return "person.fill"
        case .health: return "heart.fill"
        case .learning: return "book.fill"
        case .creative: return "paintbrush.fill"
        case .social: return "person.2.fill"
        }
    }

    var color: Color {
        switch self {
        case .work: return .blue
        case .personal: return .green
        case .health: return .red
        case .learning: return .purple
        case .creative: return .orange
        case .social: return .pink
        }
    }

    var displayName: String {
        switch self {
        case .work: return "Work"
        case .personal: return "Personal"
        case .health: return "Health"
        case .learning: return "Learning"
        case .creative: return "Creative"
        case .social: return "Social"
        }
    }
}

extension TimeSlot {
    var displayTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        return formatter.string(from: date)
    }
}

// MARK: - Placeholder Views

struct TaskPlanningView: View {
    @ObservedObject var engine: TaskPlanningEngine

    var body: some View {
        List {
            Section("Planning State") {
                Text(engine.planningState.description)
                    .fontWeight(.medium)
            }

            if !engine.insights.isEmpty {
                Section("Recent Insights") {
                    ForEach(engine.insights.prefix(3), id: \.id) { insight in
                        VStack(alignment: .leading) {
                            Text(insight.title)
                                .fontWeight(.medium)
                            Text(insight.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("AI Planning Engine")
    }
}

struct PerformanceMetricsView: View {
    var body: some View {
        List {
            Section("Coming Soon") {
                Text("Performance metrics will be available in the next update.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Performance Metrics")
    }
}

struct UsageStatisticsView: View {
    var body: some View {
        List {
            Section("Coming Soon") {
                Text("Usage statistics will be available in the next update.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Usage Statistics")
    }
}

struct AIPreferencesView: View {
    var body: some View {
        List {
            Section("Coming Soon") {
                Text("AI preferences will be available in the next update.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("AI Preferences")
    }
}

struct NotificationSettingsView: View {
    var body: some View {
        List {
            Section("Coming Soon") {
                Text("Notification settings will be available in the next update.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Notification Settings")
    }
}

extension PlanningState {
    var description: String {
        switch self {
        case .idle: return "Idle"
        case .analyzing: return "Analyzing Tasks"
        case .optimizing: return "Optimizing Schedule"
        case .adapting: return "Adapting Plan"
        case .completed: return "Plan Ready"
        }
    }
}
