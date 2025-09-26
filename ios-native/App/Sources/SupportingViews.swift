import SwiftUI
import SharedKit

/// Supporting views for the award-winning app interface
@available(iOS 17.0, *)

// MARK: - Placeholder Types for Missing Dependencies

struct TaskRecommendationPlaceholder {
    let type: RecommendationType = .timeOptimization
    let priority: RecommendationPriority = .medium
    let title: String = "Placeholder"
    let description: String = "Placeholder description"
    let estimatedImpact: Double = 0.5
    let actionable: Bool = false
}

// Import TaskTemplateSystem types
typealias TemplateCategory = TaskTemplateSystem.TemplateCategory
typealias TaskTemplate = TaskTemplateSystem.TaskTemplate

class TaskPlanningEnginePlaceholder: ObservableObject {
    static let shared = TaskPlanningEnginePlaceholder()
}

struct AssetValidationResultPlaceholder {
    let healthScore: Double = 85.0
    let completionPercentage: Double = 90.0
    let optimizationOpportunities: [String] = []
    let totalOptimizationPotential: Int = 0
    let availableAssets: [String] = []
    let totalStages: Int = 16
    let missingAssets: [String] = []
}

class AssetPipelinePlaceholder: ObservableObject {
    static let shared = AssetPipelinePlaceholder()

    func validate() async -> AssetValidationResultPlaceholder {
        return AssetValidationResultPlaceholder()
    }

    func optimizeAllAssets() async -> OptimizationResultPlaceholder {
        return OptimizationResultPlaceholder()
    }

    func preloadCriticalAssets() async {
        // Placeholder implementation
    }
}

struct OptimizationResultPlaceholder {
    let optimizedAssets: Int = 0
    let totalBytesSaved: Int = 0
    let optimizationTimeMs: Double = 0
}

enum InsightCategory {
    case productivity, difficulty, energy, timing, patterns
}

enum InsightSeverity {
    case info, warning, critical
}

enum RecommendationType {
    case timeOptimization, batching, breaks, reordering, timeBlocking, energyAlignment
}

enum RecommendationPriority: String {
    case low, medium, high, critical
}

// MARK: - AI Insights View

struct AIInsightsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Text("AI Insights coming soon")
                .navigationTitle("AI Insights")
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
    var body: some View {
        Text("Insight placeholder")
    }
}

// MARK: - Recommendation Card

struct RecommendationCard: View {
    let recommendation: TaskRecommendationPlaceholder
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
    let task: MaterializedTask
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
    @StateObject private var assetPipeline = AssetPipelinePlaceholder.shared
    @StateObject private var taskPlanningEngine = TaskPlanningEnginePlaceholder.shared
    @State private var assetValidationResult: AssetValidationResultPlaceholder?
    @State private var isValidatingAssets = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Performance") {
                    NavigationLink("Asset Pipeline") {
                        AssetPipelineView(assetPipeline: assetPipeline)
                    }

                    NavigationLink("AI Planning Engine") {
                        Text("Planning engine coming soon")
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
    @ObservedObject var assetPipeline: AssetPipelinePlaceholder
    @State private var validationResult: AssetValidationResultPlaceholder?
    @State private var optimizationResult: OptimizationResultPlaceholder?

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
    let result: AssetValidationResultPlaceholder

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

// TaskCategory extension removed - type not defined

// TimeSlot extension removed - TimeSlot is a static utility enum

// MARK: - Placeholder Views


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

// PlanningState extension removed - type not defined
