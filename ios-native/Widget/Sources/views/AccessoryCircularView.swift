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

            // Pet image in center
            if let petImageName = petImageName {
                Image(petImageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                    .clipShape(Circle())
            } else {
                // Fallback glyph
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.blue)
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