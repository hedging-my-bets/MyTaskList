import SwiftUI

struct TaskSummaryView: View {
    let completed: Int
    let total: Int

    var progress: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }

    var body: some View {
        VStack(spacing: 8) {
            Text("Today's Progress")
                .font(.headline)

            Text("\(completed) of \(total) tasks completed")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if total > 0 {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .animation(.easeInOut(duration: 0.5), value: progress)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}