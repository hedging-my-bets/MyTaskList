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
            if let currentTask = entry.tasks.first(where: { !$0.isDone }) {
                Button(intent: CompleteTaskIntent(task: currentTask)) {
                    VStack(spacing: 2) {
                        if let petImageName = petImageName {
                            Image(petImageName)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 20)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: currentStageIcon)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(currentStageColor)
                        }

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
                    if let petImageName = petImageName {
                        Image(petImageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: currentStageIcon)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(currentStageColor)
                    }

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

    private var petImageName: String? {
        let engine = PetEvolutionEngine()
        return engine.imageName(for: entry.petStage.points)
    }

    private var currentStage: Int {
        let engine = PetEvolutionEngine()
        return engine.stageIndex(for: entry.petStage.points)
    }

    private var currentStageIcon: String {
        switch currentStage {
        case 0...2: return "leaf.fill"      // Baby stages
        case 3...5: return "sparkles"       // Growing stages
        case 6...8: return "star.fill"      // Teen stages
        case 9...11: return "crown.fill"    // Adult stages
        case 12...14: return "diamond.fill" // Elite stages
        default: return "trophy.fill"       // CEO stage
        }
    }

    private var currentStageColor: Color {
        switch currentStage {
        case 0...2: return .green      // Baby stages
        case 3...5: return .blue       // Growing stages
        case 6...8: return .purple     // Teen stages
        case 9...11: return .orange    // Adult stages
        case 12...14: return .red      // Elite stages
        default: return .yellow        // CEO stage
        }
    }
}

// MARK: - Accessory Rectangular View

@available(iOS 17.0, *)
struct AccessoryRectangularTaskView: View {
    let entry: TaskEntry

    var body: some View {
        HStack(spacing: 8) {
            // Pet image at left
            if let petImageName = petImageName {
                Image(petImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
            } else {
                Image(systemName: currentStageIcon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(currentStageColor)
                    .frame(width: 24, height: 24)
            }

            // Tasks on right
            VStack(alignment: .leading, spacing: 4) {
                ForEach(entry.tasks.prefix(2), id: \.id) { task in
                    HStack(spacing: 6) {
                        Button(intent: CompleteTaskIntent(task: task)) {
                            Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 12))
                                .foregroundStyle(task.isDone ? .green : .secondary)
                        }
                        .buttonStyle(PlainButtonStyle())

                        Button(intent: SkipTaskIntent(task: task)) {
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
                    Button(intent: PreviousPageIntent()) {
                        Image(systemName: "chevron.left")
                            .font(.footnote)
                    }
                    .buttonStyle(PlainButtonStyle())

                    Spacer(minLength: 0)

                    Button(intent: NextPageIntent()) {
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

    private var petImageName: String? {
        let engine = PetEvolutionEngine()
        return engine.imageName(for: entry.petStage.points)
    }

    private var currentStage: Int {
        let engine = PetEvolutionEngine()
        return engine.stageIndex(for: entry.petStage.points)
    }

    private var currentStageIcon: String {
        switch currentStage {
        case 0...2: return "leaf.fill"
        case 3...5: return "sparkles"
        case 6...8: return "star.fill"
        case 9...11: return "crown.fill"
        case 12...14: return "diamond.fill"
        default: return "trophy.fill"
        }
    }

    private var currentStageColor: Color {
        switch currentStage {
        case 0...2: return .green
        case 3...5: return .blue
        case 6...8: return .purple
        case 9...11: return .orange
        case 12...14: return .red
        default: return .yellow
        }
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
                Image(systemName: currentStageIcon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(currentStageColor)

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
                Image(systemName: currentStageIcon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(currentStageColor)

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

    private var currentStageIcon: String {
        switch currentStage {
        case 0...2: return "leaf.fill"
        case 3...5: return "sparkles"
        case 6...8: return "star.fill"
        case 9...11: return "crown.fill"
        case 12...14: return "diamond.fill"
        default: return "trophy.fill"
        }
    }

    private var currentStageColor: Color {
        switch currentStage {
        case 0...2: return .green
        case 3...5: return .blue
        case 6...8: return .purple
        case 9...11: return .orange
        case 12...14: return .red
        default: return .yellow
        }
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
                if let petImageName = petImageName {
                    Image(petImageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                } else {
                    Image(systemName: currentStageIcon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(currentStageColor)
                }

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
                    Button(intent: CompleteTaskIntent(task: task)) {
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
                        Button(intent: SkipTaskIntent(task: task)) {
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

    private var petImageName: String? {
        let engine = PetEvolutionEngine()
        return engine.imageName(for: entry.petStage.points)
    }

    private var currentStage: Int {
        let engine = PetEvolutionEngine()
        return engine.stageIndex(for: entry.petStage.points)
    }

    private var currentStageIcon: String {
        switch currentStage {
        case 0...2: return "leaf.fill"
        case 3...5: return "sparkles"
        case 6...8: return "star.fill"
        case 9...11: return "crown.fill"
        case 12...14: return "diamond.fill"
        default: return "trophy.fill"
        }
    }

    private var currentStageColor: Color {
        switch currentStage {
        case 0...2: return .green
        case 3...5: return .blue
        case 6...8: return .purple
        case 9...11: return .orange
        case 12...14: return .red
        default: return .yellow
        }
    }
}

// MARK: - Task Entry Model

struct TaskEntry: TimelineEntry {
    let date: Date
    let tasks: [TaskEntity]
    let petStage: PetStage
}

struct PetStage {
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