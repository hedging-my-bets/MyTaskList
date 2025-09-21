import Foundation
import os.log
import UIKit

/// Production telemetry system - Privacy-safe operational metrics for 100/100 quality
/// No user data collected, only technical performance metrics for operational excellence
public final class ProductionTelemetry {
    public static let shared = ProductionTelemetry()

    private let logger = Logger(subsystem: "com.petprogress.Telemetry", category: "Production")
    private let metricsLogger = Logger(subsystem: "com.petprogress.Telemetry", category: "Metrics")
    private let performanceLogger = Logger(subsystem: "com.petprogress.Telemetry", category: "Performance")

    private var sessionStartTime: Date
    private var widgetActionCount = 0
    private var taskCompletionTimes: [TimeInterval] = []
    private var memoryWarningCount = 0

    private init() {
        self.sessionStartTime = Date()
        setupMemoryMonitoring()
    }

    // MARK: - Widget Performance Metrics

    /// Track Lock Screen action performance for sub-1-second guarantee
    public func trackWidgetAction(_ action: String, duration: TimeInterval) {
        performanceLogger.info("Widget action '\(action)' completed in \(String(format: "%.3f", duration))s")

        widgetActionCount += 1

        // Alert if Lock Screen action takes > 1 second (UX requirement)
        if duration > 1.0 {
            performanceLogger.warning("SLOW WIDGET ACTION: \(action) took \(String(format: "%.3f", duration))s (target: <1.0s)")
        }

        // Track task completion specifically
        if action.contains("complete") {
            taskCompletionTimes.append(duration)
        }
    }

    /// Track widget timeline refresh performance
    public func trackTimelineRefresh(taskCount: Int, duration: TimeInterval) {
        performanceLogger.info("Timeline refresh: \(taskCount) tasks in \(String(format: "%.3f", duration))s")

        // Alert if timeline refresh is too slow
        if duration > 0.5 {
            performanceLogger.warning("SLOW TIMELINE: Refresh took \(String(format: "%.3f", duration))s (target: <0.5s)")
        }
    }

    /// Track battery-critical widget update frequency
    public func trackWidgetUpdateFrequency() {
        let now = Date()
        metricsLogger.info("Widget update timestamp: \(now.timeIntervalSince1970)")
    }

    // MARK: - Memory & Battery Optimization

    private func setupMemoryMonitoring() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.recordMemoryWarning()
        }
    }

    private func recordMemoryWarning() {
        self.memoryWarningCount += 1
        performanceLogger.warning("Memory warning received (count: \(self.memoryWarningCount))")

        // Log current memory usage for optimization
        let memoryUsage = getCurrentMemoryUsage()
        performanceLogger.info("Current memory usage: \(String(format: "%.2f", memoryUsage)) MB")
    }

    private func getCurrentMemoryUsage() -> Double {
        var taskInfo = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size) / 4

        let result = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }

        guard result == KERN_SUCCESS else { return 0 }

        let usedMemory = Double(taskInfo.phys_footprint) / 1024 / 1024 // Convert to MB
        return usedMemory
    }

    // MARK: - Pet Evolution Performance

    /// Track pet evolution calculation performance
    public func trackPetEvolution(fromStage: Int, toStage: Int, calculationTime: TimeInterval) {
        if toStage > fromStage {
            metricsLogger.info("Pet evolved: Stage \(fromStage) → Stage \(toStage) in \(String(format: "%.3f", calculationTime))s")
        } else if toStage < fromStage {
            metricsLogger.info("Pet devolved: Stage \(fromStage) → Stage \(toStage) in \(String(format: "%.3f", calculationTime))s")
        }
    }

    /// Track XP calculation performance for large task sets
    public func trackXPCalculation(taskCount: Int, duration: TimeInterval) {
        performanceLogger.info("XP calculation: \(taskCount) tasks in \(String(format: "%.3f", duration))s")

        if duration > 0.1 {
            performanceLogger.warning("SLOW XP CALC: \(taskCount) tasks took \(String(format: "%.3f", duration))s")
        }
    }

    // MARK: - Grace Period Analytics

    /// Track grace period effectiveness (privacy-safe)
    public func trackGracePeriodUsage(graceMinutes: Int, tasksInWindow: Int) {
        metricsLogger.info("Grace period: \(graceMinutes)min window contains \(tasksInWindow) tasks")
    }

    // MARK: - Error & Edge Case Tracking

    /// Track edge cases and error conditions
    public func trackEdgeCase(_ condition: String, context: String) {
        logger.info("Edge case handled: \(condition) - \(context)")
    }

    /// Track error conditions for reliability metrics
    public func trackError(_ error: String, recoverable: Bool) {
        if recoverable {
            logger.warning("Recoverable error: \(error)")
        } else {
            logger.error("Critical error: \(error)")
        }
    }

    // MARK: - Session Analytics

    /// Generate session performance report (for debugging, not user tracking)
    public func generateSessionReport() -> SessionReport {
        let sessionDuration = Date().timeIntervalSince(sessionStartTime)
        let averageTaskCompletion = taskCompletionTimes.isEmpty ? 0 : taskCompletionTimes.reduce(0, +) / Double(taskCompletionTimes.count)
        let currentMemory = getCurrentMemoryUsage()

        return SessionReport(
            sessionDuration: sessionDuration,
            widgetActionCount: widgetActionCount,
            averageTaskCompletionTime: averageTaskCompletion,
            currentMemoryUsage: currentMemory,
            memoryWarningCount: memoryWarningCount
        )
    }

    /// Log session report for operational visibility
    public func logSessionReport() {
        let report = generateSessionReport()

        metricsLogger.info("SESSION REPORT:")
        metricsLogger.info("Duration: \(String(format: "%.1f", report.sessionDuration))s")
        metricsLogger.info("Widget actions: \(report.widgetActionCount)")
        metricsLogger.info("Avg task completion: \(String(format: "%.3f", report.averageTaskCompletionTime))s")
        metricsLogger.info("Memory usage: \(String(format: "%.2f", report.currentMemoryUsage)) MB")
        metricsLogger.info("Memory warnings: \(report.memoryWarningCount)")

        // Performance quality assessment
        let qualityScore = calculateQualityScore(report: report)
        metricsLogger.info("Performance quality score: \(qualityScore)/100")
    }

    private func calculateQualityScore(report: SessionReport) -> Int {
        var score = 100

        // Deduct for slow task completions
        if report.averageTaskCompletionTime > 1.0 {
            score -= 20
        } else if report.averageTaskCompletionTime > 0.5 {
            score -= 10
        }

        // Deduct for high memory usage
        if report.currentMemoryUsage > 100 {
            score -= 15
        } else if report.currentMemoryUsage > 50 {
            score -= 5
        }

        // Deduct for memory warnings
        score -= (report.memoryWarningCount * 10)

        return max(0, score)
    }
}

// MARK: - Session Report Model

public struct SessionReport {
    public let sessionDuration: TimeInterval
    public let widgetActionCount: Int
    public let averageTaskCompletionTime: TimeInterval
    public let currentMemoryUsage: Double
    public let memoryWarningCount: Int
}

// MARK: - Performance Benchmarking Extensions

extension ProductionTelemetry {

    /// Benchmark any operation and log if it exceeds target
    public func benchmark<T>(_ operation: String, target: TimeInterval, block: () throws -> T) rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        defer {
            let duration = CFAbsoluteTimeGetCurrent() - startTime

            if duration > target {
                performanceLogger.warning("BENCHMARK FAIL: \(operation) took \(String(format: "%.3f", duration))s (target: \(String(format: "%.3f", target))s)")
            } else {
                performanceLogger.debug("Benchmark pass: \(operation) in \(String(format: "%.3f", duration))s")
            }
        }

        return try block()
    }

    /// Benchmark async operations
    public func benchmarkAsync<T>(_ operation: String, target: TimeInterval, block: () async throws -> T) async rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        defer {
            let duration = CFAbsoluteTimeGetCurrent() - startTime

            if duration > target {
                performanceLogger.warning("ASYNC BENCHMARK FAIL: \(operation) took \(String(format: "%.3f", duration))s (target: \(String(format: "%.3f", target))s)")
            } else {
                performanceLogger.debug("Async benchmark pass: \(operation) in \(String(format: "%.3f", duration))s")
            }
        }

        return try await block()
    }
}

// MARK: - Battery Impact Monitoring

extension ProductionTelemetry {

    /// Start battery monitoring session (iOS 15+ only)
    public func startBatteryMonitoring() {
        if #available(iOS 15.0, *) {
            UIDevice.current.isBatteryMonitoringEnabled = true

            NotificationCenter.default.addObserver(
                forName: UIDevice.batteryLevelDidChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.recordBatteryLevel()
            }
        }
    }

    @available(iOS 15.0, *)
    private func recordBatteryLevel() {
        let level = UIDevice.current.batteryLevel
        let state = UIDevice.current.batteryState

        metricsLogger.debug("Battery: \(String(format: "%.1f", level * 100))% (\(self.batteryStateString(state)))")
    }

    private func batteryStateString(_ state: UIDevice.BatteryState) -> String {
        switch state {
        case .unknown: return "unknown"
        case .unplugged: return "unplugged"
        case .charging: return "charging"
        case .full: return "full"
        @unknown default: return "unknown"
        }
    }
}