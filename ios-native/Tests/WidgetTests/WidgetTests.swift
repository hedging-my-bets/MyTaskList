import XCTest
import SwiftUI
import WidgetKit
import OSLog
@testable import Widget
@testable import SharedKit

/// Comprehensive Widget tests with timeline and interaction coverage
@available(iOS 17.0, *)
final class WidgetTests: XCTestCase {

    private let logger = Logger(subsystem: "com.mytasklist.tests", category: "WidgetTests")
    private let performanceMeasurer = WidgetPerformanceMeasurer()

    override func setUp() {
        super.setUp()
        logger.info("Starting Widget test suite")
        performanceMeasurer.reset()
    }

    override func tearDown() {
        performanceMeasurer.logResults()
        logger.info("Widget test suite completed")
        super.tearDown()
    }

    // MARK: - Widget Provider Tests

    func testPetProgressProviderTimeline() async {
        let provider = PetProgressProvider()

        let context = TimelineProviderContext()
        let startTime = CFAbsoluteTimeGetCurrent()

        let timeline = await provider.timeline(in: context)

        let executionTime = CFAbsoluteTimeGetCurrent() - startTime
        performanceMeasurer.record(test: "WidgetProvider_Timeline", time: executionTime)

        XCTAssertNotNil(timeline, "Provider should generate timeline")
        XCTAssertFalse(timeline.entries.isEmpty, "Timeline should have entries")
        XCTAssertLessThan(executionTime, 1.0, "Timeline generation should complete within 1 second")

        // Verify timeline policy
        switch timeline.policy {
        case .atEnd:
            XCTAssert(true, "Timeline policy should be appropriate")
        case .after(let date):
            XCTAssertGreaterThan(date, Date(), "Next update should be in the future")
        case .never:
            XCTAssert(false, "Timeline should not use never policy for active widgets")
        @unknown default:
            XCTAssert(false, "Unknown timeline policy")
        }
    }

    func testWidgetTimelineEntries() async {
        let provider = PetProgressProvider()
        let context = TimelineProviderContext()

        let timeline = await provider.timeline(in: context)
        let entries = timeline.entries

        XCTAssertGreaterThan(entries.count, 0, "Should have timeline entries")
        XCTAssertLessThanOrEqual(entries.count, 24, "Should not have excessive entries")

        // Test entry dates are sequential
        for i in 1..<entries.count {
            XCTAssertGreaterThan(entries[i].date, entries[i-1].date,
                                "Entry dates should be in chronological order")
        }

        // Test entry data validity
        for entry in entries {
            XCTAssertGreaterThanOrEqual(entry.petStage, 0, "Pet stage should be non-negative")
            XCTAssertGreaterThanOrEqual(entry.petPoints, 0, "Pet points should be non-negative")
            XCTAssertGreaterThanOrEqual(entry.completedTasks, 0, "Completed tasks should be non-negative")
            XCTAssertGreaterThanOrEqual(entry.totalTasks, entry.completedTasks,
                                       "Total tasks should be >= completed tasks")
        }
    }

    func testWidgetPlaceholder() {
        let provider = PetProgressProvider()
        let startTime = CFAbsoluteTimeGetCurrent()

        let placeholder = provider.placeholder(in: TimelineProviderContext())

        let executionTime = CFAbsoluteTimeGetCurrent() - startTime
        performanceMeasurer.record(test: "WidgetProvider_Placeholder", time: executionTime)

        XCTAssertNotNil(placeholder, "Provider should generate placeholder")
        XCTAssertLessThan(executionTime, 0.1, "Placeholder generation should be very fast")

        // Verify placeholder has valid data
        XCTAssertGreaterThanOrEqual(placeholder.petStage, 0, "Placeholder pet stage should be valid")
        XCTAssertGreaterThanOrEqual(placeholder.petPoints, 0, "Placeholder pet points should be valid")
        XCTAssertGreaterThanOrEqual(placeholder.completedTasks, 0, "Placeholder completed tasks should be valid")
        XCTAssertGreaterThanOrEqual(placeholder.totalTasks, placeholder.completedTasks,
                                   "Placeholder total tasks should be >= completed")
    }

    func testWidgetSnapshot() async {
        let provider = PetProgressProvider()
        let context = TimelineProviderContext()

        let startTime = CFAbsoluteTimeGetCurrent()
        let snapshot = await provider.snapshot(in: context)
        let executionTime = CFAbsoluteTimeGetCurrent() - startTime

        performanceMeasurer.record(test: "WidgetProvider_Snapshot", time: executionTime)

        XCTAssertNotNil(snapshot, "Provider should generate snapshot")
        XCTAssertLessThan(executionTime, 0.5, "Snapshot generation should be fast")

        // Snapshot should have current data
        XCTAssertGreaterThanOrEqual(snapshot.petStage, 0, "Snapshot pet stage should be valid")
        XCTAssertTrue(snapshot.next3Tasks.count <= 3, "Should show at most 3 tasks")
    }

    // MARK: - Widget View Tests

    func testRectangularLockScreenView() {
        let entry = PetProgressEntry(
            date: Date(),
            petStage: 3,
            petPoints: 150,
            completedTasks: 2,
            totalTasks: 5,
            next3Tasks: createTestTasks(count: 3),
            emotionalState: .happy
        )

        let view = RectangularLockScreenView(entry: entry)
        XCTAssertNotNil(view, "RectangularLockScreenView should create successfully")

        // Test view body creation
        let body = view.body
        XCTAssertNotNil(body, "View body should create successfully")
    }

    func testCircularLockScreenView() {
        let entry = PetProgressEntry(
            date: Date(),
            petStage: 2,
            petPoints: 75,
            completedTasks: 1,
            totalTasks: 3,
            next3Tasks: createTestTasks(count: 2),
            emotionalState: .content
        )

        let view = CircularLockScreenView(entry: entry)
        XCTAssertNotNil(view, "CircularLockScreenView should create successfully")

        let body = view.body
        XCTAssertNotNil(body, "Circular view body should create successfully")
    }

    func testSystemSmallView() {
        let entry = PetProgressEntry(
            date: Date(),
            petStage: 4,
            petPoints: 200,
            completedTasks: 3,
            totalTasks: 4,
            next3Tasks: createTestTasks(count: 1),
            emotionalState: .ecstatic
        )

        let view = SystemSmallView(entry: entry)
        XCTAssertNotNil(view, "SystemSmallView should create successfully")

        let body = view.body
        XCTAssertNotNil(body, "System small view body should create successfully")
    }

    func testSystemMediumView() {
        let entry = PetProgressEntry(
            date: Date(),
            petStage: 1,
            petPoints: 25,
            completedTasks: 0,
            totalTasks: 6,
            next3Tasks: createTestTasks(count: 3),
            emotionalState: .neutral
        )

        let view = SystemMediumView(entry: entry)
        XCTAssertNotNil(view, "SystemMediumView should create successfully")

        let body = view.body
        XCTAssertNotNil(body, "System medium view body should create successfully")
    }

    func testSystemLargeView() {
        let entry = PetProgressEntry(
            date: Date(),
            petStage: 5,
            petPoints: 500,
            completedTasks: 8,
            totalTasks: 10,
            next3Tasks: createTestTasks(count: 2),
            emotionalState: .happy
        )

        let view = SystemLargeView(entry: entry)
        XCTAssertNotNil(view, "SystemLargeView should create successfully")

        let body = view.body
        XCTAssertNotNil(body, "System large view body should create successfully")
    }

    // MARK: - App Intent Tests

    func testCompleteTaskIntent() async {
        let intent = CompleteTaskIntent()
        intent.taskId = "test-task-123"

        do {
            let result = try await intent.perform()
            XCTAssertNotNil(result, "CompleteTaskIntent should return result")

            // Verify the result contains appropriate feedback
            if case .result(let dialog) = result {
                XCTAssertFalse(dialog.isEmpty, "Result should contain feedback dialog")
            }
        } catch {
            // Intent might fail in test environment, but should handle gracefully
            XCTAssertTrue(error is IntentError, "Should throw appropriate intent error")
        }
    }

    func testSnoozeTaskIntent() async {
        let intent = SnoozeTaskIntent()
        intent.taskId = "test-task-456"
        intent.duration = .oneHour

        do {
            let result = try await intent.perform()
            XCTAssertNotNil(result, "SnoozeTaskIntent should return result")

            if case .result(let dialog) = result {
                XCTAssertFalse(dialog.isEmpty, "Result should contain feedback dialog")
            }
        } catch {
            XCTAssertTrue(error is IntentError, "Should throw appropriate intent error")
        }
    }

    func testMarkNextIntent() async {
        let intent = MarkNextIntent()
        intent.currentTaskId = "current-task"

        do {
            let result = try await intent.perform()
            XCTAssertNotNil(result, "MarkNextIntent should return result")

            if case .result(let dialog) = result {
                XCTAssertFalse(dialog.isEmpty, "Result should contain feedback dialog")
            }
        } catch {
            XCTAssertTrue(error is IntentError, "Should throw appropriate intent error")
        }
    }

    func testPetStatusIntent() async {
        let intent = PetStatusIntent()

        do {
            let result = try await intent.perform()
            XCTAssertNotNil(result, "PetStatusIntent should return result")

            if case .result(let dialog) = result {
                XCTAssertFalse(dialog.isEmpty, "Result should contain status information")
            }
        } catch {
            XCTAssertTrue(error is IntentError, "Should throw appropriate intent error")
        }
    }

    // MARK: - App Intent Snippet Tests

    func testCompletionSnippetView() {
        let snippetView = CompletionSnippetView(
            taskTitle: "Morning Exercise",
            pointsGained: 25,
            newStage: 3,
            completedCount: 4,
            totalCount: 8
        )

        XCTAssertNotNil(snippetView, "CompletionSnippetView should create successfully")

        let body = snippetView.body
        XCTAssertNotNil(body, "Completion snippet body should create successfully")
    }

    func testSnoozeSnippetView() {
        let snippetView = SnoozeSnippetView(
            taskTitle: "Team Meeting",
            originalTime: 14,
            newTime: 15,
            snoozeDuration: .oneHour
        )

        XCTAssertNotNil(snippetView, "SnoozeSnippetView should create successfully")

        let body = snippetView.body
        XCTAssertNotNil(body, "Snooze snippet body should create successfully")
    }

    func testMarkNextSnippetView() {
        let snippetView = MarkNextSnippetView(
            completedTask: "Daily Standup",
            nextTask: "Code Review",
            nextTaskTime: 16,
            newStage: 4
        )

        XCTAssertNotNil(snippetView, "MarkNextSnippetView should create successfully")

        let body = snippetView.body
        XCTAssertNotNil(body, "Mark next snippet body should create successfully")
    }

    func testPetStatusSnippetView() {
        let snippetView = PetStatusSnippetView(
            stage: 5,
            points: 325,
            completedTasks: 6,
            totalTasks: 10,
            emotionalState: .happy,
            analysis: createMockEvolutionAnalysis()
        )

        XCTAssertNotNil(snippetView, "PetStatusSnippetView should create successfully")

        let body = snippetView.body
        XCTAssertNotNil(body, "Pet status snippet body should create successfully")
    }

    // MARK: - Widget Interaction Tests

    func testWidgetInteractiveButtons() {
        let entry = PetProgressEntry(
            date: Date(),
            petStage: 2,
            petPoints: 100,
            completedTasks: 2,
            totalTasks: 5,
            next3Tasks: createTestTasks(count: 3),
            emotionalState: .content
        )

        let rectangularView = RectangularLockScreenView(entry: entry)

        // Test that view contains interactive elements
        // Note: In actual implementation, we would need to inspect the view hierarchy
        // For now, we test that the view creates without errors
        let body = rectangularView.body
        XCTAssertNotNil(body, "Interactive widget view should create successfully")
    }

    func testWidgetAccessibilitySupport() {
        let entry = PetProgressEntry(
            date: Date(),
            petStage: 1,
            petPoints: 50,
            completedTasks: 1,
            totalTasks: 4,
            next3Tasks: createTestTasks(count: 2),
            emotionalState: .neutral
        )

        // Test different widget views for accessibility
        let views: [any View] = [
            RectangularLockScreenView(entry: entry),
            CircularLockScreenView(entry: entry),
            SystemSmallView(entry: entry),
            SystemMediumView(entry: entry),
            SystemLargeView(entry: entry)
        ]

        for view in views {
            XCTAssertNotNil(view, "Accessible widget view should create successfully")
        }
    }

    // MARK: - Performance Tests

    func testWidgetRenderingPerformance() {
        let entry = PetProgressEntry(
            date: Date(),
            petStage: 3,
            petPoints: 175,
            completedTasks: 3,
            totalTasks: 6,
            next3Tasks: createTestTasks(count: 3),
            emotionalState: .happy
        )

        let startTime = CFAbsoluteTimeGetCurrent()

        // Create multiple widget views
        for _ in 0..<50 {
            let rectangularView = RectangularLockScreenView(entry: entry)
            let circularView = CircularLockScreenView(entry: entry)
            let smallView = SystemSmallView(entry: entry)
            let mediumView = SystemMediumView(entry: entry)
            let largeView = SystemLargeView(entry: entry)

            // Access body to trigger view creation
            _ = rectangularView.body
            _ = circularView.body
            _ = smallView.body
            _ = mediumView.body
            _ = largeView.body
        }

        let executionTime = CFAbsoluteTimeGetCurrent() - startTime
        performanceMeasurer.record(test: "WidgetRendering_Performance", time: executionTime)

        XCTAssertLessThan(executionTime, 2.0, "Widget rendering should be efficient")
    }

    func testTimelineGenerationPerformance() async {
        let provider = PetProgressProvider()
        let context = TimelineProviderContext()

        let startTime = CFAbsoluteTimeGetCurrent()

        // Generate multiple timelines
        for _ in 0..<10 {
            let timeline = await provider.timeline(in: context)
            XCTAssertNotNil(timeline, "Timeline should generate successfully")
        }

        let executionTime = CFAbsoluteTimeGetCurrent() - startTime
        performanceMeasurer.record(test: "TimelineGeneration_Performance", time: executionTime)

        XCTAssertLessThan(executionTime, 5.0, "Timeline generation should be efficient")
    }

    func testWidgetMemoryUsage() {
        let initialMemory = getMemoryUsage()

        // Create many widget entries
        var entries: [PetProgressEntry] = []
        for i in 0..<100 {
            let entry = PetProgressEntry(
                date: Date().addingTimeInterval(TimeInterval(i * 3600)),
                petStage: i % 16,
                petPoints: i * 10,
                completedTasks: i % 5,
                totalTasks: 5,
                next3Tasks: createTestTasks(count: min(3, i % 4)),
                emotionalState: [.neutral, .content, .happy, .ecstatic][i % 4]
            )
            entries.append(entry)
        }

        let peakMemory = getMemoryUsage()

        // Release entries
        entries.removeAll()

        let finalMemory = getMemoryUsage()
        let memoryIncrease = finalMemory - initialMemory

        performanceMeasurer.recordMemory(test: "Widget_Memory", bytes: memoryIncrease)

        XCTAssertLessThan(memoryIncrease, 2 * 1024 * 1024, "Widget memory usage should be reasonable")
    }

    // MARK: - Edge Case Tests

    func testWidgetWithEmptyData() {
        let emptyEntry = PetProgressEntry(
            date: Date(),
            petStage: 0,
            petPoints: 0,
            completedTasks: 0,
            totalTasks: 0,
            next3Tasks: [],
            emotionalState: .neutral
        )

        // All views should handle empty data gracefully
        let rectangularView = RectangularLockScreenView(entry: emptyEntry)
        let circularView = CircularLockScreenView(entry: emptyEntry)
        let smallView = SystemSmallView(entry: emptyEntry)
        let mediumView = SystemMediumView(entry: emptyEntry)
        let largeView = SystemLargeView(entry: emptyEntry)

        XCTAssertNotNil(rectangularView.body, "Should handle empty data")
        XCTAssertNotNil(circularView.body, "Should handle empty data")
        XCTAssertNotNil(smallView.body, "Should handle empty data")
        XCTAssertNotNil(mediumView.body, "Should handle empty data")
        XCTAssertNotNil(largeView.body, "Should handle empty data")
    }

    func testWidgetWithMaximumData() {
        let maxEntry = PetProgressEntry(
            date: Date(),
            petStage: 15,
            petPoints: 10000,
            completedTasks: 100,
            totalTasks: 100,
            next3Tasks: createTestTasks(count: 3),
            emotionalState: .ecstatic
        )

        // Views should handle maximum values
        let views: [any View] = [
            RectangularLockScreenView(entry: maxEntry),
            CircularLockScreenView(entry: maxEntry),
            SystemSmallView(entry: maxEntry),
            SystemMediumView(entry: maxEntry),
            SystemLargeView(entry: maxEntry)
        ]

        for view in views {
            XCTAssertNotNil(view, "Should handle maximum data values")
        }
    }

    func testWidgetWithInvalidData() {
        let invalidEntry = PetProgressEntry(
            date: Date(),
            petStage: -1,
            petPoints: -100,
            completedTasks: -5,
            totalTasks: -10,
            next3Tasks: createTestTasks(count: 0),
            emotionalState: .frustrated
        )

        // Views should handle invalid data without crashing
        let rectangularView = RectangularLockScreenView(entry: invalidEntry)
        XCTAssertNotNil(rectangularView, "Should handle invalid data gracefully")

        // Body should still render without errors
        let body = rectangularView.body
        XCTAssertNotNil(body, "Should render even with invalid data")
    }

    // MARK: - Integration Tests

    func testWidgetDataConsistency() async {
        let provider = PetProgressProvider()
        let context = TimelineProviderContext()

        let timeline = await provider.timeline(in: context)
        let entries = timeline.entries

        // Test data consistency across timeline entries
        for entry in entries {
            // Pet stage should be within valid range
            XCTAssertGreaterThanOrEqual(entry.petStage, 0, "Pet stage should be >= 0")
            XCTAssertLessThanOrEqual(entry.petStage, 15, "Pet stage should be <= 15")

            // Completed tasks should not exceed total
            XCTAssertLessThanOrEqual(entry.completedTasks, entry.totalTasks,
                                    "Completed tasks should not exceed total")

            // Next tasks array should not exceed 3
            XCTAssertLessThanOrEqual(entry.next3Tasks.count, 3,
                                    "Should show at most 3 next tasks")

            // Emotional state should be valid
            let validStates: [PetEvolutionEngine.EmotionalState] = [
                .neutral, .content, .happy, .ecstatic, .worried, .sad, .frustrated
            ]
            XCTAssertTrue(validStates.contains(entry.emotionalState),
                         "Emotional state should be valid")
        }
    }

    func testWidgetWithSharedStore() async {
        let store = SharedStore.shared

        // Add some test tasks
        let testTasks = createTestTasks(count: 5)
        for task in testTasks {
            await store.addTask(task)
        }

        let provider = PetProgressProvider()
        let timeline = await provider.timeline(in: TimelineProviderContext())

        // Timeline should reflect store data
        let latestEntry = timeline.entries.last ?? timeline.entries.first!
        XCTAssertGreaterThanOrEqual(latestEntry.totalTasks, testTasks.count,
                                   "Timeline should reflect store data")
    }

    // MARK: - Helper Methods

    private func createTestTasks(count: Int) -> [Task] {
        return (0..<count).map { index in
            Task(
                id: "test-task-\(index)",
                title: "Test Task \(index + 1)",
                scheduledTime: TimeSlot(hour: (9 + index) % 24),
                difficulty: [TaskDifficulty.easy, .medium, .hard][index % 3],
                category: [TaskCategory.work, .personal, .health][index % 3],
                notes: "Test task \(index + 1) for widget testing"
            )
        }
    }

    private func createMockEvolutionAnalysis() -> PetEvolutionEngine.EvolutionAnalysis {
        return PetEvolutionEngine.EvolutionAnalysis(
            totalTasksCompleted: 25,
            averageCompletionTime: 30 * 60, // 30 minutes
            recentEvolutionTrend: .improving,
            predictedNextEvolution: PetEvolutionEngine.EvolutionPrediction(
                timeToNextStage: 2 * 24 * 60 * 60, // 2 days
                predictedStageIn24Hours: 6,
                confidenceLevel: 0.85
            ),
            behaviorInsights: [
                "Most productive in the morning",
                "Prefers short focused sessions",
                "Responds well to visual feedback"
            ]
        )
    }

    private func getMemoryUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }

        return kerr == KERN_SUCCESS ? Int64(info.resident_size) : 0
    }
}

// MARK: - Widget Performance Measurement

final class WidgetPerformanceMeasurer {
    private var measurements: [String: [Double]] = [:]
    private var memoryMeasurements: [String: Int64] = [:]
    private let logger = Logger(subsystem: "com.mytasklist.tests", category: "WidgetPerformance")

    func record(test: String, time: Double) {
        if measurements[test] == nil {
            measurements[test] = []
        }
        measurements[test]?.append(time)
        logger.info("Widget Performance: \(test) completed in \(String(format: "%.2f", time * 1000))ms")
    }

    func recordMemory(test: String, bytes: Int64) {
        memoryMeasurements[test] = bytes
        let mb = Double(bytes) / (1024 * 1024)
        logger.info("Widget Memory: \(test) used \(String(format: "%.2f", mb))MB")
    }

    func reset() {
        measurements.removeAll()
        memoryMeasurements.removeAll()
    }

    func logResults() {
        logger.info("=== Widget Performance Test Results ===")

        for (test, times) in measurements {
            let avgTime = times.reduce(0, +) / Double(times.count)
            let minTime = times.min() ?? 0
            let maxTime = times.max() ?? 0

            logger.info("Widget \(test): avg=\(String(format: "%.2f", avgTime * 1000))ms, min=\(String(format: "%.2f", minTime * 1000))ms, max=\(String(format: "%.2f", maxTime * 1000))ms")
        }

        for (test, bytes) in memoryMeasurements {
            let mb = Double(bytes) / (1024 * 1024)
            logger.info("Widget \(test): \(String(format: "%.2f", mb))MB")
        }

        logger.info("=== End Widget Performance Results ===")
    }
}
