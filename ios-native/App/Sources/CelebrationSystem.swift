import SwiftUI
import UIKit
import AVFoundation

// MARK: - Enhanced Haptic Feedback

enum HapticFeedback {
    case success
    case warning
    case error
    case impact(UIImpactFeedbackGenerator.FeedbackStyle)

    func trigger() {
        switch self {
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        case .impact(let style):
            UIImpactFeedbackGenerator(style: style).impactOccurred()
        }
    }
}

// MARK: - Celebration System

@MainActor
final class CelebrationSystem: ObservableObject {
    static let shared = CelebrationSystem()

    @Published var isShowingCelebration = false
    @Published var celebrationType: CelebrationType = .taskComplete
    @Published var celebrationMessage = ""

    private var audioPlayer: AVAudioPlayer?
    private var hapticGenerator = UINotificationFeedbackGenerator()

    private init() {
        hapticGenerator.prepare()
    }

    // MARK: - Celebration Types

    enum CelebrationType: String, CaseIterable {
        case taskComplete = "task_complete"
        case levelUp = "level_up"
        case perfectDay = "perfect_day"
        case streak = "streak"
        case milestone = "milestone"

        var duration: TimeInterval {
            switch self {
            case .taskComplete: return 1.5
            case .levelUp: return 3.0
            case .perfectDay: return 4.0
            case .streak: return 2.5
            case .milestone: return 3.5
            }
        }

        var hapticPattern: [HapticFeedback] {
            switch self {
            case .taskComplete: return [.success]
            case .levelUp: return [.impact(.medium), .success, .impact(.heavy)]
            case .perfectDay: return [.success, .impact(.heavy), .success, .impact(.heavy), .success]
            case .streak: return [.impact(.medium), .success, .impact(.medium)]
            case .milestone: return [.impact(.heavy), .success, .impact(.heavy), .success, .impact(.heavy)]
            }
        }

        var soundFileName: String? {
            switch self {
            case .taskComplete: return "task_complete"
            case .levelUp: return "level_up"
            case .perfectDay: return "perfect_day"
            case .streak: return "streak"
            case .milestone: return "milestone"
            }
        }

        var confettiStyle: ConfettiStyle {
            switch self {
            case .taskComplete: return .gentle
            case .levelUp: return .celebration
            case .perfectDay: return .spectacular
            case .streak: return .focused
            case .milestone: return .epic
            }
        }
    }

    // MARK: - Public Interface

    func celebrate(_ type: CelebrationType, message: String = "") {
        guard !isShowingCelebration else { return }

        celebrationType = type
        celebrationMessage = message.isEmpty ? defaultMessage(for: type) : message

        // Execute celebration sequence
        Task {
            await self.performCelebration(type)
        }
    }

    func celebrateTaskCompletion(taskName: String, isOnTime: Bool = true) {
        let message = isOnTime ? "✅ \(taskName) completed!" : "⏰ \(taskName) completed late"
        celebrate(.taskComplete, message: message)
    }

    func celebrateLevelUp(newStage: Int, petName: String) {
        let message = "🎉 Level up! \(petName) reached Stage \(newStage + 1)!"
        celebrate(.levelUp, message: message)
    }

    func celebrateLevelUp(from oldStage: Int, to newStage: Int) {
        let stageNames = ["Baby", "Toddler", "Frog", "Hermit", "Seahorse", "Beaver", "Dolphin", "Wolf", "Bear", "Bison", "Elephant", "Rhino", "Alligator", "Adult", "Gold", "CEO"]
        let petName = stageNames.indices.contains(newStage) ? stageNames[newStage] : "Pet"
        let message = "🎉 Level up! Your pet evolved to \(petName)!"
        celebrate(.levelUp, message: message)
    }

    func celebratePerfectDay() {
        celebrate(.perfectDay, message: "🌟 Perfect day! All tasks completed!")
    }

    func celebrateStreak(days: Int) {
        celebrate(.streak, message: "🔥 \(days) day streak!")
    }

    func celebrateMilestone(description: String) {
        celebrate(.milestone, message: "🏆 \(description)")
    }

    // MARK: - Private Implementation

    private func defaultMessage(for type: CelebrationType) -> String {
        switch type {
        case .taskComplete: return "✅ Task completed!"
        case .levelUp: return "🎉 Level up!"
        case .perfectDay: return "🌟 Perfect day!"
        case .streak: return "🔥 Streak!"
        case .milestone: return "🏆 Milestone!"
        }
    }

    private func performCelebration(_ type: CelebrationType) async {
        // Show visual celebration
        withAnimation(.easeInOut(duration: 0.3)) {
            isShowingCelebration = true
        }

        // Play haptics
        await playHapticSequence(type.hapticPattern)

        // Play sound if available
        playSound(type.soundFileName)

        // Hide after duration
        try? await Task.sleep(nanoseconds: UInt64(type.duration * 1_000_000_000))

        withAnimation(.easeInOut(duration: 0.3)) {
            isShowingCelebration = false
        }
    }

    private func playHapticSequence(_ pattern: [HapticFeedback]) async {
        for (index, feedback) in pattern.enumerated() {
            feedback.trigger()
            if index < pattern.count - 1 {
                try? await Task.sleep(nanoseconds: 150_000_000) // 0.15 second delay
            }
        }
    }

    private func playSound(_ fileName: String?) async {
        guard let fileName = fileName,
              let url = Bundle.main.url(forResource: fileName, withExtension: "mp3") else {
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.volume = 0.7
            audioPlayer?.play()
        } catch {
            print("Failed to play celebration sound: \(error)")
        }
    }
}

// MARK: - Confetti System

enum ConfettiStyle {
    case gentle, celebration, spectacular, focused, epic

    var particleCount: Int {
        switch self {
        case .gentle: return 25
        case .celebration: return 100
        case .spectacular: return 200
        case .focused: return 50
        case .epic: return 300
        }
    }

    var colors: [Color] {
        switch self {
        case .gentle: return [.blue, .green]
        case .celebration: return [.yellow, .orange, .red, .pink]
        case .spectacular: return [.yellow, .orange, .red, .pink, .purple, .blue, .green]
        case .focused: return [.orange, .yellow]
        case .epic: return [.yellow, .orange, .red, .pink, .purple, .blue, .green, .mint, .cyan]
        }
    }

    var fallDuration: TimeInterval {
        switch self {
        case .gentle: return 2.0
        case .celebration: return 3.0
        case .spectacular: return 4.0
        case .focused: return 2.5
        case .epic: return 5.0
        }
    }
}

struct ConfettiView: View {
    let style: ConfettiStyle
    @State private var animate = false
    @State private var particles: [ConfettiParticle] = []

    var body: some View {
        ZStack {
            ForEach(particles.indices, id: \.self) { index in
                Circle()
                    .fill(particles[index].color)
                    .frame(width: particles[index].size, height: particles[index].size)
                    .position(
                        x: animate ? particles[index].endX : particles[index].startX,
                        y: animate ? particles[index].endY : particles[index].startY
                    )
                    .rotationEffect(.degrees(animate ? particles[index].endRotation : 0))
                    .opacity(animate ? 0 : 1)
            }
        }
        .onAppear {
            generateParticles()
            withAnimation(.easeInOut(duration: style.fallDuration)) {
                animate = true
            }
        }
    }

    private func generateParticles() {
        particles = (0..<style.particleCount).map { _ in
            ConfettiParticle(
                color: style.colors.randomElement() ?? .yellow,
                size: Double.random(in: 4...12),
                startX: Double.random(in: 0...400),
                startY: -50,
                endX: Double.random(in: 0...400),
                endY: 900,
                endRotation: Double.random(in: 0...720)
            )
        }
    }
}

struct ConfettiParticle {
    let color: Color
    let size: Double
    let startX: Double
    let startY: Double
    let endX: Double
    let endY: Double
    let endRotation: Double
}

// MARK: - Celebration Overlay View

struct CelebrationOverlay: View {
    @StateObject private var celebrationSystem = CelebrationSystem.shared

    var body: some View {
        ZStack {
            if celebrationSystem.isShowingCelebration {
                // Background overlay
                Color.black.opacity(0.1)
                    .ignoresSafeArea()

                // Confetti
                ConfettiView(style: celebrationSystem.celebrationType.confettiStyle)
                    .allowsHitTesting(false)

                // Message
                VStack {
                    Spacer()

                    Text(celebrationSystem.celebrationMessage)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                        .shadow(radius: 10)
                        .scaleEffect(celebrationSystem.isShowingCelebration ? 1.0 : 0.8)
                        .opacity(celebrationSystem.isShowingCelebration ? 1.0 : 0.0)

                    Spacer()
                        .frame(height: 100)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - SwiftUI View Extension

extension View {
    func withCelebrations() -> some View {
        self.overlay(CelebrationOverlay())
    }
}