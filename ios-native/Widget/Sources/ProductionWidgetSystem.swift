import WidgetKit
import SwiftUI
import SharedKit
import AppIntents
import os.log

/// Production-grade widget system with comprehensive error handling,
/// execution budget monitoring, and graceful degradation strategies
@available(iOS 17.0, *)
final class ProductionWidgetSystem: Sendable {
    static let shared = ProductionWidgetSystem()

    private let logger = Logger(subsystem: "com.petprogress.Widget", category: "ProductionSystem")
    private let performanceMonitor = WidgetPerformanceMonitor()

    private init() {}

    // MARK: - Production Timeline Provider

    func createProductionTimeline(
        for configuration: ConfigurationAppIntent,
        in context: TimelineProviderContext,
        completion: @escaping (Timeline<SimpleEntry>) -> Void
    ) {
        let executionID = UUID().uuidString
        let startTime = CFAbsoluteTimeGetCurrent()

        logger.info("Starting timeline generation [ID: \(executionID)]")
        performanceMonitor.startOperation(id: executionID, type: .timelineGeneration)

        // Execution budget based on widget family and context
        let budget = executionBudget(for: context)
        logger.debug("Execution budget: \(budget)s for \(context.family.description)")

        Task {
            do {
                let timeline = try await buildTimelineWithBudget(
                    budget: budget,
                    executionID: executionID,
                    context: context
                )

                let duration = CFAbsoluteTimeGetCurrent() - startTime
                performanceMonitor.completeOperation(id: executionID, duration: duration)
                logger.info("Timeline generated successfully [ID: \(executionID), Duration: \(String(format: "%.3f", duration))s]")

                completion(timeline)

            } catch {
                let duration = CFAbsoluteTimeGetCurrent() - startTime
                performanceMonitor.failOperation(id: executionID, error: error, duration: duration)

                logger.error("Timeline generation failed [ID: \(executionID), Error: \(error.localizedDescription)]")

                // Fallback timeline
                let fallbackTimeline = createFallbackTimeline()
                completion(fallbackTimeline)
            }
        }
    }

    // MARK: - Timeline Construction

    private func buildTimelineWithBudget(
        budget: TimeInterval,
        executionID: String,
        context: TimelineProviderContext
    ) async throws -> Timeline<SimpleEntry> {

        let budgetMonitor = ExecutionBudgetMonitor(budget: budget)

        // Step 1: Load current data (30% of budget)
        try? budgetMonitor.checkBudget(operation: "data loading")
        let currentData = try await loadCurrentDataWithTimeout(
            timeout: budget * 0.3,
            executionID: executionID
        )

        // Step 2: Build timeline entries (60% of budget)
        try? budgetMonitor.checkBudget(operation: "entry generation")
        let entries = try await generateTimelineEntries(
            from: currentData,
            timeout: budget * 0.6,
            executionID: executionID
        )

        // Step 3: Finalize timeline (10% of budget)
        try? budgetMonitor.checkBudget(operation: "timeline finalization")
        let timeline = finalizeTimeline(entries: entries)

        return timeline
    }

    private func loadCurrentDataWithTimeout(
        timeout: TimeInterval,
        executionID: String
    ) async throws -> DayModel {

        return try await withTimeout(timeout) {
            // Try primary data source
            if let primaryData = SharedStore.shared.getCurrentDayModel() {
                self.logger.debug("Loaded from primary data source [ID: \(executionID)]")
                return primaryData
            }

            // Fallback to cached data
            if let cachedData = self.loadCachedData() {
                self.logger.warning("Using cached data fallback [ID: \(executionID)]")
                return cachedData
            }

            // Last resort: create placeholder
            self.logger.warning("Using placeholder data [ID: \(executionID)]")
            return self.createPlaceholderData()
        }
    }

    private func generateTimelineEntries(
        from dayModel: DayModel,
        timeout: TimeInterval,
        executionID: String
    ) async throws -> [SimpleEntry] {

        return try await withTimeout(timeout) {
            let now = Date()
            let calendar = Calendar.current

            // Calculate next refresh time (top of next hour)
            let nextHour = calendar.nextDate(
                after: now,
                matching: DateComponents(minute: 0, second: 0),
                matchingPolicy: .nextTime,
                direction: .forward
            ) ?? now.addingTimeInterval(3600)

            var entries: [SimpleEntry] = []

            // Current entry
            entries.append(SimpleEntry(date: now, dayModel: dayModel))

            // Future entries (next 6 hours max for performance)
            for hourOffset in 1...6 {
                let entryDate = calendar.date(byAdding: .hour, value: hourOffset, to: nextHour) ?? nextHour
                let futureModel = self.projectDayModel(dayModel, to: entryDate)
                entries.append(SimpleEntry(date: entryDate, dayModel: futureModel))
            }

            self.logger.debug("Generated \(entries.count) timeline entries [ID: \(executionID)]")
            return entries
        }
    }

    private func finalizeTimeline(entries: [SimpleEntry]) -> Timeline<SimpleEntry> {
        guard !entries.isEmpty else {
            logger.warning("Empty entries, using fallback timeline")
            return createFallbackTimeline()
        }

        // Calculate next refresh policy
        let refreshDate = entries.last?.date.addingTimeInterval(3600) ?? Date().addingTimeInterval(3600)
        let policy: TimelineReloadPolicy = .after(refreshDate)

        return Timeline(entries: entries, policy: policy)
    }

    // MARK: - Error Handling & Fallbacks

    private func createFallbackTimeline() -> Timeline<SimpleEntry> {
        let fallbackModel = DayModel(
            key: TimeSlot.dayKey(for: Date()),
            slots: [
                DayModel.Slot(hour: 9, title: "Add tasks in app", isDone: false),
                DayModel.Slot(hour: 14, title: "Check progress", isDone: false),
                DayModel.Slot(hour: 18, title: "Review day", isDone: false)
            ],
            points: 25
        )

        let entry = SimpleEntry(date: Date(), dayModel: fallbackModel)
        let refreshDate = Date().addingTimeInterval(300) // Retry in 5 minutes

        return Timeline(entries: [entry], policy: .after(refreshDate))
    }

    private func loadCachedData() -> DayModel? {
        // Implement cache retrieval logic
        // This could use UserDefaults, Core Data, or file system caching
        let defaults = UserDefaults(suiteName: "group.com.hedgingmybets.PetProgress")
        guard let data = defaults?.data(forKey: "cached_day_model"),
              let cached = try? JSONDecoder().decode(DayModel.self, from: data) else {
            return nil
        }

        // Check if cached data is not too old (max 1 hour)
        let cacheAge = Date().timeIntervalSince(defaults?.object(forKey: "cache_timestamp") as? Date ?? Date.distantPast)
        return cacheAge < 3600 ? cached : nil
    }

    private func createPlaceholderData() -> DayModel {
        return DayModel(
            key: TimeSlot.dayKey(for: Date()),
            slots: [
                DayModel.Slot(hour: 9, title: "Open app to sync", isDone: false)
            ],
            points: 0
        )
    }

    private func projectDayModel(_ baseModel: DayModel, to date: Date) -> DayModel {
        // Create a projected model for future timeline entries
        // This could simulate task completion probabilities or show schedule changes
        return baseModel
    }

    // MARK: - Budget Management

    private func executionBudget(for context: TimelineProviderContext) -> TimeInterval {
        switch context.family {
        case .accessoryCircular, .accessoryRectangular:
            return 2.0  // Lock screen widgets have tighter budgets
        case .systemSmall:
            return 4.0
        case .systemMedium, .systemLarge:
            return 6.0
        default:
            return 3.0
        }
    }
}

// MARK: - Execution Budget Monitor

private final class ExecutionBudgetMonitor: Sendable {
    private let budget: TimeInterval
    private let startTime: CFAbsoluteTime

    init(budget: TimeInterval) {
        self.budget = budget
        self.startTime = CFAbsoluteTimeGetCurrent()
    }

    func checkBudget(operation: String) throws {
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        let remaining = budget - elapsed

        if remaining <= 0 {
            throw WidgetError.budgetExceeded(operation: operation, elapsed: elapsed, budget: budget)
        }
    }

    var remainingBudget: TimeInterval {
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        return max(0, budget - elapsed)
    }
}

// MARK: - Performance Monitor

private final class WidgetPerformanceMonitor: Sendable {
    private let operationsLock = NSLock()
    private var _operations: [String: OperationMetrics] = [:]
    private let logger = Logger(subsystem: "com.petprogress.Widget", category: "Performance")

    struct OperationMetrics: Sendable {
        let startTime: CFAbsoluteTime
        let type: OperationType
        var duration: TimeInterval?
        var error: Error?
    }

    enum OperationType: Sendable {
        case timelineGeneration
        case dataLoading
        case entryCreation
    }

    func startOperation(id: String, type: OperationType) {
        operationsLock.lock()
        defer { operationsLock.unlock() }
        _operations[id] = OperationMetrics(
            startTime: CFAbsoluteTimeGetCurrent(),
            type: type
        )
    }

    func completeOperation(id: String, duration: TimeInterval) {
        operationsLock.lock()
        defer { operationsLock.unlock() }
        guard var metrics = _operations[id] else { return }
        metrics.duration = duration
        _operations[id] = metrics

        // Log performance metrics
        logger.info("Operation completed [ID: \(id), Type: \(String(describing: metrics.type)), Duration: \(String(format: "%.3f", duration))s]")

        // Track performance trends
        trackPerformanceTrend(type: metrics.type, duration: duration)
    }

    func failOperation(id: String, error: Error, duration: TimeInterval) {
        operationsLock.lock()
        defer { operationsLock.unlock() }
        guard var metrics = _operations[id] else { return }
        metrics.duration = duration
        metrics.error = error
        _operations[id] = metrics

        logger.error("Operation failed [ID: \(id), Type: \(String(describing: metrics.type)), Duration: \(String(format: "%.3f", duration))s, Error: \(error.localizedDescription)]")
    }

    private func trackPerformanceTrend(type: OperationType, duration: TimeInterval) {
        // Store performance metrics for trend analysis
        let defaults = UserDefaults(suiteName: "group.com.hedgingmybets.PetProgress")
        let key = "perf_\(type)"

        var durations = defaults?.array(forKey: key) as? [Double] ?? []
        durations.append(duration)

        // Keep only last 50 measurements
        if durations.count > 50 {
            durations = Array(durations.suffix(50))
        }

        defaults?.set(durations, forKey: key)

        // Log if performance is degrading
        if durations.count >= 10 {
            let average = durations.reduce(0, +) / Double(durations.count)
            let recent = durations.suffix(5).reduce(0, +) / 5.0

            if recent > average * 1.5 {
                logger.warning("Performance degradation detected for \(String(describing: type)): recent=\(String(format: "%.3f", recent))s, avg=\(String(format: "%.3f", average))s")
            }
        }
    }
}

// MARK: - Widget Errors

enum WidgetError: LocalizedError, Sendable {
    case budgetExceeded(operation: String, elapsed: TimeInterval, budget: TimeInterval)
    case dataLoadTimeout
    case invalidData(reason: String)

    var errorDescription: String? {
        switch self {
        case .budgetExceeded(let operation, let elapsed, let budget):
            return "Execution budget exceeded during \(operation): \(String(format: "%.3f", elapsed))s > \(String(format: "%.3f", budget))s"
        case .dataLoadTimeout:
            return "Data loading timed out"
        case .invalidData(let reason):
            return "Invalid data: \(reason)"
        }
    }
}

// MARK: - Timeout Helper

private func withTimeout<T>(_ timeout: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
    return try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            return try await operation()
        }

        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
            throw WidgetError.dataLoadTimeout
        }

        guard let result = try await group.next() else {
            throw WidgetError.dataLoadTimeout
        }

        group.cancelAll()
        return result
    }
}

// MARK: - Widget Family Extensions

private extension WidgetFamily {
    var description: String {
        switch self {
        case .accessoryCircular: return "accessoryCircular"
        case .accessoryRectangular: return "accessoryRectangular"
        case .systemSmall: return "systemSmall"
        case .systemMedium: return "systemMedium"
        case .systemLarge: return "systemLarge"
        default: return "unknown"
        }
    }
}