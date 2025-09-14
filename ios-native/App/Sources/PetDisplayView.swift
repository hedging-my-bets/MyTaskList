import SwiftUI
import SharedKit

struct PetDisplayView: View {
    let stage: Int
    let points: Int
    let imageName: String

    var body: some View {
        VStack(spacing: 12) {
            // Pet Image
            if #available(iOS 17.0, *) {
                AssetPipeline.shared.image(for: stage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 4)
            } else {
                // Fallback for older iOS versions
                Image(systemName: "pawprint.circle.fill")
                    .font(.system(size: 120))
                    .foregroundStyle(.blue.gradient)
            }

            // Stage Info
            VStack(spacing: 4) {
                Text("Stage \(stage)")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("\(points) points")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .animation(.easeInOut(duration: 0.6), value: stage)
    }
}
