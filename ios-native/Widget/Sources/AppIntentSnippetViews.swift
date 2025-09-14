import SwiftUI
import AppIntents
import SharedKit

// MARK: - Task Completion Snippet View

@available(iOS 17.0, *)
struct CompletionSnippetView: View {
    let taskTitle: String
    let pointsGained: Int
    let newStage: Int
    let completedCount: Int
    let totalCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.green)

                Text("Task Completed!")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()
            }

            // Task details
            VStack(alignment: .leading, spacing: 4) {
                Text("'\(taskTitle)'")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                HStack {
                    Text("+\(pointsGained) points")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(.green.opacity(0.2))
                        .foregroundStyle(.green)
                        .clipShape(Capsule())

                    Text("Stage \(newStage)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(.blue.opacity(0.2))
                        .foregroundStyle(.blue)
                        .clipShape(Capsule())
                }
            }

            // Progress indicator
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("Today's Progress")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("\(completedCount)/\(totalCount)")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }

                ProgressView(value: Double(completedCount), total: Double(totalCount))
                    .progressViewStyle(LinearProgressViewStyle())
                    .tint(.blue)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Task Snooze Snippet View

@available(iOS 17.0, *)
struct SnoozeSnippetView: View {
    let taskTitle: String
    let originalTime: Int
    let newTime: Int
    let snoozeDuration: SnoozeDuration

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: "clock.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)

                Text("Task Snoozed")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()
            }

            // Task details
            VStack(alignment: .leading, spacing: 4) {
                Text("'\(taskTitle)'")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                HStack {
                    VStack(alignment: .center, spacing: 2) {
                        Text("FROM")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("\(originalTime):00")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.secondary.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }

                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    VStack(alignment: .center, spacing: 2) {
                        Text("TO")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("\(newTime):00")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.orange.opacity(0.2))
                            .foregroundStyle(.orange)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }

                    Spacer()
                }
            }

            // Duration indicator
            HStack {
                Image(systemName: "plus")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text(snoozeDuration.rawValue)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("You've got this! 💪")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Mark Next Snippet View

@available(iOS 17.0, *)
struct MarkNextSnippetView: View {
    let completedTask: String
    let nextTask: String?
    let nextTaskTime: Int?
    let newStage: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)

                Text("Task Complete → Next")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()
            }

            // Completed task
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .foregroundStyle(.green)

                    Text("Completed: '\(completedTask)'")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .strikethrough()
                        .foregroundStyle(.secondary)
                }

                if let next = nextTask, let time = nextTaskTime {
                    HStack {
                        Image(systemName: "arrow.right")
                            .font(.caption)
                            .foregroundStyle(.blue)

                        Text("Next: '\(next)' at \(time):00")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                    }
                } else {
                    HStack {
                        Image(systemName: "party.popper.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)

                        Text("All tasks complete!")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.green)
                    }
                }
            }

            // Stage indicator
            HStack {
                Text("Pet Stage")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("Stage \(newStage)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(.blue.opacity(0.2))
                    .foregroundStyle(.blue)
                    .clipShape(Capsule())
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Pet Status Snippet View

@available(iOS 17.0, *)
struct PetStatusSnippetView: View {
    let stage: Int
    let points: Int
    let completedTasks: Int
    let totalTasks: Int
    let emotionalState: PetEvolutionEngine.EmotionalState
    let analysis: PetEvolutionEngine.EvolutionAnalysis

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with pet info
            HStack {
                // Pet avatar (using SF Symbol placeholder)
                ZStack {
                    Circle()
                        .fill(emotionalStateColor.opacity(0.2))
                        .frame(width: 40, height: 40)

                    AssetPipeline.shared.placeholderImage(for: stage)
                        .font(.title3)
                        .foregroundStyle(emotionalStateColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Stage \(stage) Pet")
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text("\(points) points • \(emotionalState.rawValue.capitalized)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Emotional state indicator
                VStack {
                    Text(emotionalStateEmoji)
                        .font(.title2)

                    Text(emotionalState.rawValue.capitalized)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            // Progress section
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Today's Progress")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Spacer()

                    Text("\(completedTasks)/\(totalTasks)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(progressColor)
                }

                if totalTasks > 0 {
                    ProgressView(value: Double(completedTasks), total: Double(totalTasks))
                        .progressViewStyle(LinearProgressViewStyle())
                        .tint(progressColor)
                }

                if completedTasks == totalTasks && totalTasks > 0 {
                    Text("🎉 All tasks complete!")
                        .font(.caption)
                        .foregroundStyle(.green)
                        .fontWeight(.medium)
                } else if totalTasks > 0 {
                    let remaining = totalTasks - completedTasks
                    Text("\(remaining) task\(remaining == 1 ? "" : "s") remaining")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Evolution trend
            if let prediction = analysis.predictedNextEvolution {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Prediction")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    HStack {
                        Text("Trend: \(analysis.recentEvolutionTrend.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text("Stage \(prediction.predictedStageIn24Hours) tomorrow")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.blue.opacity(0.2))
                            .foregroundStyle(.blue)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var emotionalStateColor: Color {
        switch emotionalState {
        case .ecstatic, .happy: return .green
        case .content: return .blue
        case .neutral: return .gray
        case .worried: return .orange
        case .sad, .frustrated: return .red
        }
    }

    private var emotionalStateEmoji: String {
        switch emotionalState {
        case .ecstatic: return "🤩"
        case .happy: return "😊"
        case .content: return "😌"
        case .neutral: return "😐"
        case .worried: return "😟"
        case .sad: return "😢"
        case .frustrated: return "😤"
        }
    }

    private var progressColor: Color {
        guard totalTasks > 0 else { return .gray }
        let progress = Double(completedTasks) / Double(totalTasks)
        if progress >= 1.0 { return .green }
        if progress >= 0.7 { return .blue }
        if progress >= 0.4 { return .orange }
        return .red
    }
}

// MARK: - Preview Support

@available(iOS 17.0, *)
struct AppIntentSnippetViews_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            CompletionSnippetView(
                taskTitle: "Morning workout",
                pointsGained: 5,
                newStage: 3,
                completedCount: 2,
                totalCount: 4
            )

            SnoozeSnippetView(
                taskTitle: "Project review",
                originalTime: 14,
                newTime: 15,
                snoozeDuration: .oneHour
            )

            MarkNextSnippetView(
                completedTask: "Design meeting",
                nextTask: "Code review",
                nextTaskTime: 16,
                newStage: 4
            )
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .previewLayout(.sizeThatFits)
    }
}