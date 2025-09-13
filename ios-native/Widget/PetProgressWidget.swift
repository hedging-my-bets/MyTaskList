import SwiftUI
import UIKit
import WidgetKit
import AppIntents
import PetProgressShared

@main
struct PetProgressWidgetBundle: WidgetBundle {
    var body: some Widget {
        PetProgressWidget()
    }
}

struct PetEntry: TimelineEntry {
    let date: Date
    let stageIndex: Int
    let stageXP: Int
    let threshold: Int
    let tasksDone: Int
    let tasksTotal: Int
    let rows: [MaterializedTask]
    let dayKey: String
}

struct PetProgressWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "PetProgressWidget", provider: Provider()) { entry in
            PetWidgetView(entry: entry)
                .widgetURL(URL(string: "petprogress://planner"))
        }
        .configurationDisplayName("Pet Progress")
        .description("Track your pet's evolution with your tasks.")
        .supportedFamilies([.accessoryRectangular, .systemSmall])
    }
}

struct PetWidgetView: View {
    let entry: PetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(uiImage: imageForStage(entry.stageIndex))
                    .resizable()
                    .scaledToFit()
                    .frame(height: 24)
                    .accessibilityLabel(stageName(for: entry.stageIndex))
                Spacer()
                Text("\(entry.tasksDone)/\(entry.tasksTotal)")
                    .font(.caption2)
                    .accessibilityLabel("\(entry.tasksDone) of \(entry.tasksTotal) tasks done")
            }
            ProgressView(value: progress)
                .accessibilityLabel(progressLabel)
            VStack(alignment: .leading, spacing: 2) {
                ForEach(entry.rows, id: \.id) { row in
                    HStack(spacing: 4) {
                        Button(intent: CompleteTaskIntent(taskId: row.id.uuidString, dayKey: entry.dayKey)) {
                            Image(systemName: row.isCompleted ? "checkmark.circle.fill" : "circle")
                        }
                        .accessibilityLabel(row.isCompleted ? "Completed" : "Mark as complete")
                        Text(String(format: "%02d:%02d", row.time.hour ?? 0, row.time.minute ?? 0))
                            .font(.caption2)
                        Text(row.title)
                            .font(.caption2)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding(4)
    }

    private var progress: Double {
        if entry.threshold == 0 { return 1 }
        return Double(max(0, min(entry.stageXP, entry.threshold))) / Double(entry.threshold)
    }

    private var progressLabel: String {
        if entry.threshold == 0 {
            return "Stage \(entry.stageIndex + 1): Complete"
        }
        let percentage = Int(progress * 100)
        return "\(percentage)% to next stage"
    }

    private func stageName(for stageIndex: Int) -> String {
        let loader = StageConfigLoader()
        let cfg = (try? loader.load(bundle: .main)) ?? StageCfg.defaultConfig()
        return cfg.stages[safe: stageIndex]?.name ?? "Stage \(stageIndex + 1)"
    }

    private func imageForStage(_ idx: Int) -> UIImage {
        let loader = StageConfigLoader()
        let cfg = (try? loader.load(bundle: .main)) ?? StageCfg.defaultConfig()
        let asset = cfg.stages[safe: idx]?.asset ?? "pet_tadpole"
        return UIImage(named: asset) ?? (UIImage(systemName: "leaf") ?? UIImage())
    }
}

