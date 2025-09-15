import SwiftUI
import WidgetKit
import SharedKit

struct AccessoryCircularView: View {
    let entry: SimpleEntry

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.secondary.opacity(0.3), lineWidth: 4)

            // Progress ring
            Circle()
                .trim(from: 0, to: progressToNextStage)
                .stroke(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progressToNextStage)

            // Pet image in center with stage indicator
            VStack(spacing: 1) {
                if let petImageName = petImageName {
                    Image(petImageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                        .clipShape(Circle())
                } else {
                    // Fallback glyph based on current stage
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
        .containerBackground(for: .widget) {
            Color.clear
        }
    }

    private var progressToNextStage: Double {
        let engine = PetEvolutionEngine()
        let currentXP = entry.dayModel.points
        let currentStage = engine.stageIndex(for: currentXP)

        // If at max stage, show full circle
        if currentStage >= 15 {
            return 1.0
        }

        let currentThreshold = engine.threshold(for: currentStage)
        let nextThreshold = engine.threshold(for: currentStage + 1)
        let progressInStage = currentXP - currentThreshold
        let totalNeededForStage = nextThreshold - currentThreshold

        guard totalNeededForStage > 0 else { return 1.0 }

        return Double(progressInStage) / Double(totalNeededForStage)
    }

    private var petImageName: String? {
        let engine = PetEvolutionEngine()
        return engine.imageName(for: entry.dayModel.points)
    }

    private var currentStage: Int {
        let engine = PetEvolutionEngine()
        return engine.stageIndex(for: entry.dayModel.points)
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

#Preview {
    AccessoryCircularView(entry: SimpleEntry(
        date: Date(),
        dayModel: DayModel(
            key: "2024-09-14",
            slots: [
                DayModel.Slot(id: "1", title: "Morning Task", hour: 9, isDone: true),
                DayModel.Slot(id: "2", title: "Afternoon Task", hour: 14, isDone: false)
            ],
            points: 25
        )
    ))
    .previewContext(WidgetPreviewContext(family: .accessoryCircular))
}