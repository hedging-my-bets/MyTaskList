import UIKit
import AVFoundation
import os.log

/// Enterprise-grade haptic feedback system with Steve Jobs-level attention to detail
/// Designed for iOS 17+ with precise haptic patterns for task completion and pet evolution
@available(iOS 17.0, *)
public final class HapticManager {
    public static let shared = HapticManager()

    private let logger = Logger(subsystem: "com.petprogress.Haptics", category: "Feedback")

    // Haptic generators - prepared for zero-latency feedback
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let notification = UINotificationFeedbackGenerator()
    private let selection = UISelectionFeedbackGenerator()

    // Haptics enabled state
    private var _hapticsEnabled: Bool = true

    private init() {
        // Prepare all generators for instant response
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        notification.prepare()
        selection.prepare()

        logger.debug("HapticManager initialized with all generators prepared")
    }

    // MARK: - Task Completion Haptics

    /// Task completed successfully - satisfying success haptic
    public func taskCompleted() {
        guard isHapticsEnabled else { return }
        DispatchQueue.main.async { [weak self] in
            self?.notification.notificationOccurred(.success)
            self?.logger.debug("Task completion haptic triggered")
        }
    }

    /// Task skipped - subtle neutral feedback
    public func taskSkipped() {
        guard isHapticsEnabled else { return }
        DispatchQueue.main.async { [weak self] in
            self?.impactLight.impactOccurred()
            self?.logger.debug("Task skip haptic triggered")
        }
    }

    /// Task navigation - crisp selection feedback
    public func taskNavigation() {
        guard isHapticsEnabled else { return }
        DispatchQueue.main.async { [weak self] in
            self?.selection.selectionChanged()
            self?.logger.debug("Task navigation haptic triggered")
        }
    }

    // MARK: - Pet Evolution Haptics

    /// Pet level up - celebratory sequence
    public func petLevelUp(fromStage: Int, toStage: Int) {
        guard isHapticsEnabled else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // Major milestone haptic sequence
            if toStage >= 15 { // CEO level
                self.levelUpCEO()
            } else if toStage >= 10 { // Gold tier
                self.levelUpGold()
            } else if toStage >= 5 { // Mid tier
                self.levelUpMajor()
            } else {
                self.levelUpStandard()
            }

            self.logger.info("Pet level up haptic: stage \(fromStage) -> \(toStage)")
        }
    }

    /// Pet de-evolution - gentle disappointment
    public func petDeEvolution() {
        guard isHapticsEnabled else { return }
        DispatchQueue.main.async { [weak self] in
            self?.notification.notificationOccurred(.warning)
            self?.logger.debug("Pet de-evolution haptic triggered")
        }
    }

    /// Generic level up haptic - simplified version for general use
    public func levelUp() {
        guard isHapticsEnabled else { return }
        DispatchQueue.main.async { [weak self] in
            self?.levelUpStandard()
            self?.logger.debug("Generic level up haptic triggered")
        }
    }

    // MARK: - Level Up Sequences

    private func levelUpStandard() {
        // Simple success haptic
        notification.notificationOccurred(.success)
    }

    private func levelUpMajor() {
        // Success + medium impact
        notification.notificationOccurred(.success)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.impactMedium.impactOccurred()
        }
    }

    private func levelUpGold() {
        // Success + double impact for gold tier
        notification.notificationOccurred(.success)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.impactMedium.impactOccurred()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.impactHeavy.impactOccurred()
        }
    }

    private func levelUpCEO() {
        // Maximum celebration sequence for CEO achievement
        notification.notificationOccurred(.success)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.impactMedium.impactOccurred()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.impactHeavy.impactOccurred()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.impactHeavy.impactOccurred()
        }
    }

    // MARK: - Widget Haptics

    /// Widget interaction feedback
    public func widgetInteraction() {
        guard isHapticsEnabled else { return }
        DispatchQueue.main.async { [weak self] in
            self?.impactLight.impactOccurred()
            self?.logger.debug("Widget interaction haptic triggered")
        }
    }

    // MARK: - Settings Haptics

    /// Settings changed feedback
    public func settingsChanged() {
        guard isHapticsEnabled else { return }
        DispatchQueue.main.async { [weak self] in
            self?.impactLight.impactOccurred()
            self?.logger.debug("Settings change haptic triggered")
        }
    }

    /// Error or warning feedback
    public func error() {
        guard isHapticsEnabled else { return }
        DispatchQueue.main.async { [weak self] in
            self?.notification.notificationOccurred(.error)
            self?.logger.debug("Error haptic triggered")
        }
    }

    // MARK: - Audio Integration

    /// Play system sound for major celebrations (optional)
    public func playLevelUpSound() {
        DispatchQueue.main.async { [weak self] in
            // Use system sound for celebration
            AudioServicesPlaySystemSound(1057) // SMS tone
            self?.logger.debug("Level up sound played")
        }
    }

    // MARK: - Utility

    /// Prepare generators for upcoming interactions
    public func prepareForInteraction() {
        impactLight.prepare()
        impactMedium.prepare()
        notification.prepare()
        selection.prepare()
    }

    /// Check if haptics are available on device
    public var isHapticsAvailable: Bool {
        return UIDevice.current.userInterfaceIdiom == .phone
    }

    /// Check if haptics are enabled by user
    public var isHapticsEnabled: Bool {
        return _hapticsEnabled && isHapticsAvailable
    }

    /// Enable or disable haptics
    public func setHapticsEnabled(_ enabled: Bool) {
        _hapticsEnabled = enabled
        logger.info("Haptics \(enabled ? "enabled" : "disabled")")
    }
}

#if canImport(SwiftUI)
import SwiftUI

// MARK: - SwiftUI Integration

@available(iOS 17.0, *)
public extension View {
    /// Add haptic feedback to any view tap
    func onTapHaptic(_ hapticType: HapticType = .light) -> some View {
        self.onTapGesture {
            switch hapticType {
            case .light:
                HapticManager.shared.widgetInteraction()
            case .success:
                HapticManager.shared.taskCompleted()
            case .selection:
                HapticManager.shared.taskNavigation()
            case .error:
                HapticManager.shared.error()
            }
        }
    }
}
#endif

@available(iOS 17.0, *)
public enum HapticType {
    case light
    case success
    case selection
    case error
}