import SwiftUI
import SharedKit

/// Steve Jobs-level celebration system with confetti and micro-animations
/// Designed for pet level-up moments with precise timing and visual polish
@available(iOS 17.0, *)
struct CelebrationView: View {
    let petStage: Int
    let stageName: String
    let onDismiss: () -> Void

    @State private var isAnimating = false
    @State private var confettiParticles: [ConfettiParticle] = []
    @State private var titleScale: CGFloat = 0.1
    @State private var petImageScale: CGFloat = 0.1
    @State private var backgroundOpacity: Double = 0.0

    private let colors = [
        Color.blue, Color.green, Color.orange, Color.purple,
        Color.pink, Color.red, Color.yellow, Color.cyan
    ]

    var body: some View {
        ZStack {
            // Background overlay
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
                .opacity(backgroundOpacity)
                .onTapGesture {
                    dismissCelebration()
                }

            VStack(spacing: 24) {
                // Pet image with glow effect
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [petColor.opacity(0.3), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                        .blur(radius: isAnimating ? 10 : 0)

                    // Pet image
                    WidgetImageOptimizer.shared.widgetImage(for: petStage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .scaleEffect(petImageScale)
                        .rotationEffect(.degrees(isAnimating ? 360 : 0))
                }

                // Level up text
                VStack(spacing: 8) {
                    Text("Level Up!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [petColor, petColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(titleScale)

                    Text("Your pet evolved to \(stageName)!")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .opacity(isAnimating ? 1 : 0)
                }

                // Dismiss button
                Button(action: dismissCelebration) {
                    Text("Awesome!")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(petColor)
                        )
                }
                .opacity(isAnimating ? 1 : 0)
                .scaleEffect(isAnimating ? 1 : 0.5)
            }
            .padding()

            // Confetti particles
            ForEach(confettiParticles, id: \.id) { particle in
                ConfettiParticleView(particle: particle)
            }
        }
        .onAppear {
            startCelebration()
        }
    }

    private var petColor: Color {
        let colorIndex = petStage % colors.count
        return colors[colorIndex]
    }

    private func startCelebration() {
        // Trigger haptics
        HapticManager.shared.petLevelUp(fromStage: max(0, petStage - 1), toStage: petStage)

        // Create confetti
        generateConfetti()

        // Animate elements with careful timing
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            backgroundOpacity = 1.0
            titleScale = 1.0
        }

        withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2)) {
            petImageScale = 1.0
        }

        withAnimation(.easeInOut(duration: 2.0)) {
            isAnimating = true
        }

        // Auto-dismiss after celebration
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if isAnimating {
                dismissCelebration()
            }
        }
    }

    private func dismissCelebration() {
        withAnimation(.easeInOut(duration: 0.3)) {
            backgroundOpacity = 0.0
            titleScale = 0.1
            petImageScale = 0.1
            isAnimating = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }

    private func generateConfetti() {
        confettiParticles = (0..<50).map { _ in
            ConfettiParticle(
                color: colors.randomElement() ?? .blue,
                x: Double.random(in: 0...UIScreen.main.bounds.width),
                y: -20,
                velocityX: Double.random(in: -100...100),
                velocityY: Double.random(in: 200...400),
                rotation: Double.random(in: 0...360),
                scale: Double.random(in: 0.5...1.5)
            )
        }
    }
}

struct ConfettiParticle {
    let id = UUID()
    let color: Color
    var x: Double
    var y: Double
    var velocityX: Double
    var velocityY: Double
    var rotation: Double
    var scale: Double
}

struct ConfettiParticleView: View {
    @State private var particle: ConfettiParticle
    @State private var isAnimating = false

    init(particle: ConfettiParticle) {
        self._particle = State(initialValue: particle)
    }

    var body: some View {
        Rectangle()
            .fill(particle.color)
            .frame(width: 8 * particle.scale, height: 8 * particle.scale)
            .rotationEffect(.degrees(particle.rotation))
            .position(x: particle.x, y: particle.y)
            .onAppear {
                startAnimation()
            }
    }

    private func startAnimation() {
        withAnimation(.linear(duration: 3.0)) {
            particle.y += particle.velocityY
            particle.x += particle.velocityX
            particle.rotation += Double.random(in: 180...720)
        }

        // Fade out
        withAnimation(.easeOut(duration: 1.0).delay(2.0)) {
            isAnimating = false
        }
    }
}

// MARK: - Celebration Trigger

@available(iOS 17.0, *)
extension View {
    func celebrationOverlay(
        isPresented: Binding<Bool>,
        petStage: Int,
        stageName: String
    ) -> some View {
        self.overlay {
            if isPresented.wrappedValue {
                CelebrationView(
                    petStage: petStage,
                    stageName: stageName
                ) {
                    isPresented.wrappedValue = false
                }
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .opacity
                ))
            }
        }
    }
}