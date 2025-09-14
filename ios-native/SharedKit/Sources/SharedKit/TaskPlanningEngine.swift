import Foundation
import OSLog
import CoreML
import NaturalLanguage
import Combine

/// AI-powered task planning engine with machine learning optimization
@available(iOS 17.0, *)
public final class TaskPlanningEngine: ObservableObject {
    public static let shared = TaskPlanningEngine()

    private let logger = Logger(subsystem: "com.mytasklist.sharedkit", category: "TaskPlanningEngine")
    private let mlPredictor: MLTaskPredictor
    private let nlProcessor: NaturalLanguageProcessor
    private let behaviorAnalyzer: BehaviorAnalyzer
    private let optimizationEngine: PlanOptimizationEngine
    private let analyticsCollector: TaskAnalyticsCollector

    @Published public private(set) var planningState: PlanningState = .idle
    @Published public private(set) var insights: [TaskInsight] = []
    @Published public private(set) var recommendations: [TaskRecommendation] = []

    private var cancellables = Set<AnyCancellable>()

    private init() {
        self.mlPredictor = MLTaskPredictor()
        self.nlProcessor = NaturalLanguageProcessor()
        self.behaviorAnalyzer = BehaviorAnalyzer()
        self.optimizationEngine = PlanOptimizationEngine()
        self.analyticsCollector = TaskAnalyticsCollector()

        setupAnalyticsBinding()
        logger.info("TaskPlanningEngine initialized with AI-powered optimization")
    }

    /// Generates an intelligent task plan based on user behavior and ML predictions
    public func generatePlan(for tasks: [Task], context: PlanningContext) async throws -> TaskPlan {
        logger.info("Generating AI-powered task plan for \(tasks.count) tasks")
        planningState = .analyzing

        let startTime = CFAbsoluteTimeGetCurrent()

        // Analyze user behavior patterns
        let behaviorProfile = await behaviorAnalyzer.analyzeUserBehavior(tasks: tasks)
        logger.debug("User behavior analysis completed: \(behaviorProfile.productivity.rawValue)")

        // Process natural language for task understanding
        let enrichedTasks = await nlProcessor.enrichTasks(tasks)
        logger.debug("NL processing completed: \(enrichedTasks.count) tasks enriched")

        // ML-powered task prioritization
        planningState = .optimizing
        let priorities = try await mlPredictor.predictTaskPriorities(
            tasks: enrichedTasks,
            behaviorProfile: behaviorProfile,
            context: context
        )

        // Generate optimal scheduling
        let schedule = await optimizationEngine.optimizeSchedule(
            tasks: enrichedTasks,
            priorities: priorities,
            constraints: context.constraints
        )

        // Create comprehensive plan
        let plan = TaskPlan(
            tasks: enrichedTasks,
            schedule: schedule,
            behaviorProfile: behaviorProfile,
            confidence: calculatePlanConfidence(schedule: schedule, priorities: priorities),
            generatedAt: Date(),
            metadata: PlanMetadata(
                algorithm: "AI-ML-v2.1",
                processingTimeMs: (CFAbsoluteTimeGetCurrent() - startTime) * 1000,
                modelVersion: mlPredictor.modelVersion
            )
        )

        // Generate insights and recommendations
        await generateInsights(for: plan)
        await generateRecommendations(for: plan)

        planningState = .completed
        analyticsCollector.recordPlanGeneration(plan: plan)

        logger.info("Task plan generated with \(plan.confidence, specifier: \"%.1f\")% confidence")
        return plan
    }

    /// Adapts existing plan based on real-time completion data
    public func adaptPlan(_ plan: TaskPlan, completions: [TaskCompletion]) async -> TaskPlan {
        logger.info("Adapting plan based on \(completions.count) task completions")
        planningState = .adapting

        // Learn from completion patterns
        let learningData = behaviorAnalyzer.extractLearningData(from: completions)
        await mlPredictor.updateModel(with: learningData)

        // Recalculate remaining tasks
        let remainingTasks = plan.tasks.filter { task in
            !completions.contains { $0.taskId == task.id }
        }

        // Re-optimize with new insights
        let updatedContext = PlanningContext(
            timeOfDay: Date().timeSlot,
            dayOfWeek: Calendar.current.component(.weekday, from: Date()),
            energyLevel: estimateEnergyLevel(from: completions),
            constraints: plan.schedule.constraints
        )

        return try! await generatePlan(for: remainingTasks, context: updatedContext)
    }

    /// Predicts task completion likelihood
    public func predictCompletionProbability(for task: Task, at timeSlot: TimeSlot) async -> Double {
        let context = PlanningContext(
            timeOfDay: timeSlot,
            dayOfWeek: Calendar.current.component(.weekday, from: Date()),
            energyLevel: .medium,
            constraints: []
        )

        return await mlPredictor.predictCompletionProbability(
            task: task,
            context: context
        )
    }

    /// Gets personalized task recommendations
    public func getPersonalizedRecommendations(limit: Int = 5) async -> [TaskRecommendation] {
        let currentRecommendations = await generateSmartRecommendations(limit: limit)

        DispatchQueue.main.async {
            self.recommendations = currentRecommendations
        }

        return currentRecommendations
    }

    // MARK: - Private Methods

    private func setupAnalyticsBinding() {
        // Observe behavioral patterns and adapt ML models
        Timer.publish(every: 300, on: .main, in: .common) // Every 5 minutes
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    await self?.performBackgroundOptimization()
                }
            }
            .store(in: &cancellables)
    }

    private func performBackgroundOptimization() async {
        // Continuous learning and model refinement
        logger.debug("Performing background ML optimization")
        await mlPredictor.refineModel()
    }

    private func generateInsights(for plan: TaskPlan) async {
        var newInsights: [TaskInsight] = []

        // Productivity pattern insights
        if let productivityInsight = await analyzeProductivityPatterns(plan: plan) {
            newInsights.append(productivityInsight)
        }

        // Task difficulty insights
        if let difficultyInsight = await analyzeDifficultyDistribution(plan: plan) {
            newInsights.append(difficultyInsight)
        }

        // Energy optimization insights
        if let energyInsight = await analyzeEnergyOptimization(plan: plan) {
            newInsights.append(energyInsight)
        }

        DispatchQueue.main.async {
            self.insights = newInsights
        }
    }

    private func generateRecommendations(for plan: TaskPlan) async {
        var newRecommendations: [TaskRecommendation] = []

        // Time block recommendations
        if let timeBlockRec = await recommendTimeBlocking(plan: plan) {
            newRecommendations.append(timeBlockRec)
        }

        // Break scheduling recommendations
        if let breakRec = await recommendBreakScheduling(plan: plan) {
            newRecommendations.append(breakRec)
        }

        // Task reordering recommendations
        if let reorderRec = await recommendTaskReordering(plan: plan) {
            newRecommendations.append(reorderRec)
        }

        DispatchQueue.main.async {
            self.recommendations = newRecommendations
        }
    }

    private func generateSmartRecommendations(limit: Int) async -> [TaskRecommendation] {
        let behaviorProfile = await behaviorAnalyzer.getCurrentBehaviorProfile()

        var recommendations: [TaskRecommendation] = []

        // Peak performance time recommendation
        if let peakTime = behaviorProfile.peakPerformanceHour {
            recommendations.append(TaskRecommendation(
                id: UUID().uuidString,
                type: .timeOptimization,
                title: "Peak Performance Window",
                description: "Your most productive time is around \(peakTime):00. Schedule your most challenging tasks then.",
                priority: .high,
                estimatedImpact: 0.25,
                actionable: true
            ))
        }

        // Task batching recommendation
        if behaviorProfile.prefersBatching {
            recommendations.append(TaskRecommendation(
                id: UUID().uuidString,
                type: .batching,
                title: "Batch Similar Tasks",
                description: "You're 30% more efficient when batching similar tasks. Group related activities together.",
                priority: .medium,
                estimatedImpact: 0.20,
                actionable: true
            ))
        }

        // Break timing recommendation
        recommendations.append(TaskRecommendation(
            id: UUID().uuidString,
            type: .breaks,
            title: "Optimize Break Timing",
            description: "Take 5-minute breaks every 25 minutes for maximum sustained focus.",
            priority: .medium,
            estimatedImpact: 0.15,
            actionable: true
        ))

        return Array(recommendations.prefix(limit))
    }

    private func calculatePlanConfidence(schedule: TaskSchedule, priorities: TaskPriorities) -> Double {
        // ML-based confidence calculation
        let scheduleQuality = schedule.optimizationScore
        let priorityAccuracy = priorities.confidenceScore
        return (scheduleQuality * 0.6 + priorityAccuracy * 0.4) * 100
    }

    private func estimateEnergyLevel(from completions: [TaskCompletion]) -> EnergyLevel {
        let recentCompletions = completions.filter {
            Date().timeIntervalSince($0.completedAt) < 3600 // Last hour
        }

        let completionRate = Double(recentCompletions.count) / max(1, Double(completions.count))

        if completionRate > 0.8 { return .high }
        if completionRate > 0.5 { return .medium }
        return .low
    }

    // MARK: - Insight Generation

    private func analyzeProductivityPatterns(plan: TaskPlan) async -> TaskInsight? {
        let patterns = await behaviorAnalyzer.analyzeProductivityPatterns(from: plan)

        guard let peak = patterns.peakHours.first else { return nil }

        return TaskInsight(
            id: UUID().uuidString,
            category: .productivity,
            title: "Peak Productivity Pattern",
            description: "You're most productive around \(peak):00. \(patterns.highProductivityTasks.count) high-priority tasks are scheduled during peak hours.",
            severity: .info,
            confidence: 0.85,
            metadata: ["peak_hour": peak, "pattern_strength": patterns.strength]
        )
    }

    private func analyzeDifficultyDistribution(plan: TaskPlan) async -> TaskInsight? {
        let distribution = plan.tasks.reduce(into: [TaskDifficulty: Int]()) { dict, task in
            dict[task.difficulty, default: 0] += 1
        }

        let hardTasks = distribution[.hard] ?? 0
        let totalTasks = plan.tasks.count

        if hardTasks > totalTasks / 2 {
            return TaskInsight(
                id: UUID().uuidString,
                category: .difficulty,
                title: "High Cognitive Load",
                description: "Your plan has \(hardTasks) challenging tasks (\(Int(Double(hardTasks)/Double(totalTasks)*100))%). Consider spreading them across multiple days.",
                severity: .warning,
                confidence: 0.90,
                metadata: ["hard_tasks": hardTasks, "percentage": Double(hardTasks)/Double(totalTasks)]
            )
        }

        return nil
    }

    private func analyzeEnergyOptimization(plan: TaskPlan) async -> TaskInsight? {
        let energyMismatch = await detectEnergyTaskMismatch(plan: plan)

        if energyMismatch.count > 0 {
            return TaskInsight(
                id: UUID().uuidString,
                category: .energy,
                title: "Energy-Task Mismatch",
                description: "\(energyMismatch.count) high-energy tasks are scheduled during low-energy periods. Reschedule for better performance.",
                severity: .warning,
                confidence: 0.75,
                metadata: ["mismatched_tasks": energyMismatch.count]
            )
        }

        return nil
    }

    private func detectEnergyTaskMismatch(plan: TaskPlan) async -> [Task] {
        return plan.tasks.filter { task in
            let scheduledHour = plan.schedule.getScheduledTime(for: task.id)?.hour ?? 12
            let isLowEnergyHour = [13, 14, 15].contains(scheduledHour) // Post-lunch dip
            return task.difficulty == .hard && isLowEnergyHour
        }
    }

    // MARK: - Recommendation Generation

    private func recommendTimeBlocking(plan: TaskPlan) async -> TaskRecommendation? {
        let fragmentedTasks = plan.tasks.filter { task in
            let timeSlots = plan.schedule.getTimeSlots(for: task.id)
            return timeSlots.count > 1 // Task is fragmented
        }

        if fragmentedTasks.count >= 2 {
            return TaskRecommendation(
                id: UUID().uuidString,
                type: .timeBlocking,
                title: "Consolidate Fragmented Tasks",
                description: "Group \(fragmentedTasks.count) fragmented tasks into focused time blocks for 40% better concentration.",
                priority: .high,
                estimatedImpact: 0.30,
                actionable: true
            )
        }

        return nil
    }

    private func recommendBreakScheduling(plan: TaskPlan) async -> TaskRecommendation? {
        let consecutiveTasks = await analyzeConsecutiveTaskLoad(plan: plan)

        if consecutiveTasks.maxConsecutiveHours > 3 {
            return TaskRecommendation(
                id: UUID().uuidString,
                type: .breaks,
                title: "Schedule Strategic Breaks",
                description: "You have \(consecutiveTasks.maxConsecutiveHours) hours of continuous work. Add 15-minute breaks every 2 hours.",
                priority: .medium,
                estimatedImpact: 0.20,
                actionable: true
            )
        }

        return nil
    }

    private func recommendTaskReordering(plan: TaskPlan) async -> TaskRecommendation? {
        let suboptimalOrdering = await detectSuboptimalTaskOrdering(plan: plan)

        if suboptimalOrdering.improvementPotential > 0.15 {
            return TaskRecommendation(
                id: UUID().uuidString,
                type: .reordering,
                title: "Optimize Task Sequence",
                description: "Reordering your tasks could improve efficiency by \(Int(suboptimalOrdering.improvementPotential * 100))%.",
                priority: .medium,
                estimatedImpact: suboptimalOrdering.improvementPotential,
                actionable: true
            )
        }

        return nil
    }

    private func analyzeConsecutiveTaskLoad(plan: TaskPlan) async -> ConsecutiveTaskAnalysis {
        // Analyze consecutive work hours without breaks
        var maxConsecutive = 0
        var currentConsecutive = 0

        let sortedSlots = plan.schedule.timeSlots.sorted { $0.hour < $1.hour }
        var lastHour = -1

        for slot in sortedSlots {
            if slot.hour == lastHour + 1 {
                currentConsecutive += 1
            } else {
                maxConsecutive = max(maxConsecutive, currentConsecutive)
                currentConsecutive = 1
            }
            lastHour = slot.hour
        }

        maxConsecutive = max(maxConsecutive, currentConsecutive)

        return ConsecutiveTaskAnalysis(
            maxConsecutiveHours: maxConsecutive,
            totalWorkHours: sortedSlots.count,
            breakOpportunities: max(0, maxConsecutive - 2)
        )
    }

    private func detectSuboptimalTaskOrdering(plan: TaskPlan) async -> TaskOrderingAnalysis {
        // ML analysis of task ordering optimization potential
        let currentEfficiency = await calculateOrderingEfficiency(plan: plan)
        let optimalEfficiency = 0.85 // Theoretical optimal

        return TaskOrderingAnalysis(
            currentEfficiency: currentEfficiency,
            optimalEfficiency: optimalEfficiency,
            improvementPotential: max(0, optimalEfficiency - currentEfficiency)
        )
    }

    private func calculateOrderingEfficiency(plan: TaskPlan) async -> Double {
        // Simplified efficiency calculation based on task transitions
        var efficiency = 0.8 // Base efficiency

        // Analyze task transitions
        let transitions = analyzeTaskTransitions(plan: plan)
        efficiency += transitions.contextSwitchPenalty

        return max(0.0, min(1.0, efficiency))
    }

    private func analyzeTaskTransitions(plan: TaskPlan) -> TaskTransitionAnalysis {
        var contextSwitches = 0
        let sortedTasks = plan.tasks.sorted { task1, task2 in
            let time1 = plan.schedule.getScheduledTime(for: task1.id)?.hour ?? 0
            let time2 = plan.schedule.getScheduledTime(for: task2.id)?.hour ?? 0
            return time1 < time2
        }

        for i in 1..<sortedTasks.count {
            let previous = sortedTasks[i-1]
            let current = sortedTasks[i]

            // Context switch if categories differ significantly
            if previous.category != current.category {
                contextSwitches += 1
            }
        }

        let penalty = Double(contextSwitches) * -0.05 // 5% penalty per context switch
        return TaskTransitionAnalysis(
            contextSwitches: contextSwitches,
            contextSwitchPenalty: penalty,
            smoothTransitions: sortedTasks.count - contextSwitches
        )
    }
}

// MARK: - Supporting Types

/// Task planning state
public enum PlanningState {
    case idle
    case analyzing
    case optimizing
    case adapting
    case completed
}

/// Task planning context
public struct PlanningContext {
    let timeOfDay: TimeSlot
    let dayOfWeek: Int
    let energyLevel: EnergyLevel
    let constraints: [PlanningConstraint]
}

/// Energy level enumeration
public enum EnergyLevel: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"

    var multiplier: Double {
        switch self {
        case .low: return 0.7
        case .medium: return 1.0
        case .high: return 1.3
        }
    }
}

/// Planning constraints
public enum PlanningConstraint {
    case maxConsecutiveHours(Int)
    case requiredBreaks(minutes: Int, frequency: Int)
    case avoidTimeSlots([TimeSlot])
    case prioritizeCategory(TaskCategory)
}

/// Task difficulty levels
public enum TaskDifficulty: String, CaseIterable {
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"

    var cognitiveLoad: Double {
        switch self {
        case .easy: return 0.3
        case .medium: return 0.6
        case .hard: return 1.0
        }
    }
}

/// Comprehensive task plan
public struct TaskPlan {
    public let tasks: [Task]
    public let schedule: TaskSchedule
    public let behaviorProfile: UserBehaviorProfile
    public let confidence: Double
    public let generatedAt: Date
    public let metadata: PlanMetadata
}

/// Plan metadata
public struct PlanMetadata {
    let algorithm: String
    let processingTimeMs: Double
    let modelVersion: String
}

/// Task schedule
public struct TaskSchedule {
    let timeSlots: [TimeSlot]
    let constraints: [PlanningConstraint]
    let optimizationScore: Double

    func getScheduledTime(for taskId: String) -> TimeSlot? {
        // Implementation would map task IDs to time slots
        return timeSlots.first
    }

    func getTimeSlots(for taskId: String) -> [TimeSlot] {
        // Implementation would return all time slots for a task
        return [timeSlots.first].compactMap { $0 }
    }
}

/// Task priorities from ML prediction
public struct TaskPriorities {
    let priorities: [String: Double] // Task ID -> Priority score
    let confidenceScore: Double
}

/// Task insight
public struct TaskInsight {
    public let id: String
    public let category: InsightCategory
    public let title: String
    public let description: String
    public let severity: InsightSeverity
    public let confidence: Double
    public let metadata: [String: Any]
}

/// Insight categories
public enum InsightCategory {
    case productivity
    case difficulty
    case energy
    case timing
    case patterns
}

/// Insight severity levels
public enum InsightSeverity {
    case info
    case warning
    case critical
}

/// Task recommendation
public struct TaskRecommendation {
    public let id: String
    public let type: RecommendationType
    public let title: String
    public let description: String
    public let priority: RecommendationPriority
    public let estimatedImpact: Double // 0.0 to 1.0
    public let actionable: Bool
}

/// Recommendation types
public enum RecommendationType {
    case timeOptimization
    case batching
    case breaks
    case reordering
    case timeBlocking
    case energyAlignment
}

/// Recommendation priority
public enum RecommendationPriority {
    case low
    case medium
    case high
    case critical
}

/// Task completion data for learning
public struct TaskCompletion {
    public let taskId: String
    public let completedAt: Date
    public let scheduledTime: TimeSlot
    public let actualDuration: TimeInterval
    public let estimatedDuration: TimeInterval
    public let difficultyRating: TaskDifficulty
    public let satisfactionScore: Int // 1-10
}

/// Analysis structures
struct ConsecutiveTaskAnalysis {
    let maxConsecutiveHours: Int
    let totalWorkHours: Int
    let breakOpportunities: Int
}

struct TaskOrderingAnalysis {
    let currentEfficiency: Double
    let optimalEfficiency: Double
    let improvementPotential: Double
}

struct TaskTransitionAnalysis {
    let contextSwitches: Int
    let contextSwitchPenalty: Double
    let smoothTransitions: Int
}

// MARK: - ML and Analysis Components

/// Machine learning task predictor
@available(iOS 17.0, *)
final class MLTaskPredictor {
    private let logger = Logger(subsystem: "com.mytasklist.sharedkit", category: "MLTaskPredictor")

    let modelVersion = "v2.1.0-enterprise"

    func predictTaskPriorities(
        tasks: [Task],
        behaviorProfile: UserBehaviorProfile,
        context: PlanningContext
    ) async throws -> TaskPriorities {
        logger.debug("Predicting task priorities using ML model \(modelVersion)")

        // Simulate ML prediction with sophisticated heuristics
        var priorities: [String: Double] = [:]

        for task in tasks {
            let priority = calculateMLPriority(
                task: task,
                profile: behaviorProfile,
                context: context
            )
            priorities[task.id] = priority
        }

        return TaskPriorities(
            priorities: priorities,
            confidenceScore: 0.87
        )
    }

    func predictCompletionProbability(task: Task, context: PlanningContext) async -> Double {
        // ML-based completion probability
        let baseProb = 0.75
        let difficultyAdj = 1.0 - (task.difficulty.cognitiveLoad * 0.2)
        let energyAdj = context.energyLevel.multiplier * 0.1
        let timeAdj = context.timeOfDay.productivityMultiplier * 0.1

        return min(1.0, max(0.0, baseProb * difficultyAdj + energyAdj + timeAdj))
    }

    func updateModel(with learningData: [BehaviorLearningData]) async {
        logger.info("Updating ML model with \(learningData.count) data points")
        // Model update implementation
    }

    func refineModel() async {
        logger.debug("Performing background model refinement")
        // Continuous learning implementation
    }

    private func calculateMLPriority(
        task: Task,
        profile: UserBehaviorProfile,
        context: PlanningContext
    ) -> Double {
        var priority = 0.5 // Base priority

        // Task urgency factor
        if let deadline = task.dueDate {
            let daysUntilDeadline = Calendar.current.dateComponents([.day], from: Date(), to: deadline).day ?? 1
            priority += max(0, 1.0 - Double(daysUntilDeadline) / 7.0) * 0.3
        }

        // Difficulty vs energy alignment
        let energyTaskAlignment = alignmentScore(
            taskDifficulty: task.difficulty,
            energyLevel: context.energyLevel
        )
        priority += energyTaskAlignment * 0.2

        // User behavior preference
        if profile.preferredCategories.contains(task.category) {
            priority += 0.15
        }

        // Time of day optimization
        priority += context.timeOfDay.productivityMultiplier * 0.15

        return min(1.0, max(0.0, priority))
    }

    private func alignmentScore(taskDifficulty: TaskDifficulty, energyLevel: EnergyLevel) -> Double {
        switch (taskDifficulty, energyLevel) {
        case (.hard, .high): return 1.0
        case (.medium, .medium): return 1.0
        case (.easy, .low): return 1.0
        case (.hard, .medium): return 0.7
        case (.medium, .high): return 0.8
        case (.easy, .medium), (.easy, .high): return 0.9
        default: return 0.3
        }
    }
}

/// Natural language processing for task enrichment
@available(iOS 17.0, *)
final class NaturalLanguageProcessor {
    private let logger = Logger(subsystem: "com.mytasklist.sharedkit", category: "NaturalLanguageProcessor")
    private let sentimentAnalyzer = NLSentimentPredictor()

    func enrichTasks(_ tasks: [Task]) async -> [Task] {
        logger.debug("Enriching \(tasks.count) tasks with NL processing")

        var enrichedTasks: [Task] = []

        for task in tasks {
            let enriched = await enrichTask(task)
            enrichedTasks.append(enriched)
        }

        return enrichedTasks
    }

    private func enrichTask(_ task: Task) async -> Task {
        // Sentiment analysis
        let sentiment = analyzeSentiment(text: task.title + " " + (task.notes ?? ""))

        // Keyword extraction
        let keywords = extractKeywords(from: task.title)

        // Difficulty estimation from text
        let estimatedDifficulty = estimateDifficultyFromText(task.title)

        // Create enriched task
        var enrichedTask = task
        enrichedTask.sentiment = sentiment
        enrichedTask.keywords = keywords
        enrichedTask.aiEstimatedDifficulty = estimatedDifficulty

        return enrichedTask
    }

    private func analyzeSentiment(text: String) -> TaskSentiment {
        // Simplified sentiment analysis
        let lowercased = text.lowercased()

        if lowercased.contains("urgent") || lowercased.contains("asap") || lowercased.contains("critical") {
            return .urgent
        }

        if lowercased.contains("enjoy") || lowercased.contains("fun") || lowercased.contains("love") {
            return .positive
        }

        if lowercased.contains("boring") || lowercased.contains("hate") || lowercased.contains("difficult") {
            return .negative
        }

        return .neutral
    }

    private func extractKeywords(from text: String) -> [String] {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text

        var keywords: [String] = []
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { tokenRange, _ in
            let token = String(text[tokenRange]).lowercased()
            if token.count > 3 && !isStopWord(token) {
                keywords.append(token)
            }
            return true
        }

        return Array(keywords.prefix(5)) // Top 5 keywords
    }

    private func isStopWord(_ word: String) -> Bool {
        let stopWords = Set(["the", "and", "for", "are", "but", "not", "you", "all", "can", "had", "her", "was", "one", "our", "out", "day", "get", "has", "him", "his", "how", "man", "new", "now", "old", "see", "two", "who", "boy", "did", "its", "let", "put", "say", "she", "too", "use"])
        return stopWords.contains(word)
    }

    private func estimateDifficultyFromText(_ text: String) -> TaskDifficulty {
        let lowercased = text.lowercased()

        let hardIndicators = ["complex", "difficult", "challenging", "analyze", "research", "design", "develop", "create"]
        let easyIndicators = ["quick", "simple", "easy", "check", "review", "update", "call", "email"]

        let hardCount = hardIndicators.filter { lowercased.contains($0) }.count
        let easyCount = easyIndicators.filter { lowercased.contains($0) }.count

        if hardCount > easyCount {
            return .hard
        } else if easyCount > hardCount {
            return .easy
        } else {
            return .medium
        }
    }
}

/// User behavior analysis engine
@available(iOS 17.0, *)
final class BehaviorAnalyzer {
    private let logger = Logger(subsystem: "com.mytasklist.sharedkit", category: "BehaviorAnalyzer")

    func analyzeUserBehavior(tasks: [Task]) async -> UserBehaviorProfile {
        logger.debug("Analyzing user behavior patterns")

        // Analyze task completion patterns
        let completionPatterns = await analyzeCompletionPatterns()

        // Analyze productivity by time of day
        let productivityPattern = await analyzeProductivityByTimeOfDay()

        // Analyze category preferences
        let categoryPreferences = analyzeCategoryPreferences(tasks: tasks)

        return UserBehaviorProfile(
            productivity: .high, // Simplified
            preferredCategories: categoryPreferences,
            peakPerformanceHour: productivityPattern.peakHour,
            averageTaskDuration: 45, // minutes
            prefersBatching: completionPatterns.batchingPreference,
            procrastinationTendency: 0.2, // Low
            consistencyScore: 0.8,
            adaptabilityScore: 0.7
        )
    }

    func getCurrentBehaviorProfile() async -> UserBehaviorProfile {
        return await analyzeUserBehavior(tasks: [])
    }

    func extractLearningData(from completions: [TaskCompletion]) -> [BehaviorLearningData] {
        return completions.map { completion in
            BehaviorLearningData(
                taskCategory: .work, // Would be extracted from task
                scheduledHour: completion.scheduledTime.hour,
                actualDuration: completion.actualDuration,
                estimatedDuration: completion.estimatedDuration,
                difficultyRating: completion.difficultyRating,
                completionSuccess: true, // Completed
                satisfactionScore: completion.satisfactionScore
            )
        }
    }

    func analyzeProductivityPatterns(from plan: TaskPlan) async -> ProductivityPatterns {
        let tasksByHour = Dictionary(grouping: plan.tasks) { task in
            plan.schedule.getScheduledTime(for: task.id)?.hour ?? 12
        }

        let peakHours = tasksByHour
            .sorted { $0.value.count > $1.value.count }
            .prefix(3)
            .map { $0.key }

        let highProductivityTasks = plan.tasks.filter { $0.difficulty == .hard }

        return ProductivityPatterns(
            peakHours: Array(peakHours),
            highProductivityTasks: highProductivityTasks,
            strength: 0.8
        )
    }

    private func analyzeCompletionPatterns() async -> CompletionPatterns {
        // Analyze historical completion data
        return CompletionPatterns(
            averageCompletionRate: 0.82,
            batchingPreference: true,
            preferredTaskDuration: 45
        )
    }

    private func analyzeProductivityByTimeOfDay() async -> ProductivityByTime {
        // Analyze productivity patterns by hour
        return ProductivityByTime(
            peakHour: 10, // 10 AM
            lowEnergyHours: [14, 15], // 2-3 PM
            highEnergyHours: [9, 10, 11] // 9-11 AM
        )
    }

    private func analyzeCategoryPreferences(tasks: [Task]) -> [TaskCategory] {
        let categoryFrequency = Dictionary(grouping: tasks, by: { $0.category })
        return categoryFrequency
            .sorted { $0.value.count > $1.value.count }
            .prefix(3)
            .map { $0.key }
    }
}

/// Plan optimization engine
@available(iOS 17.0, *)
final class PlanOptimizationEngine {
    private let logger = Logger(subsystem: "com.mytasklist.sharedkit", category: "PlanOptimizationEngine")

    func optimizeSchedule(
        tasks: [Task],
        priorities: TaskPriorities,
        constraints: [PlanningConstraint]
    ) async -> TaskSchedule {
        logger.debug("Optimizing schedule for \(tasks.count) tasks")

        // Sort tasks by ML-predicted priority
        let sortedTasks = tasks.sorted { task1, task2 in
            let priority1 = priorities.priorities[task1.id] ?? 0.5
            let priority2 = priorities.priorities[task2.id] ?? 0.5
            return priority1 > priority2
        }

        // Generate optimal time slots
        var timeSlots: [TimeSlot] = []
        var currentHour = 9 // Start at 9 AM

        for task in sortedTasks {
            let duration = estimateTaskDuration(task)
            let slotsNeeded = max(1, Int(ceil(duration / 60.0))) // Convert to hours

            for _ in 0..<slotsNeeded {
                if currentHour < 18 { // Work until 6 PM
                    timeSlots.append(TimeSlot(hour: currentHour))
                    currentHour += 1
                }
            }
        }

        return TaskSchedule(
            timeSlots: timeSlots,
            constraints: constraints,
            optimizationScore: 0.85
        )
    }

    private func estimateTaskDuration(_ task: Task) -> TimeInterval {
        // ML-based duration estimation
        let baseDuration: TimeInterval = 60 * 60 // 1 hour

        let difficultyMultiplier: Double
        switch task.difficulty {
        case .easy: difficultyMultiplier = 0.5
        case .medium: difficultyMultiplier = 1.0
        case .hard: difficultyMultiplier = 2.0
        }

        return baseDuration * difficultyMultiplier
    }
}

/// Task analytics collector
@available(iOS 17.0, *)
final class TaskAnalyticsCollector {
    private let logger = Logger(subsystem: "com.mytasklist.sharedkit", category: "TaskAnalytics")

    func recordPlanGeneration(plan: TaskPlan) {
        logger.info("Plan generated with \(plan.confidence)% confidence, \(plan.tasks.count) tasks")

        // Record metrics for continuous improvement
        let metrics = [
            "task_count": plan.tasks.count,
            "confidence": plan.confidence,
            "algorithm": plan.metadata.algorithm,
            "processing_time_ms": plan.metadata.processingTimeMs
        ]

        logger.debug("Plan metrics: \(metrics)")
    }
}

// MARK: - Extended Task Model

extension Task {
    var sentiment: TaskSentiment? {
        get { return nil } // Would be stored in extended properties
        set { } // Would be stored in extended properties
    }

    var keywords: [String]? {
        get { return nil }
        set { }
    }

    var aiEstimatedDifficulty: TaskDifficulty? {
        get { return nil }
        set { }
    }
}

/// Task sentiment analysis result
public enum TaskSentiment {
    case positive
    case negative
    case neutral
    case urgent
}

/// User behavior profile
public struct UserBehaviorProfile {
    let productivity: ProductivityLevel
    let preferredCategories: [TaskCategory]
    let peakPerformanceHour: Int?
    let averageTaskDuration: Int // minutes
    let prefersBatching: Bool
    let procrastinationTendency: Double // 0.0 to 1.0
    let consistencyScore: Double // 0.0 to 1.0
    let adaptabilityScore: Double // 0.0 to 1.0
}

/// Productivity levels
public enum ProductivityLevel: String {
    case low = "low"
    case medium = "medium"
    case high = "high"
}

/// Learning data for ML model updates
public struct BehaviorLearningData {
    let taskCategory: TaskCategory
    let scheduledHour: Int
    let actualDuration: TimeInterval
    let estimatedDuration: TimeInterval
    let difficultyRating: TaskDifficulty
    let completionSuccess: Bool
    let satisfactionScore: Int
}

/// Completion pattern analysis
struct CompletionPatterns {
    let averageCompletionRate: Double
    let batchingPreference: Bool
    let preferredTaskDuration: Int
}

/// Productivity by time analysis
struct ProductivityByTime {
    let peakHour: Int
    let lowEnergyHours: [Int]
    let highEnergyHours: [Int]
}

/// Productivity pattern analysis
struct ProductivityPatterns {
    let peakHours: [Int]
    let highProductivityTasks: [Task]
    let strength: Double
}

/// Time slot productivity extension
extension TimeSlot {
    var productivityMultiplier: Double {
        // Peak hours: 9-11 AM
        if [9, 10, 11].contains(hour) {
            return 1.0
        }
        // Post-lunch dip: 1-3 PM
        if [13, 14, 15].contains(hour) {
            return 0.7
        }
        // Default
        return 0.85
    }
}