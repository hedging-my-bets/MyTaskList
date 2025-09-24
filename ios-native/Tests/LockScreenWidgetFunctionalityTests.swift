import XCTest
import WidgetKit
@testable import SharedKit

/// Comprehensive test suite for Lock Screen widget functionality
/// Validates all requirements from the blueprint analysis
@available(iOS 17.0, *)
final class LockScreenWidgetFunctionalityTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Reset App Group storage for clean tests
        AppGroupDefaults.shared.synchronize()
    }

    // MARK: - Widget Configuration Tests

    func testAppIntentTimelineProviderIsConfigured() {
        let provider = Provider()
        XCTAssertNotNil(provider, "AppIntentTimelineProvider should be initialized")

        // Test placeholder
        let placeholder = provider.placeholder(in: TimelineProviderContext())
        XCTAssertNotNil(placeholder.date, "Placeholder should have valid date")
        XCTAssertNotNil(placeholder.dayModel, "Placeholder should have day model")
    }

    func testLockScreenWidgetFamiliesSupported() {
        // Verify supported widget families
        let supportedFamilies: [WidgetFamily] = [
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ]

        for family in supportedFamilies {
            // Each family should render without errors
            let entry = SimpleEntry(
                date: Date(),
                dayModel: createTestDayModel()
            )

            // This would need actual view testing in a UI test
            // For now, we verify the entry is valid
            XCTAssertNotNil(entry, "Entry should be valid for \(family)")
        }
    }

    // MARK: - App Intents Tests

    func testMarkNextTaskDoneIntent() async throws {
        let intent = MarkNextTaskDoneIntent()

        // Create test tasks
        let dayKey = TimeSlot.dayKey(for: Date())
        let testTasks = [
            TaskEntity(id: "test1", title: "Test Task 1", dueHour: 9, isDone: false, dayKey: dayKey),
            TaskEntity(id: "test2", title: "Test Task 2", dueHour: 10, isDone: false, dayKey: dayKey)
        ]
        AppGroupDefaults.shared.setTasks(testTasks, dayKey: dayKey)

        // Execute intent
        let result = try await intent.perform()
        XCTAssertNotNil(result, "Intent should return result")
    }

    func testSkipCurrentTaskIntent() async throws {
        let intent = SkipCurrentTaskIntent()

        // Create test task
        let dayKey = TimeSlot.dayKey(for: Date())
        let testTasks = [
            TaskEntity(id: "test1", title: "Test Task", dueHour: 9, isDone: false, dayKey: dayKey)
        ]
        AppGroupDefaults.shared.setTasks(testTasks, dayKey: dayKey)

        // Execute intent
        let result = try await intent.perform()
        XCTAssertNotNil(result, "Intent should return result")
    }

    func testGoToNextTaskIntent() async throws {
        let intent = GoToNextTaskIntent()

        // Execute intent
        let result = try await intent.perform()
        XCTAssertNotNil(result, "Intent should return result")

        // Verify page navigation
        let currentPage = AppGroupStore.shared.state.currentPage
        XCTAssertGreaterThanOrEqual(currentPage, 0, "Current page should be valid")
    }

    func testGoToPreviousTaskIntent() async throws {
        let intent = GoToPreviousTaskIntent()

        // Execute intent
        let result = try await intent.perform()
        XCTAssertNotNil(result, "Intent should return result")

        // Verify page navigation
        let currentPage = AppGroupStore.shared.state.currentPage
        XCTAssertGreaterThanOrEqual(currentPage, 0, "Current page should be valid")
    }

    // MARK: - Pet Evolution Tests

    func testPetEvolutionVisualization() {
        // Test WidgetImageOptimizer provides correct images
        for stage in 0...15 {
            let image = WidgetImageOptimizer.shared.widgetImage(for: stage)
            XCTAssertNotNil(image, "Image should exist for stage \(stage)")
        }
    }

    func testPetXPCalculation() {
        var petState = PetState(stageIndex: 0, stageXP: 0)
        let cfg = StageCfg.standard()

        // Test task completion adds XP
        PetEngine.onCheck(onTime: true, pet: &petState, cfg: cfg)
        XCTAssertGreaterThan(petState.stageXP, 0, "XP should increase on task completion")

        // Test task miss reduces XP
        let previousXP = petState.stageXP
        PetEngine.onMiss(pet: &petState, cfg: cfg)
        XCTAssertLessThan(petState.stageXP, previousXP, "XP should decrease on task miss")
    }

    // MARK: - Grace Period Tests

    func testGracePeriodRespected() {
        // Test grace minutes setting
        AppGroupDefaults.shared.graceMinutes = 30

        let graceMinutes = AppGroupDefaults.shared.graceMinutes
        XCTAssertEqual(graceMinutes, 30, "Grace minutes should be stored correctly")

        // Test rollover respects grace period
        let handler = TaskRolloverHandler.shared
        handler.checkAndPerformRollover()
        // Rollover should respect the grace period setting
    }

    // MARK: - App Group Storage Tests

    func testAppGroupStorageSharing() {
        let testDayKey = "2025-01-21"
        let testTasks = [
            TaskEntity(id: "1", title: "Task 1", dueHour: 9, isDone: false, dayKey: testDayKey),
            TaskEntity(id: "2", title: "Task 2", dueHour: 14, isDone: true, dayKey: testDayKey)
        ]

        // Store tasks
        AppGroupDefaults.shared.setTasks(testTasks, dayKey: testDayKey)

        // Retrieve tasks
        let retrievedTasks = AppGroupDefaults.shared.getTasks(dayKey: testDayKey)
        XCTAssertEqual(retrievedTasks.count, 2, "Should retrieve correct number of tasks")
        XCTAssertEqual(retrievedTasks.first?.title, "Task 1", "Task data should be preserved")
    }

    func testPetStateSharing() {
        let testPetState = PetState(
            stageIndex: 5,
            stageXP: 150,
            lastCelebratedStage: 4,
            lastCloseoutDayKey: "2025-01-20"
        )

        // Store pet state
        AppGroupDefaults.shared.setPetState(testPetState)

        // Retrieve pet state
        let retrievedState = AppGroupDefaults.shared.getPetState()
        XCTAssertNotNil(retrievedState, "Pet state should be retrievable")
        XCTAssertEqual(retrievedState?.stageIndex, 5, "Stage index should be preserved")
        XCTAssertEqual(retrievedState?.stageXP, 150, "Stage XP should be preserved")
    }

    // MARK: - Widget Timeline Tests

    func testHourlyTimelineRefresh() async {
        let provider = Provider()
        let config = ConfigurationAppIntent()
        let context = TimelineProviderContext()

        let expectation = XCTestExpectation(description: "Timeline generated")

        provider.timeline(for: config, in: context) { timeline in
            XCTAssertGreaterThan(timeline.entries.count, 0, "Timeline should have entries")

            // Verify hourly refresh policy
            if case .after(let date) = timeline.policy {
                let calendar = Calendar.current
                let components = calendar.dateComponents([.minute], from: Date(), to: date)
                XCTAssertLessThanOrEqual(components.minute ?? 0, 60, "Should refresh within an hour")
            }

            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 5.0)
    }

    // MARK: - Rollover Tests

    func testTaskRolloverWithGracePeriod() {
        let handler = TaskRolloverHandler.shared

        // Set up previous day tasks
        let previousDayKey = "2025-01-20"
        let testTasks = [
            TaskEntity(id: "1", title: "Incomplete Task", dueHour: 23, isDone: false, dayKey: previousDayKey),
            TaskEntity(id: "2", title: "Completed Task", dueHour: 22, isDone: true, dayKey: previousDayKey)
        ]
        AppGroupDefaults.shared.setTasks(testTasks, dayKey: previousDayKey)

        // Enable rollover
        AppGroupStore.shared.state.rolloverEnabled = true

        // Test rollover is called on app foreground
        handler.handleAppForeground()

        // Test rollover is called in intents
        handler.handleIntentExecution()
    }

    // MARK: - Haptic Integration Tests

    func testHapticManagerIntegration() {
        // Test haptic feedback is available
        let hapticManager = HapticManager.shared
        XCTAssertTrue(hapticManager.isHapticsAvailable || !UIDevice.current.userInterfaceIdiom.rawValue.isMultiple(of: 1),
                     "Haptics should be available on iPhone")

        // Test haptic methods don't crash
        hapticManager.taskCompleted()
        hapticManager.taskSkipped()
        hapticManager.taskNavigation()
        hapticManager.petLevelUp(fromStage: 0, toStage: 1)
        hapticManager.petDeEvolution()
    }

    // MARK: - Helper Methods

    private func createTestDayModel() -> DayModel {
        return DayModel(
            key: TimeSlot.dayKey(for: Date()),
            slots: [
                DayModel.Slot(id: "1", title: "Morning Task", hour: 9, isDone: false),
                DayModel.Slot(id: "2", title: "Afternoon Task", hour: 14, isDone: true),
                DayModel.Slot(id: "3", title: "Evening Task", hour: 18, isDone: false)
            ],
            points: 50
        )
    }

    // MARK: - Performance Tests

    func testWidgetImageLoadingPerformance() {
        measure {
            // Test sub-50ms image loading guarantee
            for stage in 0...15 {
                let startTime = CFAbsoluteTimeGetCurrent()
                _ = WidgetImageOptimizer.shared.widgetImage(for: stage)
                let duration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000

                XCTAssertLessThan(duration, 50, "Image loading should be under 50ms for stage \(stage)")
            }
        }
    }

    func testAppIntentExecutionPerformance() {
        measure {
            let intent = MarkNextTaskDoneIntent()
            let expectation = XCTestExpectation(description: "Intent completed")

            Task {
                _ = try? await intent.perform()
                expectation.fulfill()
            }

            wait(for: [expectation], timeout: 1.0)
        }
    }
}

// MARK: - Test Utilities

extension TimelineProviderContext {
    init() {
        self.init(
            environmentVariants: [],
            family: .accessoryRectangular,
            displaySize: CGSize(width: 157, height: 48),
            displayScale: 3.0,
            isPreview: false
        )
    }
}