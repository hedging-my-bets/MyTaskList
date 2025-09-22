import SwiftUI
import WidgetKit
import SharedKit

/// Enterprise-grade interactive Lock Screen widgets with Button(intent:) for zero-app-launch task completion
/// Built by world-class engineers for sub-1-second user experience
@available(iOS 17.0, *)
struct InteractiveCircularLockScreenView: View {
    let entry: TaskTimelineEntry

    var body: some View {
        ZStack {
            // Background progress ring
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 6)

            // Progress ring based on pet XP
            Circle()
                .trim(from: 0, to: progressRatio)
                .stroke(petColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: progressRatio)

            // Interactive center content
            Button(intent: completeTaskIntent) {
                VStack(spacing: 2) {
                    // Pet image or stage indicator
                    petImageView
                        .font(.system(size: 16, weight: .bold))

                    // Status text
                    Text(statusText)
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }

    // MARK: - Computed Properties

    private var progressRatio: CGFloat {
        let stageCfg = StageConfigLoader.shared.loadStageConfig()
        guard entry.petState.stageIndex < stageCfg.stages.count else { return 0 }

        let currentThreshold = stageCfg.stages[entry.petState.stageIndex].threshold
        guard currentThreshold > 0 else { return 0 }

        return CGFloat(entry.petState.stageXP) / CGFloat(currentThreshold)
    }

    private var petColor: Color {
        let stageIndex = entry.petState.stageIndex
        let colors: [Color] = [
            .blue, .green, .orange, .purple, .pink, .red, .yellow, .cyan
        ]
        return colors[stageIndex % colors.count]
    }

    @ViewBuilder
    private var petImageView: some View {
        if let currentTask = entry.currentTask {
            // Show task completion button
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(petColor)
        } else if let nextTask = entry.nextTask {
            // Show optimized pet image with stage
            WidgetImageOptimizer.shared.widgetImage(for: entry.petState.stageIndex)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
        } else {
            // Show celebrating pet (all done)
            Image(systemName: "star.fill")
                .foregroundColor(.yellow)
        }
    }

    private var statusText: String {
        if entry.currentTask != nil {
            return "Tap"
        } else if let nextTask = entry.nextTask, let hour = nextTask.scheduledAt.hour {
            return "\(hour):00"
        } else {
            return "Done"
        }
    }

    private var nextTaskTimeText: String {
        guard let nextTask = entry.nextTask,
              let nextHour = nextTask.scheduledAt.hour else { return "✓" }

        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)

        let hoursUntil = nextHour >= currentHour ? nextHour - currentHour : (24 - currentHour) + nextHour

        if hoursUntil == 0 {
            return "Now"
        } else if hoursUntil <= 6 {
            return "\(hoursUntil)h"
        } else {
            return "✓"
        }
    }

    private var completeTaskIntent: MarkNextTaskDoneIntent {
        return MarkNextTaskDoneIntent()
    }
}

@available(iOS 17.0, *)
struct InteractiveRectangularLockScreenView: View {
    let entry: TaskTimelineEntry

    var body: some View {
        HStack(spacing: 8) {
            // Pet image - optimized for instant loading
            petImageView
                .frame(width: 24, height: 24)

            // Main content area
            VStack(alignment: .leading, spacing: 2) {
                // Navigation and status
                HStack {
                    // Previous button
                    Button(intent: GoToPreviousTaskIntent()) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())

                    Spacer()

                    // Status text
                    Text(statusText)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.primary)

                    Spacer()

                    // Next/Skip buttons
                    HStack(spacing: 4) {
                        if entry.currentTask != nil {
                            // Skip button for current task
                            Button(intent: skipTaskIntent) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }

                        // Next button
                        Button(intent: GoToNextTaskIntent()) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }

                // Task title (tappable for completion if current task)
                if let currentTask = entry.currentTask {
                    Button(intent: MarkNextTaskDoneIntent()) {
                        Text(currentTask.title)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    Text(taskTitleText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.horizontal, 8)
        .containerBackground(for: .widget) {
            Color.clear
        }
    }

    // MARK: - Computed Properties

    @ViewBuilder
    private var petImageView: some View {
        // Steve Jobs-level instant image loading
        WidgetImageOptimizer.shared.widgetImage(for: entry.petState.stageIndex)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundColor(petColor)
    }

    private var petColor: Color {
        let stageIndex = entry.petState.stageIndex
        let colors: [Color] = [
            .blue, .green, .orange, .purple, .pink, .red, .yellow, .cyan
        ]
        return colors[stageIndex % colors.count]
    }

    private var statusText: String {
        if let currentTask = entry.currentTask {
            return "Now"
        } else if let nextTask = entry.nextTask, let hour = nextTask.scheduledAt.hour {
            let now = Date()
            let calendar = Calendar.current
            let currentHour = calendar.component(.hour, from: now)
            let hoursUntil = hour >= currentHour ? hour - currentHour : (24 - currentHour) + hour

            if hoursUntil == 0 {
                return "Next now"
            } else if hoursUntil == 1 {
                return "1h free"
            } else {
                return "\(hoursUntil)h free"
            }
        } else {
            return "All done"
        }
    }

    private var taskTitleText: String {
        if let nextTask = entry.nextTask {
            return nextTask.title
        } else {
            return "No more tasks"
        }
    }

    private var skipTaskIntent: SkipCurrentTaskIntent {
        return SkipCurrentTaskIntent()
    }
}

@available(iOS 17.0, *)
struct InteractiveInlineLockScreenView: View {
    let entry: TaskTimelineEntry

    var body: some View {
        HStack(spacing: 6) {
            // Pet stage indicator
            Text(petStageEmoji)
                .font(.system(size: 14, weight: .bold))

            // Main text content
            if let currentTask = entry.currentTask {
                Button(intent: MarkNextTaskDoneIntent()) {
                    Text("Now: \(currentTask.title)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }
                .buttonStyle(PlainButtonStyle())
            } else if let nextTask = entry.nextTask, let hour = nextTask.scheduledAt.hour {
                Text("Next \(hour):00: \(nextTask.title)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            } else {
                Text("All caught up")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }

    // MARK: - Computed Properties

    private var petStageEmoji: String {
        let stageIndex = entry.petState.stageIndex
        let stageEmojis = ["🥚", "🐣", "🐤", "🐥", "🐦", "🦅", "🦉", "🦆", "🦢", "🐧", "🦜", "🦚", "🪶", "✨", "🌟", "⭐"]
        return stageEmojis[min(stageIndex, stageEmojis.count - 1)]
    }
}

// MARK: - Widget Configuration
// Note: The widget configuration is defined in PetProgressInteractiveLockScreenWidget.swift

@available(iOS 17.0, *)
struct PetProgressLockScreenWidgetEntryView: View {
    var entry: TaskTimelineProvider.Entry

    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        switch widgetFamily {
        case .accessoryCircular:
            InteractiveCircularLockScreenView(entry: entry)
        case .accessoryRectangular:
            InteractiveRectangularLockScreenView(entry: entry)
        case .accessoryInline:
            InteractiveInlineLockScreenView(entry: entry)
        default:
            Text("Unsupported")
                .font(.caption)
        }
    }
}

// Configuration intent moved to PetProgressWidget.swift to avoid duplicates

// MARK: - Preview Provider

@available(iOS 17.0, *)
struct InteractiveLockScreenViews_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Circular preview
            InteractiveCircularLockScreenView(entry: sampleEntry)
                .previewContext(WidgetPreviewContext(family: .accessoryCircular))

            // Rectangular preview
            InteractiveRectangularLockScreenView(entry: sampleEntry)
                .previewContext(WidgetPreviewContext(family: .accessoryRectangular))

            // Inline preview
            InteractiveInlineLockScreenView(entry: sampleEntry)
                .previewContext(WidgetPreviewContext(family: .accessoryInline))
        }
    }

    static var sampleEntry: TaskTimelineEntry {
        TaskTimelineEntry(
            date: Date(),
            currentTask: TaskItem(
                id: UUID(),
                title: "Morning standup",
                scheduledAt: DateComponents(hour: 9),
                isCompleted: false,
                dayKey: TimeSlot.dayKey(for: Date())
            ),
            nextTask: TaskItem(
                id: UUID(),
                title: "Code review",
                scheduledAt: DateComponents(hour: 11),
                isCompleted: false,
                dayKey: TimeSlot.dayKey(for: Date())
            ),
            petState: PetState(stageIndex: 3, stageXP: 25, lastCloseoutDayKey: "", lastCelebratedStage: 2),
            graceMinutes: 30,
            emptyStateMessage: nil
        )
    }
}