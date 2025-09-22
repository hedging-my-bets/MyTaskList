import SwiftUI

/// Cinematic animation components for award-winning user experience
@available(iOS 17.0, *)

// MARK: - Sparkle Effect View

struct SparkleEffectView: View {
    @State private var sparkles: [SparkleParticle] = []
    @State private var animationTimer: Timer?

    var body: some View {
        ZStack {
            ForEach(sparkles, id: \.id) { sparkle in
                SparkleParticleView(sparkle: sparkle)
            }
        }
        .onAppear {
            generateSparkles()
            startAnimation()
        }
        .onDisappear {
            animationTimer?.invalidate()
        }
    }

    private func generateSparkles() {
        sparkles = (0..<12).map { index in
            SparkleParticle(
                id: index,
                position: CGPoint(
                    x: Double.random(in: -100...100),
                    y: Double.random(in: -100...100)
                ),
                scale: Double.random(in: 0.3...1.0),
                rotation: Double.random(in: 0...360),
                opacity: Double.random(in: 0.4...1.0),
                color: [.yellow, .orange, .pink, .blue, .purple].randomElement() ?? .yellow,
                animationDelay: Double.random(in: 0...0.5)
            )
        }
    }

    private func startAnimation() {
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            updateSparkles()
        }
    }

    private func updateSparkles() {
        for index in sparkles.indices {
            sparkles[index].update()
        }
    }
}

// MARK: - Sparkle Particle

struct SparkleParticle {
    let id: Int
    var position: CGPoint
    var scale: Double
    var rotation: Double
    var opacity: Double
    let color: Color
    let animationDelay: Double

    private var velocity: CGPoint = CGPoint(
        x: Double.random(in: -2...2),
        y: Double.random(in: -3...1)
    )
    private var rotationSpeed: Double = Double.random(in: 2...8)
    private var scaleSpeed: Double = Double.random(in: 0.02...0.05)
    private var life: Double = 1.0

    init(id: Int, position: CGPoint, scale: Double, rotation: Double, opacity: Double, color: Color, animationDelay: Double) {
        self.id = id
        self.position = position
        self.scale = scale
        self.rotation = rotation
        self.opacity = opacity
        self.color = color
        self.animationDelay = animationDelay
    }

    mutating func update() {
        position.x += velocity.x
        position.y += velocity.y
        rotation += rotationSpeed
        scale -= scaleSpeed
        opacity = life * 0.8
        life -= 0.02

        // Add some physics
        velocity.y += 0.1 // Gravity
        velocity.x *= 0.98 // Air resistance
    }

    var isAlive: Bool {
        life > 0 && scale > 0
    }
}

struct SparkleParticleView: View {
    let sparkle: SparkleParticle

    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: 12))
            .foregroundStyle(sparkle.color)
            .scaleEffect(sparkle.scale)
            .rotationEffect(.degrees(sparkle.rotation))
            .opacity(sparkle.opacity)
            .offset(x: sparkle.position.x, y: sparkle.position.y)
            .animation(.none, value: sparkle.position)
    }
}

// MARK: - Floating Action Button

@available(iOS 17.0, *)
struct FloatingActionButton: View {
    let icon: String
    let action: () -> Void
    let color: Color

    @State private var isPressed = false
    @State private var showPulse = false

    var body: some View {
        Button(action: handleAction) {
            ZStack {
                // Pulse effect
                Circle()
                    .fill(color.opacity(0.3))
                    .scaleEffect(showPulse ? 1.8 : 1.0)
                    .opacity(showPulse ? 0 : 0.7)
                    .animation(.easeOut(duration: 1.0), value: showPulse)

                // Main button
                Circle()
                    .fill(color)
                    .frame(width: 56, height: 56)
                    .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
                    .overlay(
                        Image(systemName: icon)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                    )
            }
        }
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }

    private func handleAction() {
        // Trigger pulse
        showPulse = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            showPulse = false
        }

        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

        action()
    }
}

// MARK: - Morphing Background

@available(iOS 17.0, *)
struct MorphingBackground: View {
    @State private var phase: Double = 0

    let colors: [Color] = [
        .blue.opacity(0.1),
        .purple.opacity(0.1),
        .pink.opacity(0.1),
        .orange.opacity(0.1)
    ]

    var body: some View {
        ZStack {
            ForEach(0..<colors.count, id: \.self) { index in
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [colors[index], Color.clear]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 300
                        )
                    )
                    .frame(width: 600, height: 600)
                    .offset(
                        x: cos(phase + Double(index) * .pi / 2) * 100,
                        y: sin(phase + Double(index) * .pi / 2) * 100
                    )
                    .opacity(0.3 + 0.2 * sin(phase + Double(index)))
            }
        }
        .blur(radius: 20)
        .onAppear {
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                phase = .pi * 4
            }
        }
    }
}

// MARK: - Progress Ring

@available(iOS 17.0, *)
struct ProgressRing: View {
    let progress: Double
    let lineWidth: CGFloat
    let size: CGFloat
    let color: Color

    @State private var animatedProgress: Double = 0

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
                .frame(width: size, height: size)

            // Progress ring
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [color.opacity(0.8), color]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))

            // Animated end cap
            if animatedProgress > 0 {
                Circle()
                    .fill(color)
                    .frame(width: lineWidth * 0.8, height: lineWidth * 0.8)
                    .offset(x: size / 2)
                    .rotationEffect(.degrees(360 * animatedProgress - 90))
                    .shadow(color: color.opacity(0.5), radius: 2)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 1.2, dampingFraction: 0.8)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { oldValue, newValue in
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                animatedProgress = newValue
            }
        }
    }
}

// MARK: - Bouncy Button

@available(iOS 17.0, *)
struct BouncyButton<Content: View>: View {
    let content: Content
    let action: () -> Void

    @State private var isPressed = false

    init(action: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.action = action
        self.content = content()
    }

    var body: some View {
        Button(action: handleAction) {
            content
        }
        .scaleEffect(isPressed ? 0.92 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }

    private func handleAction() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()

        action()
    }
}

// MARK: - Shimmer Effect

@available(iOS 17.0, *)
struct ShimmerEffect: View {
    @State private var shimmerOffset: CGFloat = -1

    let gradient = LinearGradient(
        gradient: Gradient(colors: [
            Color.clear,
            Color.white.opacity(0.6),
            Color.clear
        ]),
        startPoint: .leading,
        endPoint: .trailing
    )

    var body: some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(gradient)
                .offset(x: shimmerOffset * geometry.size.width)
                .onAppear {
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        shimmerOffset = 1
                    }
                }
        }
        .clipped()
    }
}

// MARK: - Pulse Effect

@available(iOS 17.0, *)
struct PulseEffect: View {
    let color: Color
    let size: CGFloat

    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 1.0

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .scaleEffect(pulseScale)
            .opacity(pulseOpacity)
            .onAppear {
                withAnimation(.easeOut(duration: 1.0).repeatForever(autoreverses: false)) {
                    pulseScale = 1.5
                    pulseOpacity = 0
                }
            }
    }
}

// MARK: - Typewriter Text

@available(iOS 17.0, *)
struct TypewriterText: View {
    let text: String
    let font: Font
    let speed: Double // Characters per second

    @State private var displayedText = ""
    @State private var currentIndex = 0

    var body: some View {
        Text(displayedText)
            .font(font)
            .onAppear {
                startTypewriting()
            }
    }

    private func startTypewriting() {
        displayedText = ""
        currentIndex = 0

        Timer.scheduledTimer(withTimeInterval: 1.0 / speed, repeats: true) { timer in
            if currentIndex < text.count {
                let index = text.index(text.startIndex, offsetBy: currentIndex)
                displayedText += String(text[index])
                currentIndex += 1
            } else {
                timer.invalidate()
            }
        }
    }
}

// MARK: - Floating Hearts

@available(iOS 17.0, *)
struct FloatingHeart: View {
    @State private var yOffset: CGFloat = 0
    @State private var opacity: Double = 1.0
    @State private var scale: Double = 1.0

    var body: some View {
        Image(systemName: "heart.fill")
            .font(.title2)
            .foregroundStyle(.pink)
            .scaleEffect(scale)
            .opacity(opacity)
            .offset(y: yOffset)
            .onAppear {
                withAnimation(.easeOut(duration: 2.0)) {
                    yOffset = -100
                    opacity = 0
                    scale = 1.5
                }
            }
    }
}

// MARK: - Gradient Text

@available(iOS 17.0, *)
struct GradientText: View {
    let text: String
    let font: Font
    let gradient: LinearGradient

    var body: some View {
        Text(text)
            .font(font)
            .foregroundStyle(gradient)
    }
}

// MARK: - 3D Card Effect

@available(iOS 17.0, *)
struct Card3DEffect<Content: View>: View {
    let content: Content

    @State private var rotationX: Double = 0
    @State private var rotationY: Double = 0

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .rotation3DEffect(
                .degrees(rotationX),
                axis: (x: 1, y: 0, z: 0)
            )
            .rotation3DEffect(
                .degrees(rotationY),
                axis: (x: 0, y: 1, z: 0)
            )
            .gesture(
                DragGesture()
                    .onChanged { value in
                        rotationY = value.translation.width / 10
                        rotationX = -value.translation.height / 10
                    }
                    .onEnded { _ in
                        withAnimation(.spring()) {
                            rotationX = 0
                            rotationY = 0
                        }
                    }
            )
    }
}

// MARK: - Loading Dots

@available(iOS 17.0, *)
struct LoadingDots: View {
    @State private var animationOffset: CGFloat = 0

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(.secondary)
                    .frame(width: 8, height: 8)
                    .offset(y: animationOffset)
                    .animation(
                        .easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: animationOffset
                    )
            }
        }
        .onAppear {
            animationOffset = -10
        }
    }
}

// MARK: - Glowing Border

@available(iOS 17.0, *)
struct GlowingBorder: ViewModifier {
    let color: Color
    let intensity: Double

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color, lineWidth: 1)
                    .blur(radius: intensity)
                    .opacity(0.8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color, lineWidth: 1)
            )
    }
}

extension View {
    func glowingBorder(color: Color, intensity: Double = 2.0) -> some View {
        modifier(GlowingBorder(color: color, intensity: intensity))
    }
}

// MARK: - Wave Animation

@available(iOS 17.0, *)
struct WaveAnimation: View {
    @State private var waveOffset: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                let wavelength = width / 2

                path.move(to: CGPoint(x: 0, y: height / 2))

                for x in stride(from: 0, through: width, by: 1) {
                    let relativeX = x / wavelength
                    let sine = sin(relativeX * .pi + waveOffset)
                    let y = height / 2 + sine * 20
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            .stroke(.blue.opacity(0.7), lineWidth: 3)
            .onAppear {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    waveOffset = .pi * 2
                }
            }
        }
    }
}
