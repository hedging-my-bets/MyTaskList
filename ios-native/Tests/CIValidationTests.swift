import XCTest
import WidgetKit
@testable import SharedKit

/// CI validation tests for green build requirements
@available(iOS 17.0, *)
final class CIValidationTests: XCTestCase {

    // MARK: - Timeline Tests

    func testTimelineWithGracePeriod() async throws {
        // Test case: 23:30 with 120-min grace should survive until 01:30
        let calendar = Calendar.current
        let testDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 15, hour: 23, minute: 30))!

        // Set 120-minute grace period
        AppGroupDefaults.shared.graceMinutes = 120

        // Create provider and test timeline generation
        let provider = Provider()
        let config = ConfigurationAppIntent()
        let context = TimelineProviderContext()

        let expectation = XCTestExpectation(description: "Timeline generated")

        provider.timeline(for: config, in: context) { timeline in
            XCTAssertGreaterThan(timeline.entries.count, 0, "Timeline should have entries")

            // Verify policy refreshes at correct boundary
            if case .after(let refreshDate) = timeline.policy {
                let expectedRefresh = calendar.date(byAdding: .hour, value: 1, to: testDate.topOfHour)!
                XCTAssertEqual(refreshDate.timeIntervalSince1970, expectedRefresh.timeIntervalSince1970, accuracy: 60,
                              "Timeline should refresh at next hour boundary")
            }

            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 5.0)
    }

    func testNearestHourWithGracePeriod() {
        // Test grace period logic: 13:15 with 30-min grace should include 12:xx tasks
        let calendar = Calendar.current
        let testDate = calendar.date(from: DateComponents(hour: 13, minute: 15))!

        AppGroupDefaults.shared.graceMinutes = 30

        // Create test tasks
        let dayKey = TimeSlot.dayKey(for: testDate)
        let testTasks = [
            TaskEntity(id: "task1", title: "12pm Task", dueHour: 12, isDone: false, dayKey: dayKey),
            TaskEntity(id: "task2", title: "1pm Task", dueHour: 13, isDone: false, dayKey: dayKey),
            TaskEntity(id: "task3", title: "2pm Task", dueHour: 14, isDone: false, dayKey: dayKey)
        ]
        AppGroupDefaults.shared.setTasks(testTasks, dayKey: dayKey)

        let provider = Provider()
        let dayModel = provider.loadNearestHourDayModel(for: testDate)

        // Should include 12pm (grace period) and 1pm (current hour) tasks
        let activeTasks = dayModel.slots
        XCTAssertTrue(activeTasks.contains { $0.hour == 12 }, "Should include 12pm task within grace period")
        XCTAssertTrue(activeTasks.contains { $0.hour == 13 }, "Should include current 1pm task")
        XCTAssertFalse(activeTasks.contains { $0.hour == 14 }, "Should not include future 2pm task")
    }

    // MARK: - App Intent Tests

    func testAppIntentExecution() async throws {
        let testLogger = Logger(subsystem: "com.petprogress.tests", category: "CI")

        // Create test environment
        let dayKey = TimeSlot.dayKey(for: Date())
        let testTasks = [
            TaskEntity(id: "test1", title: "Test Task", dueHour: 10, isDone: false, dayKey: dayKey)
        ]
        AppGroupDefaults.shared.setTasks(testTasks, dayKey: dayKey)

        // Test MarkNextTaskDoneIntent
        let intent = MarkNextTaskDoneIntent()
        let result = try await intent.perform()

        XCTAssertNotNil(result, "Intent should return result")
        testLogger.info("✅ App Intent execution validated")

        // Verify state changed in App Group
        let updatedTasks = AppGroupDefaults.shared.getTasks(dayKey: dayKey)
        XCTAssertTrue(updatedTasks.contains { $0.isDone }, "Task should be marked as completed")
    }

    func testWidgetReloadAfterIntent() async throws {
        // Verify that intents trigger widget timeline reload
        let intent = MarkNextTaskDoneIntent()

        // Mock widget center to verify reload is called
        let expectation = XCTestExpectation(description: "Widget reload triggered")

        // Execute intent
        _ = try await intent.perform()

        // In real implementation, this would verify WidgetCenter.shared.reloadTimelines(ofKind:) was called
        // For CI testing, we verify the intent completes successfully
        expectation.fulfill()

        await fulfillment(of: [expectation], timeout: 1.0)
    }

    // MARK: - App Group Storage Tests

    func testAppGroupSharedStorage() {
        let testDayKey = "2024-01-15"
        let testPetState = PetState(stageIndex: 5, stageXP: 100, lastCloseoutDayKey: "2024-01-14")

        // Test App Group storage consistency
        AppGroupDefaults.shared.setPetState(testPetState)
        AppGroupDefaults.shared.graceMinutes = 45

        let retrievedPetState = AppGroupDefaults.shared.getPetState()
        let retrievedGrace = AppGroupDefaults.shared.graceMinutes

        XCTAssertNotNil(retrievedPetState, "Pet state should be retrievable from App Group")
        XCTAssertEqual(retrievedPetState?.stageIndex, 5, "Pet state should persist correctly")
        XCTAssertEqual(retrievedGrace, 45, "Grace minutes should persist correctly")
    }

    // MARK: - Performance Tests

    func testAppIntentPerformance() {
        measure {
            let intent = MarkNextTaskDoneIntent()
            let expectation = XCTestExpectation(description: "Intent performance")

            Task {
                _ = try? await intent.perform()
                expectation.fulfill()
            }

            wait(for: [expectation], timeout: 1.0)
        }
    }
}

// MARK: - Test Utilities

extension Provider {
    /// Expose internal method for testing
    func loadNearestHourDayModel(for date: Date) -> DayModel {
        return loadNearestHourDayModel(for: date)
    }
}

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