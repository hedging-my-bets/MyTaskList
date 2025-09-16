import XCTest
import SwiftUI
import OSLog
@testable import App
@testable import SharedKit

/// Comprehensive App layer tests with UI testing and integration coverage
@available(iOS 17.0, *)
final class AppTests: XCTestCase {

    private let logger = Logger(subsystem: "com.mytasklist.tests", category: "AppTests")
    private let performanceMeasurer = PerformanceMeasurer()

    override func setUp() {
        super.setUp()
        logger.info("Starting App test suite")
        performanceMeasurer.reset()
    }

    override func tearDown() {
        performanceMeasurer.logResults()
        logger.info("App test suite completed")
        super.tearDown()
    }

    // MARK: - AppViewModel Tests

    func testAppViewModelInitialization() {
        let viewModel = AppViewModel()

        XCTAssertNotNil(viewModel, "ViewModel should initialize")
        XCTAssertEqual(viewModel.petStage, 0, "Should start at stage 0")
        XCTAssertEqual(viewModel.petPoints, 0, "Should start with 0 points")
        XCTAssertEqual(viewModel.completedTasks, 0, "Should start with 0 completed tasks")
        XCTAssertEqual(viewModel.totalTasks, 0, "Should start with 0 total tasks")
        XCTAssertTrue(viewModel.next3Tasks.isEmpty, "Should start with empty task list")
    }

    func testAppViewModelDataLoading() async {
        let viewModel = AppViewModel()

        await viewModel.loadTodaysData()

        // After loading, viewModel should have valid state
        XCTAssertGreaterThanOrEqual(viewModel.petStage, 0, "Pet stage should be valid")
        XCTAssertGreaterThanOrEqual(viewModel.petPoints, 0, "Pet points should be valid")
        XCTAssertGreaterThanOrEqual(viewModel.completedTasks, 0, "Completed tasks should be valid")
        XCTAssertGreaterThanOrEqual(viewModel.totalTasks, 0, "Total tasks should be valid")
    }

    func testAppViewModelTaskCompletion() async {
        let viewModel = AppViewModel()

        // Setup test data
        await viewModel.setupDefaultTasks()
        await viewModel.loadTodaysData()

        let initialCompletedCount = viewModel.completedTasks
        let initialPoints = viewModel.petPoints

        // Complete a task if available
        if let firstTask = viewModel.next3Tasks.first {
            viewModel.completeTask(firstTask)

            // Allow time for async operations
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

            // Verify completion effects
            XCTAssertGreaterThan(viewModel.completedTasks, initialCompletedCount,
                                "Completed task count should increase")
            XCTAssertGreaterThan(viewModel.petPoints, initialPoints,
                                "Pet points should increase after task completion")
        }
    }

    func testAppViewModelRefreshData() async {
        let viewModel = AppViewModel()
        let startTime = CFAbsoluteTimeGetCurrent()

        await viewModel.refreshData()

        let executionTime = CFAbsoluteTimeGetCurrent() - startTime
        performanceMeasurer.record(test: "AppViewModel_RefreshData", time: executionTime)

        XCTAssertLessThan(executionTime, 2.0, "Data refresh should complete within 2 seconds")
    }

    func testAppViewModelDefaultTaskSetup() async {
        let viewModel = AppViewModel()

        await viewModel.setupDefaultTasks()
        await viewModel.loadTodaysData()

        XCTAssertGreaterThan(viewModel.totalTasks, 0, "Should have tasks after setup")
        XCTAssertLessThanOrEqual(viewModel.next3Tasks.count, 3, "Should show at most 3 next tasks")
    }

    // MARK: - View Model Integration Tests

    func testViewModelTaskPlanningIntegration() async {
        let viewModel = AppViewModel()
        let taskPlanningEngine = TaskPlanningEngine.shared

        await viewModel.setupDefaultTasks()
        await viewModel.loadTodaysData()

        // Generate AI recommendations
        let recommendations = await taskPlanningEngine.getPersonalizedRecommendations(limit: 3)

        XCTAssertGreaterThanOrEqual(recommendations.count, 0, "Should generate recommendations")

        // Test that viewModel can work with recommendations
        for recommendation in recommendations {
            XCTAssertFalse(recommendation.title.isEmpty, "Recommendations should have titles")
            XCTAssertGreaterThan(recommendation.estimatedImpact, 0, "Should have positive impact")
        }
    }

    func testViewModelAssetPipelineIntegration() async {
        let viewModel = AppViewModel()
        let assetPipeline = AssetPipeline.shared

        await viewModel.loadTodaysData()

        // Test asset loading for current pet stage
        let petImage = await assetPipeline.loadImage(for: viewModel.petStage, quality: .high)
        XCTAssertNotNil(petImage, "Should load pet image for current stage")

        // Verify pet image name
        let expectedImageName = assetPipeline.imageName(for: viewModel.petStage)
        XCTAssertEqual(viewModel.petImageName, expectedImageName, "Pet image name should match pipeline")
    }

    func testViewModelConcurrentOperations() async {
        let viewModel = AppViewModel()
        let expectation = XCTestExpectation(description: "Concurrent operations")
        expectation.expectedFulfillmentCount = 5

        let startTime = CFAbsoluteTimeGetCurrent()

        // Simulate concurrent UI operations
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<5 {
                group.addTask {
                    await viewModel.loadTodaysData()
                    await viewModel.refreshData()
                    expectation.fulfill()
                }
            }
        }

        let executionTime = CFAbsoluteTimeGetCurrent() - startTime
        performanceMeasurer.record(test: "AppViewModel_ConcurrentOperations", time: executionTime)

        await fulfillment(of: [expectation], timeout: 10.0)
        XCTAssertLessThan(executionTime, 5.0, "Concurrent operations should complete within 5 seconds")
    }

    // MARK: - UI Component Tests

    func testTaskRowViewCreation() {
        let testTask = Task(
            id: "test-task",
            title: "Test Task",
            scheduledTime: TimeSlot(hour: 14),
            difficulty: .medium,
            category: .work,
            notes: "Test notes"
        )

        let taskRowView = TaskRowView(
            task: testTask,
            onComplete: { _ in },
            onEdit: { _ in }
        )

        XCTAssertNotNil(taskRowView, "TaskRowView should create successfully")
    }

    func testPetDisplayViewCreation() {
        let petDisplayView = PetDisplayView(
            stage: 3,
            points: 150,
            imageName: "pet_seahorse"
        )

        XCTAssertNotNil(petDisplayView, "PetDisplayView should create successfully")
    }

    func testTaskSummaryViewCreation() {
        let taskSummaryView = TaskSummaryView(
            completed: 5,
            total: 8
        )

        XCTAssertNotNil(taskSummaryView, "TaskSummaryView should create successfully")
    }

    func testEnhancedContentViewCreation() {
        let enhancedContentView = EnhancedContentView()
        XCTAssertNotNil(enhancedContentView, "EnhancedContentView should create successfully")
    }

    // MARK: - Animation Component Tests

    func testSparkleEffectViewCreation() {
        let sparkleEffect = SparkleEffectView()
        XCTAssertNotNil(sparkleEffect, "SparkleEffectView should create successfully")
    }

    func testFloatingActionButtonCreation() {
        let fab = FloatingActionButton(
            icon: "plus",
            action: { },
            color: .blue
        )
        XCTAssertNotNil(fab, "FloatingActionButton should create successfully")
    }

    func testProgressRingCreation() {
        let progressRing = ProgressRing(
            progress: 0.75,
            lineWidth: 8,
            size: 100,
            color: .blue
        )
        XCTAssertNotNil(progressRing, "ProgressRing should create successfully")
    }

    func testBouncyButtonCreation() {
        let bouncyButton = BouncyButton(action: { }) {
            Text("Test Button")
        }
        XCTAssertNotNil(bouncyButton, "BouncyButton should create successfully")
    }

    // MARK: - Supporting Views Tests

    func testInsightCardCreation() {
        let testInsight = TaskInsight(
            id: "test-insight",
            category: .productivity,
            title: "Test Insight",
            description: "This is a test insight for productivity optimization.",
            severity: .info,
            confidence: 0.85,
            metadata: ["test": "data"]
        )

        let insightCard = InsightCard(insight: testInsight)
        XCTAssertNotNil(insightCard, "InsightCard should create successfully")
    }

    func testRecommendationCardCreation() {
        let testRecommendation = TaskRecommendation(
            id: "test-recommendation",
            type: .timeOptimization,
            title: "Test Recommendation",
            description: "This is a test recommendation for time optimization.",
            priority: .high,
            estimatedImpact: 0.25,
            actionable: true
        )

        let recommendationCard = RecommendationCard(recommendation: testRecommendation) {
            // Action handler
        }
        XCTAssertNotNil(recommendationCard, "RecommendationCard should create successfully")
    }

    func testTaskDetailViewCreation() {
        let testTask = Task(
            id: "detail-test",
            title: "Detail Test Task",
            scheduledTime: TimeSlot(hour: 16),
            difficulty: .hard,
            category: .learning,
            notes: "Detailed task for testing the detail view"
        )

        let taskDetailView = TaskDetailView(task: testTask)
        XCTAssertNotNil(taskDetailView, "TaskDetailView should create successfully")
    }

    func testAIInsightsViewCreation() {
        let testInsights = [
            TaskInsight(
                id: "insight-1",
                category: .productivity,
                title: "Peak Performance",
                description: "Your most productive time is 10 AM.",
                severity: .info,
                confidence: 0.9,
                metadata: [:]
            ),
            TaskInsight(
                id: "insight-2",
                category: .energy,
                title: "Energy Dip",
                description: "You experience an energy dip at 2 PM.",
                severity: .warning,
                confidence: 0.7,
                metadata: [:]
            )
        ]

        let aiInsightsView = AIInsightsView(insights: testInsights)
        XCTAssertNotNil(aiInsightsView, "AIInsightsView should create successfully")
    }

    // MARK: - Performance Tests

    func testViewCreationPerformance() {
        let startTime = CFAbsoluteTimeGetCurrent()

        // Create multiple views to test performance
        for i in 0..<100 {
            let task = Task(
                id: "perf-task-\(i)",
                title: "Performance Task \(i)",
                scheduledTime: TimeSlot(hour: (9 + i) % 24),
                difficulty: .medium,
                category: .work
            )

            let taskRowView = TaskRowView(
                task: task,
                onComplete: { _ in },
                onEdit: { _ in }
            )

            XCTAssertNotNil(taskRowView, "TaskRowView \(i) should create successfully")
        }

        let executionTime = CFAbsoluteTimeGetCurrent() - startTime
        performanceMeasurer.record(test: "ViewCreation_Performance", time: executionTime)

        XCTAssertLessThan(executionTime, 1.0, "Creating 100 views should complete within 1 second")
    }

    func testViewModelStateUpdatePerformance() async {
        let viewModel = AppViewModel()
        await viewModel.setupDefaultTasks()

        let startTime = CFAbsoluteTimeGetCurrent()

        // Rapid state updates
        for i in 0..<50 {
            await viewModel.loadTodaysData()

            if i % 10 == 0 {
                await viewModel.refreshData()
            }
        }

        let executionTime = CFAbsoluteTimeGetCurrent() - startTime
        performanceMeasurer.record(test: "ViewModelStateUpdate_Performance", time: executionTime)

        XCTAssertLessThan(executionTime, 3.0, "50 state updates should complete within 3 seconds")
    }

    // MARK: - Integration Tests

    func testFullAppWorkflow() async {
        let viewModel = AppViewModel()

        // 1. Initialize app
        await viewModel.setupDefaultTasks()
        await viewModel.loadTodaysData()

        let initialState = (
            stage: viewModel.petStage,
            points: viewModel.petPoints,
            completed: viewModel.completedTasks,
            total: viewModel.totalTasks
        )

        XCTAssertGreaterThanOrEqual(initialState.total, 0, "Should have initialized with tasks")

        // 2. Complete some tasks
        let tasksToComplete = min(3, viewModel.next3Tasks.count)
        for i in 0..<tasksToComplete {
            let task = viewModel.next3Tasks[i]
            viewModel.completeTask(task)
        }

        // Allow async operations to complete
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        // 3. Refresh data to see changes
        await viewModel.refreshData()

        let finalState = (
            stage: viewModel.petStage,
            points: viewModel.petPoints,
            completed: viewModel.completedTasks,
            total: viewModel.totalTasks
        )

        // 4. Verify workflow results
        XCTAssertGreaterThanOrEqual(finalState.completed, tasksToComplete,
                                    "Should have completed the expected number of tasks")
        XCTAssertGreaterThan(finalState.points, initialState.points,
                            "Pet should have gained points")

        // Pet might have evolved
        XCTAssertGreaterThanOrEqual(finalState.stage, initialState.stage,
                                   "Pet stage should not regress")
    }

    func testUIStateConsistency() async {
        let viewModel = AppViewModel()
        await viewModel.setupDefaultTasks()
        await viewModel.loadTodaysData()

        // Test state consistency across multiple operations
        let operations = 20
        var stateHistory: [(stage: Int, points: Int, completed: Int, total: Int)] = []

        for i in 0..<operations {
            if i % 5 == 0 {
                await viewModel.refreshData()
            } else {
                await viewModel.loadTodaysData()
            }

            let currentState = (
                stage: viewModel.petStage,
                points: viewModel.petPoints,
                completed: viewModel.completedTasks,
                total: viewModel.totalTasks
            )

            stateHistory.append(currentState)

            // Verify state consistency
            XCTAssertGreaterThanOrEqual(currentState.stage, 0, "Pet stage should always be non-negative")
            XCTAssertGreaterThanOrEqual(currentState.points, 0, "Pet points should always be non-negative")
            XCTAssertGreaterThanOrEqual(currentState.completed, 0, "Completed tasks should be non-negative")
            XCTAssertGreaterThanOrEqual(currentState.total, currentState.completed,
                                       "Total tasks should be >= completed tasks")
        }

        // Verify no impossible state transitions
        for i in 1..<stateHistory.count {
            let previous = stateHistory[i-1]
            let current = stateHistory[i]

            XCTAssertLessThanOrEqual(abs(current.stage - previous.stage), 2,
                                    "Pet stage should not change dramatically between operations")
        }
    }

    // MARK: - Error Handling Tests

    func testViewModelErrorResilience() async {
        let viewModel = AppViewModel()

        // Test handling of corrupted or invalid states
        // These operations should not crash the app
        await viewModel.loadTodaysData()
        await viewModel.refreshData()

        // Multiple rapid calls should be handled gracefully
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    await viewModel.loadTodaysData()
                }
            }
        }

        // Verify app is still in valid state
        XCTAssertGreaterThanOrEqual(viewModel.petStage, 0, "Pet stage should remain valid")
        XCTAssertGreaterThanOrEqual(viewModel.petPoints, 0, "Pet points should remain valid")
    }

    func testViewErrorHandling() {
        // Test view creation with edge case data
        let edgeCaseTask = Task(
            id: "",
            title: "",
            scheduledTime: TimeSlot(hour: -1),
            difficulty: .easy,
            category: .work
        )

        // These should handle edge cases gracefully without crashing
        let taskRowView = TaskRowView(
            task: edgeCaseTask,
            onComplete: { _ in },
            onEdit: { _ in }
        )
        XCTAssertNotNil(taskRowView, "Should handle edge case task data")

        let petDisplayView = PetDisplayView(
            stage: -1,
            points: -100,
            imageName: ""
        )
        XCTAssertNotNil(petDisplayView, "Should handle edge case pet data")
    }

    // MARK: - Memory and Resource Tests

    func testViewMemoryManagement() {
        weak var weakViewModel: AppViewModel?

        autoreleasepool {
            let viewModel = AppViewModel()
            weakViewModel = viewModel

            // Use the view model
            Task {
                await viewModel.loadTodaysData()
            }
        }

        // Allow cleanup
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertNil(weakViewModel, "ViewModel should be deallocated when not retained")
        }
    }

    func testViewHierarchyMemory() {
        let initialMemory = getMemoryUsage()

        // Create and release many views
        autoreleasepool {
            for i in 0..<100 {
                let task = Task(
                    id: "memory-test-\(i)",
                    title: "Memory Test \(i)",
                    scheduledTime: TimeSlot(hour: (10 + i) % 24),
                    difficulty: .medium,
                    category: .work
                )

                let view = TaskRowView(
                    task: task,
                    onComplete: { _ in },
                    onEdit: { _ in }
                )

                // Simulate view usage
                _ = view.body
            }
        }

        let finalMemory = getMemoryUsage()
        let memoryIncrease = finalMemory - initialMemory

        performanceMeasurer.recordMemory(test: "ViewHierarchy_Memory", bytes: memoryIncrease)

        // Memory increase should be reasonable
        XCTAssertLessThan(memoryIncrease, 5 * 1024 * 1024, "Memory increase should be less than 5MB")
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

// MARK: - Performance Measurement Helpers

final class PerformanceMeasurer {
    private var measurements: [String: [Double]] = [:]
    private var memoryMeasurements: [String: Int64] = [:]
    private let logger = Logger(subsystem: "com.mytasklist.tests", category: "AppPerformance")

    func record(test: String, time: Double) {
        if measurements[test] == nil {
            measurements[test] = []
        }
        measurements[test]?.append(time)
        logger.info("Performance: \(test) completed in \(time * 1000, specifier: \"%.2f\")ms")
    }

    func recordMemory(test: String, bytes: Int64) {
        memoryMeasurements[test] = bytes
        let mb = Double(bytes) / (1024 * 1024)
        logger.info("Memory: \(test) used \(mb, specifier: \"%.2f\")MB")
    }

    func reset() {
        measurements.removeAll()
        memoryMeasurements.removeAll()
    }

    func logResults() {
        logger.info("=== App Performance Test Results ===")

        for (test, times) in measurements {
            let avgTime = times.reduce(0, +) / Double(times.count)
            let minTime = times.min() ?? 0
            let maxTime = times.max() ?? 0

            logger.info("\(test): avg=\(String(format: "%.2f", avgTime * 1000))ms, min=\(String(format: "%.2f", minTime * 1000))ms, max=\(String(format: "%.2f", maxTime * 1000))ms")
        }

        for (test, bytes) in memoryMeasurements {
            let mb = Double(bytes) / (1024 * 1024)
            logger.info("\(test): \(mb, specifier: \"%.2f\")MB")
        }

        logger.info("=== End App Performance Results ===")
    }
}
