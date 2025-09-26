import SwiftUI
import WidgetKit
import SharedKit

/// Primary Lock Screen view that displays tasks with interactive buttons using TaskEntity
@available(iOS 17.0, *)
struct TaskLockScreenView: View {
    let entry: TaskEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            AccessoryCircularTaskView(entry: entry)
        case .accessoryRectangular:
            AccessoryRectangularTaskView(entry: entry)
        case .accessoryInline:
            AccessoryInlineTaskView(entry: entry)
        case .systemSmall:
            SystemSmallTaskView(entry: entry)
        default:
            SystemSmallTaskView(entry: entry)
        }
    }
}

// MARK: - Accessory Circular View

@available(iOS 17.0, *)
struct AccessoryCircularTaskView: View {
    let entry: TaskEntry

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.secondary.opacity(0.3), lineWidth: 4)

            // Progress ring showing pet evolution progress
            Circle()
                .trim(from: 0, to: petProgressToNextStage)
                .stroke(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: petProgressToNextStage)

            // Pet image in center with interactive complete button
            if entry.tasks.first(where: { !$0.isDone }) != nil {
                Button(intent: MarkNextTaskDoneIntent()) {
                    VStack(spacing: 2) {
                        WidgetImageOptimizer.shared.widgetImage(for: currentStage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)

                        // Stage indicator (S1-S16)
                        Text("S\(currentStage + 1)")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.primary)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                // No active tasks - show pet only
                VStack(spacing: 2) {
                    WidgetImageOptimizer.shared.widgetImage(for: currentStage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)

                    Text("S\(currentStage + 1)")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.primary)
                }
            }
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }

    private var petProgressToNextStage: Double {
        let engine = PetEvolutionEngine()
        let currentXP = entry.petStage.points
        let currentStageIndex = engine.stageIndex(for: currentXP)

        // If at max stage, show full circle
        if currentStageIndex >= 15 {
            return 1.0
        }

        let currentThreshold = engine.threshold(for: currentStageIndex)
        let nextThreshold = engine.threshold(for: currentStageIndex + 1)
        let progressInStage = currentXP - currentThreshold
        let totalNeededForStage = nextThreshold - currentThreshold

        guard totalNeededForStage > 0 else { return 1.0 }

        return Double(progressInStage) / Double(totalNeededForStage)
    }

    private var currentStage: Int {
        let engine = PetEvolutionEngine()
        return engine.stageIndex(for: entry.petStage.points)
    }
}

// MARK: - Accessory Rectangular View

@available(iOS 17.0, *)
struct AccessoryRectangularTaskView: View {
    let entry: TaskEntry

    var body: some View {
        HStack(spacing: 8) {
            // Pet image at left
            WidgetImageOptimizer.shared.widgetImage(for: currentStage)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)

            // Tasks on right
            VStack(alignment: .leading, spacing: 4) {
                ForEach(entry.tasks.prefix(2), id: \.id) { task in
                    HStack(spacing: 6) {
                        Button(intent: MarkNextTaskDoneIntent()) {
                            Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 12))
                                .foregroundStyle(task.isDone ? .green : .secondary)
                        }
                        .buttonStyle(PlainButtonStyle())

                        Button(intent: SkipCurrentTaskIntent()) {
                            Image(systemName: "xmark.circle")
                                .font(.system(size: 12))
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(PlainButtonStyle())

                        Text(task.title)
                            .lineLimit(1)
                            .font(.footnote)
                            .foregroundStyle(task.isDone ? .secondary : .primary)
                    }
                }

                // Navigation controls
                HStack {
                    Button(intent: GoToPreviousTaskIntent()) {
                        Image(systemName: "chevron.left")
                            .font(.footnote)
                    }
                    .buttonStyle(PlainButtonStyle())

                    Spacer(minLength: 0)

                    Button(intent: GoToNextTaskIntent()) {
                        Image(systemName: "chevron.right")
                            .font(.footnote)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }

    private var currentStage: Int {
        let engine = PetEvolutionEngine()
        return engine.stageIndex(for: entry.petStage.points)
    }
}

// MARK: - Accessory Inline View

@available(iOS 17.0, *)
struct AccessoryInlineTaskView: View {
    let entry: TaskEntry

    var body: some View {
        HStack(spacing: 4) {
            if let nextTask = entry.tasks.first(where: { !$0.isDone }) {
                // Pet glyph
                WidgetImageOptimizer.shared.widgetImage(for: currentStage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 12, height: 12)

                Text("Next:")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)

                Text(nextTask.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text("•")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)

                Text("\(String(format: "%02d:00", nextTask.dueHour))")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            } else {
                WidgetImageOptimizer.shared.widgetImage(for: currentStage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 12, height: 12)

                Text("No upcoming tasks")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }

    private var currentStage: Int {
        let engine = PetEvolutionEngine()
        return engine.stageIndex(for: entry.petStage.points)
    }
}

// MARK: - System Small View

@available(iOS 17.0, *)
struct SystemSmallTaskView: View {
    let entry: TaskEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with pet
            HStack {
                WidgetImageOptimizer.shared.widgetImage(for: currentStage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)

                VStack(alignment: .leading) {
                    Text("Pet Progress")
                        .font(.headline)
                    Text("Stage \(currentStage + 1)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            // Tasks (up to 3)
            ForEach(entry.tasks.prefix(3), id: \.id) { task in
                HStack(spacing: 8) {
                    Button(intent: MarkNextTaskDoneIntent()) {
                        Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(task.isDone ? .green : .secondary)
                    }
                    .buttonStyle(PlainButtonStyle())

                    Text(task.title)
                        .font(.footnote)
                        .lineLimit(1)
                        .foregroundStyle(task.isDone ? .secondary : .primary)

                    Spacer()

                    if !task.isDone {
                        Button(intent: SkipCurrentTaskIntent()) {
                            Image(systemName: "xmark.circle")
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }

            Spacer()
        }
        .padding()
    }

    private var currentStage: Int {
        let engine = PetEvolutionEngine()
        return engine.stageIndex(for: entry.petStage.points)
    }
}

// MARK: - Task Entry Model

struct TaskEntry: TimelineEntry, Sendable {
    let date: Date
    let tasks: [TaskEntity]
    let petStage: PetStage
}

struct PetStage: Sendable {
    let points: Int
    let stageIndex: Int
}

#Preview {
    TaskLockScreenView(entry: TaskEntry(
        date: Date(),
        tasks: [
            TaskEntity(id: "1", title: "Deep Work Session", dueHour: 9, isDone: false, dayKey: "2024-09-14"),
            TaskEntity(id: "2", title: "Team Meeting", dueHour: 10, isDone: false, dayKey: "2024-09-14")
        ],
        petStage: PetStage(points: 25, stageIndex: 2)
    ))
    .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
}