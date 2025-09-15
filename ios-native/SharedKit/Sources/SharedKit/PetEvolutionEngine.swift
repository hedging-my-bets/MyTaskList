import Foundation
import os.log
import Combine

/// Disney-grade pet evolution system with emotional storytelling, behavioral analytics, and adaptive learning
@available(iOS 17.0, *)
public final class PetEvolutionEngine: ObservableObject {

    // MARK: - Configuration & Analytics

    public let config: StageConfig
    private let logger = Logger(subsystem: "com.petprogress.PetEvolutionEngine", category: "Evolution")
    private let analyticsLogger = Logger(subsystem: "com.petprogress.PetEvolutionEngine", category: "Analytics")

    // Evolution analytics and telemetry
    private var evolutionEvents: [EvolutionEvent] = []
    private var behaviorMetrics: BehaviorMetrics = BehaviorMetrics()
    private let maxEventHistory = 1000

    // Emotional state tracking
    @Published public private(set) var currentEmotionalState: EmotionalState = .neutral
    @Published public private(set) var petPersonality: PetPersonality = PetPersonality()

    // Performance monitoring
    private let performanceLogger = Logger(subsystem: "com.petprogress.PetEvolutionEngine", category: "Performance")
    private var calculationCount = 0
    private var totalCalculationTime: TimeInterval = 0

    // MARK: - Initialization

    public init(config: StageConfig = .defaultConfig()) {
        self.config = config
        logger.info("PetEvolutionEngine initialized with \(config.stages.count) stages")

        // Load existing personality and metrics if available
        loadPersonalityProfile()
        loadBehaviorMetrics()
    }

    // MARK: - Core Evolution Logic

    /// Returns the stage index with advanced progression analysis
    /// - Parameters:
    ///   - points: Current points
    ///   - considerPersonality: Whether to factor in personality traits for stage determination
    ///   - recordAnalytics: Whether to record this calculation for behavioral learning
    /// - Returns: Stage index with personality-influenced adjustments
    public func stageIndex(for points: Int, considerPersonality: Bool = true, recordAnalytics: Bool = true) -> Int {
        let startTime = CFAbsoluteTimeGetCurrent()

        defer {
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            recordPerformanceMetric(operation: "stageIndex", duration: duration)
        }

        let clampedPoints = clamped(points)
        logger.debug("Calculating stage for \(clampedPoints) points")

        // Base stage calculation using binary search for performance
        let baseStage = calculateBaseStageIndex(for: clampedPoints)

        // Apply personality-based adjustments if enabled
        let adjustedStage = considerPersonality ?
            applyPersonalityAdjustments(baseStage: baseStage, points: clampedPoints) :
            baseStage

        // Record analytics for behavioral learning
        if recordAnalytics {
            recordEvolutionCalculation(points: clampedPoints, baseStage: baseStage, adjustedStage: adjustedStage)
        }

        // Update emotional state based on progression
        updateEmotionalState(previousPoints: behaviorMetrics.lastKnownPoints, currentPoints: clampedPoints, stage: adjustedStage)

        behaviorMetrics.lastKnownPoints = clampedPoints
        logger.debug("Stage calculated: \(adjustedStage) (base: \(baseStage))")

        return adjustedStage
    }

    /// Returns the image name with emotional state consideration
    /// - Parameters:
    ///   - points: Current points
    ///   - includeEmotionalVariant: Whether to include emotional state in image selection
    /// - Returns: Image name, potentially with emotional variant
    public func imageName(for points: Int, includeEmotionalVariant: Bool = true) -> String {
        let stage = stageIndex(for: points)
        let baseName = AssetPipeline.shared.imageName(for: stage)

        if includeEmotionalVariant && currentEmotionalState != .neutral {
            let emotionalVariant = "\(baseName)_\(currentEmotionalState.rawValue)"

            // Check if emotional variant exists, fallback to base if not
            if AssetPipeline.shared.hasAsset(named: emotionalVariant) {
                logger.debug("Using emotional variant: \(emotionalVariant)")
                return emotionalVariant
            }
        }

        return baseName
    }

    /// Advanced point clamping with regression analysis
    /// - Parameters:
    ///   - points: Raw points value
    ///   - allowTemporaryNegative: Whether to allow temporary negative values for regression analysis
    /// - Returns: Clamped points with behavioral considerations
    public func clamped(_ points: Int, allowTemporaryNegative: Bool = false) -> Int {
        if allowTemporaryNegative && points < 0 && points > -50 {
            // Allow small negative values for regression analysis
            logger.debug("Allowing temporary negative points for regression: \(points)")
            return points
        }

        let clampedValue = max(0, points)

        if clampedValue != points {
            logger.info("Points clamped from \(points) to \(clampedValue)")
            recordRegressionEvent(originalPoints: points, clampedPoints: clampedValue)
        }

        return clampedValue
    }

    // MARK: - Advanced Analytics & Behavior

    /// Comprehensive evolution analysis for the current pet state
    /// - Parameters:
    ///   - points: Current points
    ///   - includePredictions: Whether to include future evolution predictions
    /// - Returns: Detailed analysis of pet's evolutionary state
    public func analyzeEvolutionState(for points: Int, includePredictions: Bool = true) -> EvolutionAnalysis {
        let currentStage = stageIndex(for: points, recordAnalytics: false)
        let progressInCurrentStage = calculateProgressInCurrentStage(points: points, stage: currentStage)

        let analysis = EvolutionAnalysis(
            currentPoints: points,
            currentStage: currentStage,
            stageName: config.stages[safe: currentStage]?.name ?? "Unknown",
            progressInStage: progressInCurrentStage,
            emotionalState: currentEmotionalState,
            personality: petPersonality,
            recentEvolutionTrend: calculateEvolutionTrend(),
            timeSpentInCurrentStage: calculateTimeInCurrentStage(),
            predictedNextEvolution: includePredictions ? predictNextEvolution(currentPoints: points) : nil,
            behaviorInsights: generateBehaviorInsights(),
            milestoneAchievements: calculateMilestoneAchievements(points: points)
        )

        logger.info("Generated evolution analysis: Stage \(currentStage), Progress: \(progressInCurrentStage * 100, specifier: "%.1f")%")
        return analysis
    }

    /// Records a significant evolution event for analytics
    /// - Parameters:
    ///   - type: Type of evolution event
    ///   - fromStage: Previous stage (optional)
    ///   - toStage: New stage (optional)
    ///   - context: Additional context about the event
    public func recordEvolutionEvent(_ type: EvolutionEventType, fromStage: Int? = nil, toStage: Int? = nil, context: [String: Any] = [:]) {
        let event = EvolutionEvent(
            timestamp: Date(),
            type: type,
            fromStage: fromStage,
            toStage: toStage,
            context: context,
            emotionalStateAtTime: currentEmotionalState,
            personalitySnapshot: petPersonality
        )

        evolutionEvents.append(event)

        // Maintain event history limit
        if evolutionEvents.count > maxEventHistory {
            evolutionEvents.removeFirst(evolutionEvents.count - maxEventHistory)
        }

        analyticsLogger.info("Recorded evolution event: \(type.rawValue)")

        // Update behavior metrics based on the event
        updateBehaviorMetrics(for: event)
    }

    // MARK: - Personality & Emotional System

    /// Pet's emotional states
    public enum EmotionalState: String, CaseIterable {
        case ecstatic = "ecstatic"
        case happy = "happy"
        case content = "content"
        case neutral = "neutral"
        case worried = "worried"
        case sad = "sad"
        case frustrated = "frustrated"

        var multiplier: Double {
            switch self {
            case .ecstatic: return 1.2
            case .happy: return 1.1
            case .content: return 1.05
            case .neutral: return 1.0
            case .worried: return 0.95
            case .sad: return 0.9
            case .frustrated: return 0.85
            }
        }
    }

    /// Pet's personality traits
    public struct PetPersonality: Codable {
        public var optimism: Double = 0.5      // 0.0 (pessimistic) to 1.0 (optimistic)
        public var patience: Double = 0.5      // 0.0 (impatient) to 1.0 (very patient)
        public var resilience: Double = 0.5    // 0.0 (fragile) to 1.0 (very resilient)
        public var curiosity: Double = 0.5     // 0.0 (uninterested) to 1.0 (very curious)
        public var determination: Double = 0.5 // 0.0 (gives up easily) to 1.0 (never gives up)

        public init() {}

        /// Calculates overall personality happiness factor
        public var happinessFactor: Double {
            (optimism + patience + resilience + curiosity + determination) / 5.0
        }

        /// Determines if personality tends toward positive emotions
        public var tendsPositive: Bool {
            happinessFactor > 0.6
        }
    }

    /// Evolution event types for analytics
    public enum EvolutionEventType: String, CaseIterable {
        case stageProgression = "stage_progression"
        case stageRegression = "stage_regression"
        case emotionalStateChange = "emotional_state_change"
        case milestoneAchieved = "milestone_achieved"
        case personalityShift = "personality_shift"
        case longTermStagnation = "long_term_stagnation"
        case rapidProgression = "rapid_progression"
        case recoveryFromRegression = "recovery_from_regression"
    }

    /// Comprehensive evolution analysis result
    public struct EvolutionAnalysis {
        public let currentPoints: Int
        public let currentStage: Int
        public let stageName: String
        public let progressInStage: Double // 0.0 to 1.0
        public let emotionalState: EmotionalState
        public let personality: PetPersonality
        public let recentEvolutionTrend: EvolutionTrend
        public let timeSpentInCurrentStage: TimeInterval
        public let predictedNextEvolution: EvolutionPrediction?
        public let behaviorInsights: [BehaviorInsight]
        public let milestoneAchievements: [MilestoneAchievement]
    }

    /// Evolution trend analysis
    public enum EvolutionTrend: String {
        case rapidProgress = "rapid_progress"
        case steadyProgress = "steady_progress"
        case slowProgress = "slow_progress"
        case stagnant = "stagnant"
        case regressing = "regressing"
        case recovering = "recovering"
    }

    /// Future evolution prediction
    public struct EvolutionPrediction {
        public let predictedStageIn24Hours: Int
        public let predictedStageInWeek: Int
        public let confidence: Double // 0.0 to 1.0
        public let factorsInfluencing: [String]
    }

    /// Behavioral insights from analytics
    public struct BehaviorInsight {
        public let type: InsightType
        public let title: String
        public let description: String
        public let actionable: Bool
        public let confidence: Double

        public enum InsightType {
            case motivational
            case warning
            case celebratory
            case informational
        }
    }

    /// Milestone achievements
    public struct MilestoneAchievement {
        public let id: String
        public let title: String
        public let description: String
        public let achievedAt: Date
        public let significance: Significance

        public enum Significance {
            case minor
            case major
            case epic
        }
    }

    // MARK: - Private Implementation

    private func calculateBaseStageIndex(for points: Int) -> Int {
        // Binary search for optimal performance with large stage counts
        var left = 0
        var right = config.stages.count - 1

        while left <= right {
            let mid = (left + right) / 2
            let stage = config.stages[mid]

            if points >= stage.threshold {
                if mid == config.stages.count - 1 || points < config.stages[mid + 1].threshold {
                    return mid
                }
                left = mid + 1
            } else {
                right = mid - 1
            }
        }

        return 0 // Fallback to first stage
    }

    private func applyPersonalityAdjustments(baseStage: Int, points: Int) -> Int {
        // Apply small adjustments based on personality traits
        var adjustmentFactor = 1.0

        // Optimistic pets might "feel" like they're at a slightly higher stage
        if petPersonality.optimism > 0.7 {
            adjustmentFactor += 0.05
        }

        // Resilient pets recover faster from setbacks
        if currentEmotionalState == .sad || currentEmotionalState == .frustrated {
            adjustmentFactor += petPersonality.resilience * 0.1
        }

        // Apply adjustment (small, for emotional flavor only)
        let adjustedPoints = Int(Double(points) * adjustmentFactor)

        // Recalculate with adjusted points, but limit to ±1 stage difference
        let adjustedStage = calculateBaseStageIndex(for: adjustedPoints)
        return max(baseStage - 1, min(baseStage + 1, adjustedStage))
    }

    private func updateEmotionalState(previousPoints: Int, currentPoints: Int, stage: Int) {
        let pointsDifference = currentPoints - previousPoints

        let newState: EmotionalState

        if pointsDifference > 20 {
            newState = .ecstatic
        } else if pointsDifference > 10 {
            newState = .happy
        } else if pointsDifference > 0 {
            newState = .content
        } else if pointsDifference == 0 {
            newState = .neutral
        } else if pointsDifference > -10 {
            newState = .worried
        } else if pointsDifference > -20 {
            newState = .sad
        } else {
            newState = .frustrated
        }

        if newState != currentEmotionalState {
            let previousState = currentEmotionalState
            currentEmotionalState = newState

            recordEvolutionEvent(.emotionalStateChange, context: [
                "previousState": previousState.rawValue,
                "newState": newState.rawValue,
                "pointsDifference": pointsDifference
            ])

            logger.info("Emotional state changed: \(previousState.rawValue) → \(newState.rawValue)")
        }
    }

    private func recordEvolutionCalculation(points: Int, baseStage: Int, adjustedStage: Int) {
        behaviorMetrics.totalCalculations += 1
        behaviorMetrics.lastCalculationTime = Date()

        if baseStage != adjustedStage {
            behaviorMetrics.personalityAdjustments += 1
        }
    }

    private func recordRegressionEvent(originalPoints: Int, clampedPoints: Int) {
        recordEvolutionEvent(.stageRegression, context: [
            "originalPoints": originalPoints,
            "clampedPoints": clampedPoints,
            "regressionAmount": originalPoints - clampedPoints
        ])

        behaviorMetrics.regressionEvents += 1
    }

    private func calculateProgressInCurrentStage(points: Int, stage: Int) -> Double {
        guard stage < config.stages.count - 1 else {
            return 1.0 // At final stage
        }

        let currentThreshold = config.stages[stage].threshold
        let nextThreshold = config.stages[stage + 1].threshold
        let progressRange = nextThreshold - currentThreshold

        guard progressRange > 0 else { return 1.0 }

        let progressInRange = points - currentThreshold
        return max(0.0, min(1.0, Double(progressInRange) / Double(progressRange)))
    }

    private func calculateEvolutionTrend() -> EvolutionTrend {
        let recentEvents = evolutionEvents.suffix(10)
        let progressions = recentEvents.filter { $0.type == .stageProgression }.count
        let regressions = recentEvents.filter { $0.type == .stageRegression }.count

        if progressions >= 3 && regressions == 0 {
            return .rapidProgress
        } else if progressions > regressions {
            return .steadyProgress
        } else if progressions == regressions {
            return .stagnant
        } else if regressions > progressions && progressions > 0 {
            return .recovering
        } else {
            return .regressing
        }
    }

    private func calculateTimeInCurrentStage() -> TimeInterval {
        let recentProgressionEvents = evolutionEvents.reversed().filter { $0.type == .stageProgression }

        if let lastProgression = recentProgressionEvents.first {
            return Date().timeIntervalSince(lastProgression.timestamp)
        }

        // Fallback: time since first recorded event
        if let firstEvent = evolutionEvents.first {
            return Date().timeIntervalSince(firstEvent.timestamp)
        }

        return 0
    }

    private func predictNextEvolution(currentPoints: Int) -> EvolutionPrediction? {
        // Simple prediction based on recent trends
        let recentTrend = calculateEvolutionTrend()

        let dailyProgressEstimate: Int
        let weeklyProgressEstimate: Int
        let confidence: Double

        switch recentTrend {
        case .rapidProgress:
            dailyProgressEstimate = 15
            weeklyProgressEstimate = 70
            confidence = 0.8
        case .steadyProgress:
            dailyProgressEstimate = 8
            weeklyProgressEstimate = 40
            confidence = 0.7
        case .slowProgress:
            dailyProgressEstimate = 3
            weeklyProgressEstimate = 15
            confidence = 0.6
        case .stagnant:
            dailyProgressEstimate = 0
            weeklyProgressEstimate = 5
            confidence = 0.4
        case .regressing:
            dailyProgressEstimate = -5
            weeklyProgressEstimate = -20
            confidence = 0.5
        case .recovering:
            dailyProgressEstimate = 5
            weeklyProgressEstimate = 25
            confidence = 0.6
        }

        let predictedDaily = stageIndex(for: currentPoints + dailyProgressEstimate, recordAnalytics: false)
        let predictedWeekly = stageIndex(for: currentPoints + weeklyProgressEstimate, recordAnalytics: false)

        return EvolutionPrediction(
            predictedStageIn24Hours: predictedDaily,
            predictedStageInWeek: predictedWeekly,
            confidence: confidence,
            factorsInfluencing: ["Recent trend: \(recentTrend.rawValue)", "Current emotional state: \(currentEmotionalState.rawValue)"]
        )
    }

    private func generateBehaviorInsights() -> [BehaviorInsight] {
        var insights: [BehaviorInsight] = []

        // Motivational insights
        if currentEmotionalState == .sad || currentEmotionalState == .frustrated {
            insights.append(BehaviorInsight(
                type: .motivational,
                title: "Your pet needs encouragement",
                description: "Complete a few tasks to help your pet feel better!",
                actionable: true,
                confidence: 0.9
            ))
        }

        // Warning insights
        if calculateEvolutionTrend() == .regressing {
            insights.append(BehaviorInsight(
                type: .warning,
                title: "Slipping backwards",
                description: "Your pet has been losing progress lately. Focus on consistent task completion.",
                actionable: true,
                confidence: 0.8
            ))
        }

        // Celebratory insights
        if currentEmotionalState == .ecstatic || currentEmotionalState == .happy {
            insights.append(BehaviorInsight(
                type: .celebratory,
                title: "Your pet is thriving!",
                description: "Great job maintaining consistent progress. Your pet is very happy!",
                actionable: false,
                confidence: 0.95
            ))
        }

        return insights
    }

    private func calculateMilestoneAchievements(points: Int) -> [MilestoneAchievement] {
        var achievements: [MilestoneAchievement] = []
        let currentStage = stageIndex(for: points, recordAnalytics: false)

        // Stage-based milestones
        if currentStage >= 5 {
            achievements.append(MilestoneAchievement(
                id: "first_major_evolution",
                title: "First Major Evolution",
                description: "Your pet has grown significantly!",
                achievedAt: Date(),
                significance: .major
            ))
        }

        if currentStage == config.stages.count - 1 {
            achievements.append(MilestoneAchievement(
                id: "max_evolution",
                title: "Ultimate Form Achieved",
                description: "Your pet has reached its final evolutionary stage!",
                achievedAt: Date(),
                significance: .epic
            ))
        }

        return achievements
    }

    private func updateBehaviorMetrics(for event: EvolutionEvent) {
        switch event.type {
        case .stageProgression:
            behaviorMetrics.totalProgressions += 1
        case .stageRegression:
            behaviorMetrics.regressionEvents += 1
        case .emotionalStateChange:
            behaviorMetrics.emotionalStateChanges += 1
        default:
            break
        }

        saveBehaviorMetrics()
    }

    private func recordPerformanceMetric(operation: String, duration: TimeInterval) {
        calculationCount += 1
        totalCalculationTime += duration

        let averageTime = totalCalculationTime / Double(calculationCount)

        if duration > 0.01 { // Log operations > 10ms
            performanceLogger.warning("\(operation) took \(duration * 1000, specifier: "%.3f")ms (avg: \(averageTime * 1000, specifier: "%.3f")ms)")
        }
    }

    private func loadPersonalityProfile() {
        // Implementation would load from persistent storage
        // For now, keep default personality
        logger.debug("Personality profile loaded")
    }

    private func loadBehaviorMetrics() {
        // Implementation would load from persistent storage
        behaviorMetrics = BehaviorMetrics()
        logger.debug("Behavior metrics loaded")
    }

    private func saveBehaviorMetrics() {
        // Implementation would save to persistent storage
        logger.debug("Behavior metrics saved")
    }

    // MARK: - Threshold API for Widget Integration

    /// Get the XP threshold for a specific stage index
    /// - Parameter stageIndex: The stage index (0-based)
    /// - Returns: XP threshold required to reach that stage
    public func threshold(for stageIndex: Int) -> Int {
        guard stageIndex >= 0 && stageIndex < config.stages.count else {
            logger.warning("Invalid stage index: \(stageIndex), returning 0")
            return 0
        }
        return config.stages[stageIndex].threshold
    }

    /// Get all stage thresholds for testing and validation
    /// - Returns: Array of all stage thresholds
    public func allThresholds() -> [Int] {
        return config.stages.map { $0.threshold }
    }

    // MARK: - Supporting Types

    /// Evolution event for analytics tracking
    public struct EvolutionEvent {
        public let timestamp: Date
        public let type: EvolutionEventType
        public let fromStage: Int?
        public let toStage: Int?
        public let context: [String: Any]
        public let emotionalStateAtTime: EmotionalState
        public let personalitySnapshot: PetPersonality
    }

    /// Behavior metrics for analytics
    private struct BehaviorMetrics {
        var totalCalculations: Int = 0
        var personalityAdjustments: Int = 0
        var regressionEvents: Int = 0
        var totalProgressions: Int = 0
        var emotionalStateChanges: Int = 0
        var lastCalculationTime: Date = Date()
        var lastKnownPoints: Int = 0
    }
}

// MARK: - Array Extension

extension Array {
    subscript(safe index: Int) -> Element? {
        return (0..<count).contains(index) ? self[index] : nil
    }
}
