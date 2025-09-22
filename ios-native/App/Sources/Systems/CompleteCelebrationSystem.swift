import SwiftUI
import UIKit
import AVFoundation
import os.log

/// Complete Celebration System - 100% Production Implementation
/// World-class haptics, animations, and audio feedback for pet evolution
@available(iOS 17.0, *)
public final class CompleteCelebrationSystem: ObservableObject {
    public static let shared = CompleteCelebrationSystem()

    private let logger = Logger(subsystem: "com.petprogress.App", category: "Celebration")
    private let hapticManager = HapticManager.shared

    // Animation state
    @Published var showingLevelUpAnimation = false
    @Published var showingTaskCompleteAnimation = false
    @Published var currentStage = 0
    @Published var previousStage = 0

    // Audio
    private var audioPlayer: AVAudioPlayer?
    private var backgroundAudioPlayer: AVAudioPlayer?

    private init() {
        setupAudioSession()
    }

    // MARK: - Public Interface

    /// Trigger complete level-up celebration with haptics, animation, and audio
    public func triggerLevelUpCelebration(fromStage: Int, toStage: Int) {
        logger.info("Triggering level-up celebration: Stage \(fromStage) → \(toStage)")

        previousStage = fromStage
        currentStage = toStage

        // Haptic feedback sequence
        hapticManager.petLevelUp(fromStage: fromStage, toStage: toStage)

        // Audio celebration
        playLevelUpSound()

        // Visual celebration
        DispatchQueue.main.async {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6, blendDuration: 0.3)) {
                self.showingLevelUpAnimation = true
            }

            // Auto-dismiss after celebration
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.easeOut(duration: 0.5)) {
                    self.showingLevelUpAnimation = false
                }
            }
        }
    }

    /// Trigger task completion micro-celebration
    public func triggerTaskCompleteCelebration() {
        logger.info("Triggering task completion celebration")

        // Subtle haptic
        hapticManager.taskCompleted()

        // Brief visual feedback
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.4)) {
                self.showingTaskCompleteAnimation = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.easeOut(duration: 0.3)) {
                    self.showingTaskCompleteAnimation = false
                }
            }
        }

        // Subtle completion sound
        playTaskCompleteSound()
    }

    /// Trigger de-evolution feedback
    public func triggerDeEvolutionFeedback(fromStage: Int, toStage: Int) {
        logger.info("Triggering de-evolution feedback: Stage \(fromStage) → \(toStage)")

        previousStage = fromStage
        currentStage = toStage

        // Distinct haptic pattern for de-evolution
        hapticManager.petDeEvolution()

        // Subdued audio
        playDeEvolutionSound()
    }

    // MARK: - Audio System

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            logger.error("Failed to setup audio session: \(error.localizedDescription)")
        }
    }

    private func playLevelUpSound() {
        guard let url = Bundle.main.url(forResource: "levelup", withExtension: "mp3") else {
            logger.warning("Level-up sound file not found, using system sound")
            playSystemLevelUpSound()
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.volume = 0.8
            audioPlayer?.play()
        } catch {
            logger.error("Failed to play level-up sound: \(error.localizedDescription)")
            playSystemLevelUpSound()
        }
    }

    private func playTaskCompleteSound() {
        guard let url = Bundle.main.url(forResource: "task_complete", withExtension: "mp3") else {
            // Use system sound as fallback
            AudioServicesPlaySystemSound(1057) // SMS received sound
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.volume = 0.6
            audioPlayer?.play()
        } catch {
            AudioServicesPlaySystemSound(1057)
        }
    }

    private func playDeEvolutionSound() {
        guard let url = Bundle.main.url(forResource: "de_evolution", withExtension: "mp3") else {
            // Use system sound as fallback
            AudioServicesPlaySystemSound(1053) // SMS sent sound (more subdued)
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.volume = 0.5
            audioPlayer?.play()
        } catch {
            AudioServicesPlaySystemSound(1053)
        }
    }

    private func playSystemLevelUpSound() {
        // Use iOS system sound as fallback
        AudioServicesPlaySystemSound(1026) // SMS received tone 1
    }
}

// MARK: - Enhanced Haptic Manager

@available(iOS 17.0, *)
public final class HapticManager: ObservableObject {
    public static let shared = HapticManager()

    private let logger = Logger(subsystem: "com.petprogress.App", category: "Haptics")

    // Haptic generators
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let notification = UINotificationFeedbackGenerator()
    private let selection = UISelectionFeedbackGenerator()

    @Published public var isHapticsEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(isHapticsEnabled, forKey: "haptics_enabled")
        }
    }

    public var isHapticsAvailable: Bool {
        return UIDevice.current.userInterfaceIdiom == .phone
    }

    private init() {
        isHapticsEnabled = UserDefaults.standard.bool(forKey: "haptics_enabled")
        if UserDefaults.standard.object(forKey: "haptics_enabled") == nil {
            isHapticsEnabled = true // Default enabled
        }

        // Prepare haptic generators
        prepareHaptics()
    }

    // MARK: - Public Interface

    public func setHapticsEnabled(_ enabled: Bool) {
        isHapticsEnabled = enabled
        logger.info("Haptics \(enabled ? "enabled" : "disabled")")
    }

    /// Task completion haptic - medium impact
    public func taskCompleted() {
        guard isHapticsEnabled && isHapticsAvailable else { return }

        impactMedium.impactOccurred()
        logger.debug("Task completion haptic triggered")
    }

    /// Task skipped haptic - light impact
    public func taskSkipped() {
        guard isHapticsEnabled && isHapticsAvailable else { return }

        impactLight.impactOccurred()
        logger.debug("Task skipped haptic triggered")
    }

    /// Navigation haptic - selection feedback
    public func taskNavigation() {
        guard isHapticsEnabled && isHapticsAvailable else { return }

        selection.selectionChanged()
        logger.debug("Navigation haptic triggered")
    }

    /// Pet level-up celebration - complex sequence
    public func petLevelUp(fromStage: Int, toStage: Int) {
        guard isHapticsEnabled && isHapticsAvailable else { return }

        logger.info("Level-up haptic sequence: \(fromStage) → \(toStage)")

        // Success notification
        notification.notificationOccurred(.success)

        // Celebration sequence
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.impactMedium.impactOccurred()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.impactHeavy.impactOccurred()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.impactMedium.impactOccurred()
        }
    }

    /// Pet de-evolution feedback - warning pattern
    public func petDeEvolution() {
        guard isHapticsEnabled && isHapticsAvailable else { return }

        logger.info("De-evolution haptic triggered")

        notification.notificationOccurred(.warning)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.impactLight.impactOccurred()
        }
    }

    /// Error haptic - notification error
    public func error() {
        guard isHapticsEnabled && isHapticsAvailable else { return }

        notification.notificationOccurred(.error)
        logger.debug("Error haptic triggered")
    }

    /// Success haptic - notification success
    public func success() {
        guard isHapticsEnabled && isHapticsAvailable else { return }

        notification.notificationOccurred(.success)
        logger.debug("Success haptic triggered")
    }

    // MARK: - Private Methods

    private func prepareHaptics() {
        guard isHapticsAvailable else { return }

        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        notification.prepare()
        selection.prepare()

        logger.debug("Haptic generators prepared")
    }
}

// MARK: - Celebration Animation Views

@available(iOS 17.0, *)
public struct LevelUpCelebrationOverlay: View {
    @ObservedObject private var celebrationSystem = CompleteCelebrationSystem.shared
    @State private var confettiOffset: CGFloat = -200
    @State private var sparkleOpacity: Double = 0
    @State private var scaleEffect: CGFloat = 0.8

    public init() {}

    public var body: some View {
        ZStack {
            if celebrationSystem.showingLevelUpAnimation {
                // Background overlay
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.3)) {
                            celebrationSystem.showingLevelUpAnimation = false
                        }
                    }

                // Celebration content
                VStack(spacing: 20) {
                    // Confetti animation
                    CompleteConfettiView()
                        .frame(height: 100)
                        .offset(y: confettiOffset)

                    // Level-up message
                    VStack(spacing: 12) {
                        Text("🎉 Level Up! 🎉")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)

                        Text("Stage \(celebrationSystem.previousStage + 1) → Stage \(celebrationSystem.currentStage + 1)")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .fontDesign(.monospaced)

                        Text("Your pet has evolved!")
                            .font(.headline)
                            .foregroundStyle(.blue)
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .scaleEffect(scaleEffect)

                    // Pet evolution visual
                    HStack(spacing: 20) {
                        VStack {
                            WidgetImageOptimizer.shared.widgetImage(for: celebrationSystem.previousStage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 60, height: 60)
                                .opacity(0.6)

                            Text("Stage \(celebrationSystem.previousStage + 1)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Image(systemName: "arrow.right")
                            .font(.title2)
                            .foregroundStyle(.blue)

                        VStack {
                            WidgetImageOptimizer.shared.widgetImage(for: celebrationSystem.currentStage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 80, height: 80)
                                .scaleEffect(scaleEffect)

                            Text("Stage \(celebrationSystem.currentStage + 1)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                .padding()
                .onAppear {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        confettiOffset = 0
                        scaleEffect = 1.0
                    }

                    withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                        sparkleOpacity = 1.0
                    }
                }
            }
        }
        .animation(.spring(response: 0.8, dampingFraction: 0.7), value: celebrationSystem.showingLevelUpAnimation)
    }
}

@available(iOS 17.0, *)
struct CompleteConfettiView: View {
    @State private var confettiItems: [ConfettiItem] = []

    var body: some View {
        ZStack {
            ForEach(confettiItems, id: \.id) { item in
                Circle()
                    .fill(item.color)
                    .frame(width: item.size, height: item.size)
                    .position(x: item.x, y: item.y)
                    .opacity(item.opacity)
            }
        }
        .onAppear {
            generateConfetti()
            animateConfetti()
        }
    }

    private func generateConfetti() {
        confettiItems = (0..<30).map { _ in
            ConfettiItem(
                id: UUID(),
                x: CGFloat.random(in: 0...300),
                y: CGFloat.random(in: -50...50),
                size: CGFloat.random(in: 4...12),
                color: [.red, .blue, .green, .yellow, .purple, .orange].randomElement() ?? .blue,
                opacity: Double.random(in: 0.6...1.0)
            )
        }
    }

    private func animateConfetti() {
        withAnimation(.easeOut(duration: 2.0)) {
            confettiItems = confettiItems.map { item in
                var newItem = item
                newItem.y += CGFloat.random(in: 200...400)
                newItem.x += CGFloat.random(in: -50...50)
                newItem.opacity = 0
                return newItem
            }
        }
    }
}

struct ConfettiItem {
    let id: UUID
    var x: CGFloat
    var y: CGFloat
    let size: CGFloat
    let color: Color
    var opacity: Double
}

@available(iOS 17.0, *)
public struct TaskCompleteCelebrationOverlay: View {
    @ObservedObject private var celebrationSystem = CompleteCelebrationSystem.shared

    public init() {}

    public var body: some View {
        ZStack {
            if celebrationSystem.showingTaskCompleteAnimation {
                VStack {
                    Spacer()

                    HStack {
                        Spacer()

                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.green)
                            .background(Circle().fill(.background).shadow(radius: 4))
                            .scaleEffect(celebrationSystem.showingTaskCompleteAnimation ? 1.2 : 0.8)

                        Spacer()
                    }

                    Spacer()
                }
                .allowsHitTesting(false)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: celebrationSystem.showingTaskCompleteAnimation)
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.1)
            .ignoresSafeArea()

        VStack {
            Button("Trigger Level Up") {
                CompleteCelebrationSystem.shared.triggerLevelUpCelebration(fromStage: 3, toStage: 4)
            }
            .buttonStyle(.borderedProminent)

            Button("Trigger Task Complete") {
                CompleteCelebrationSystem.shared.triggerTaskCompleteCelebration()
            }
            .buttonStyle(.bordered)
        }

        LevelUpCelebrationOverlay()
        TaskCompleteCelebrationOverlay()
    }
}