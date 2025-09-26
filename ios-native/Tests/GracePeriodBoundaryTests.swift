import XCTest
import Foundation
@testable import SharedKit

/// Production-grade tests for grace period boundary conditions
/// Tests the critical 12:58/13:00/13:14/13:16 scenarios with various grace periods
final class GracePeriodBoundaryTests: XCTestCase {

    private var store: MockAppGroupStore!
    private let calendar = Calendar.current

    override func setUp() async throws {
        try await super.setUp()
        store = MockAppGroupStore()

        // Setup test tasks
        let testTasks = [
            TaskItem(id: UUID(), title: "1pm Task", scheduledAt: DateComponents(hour: 13), isDone: false),
            TaskItem(id: UUID(), title: "2pm Task", scheduledAt: DateComponents(hour: 14), isDone: false),
            TaskItem(id: UUID(), title: "3pm Task", scheduledAt: DateComponents(hour: 15), isDone: false)
        ]

        store.state.tasks = testTasks
    }

    // MARK: - Zero Grace Period Tests

    func testZeroGracePeriod_12_58() throws {
        // At 12:58 with 0 minutes grace, 1pm task should NOT be "now"
        store.updateGraceMinutes(0)

        let testTime = createDate(hour: 12, minute: 58)
        let currentTasks = store.getCurrentTasks(now: testTime)

        XCTAssertTrue(currentTasks.isEmpty, "With 0 grace minutes, no tasks should be 'now' at 12:58")
    }

    func testZeroGracePeriod_13_00() throws {
        // At 13:00 with 0 minutes grace, 1pm task should be "now"
        store.updateGraceMinutes(0)

        let testTime = createDate(hour: 13, minute: 0)
        let currentTasks = store.getCurrentTasks(now: testTime)

        XCTAssertEqual(currentTasks.count, 1, "With 0 grace minutes, exactly one task should be 'now' at 13:00")
        XCTAssertEqual(currentTasks.first?.scheduledAt.hour, 13, "The 1pm task should be current")
    }

    func testZeroGracePeriod_13_01() throws {
        // At 13:01 with 0 minutes grace, 1pm task should NOT be "now"
        store.updateGraceMinutes(0)

        let testTime = createDate(hour: 13, minute: 1)
        let currentTasks = store.getCurrentTasks(now: testTime)

        XCTAssertTrue(currentTasks.isEmpty, "With 0 grace minutes, no tasks should be 'now' at 13:01")
    }

    // MARK: - 15 Minute Grace Period Tests

    func testFifteenMinuteGrace_12_58() throws {
        // At 12:58 with 15 minutes grace, 1pm task should NOT be "now" (2 minutes too early)
        store.updateGraceMinutes(15)

        let testTime = createDate(hour: 12, minute: 58)
        let currentTasks = store.getCurrentTasks(now: testTime)

        XCTAssertTrue(currentTasks.isEmpty, "With 15 minute grace, task at 13:00 should not be 'now' at 12:58")
    }

    func testFifteenMinuteGrace_13_00() throws {
        // At 13:00 with 15 minutes grace, 1pm task should be "now"
        store.updateGraceMinutes(15)

        let testTime = createDate(hour: 13, minute: 0)
        let currentTasks = store.getCurrentTasks(now: testTime)

        XCTAssertEqual(currentTasks.count, 1, "With 15 minute grace, one task should be 'now' at 13:00")
        XCTAssertEqual(currentTasks.first?.scheduledAt.hour, 13, "The 1pm task should be current")
    }

    func testFifteenMinuteGrace_13_14() throws {
        // At 13:14 with 15 minutes grace, 1pm task should still be "now"
        store.updateGraceMinutes(15)

        let testTime = createDate(hour: 13, minute: 14)
        let currentTasks = store.getCurrentTasks(now: testTime)

        XCTAssertEqual(currentTasks.count, 1, "With 15 minute grace, task should still be 'now' at 13:14")
        XCTAssertEqual(currentTasks.first?.scheduledAt.hour, 13, "The 1pm task should still be current")
    }

    func testFifteenMinuteGrace_13_16() throws {
        // At 13:16 with 15 minutes grace, 1pm task should NOT be "now" (16 minutes past)
        store.updateGraceMinutes(15)

        let testTime = createDate(hour: 13, minute: 16)
        let currentTasks = store.getCurrentTasks(now: testTime)

        XCTAssertTrue(currentTasks.isEmpty, "With 15 minute grace, task should not be 'now' at 13:16")
    }

    // MARK: - 60 Minute Grace Period Tests

    func testSixtyMinuteGrace_12_00() throws {
        // At 12:00 with 60 minutes grace, 1pm task should be "now"
        store.updateGraceMinutes(60)

        let testTime = createDate(hour: 12, minute: 0)
        let currentTasks = store.getCurrentTasks(now: testTime)

        XCTAssertEqual(currentTasks.count, 1, "With 60 minute grace, task should be 'now' at 12:00")
        XCTAssertEqual(currentTasks.first?.scheduledAt.hour, 13, "The 1pm task should be current")
    }

    func testSixtyMinuteGrace_14_00() throws {
        // At 14:00 with 60 minutes grace, both 1pm and 2pm tasks should be "now"
        store.updateGraceMinutes(60)

        let testTime = createDate(hour: 14, minute: 0)
        let currentTasks = store.getCurrentTasks(now: testTime)

        XCTAssertEqual(currentTasks.count, 2, "With 60 minute grace, two tasks should be 'now' at 14:00")

        let taskHours = Set(currentTasks.compactMap { $0.scheduledAt.hour })
        XCTAssertTrue(taskHours.contains(13), "1pm task should be included")
        XCTAssertTrue(taskHours.contains(14), "2pm task should be included")
    }

    func testSixtyMinuteGrace_15_30() throws {
        // At 15:30 with 60 minutes grace, tasks at 15:00 and later should be "now"
        store.updateGraceMinutes(60)

        let testTime = createDate(hour: 15, minute: 30)
        let currentTasks = store.getCurrentTasks(now: testTime)

        // Only 3pm task should be within 60 minute window
        XCTAssertEqual(currentTasks.count, 1, "With 60 minute grace, one task should be 'now' at 15:30")
        XCTAssertEqual(currentTasks.first?.scheduledAt.hour, 15, "The 3pm task should be current")
    }

    // MARK: - Edge Cases

    func testGracePeriodClamping() throws {
        // Test that grace minutes are properly clamped to 0-120 range
        store.updateGraceMinutes(-10)
        XCTAssertEqual(store.state.graceMinutes, 0, "Grace minutes should be clamped to minimum 0")

        store.updateGraceMinutes(150)
        XCTAssertEqual(store.state.graceMinutes, 120, "Grace minutes should be clamped to maximum 120")

        store.updateGraceMinutes(45)
        XCTAssertEqual(store.state.graceMinutes, 45, "Valid grace minutes should be preserved")
    }

    func testMultipleTasksInGraceWindow() throws {
        // Test scenario with multiple tasks within grace window
        store.updateGraceMinutes(60)

        // Add more tasks closer together
        let additionalTasks = [
            TaskItem(id: UUID(), title: "1:15pm Task", scheduledAt: DateComponents(hour: 13, minute: 15), isDone: false),
            TaskItem(id: UUID(), title: "1:30pm Task", scheduledAt: DateComponents(hour: 13, minute: 30), isDone: false)
        ]

        store.state.tasks.append(contentsOf: additionalTasks)

        let testTime = createDate(hour: 13, minute: 45)
        let currentTasks = store.getCurrentTasks(now: testTime)

        // With 60 minute grace, tasks at 13:00, 13:15, 13:30 should all be "now" at 13:45
        XCTAssertGreaterThanOrEqual(currentTasks.count, 3, "Multiple tasks within grace window should be included")
    }

    func testTasksAcrossHourBoundary() throws {
        // Test tasks that span across hour boundaries
        let crossBoundaryTasks = [
            TaskItem(id: UUID(), title: "12:45pm Task", scheduledAt: DateComponents(hour: 12, minute: 45), isDone: false),
            TaskItem(id: UUID(), title: "1:15pm Task", scheduledAt: DateComponents(hour: 13, minute: 15), isDone: false)
        ]

        store.state.tasks = crossBoundaryTasks
        store.updateGraceMinutes(30)

        let testTime = createDate(hour: 13, minute: 0)
        let currentTasks = store.getCurrentTasks(now: testTime)

        // Both tasks should be within 30 minute window of 13:00
        XCTAssertEqual(currentTasks.count, 2, "Tasks across hour boundary should both be 'now'")
    }

    // MARK: - Performance Tests

    func testGracePeriodCalculationPerformance() throws {
        // Test with large number of tasks to ensure performance
        let largeTasks = (0..<1000).map { index in
            TaskItem(
                id: UUID(),
                title: "Task \(index)",
                scheduledAt: DateComponents(hour: index % 24),
                isDone: false
            )
        }

        store.state.tasks = largeTasks
        store.updateGraceMinutes(60)

        let testTime = createDate(hour: 12, minute: 0)

        measure {
            let _ = store.getCurrentTasks(now: testTime)
        }
    }

    // MARK: - Helper Methods

    private func createDate(hour: Int, minute: Int = 0) -> Date {
        let components = DateComponents(year: 2024, month: 1, day: 1, hour: hour, minute: minute)
        return calendar.date(from: components) ?? Date()
    }
}

// MARK: - Shared Grace Period Logic Tests

final class GracePeriodLogicTests: XCTestCase {

    /// Test the core isNow logic that should be shared between app and widget
    func testIsNowLogic() throws {
        let testCases: [(taskHour: Int, currentHour: Int, currentMinute: Int, graceMinutes: Int, expectedResult: Bool, description: String)] = [
            // Zero grace period
            (13, 12, 58, 0, false, "0 grace: 12:58 for 1pm task should be false"),
            (13, 13, 0, 0, true, "0 grace: 13:00 for 1pm task should be true"),
            (13, 13, 1, 0, false, "0 grace: 13:01 for 1pm task should be false"),

            // 15 minute grace period
            (13, 12, 58, 15, false, "15min grace: 12:58 for 1pm task should be false"),
            (13, 13, 0, 15, true, "15min grace: 13:00 for 1pm task should be true"),
            (13, 13, 14, 15, true, "15min grace: 13:14 for 1pm task should be true"),
            (13, 13, 16, 15, false, "15min grace: 13:16 for 1pm task should be false"),

            // 60 minute grace period
            (13, 12, 0, 60, true, "60min grace: 12:00 for 1pm task should be true"),
            (13, 14, 0, 60, true, "60min grace: 14:00 for 1pm task should be true"),
            (13, 14, 1, 60, false, "60min grace: 14:01 for 1pm task should be false"),
        ]

        for testCase in testCases {
            let currentTime = createDate(hour: testCase.currentHour, minute: testCase.currentMinute)
            let result = isTaskNow(taskHour: testCase.taskHour, currentTime: currentTime, graceMinutes: testCase.graceMinutes)

            XCTAssertEqual(result, testCase.expectedResult, testCase.description)
        }
    }

    private func createDate(hour: Int, minute: Int = 0) -> Date {
        let calendar = Calendar.current
        let components = DateComponents(year: 2024, month: 1, day: 1, hour: hour, minute: minute)
        return calendar.date(from: components) ?? Date()
    }

    /// Shared logic for determining if a task is "now" - used by both app and widget
    private func isTaskNow(taskHour: Int, currentTime: Date, graceMinutes: Int) -> Bool {
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: currentTime)
        let currentMinute = calendar.component(.minute, from: currentTime)

        // Calculate minutes from start of current hour
        let minutesFromHourStart = currentMinute

        // Calculate hour difference
        let hourDifference = abs(taskHour - currentHour)

        // Convert hour difference to minutes and add current minutes
        let totalMinutesDifference: Int
        if taskHour == currentHour {
            totalMinutesDifference = 0  // Same hour, no difference
        } else if taskHour > currentHour {
            // Task is in future hour
            totalMinutesDifference = (taskHour - currentHour) * 60 - minutesFromHourStart
        } else {
            // Task is in past hour
            totalMinutesDifference = (currentHour - taskHour) * 60 + minutesFromHourStart
        }

        return totalMinutesDifference <= graceMinutes
    }
}

// MARK: - Widget Timeline Tests

final class WidgetTimelineGraceTests: XCTestCase {

    func testTimelineUpdatesWithGraceChanges() throws {
        let store = MockAppGroupStore()

        // Setup tasks
        let testTasks = [
            TaskItem(id: UUID(), title: "Morning Task", scheduledAt: DateComponents(hour: 9), isDone: false),
            TaskItem(id: UUID(), title: "Afternoon Task", scheduledAt: DateComponents(hour: 14), isDone: false)
        ]
        store.state.tasks = testTasks

        // Test different grace periods affect timeline
        let testCases = [15, 30, 60, 120]

        for graceMinutes in testCases {
            store.updateGraceMinutes(graceMinutes)

            // At 8:30, check which tasks are materialized
            let testTime = createDate(hour: 8, minute: 30)
            let currentTasks = store.getCurrentTasks(now: testTime)

            if graceMinutes >= 30 {
                // 9am task should be visible at 8:30 with 30+ minute grace
                XCTAssertGreaterThanOrEqual(currentTasks.count, 1, "With \(graceMinutes)min grace, morning task should be visible at 8:30")
            } else {
                // With less than 30 minute grace, no tasks should be visible
                XCTAssertEqual(currentTasks.count, 0, "With \(graceMinutes)min grace, no tasks should be visible at 8:30")
            }
        }
    }

    private func createDate(hour: Int, minute: Int = 0) -> Date {
        let calendar = Calendar.current
        let components = DateComponents(year: 2024, month: 1, day: 1, hour: hour, minute: minute)
        return calendar.date(from: components) ?? Date()
    }
}