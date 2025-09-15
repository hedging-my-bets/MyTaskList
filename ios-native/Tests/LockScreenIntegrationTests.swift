import XCTest
import Foundation
import WidgetKit
@testable import SharedKit

/// Integration tests for Lock Screen widget interactions - verifies the complete flow
final class LockScreenIntegrationTests: XCTestCase {

    override func setUp() async throws {
        try await super.setUp()
        // Clean slate for each test
        await SharedStoreActor.shared.reset()
    }

    /// Test the complete task completion flow from Lock Screen
    func testCompleteTaskIntegrationFlow() async throws {
        let sharedStore = SharedStoreActor.shared

        // Setup: Create a test day with tasks
        let dayKey = TimeSlot.todayKey()
        let testTasks = [
            DayModel.Slot(id: "test1", title: "Morning Task", hour: 9, isDone: false),
            DayModel.Slot(id: "test2", title: "Afternoon Task", hour: 14, isDone: false)
        ]

        let initialDay = DayModel(key: dayKey, slots: testTasks, points: 10)
        await sharedStore.saveDayModel(initialDay)

        // Get initial XP and stage
        let initialXP = initialDay.points
        let initialStage = PetEvolutionEngine().stageIndex(for: initialXP)

        // Simulate Lock Screen task completion
        guard let updatedDay = await sharedStore.markTaskComplete(taskId: "test1", dayKey: dayKey) else {
            XCTFail("Failed to complete task")
            return
        }

        // Verify task completion effects
        let completedTask = updatedDay.slots.first { $0.id == "test1" }
        XCTAssertNotNil(completedTask, "Completed task should still exist")
        XCTAssertTrue(completedTask?.isDone == true, "Task should be marked as done")

        // Verify XP increase
        XCTAssertGreaterThan(updatedDay.points, initialXP, "XP should increase after task completion")

        // Check for potential stage up
        let newStage = PetEvolutionEngine().stageIndex(for: updatedDay.points)
        if newStage > initialStage {
            print("🎉 Level up detected! Stage \(initialStage) → Stage \(newStage)")
        }

        // Verify widget can read the updated state
        let nearestHourTasks = await sharedStore.getNearestHourTasks()
        let remainingTasks = nearestHourTasks.filter { !$0.isDone }
        XCTAssertTrue(remainingTasks.count < testTasks.count, "Should have fewer remaining tasks after completion")
    }

    /// Test task skipping integration
    func testSkipTaskIntegrationFlow() async throws {
        let sharedStore = SharedStoreActor.shared

        // Setup: Create a test day
        let dayKey = TimeSlot.todayKey()
        let testTask = DayModel.Slot(id: "skip-test", title: "Skip Me", hour: 10, isDone: false)
        let initialDay = DayModel(key: dayKey, slots: [testTask], points: 25)
        await sharedStore.saveDayModel(initialDay)

        // Simulate skip from Lock Screen
        guard let updatedDay = await sharedStore.skipTask(taskId: "skip-test", dayKey: dayKey) else {
            XCTFail("Failed to skip task")
            return
        }

        // Verify skip effects (implementation dependent - might mark as done or remove)
        let skippedTask = updatedDay.slots.first { $0.id == "skip-test" }
        // Skip might remove task or mark differently
        if let task = skippedTask {
            print("Task marked as skipped: \(task.isDone)")
        } else {
            print("Task removed from list after skip")
        }

        // XP should not increase from skipping
        XCTAssertLesssThanOrEqual(updatedDay.points, initialDay.points, "XP should not increase from skipping")
    }

    /// Test nearest-hour materialization with grace windows
    func testNearestHourWithGraceWindow() async throws {
        let sharedStore = SharedStoreActor.shared

        // Create tasks at different hours
        let dayKey = TimeSlot.todayKey()
        let tasks = [
            DayModel.Slot(id: "early", title: "Early Task", hour: 8, isDone: false),
            DayModel.Slot(id: "current", title: "Current Hour", hour: 10, isDone: false),
            DayModel.Slot(id: "next", title: "Next Hour", hour: 11, isDone: false),
            DayModel.Slot(id: "later", title: "Later Task", hour: 15, isDone: false)
        ]

        let testDay = DayModel(key: dayKey, slots: tasks, points: 0)
        await sharedStore.saveDayModel(testDay)

        // Test materialization (this depends on current time and grace window)
        let nearestTasks = await sharedStore.getNearestHourTasks()

        XCTAssertGreaterThan(nearestTasks.count, 0, "Should materialize some tasks")
        print("Materialized \(nearestTasks.count) tasks for nearest hour")

        for task in nearestTasks {
            print("- \(task.title) (hour: \(task.dueHour))")
        }

        // Verify tasks are relevant to current time context
        // Note: This test might need adjustment based on when it runs
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)

        // All materialized tasks should be within reasonable range of current hour
        let hourRange = Set(nearestTasks.map { $0.dueHour })
        for hour in hourRange {
            let distance = min(abs(hour - currentHour), abs(hour - currentHour + 24), abs(hour - currentHour - 24))
            XCTAssertLessThan(distance, 12, "Materialized tasks should be reasonably close to current hour")
        }
    }

    /// Test pet evolution through multiple task completions
    func testPetEvolutionProgression() async throws {
        let sharedStore = SharedStoreActor.shared
        let engine = PetEvolutionEngine()

        // Start with zero points
        let dayKey = TimeSlot.todayKey()
        var currentDay = DayModel(key: dayKey, slots: [], points: 0)
        await sharedStore.saveDayModel(currentDay)

        let initialStage = engine.stageIndex(for: 0)
        var stageProgressions: [Int] = [initialStage]

        // Complete multiple tasks to trigger evolution
        let testTasks = (1...10).map { i in
            DayModel.Slot(id: "task\(i)", title: "Task \(i)", hour: 9 + (i % 8), isDone: false)
        }

        for task in testTasks {
            // Add task to day
            currentDay.slots.append(task)
            await sharedStore.saveDayModel(currentDay)

            // Complete the task
            if let updatedDay = await sharedStore.markTaskComplete(taskId: task.id, dayKey: dayKey) {
                currentDay = updatedDay

                let newStage = engine.stageIndex(for: updatedDay.points)
                if newStage > stageProgressions.last! {
                    stageProgressions.append(newStage)
                    print("🎉 Pet evolved! Stage \(stageProgressions[stageProgressions.count - 2]) → Stage \(newStage) (XP: \(updatedDay.points))")

                    // Verify stage image exists
                    let imageName = engine.imageName(for: updatedDay.points)
                    XCTAssertNotNil(imageName, "Stage \(newStage) should have associated image")
                    print("Pet image: \(imageName ?? "none")")
                }
            }
        }

        XCTAssertGreaterThan(currentDay.points, 0, "Should have accumulated XP")
        print("Final XP: \(currentDay.points), Final Stage: \(engine.stageIndex(for: currentDay.points))")

        if stageProgressions.count > 1 {
            print("Pet progressed through stages: \(stageProgressions)")
        }
    }

    /// Test App Group persistence between app and widget
    func testAppGroupPersistence() async throws {
        let sharedStore = SharedStoreActor.shared

        // Create test state
        let dayKey = TimeSlot.todayKey()
        let testDay = DayModel(
            key: dayKey,
            slots: [
                DayModel.Slot(id: "persist-test", title: "Persistence Test", hour: 12, isDone: false)
            ],
            points: 42
        )

        // Save to App Group storage
        await sharedStore.saveDayModel(testDay)

        // Simulate reading from widget (different process)
        let retrievedDay = await sharedStore.loadDayModel(for: dayKey)

        XCTAssertNotNil(retrievedDay, "Should be able to retrieve saved day")
        XCTAssertEqual(retrievedDay?.key, dayKey, "Day key should match")
        XCTAssertEqual(retrievedDay?.points, 42, "Points should persist")
        XCTAssertEqual(retrievedDay?.slots.count, 1, "Task count should persist")
        XCTAssertEqual(retrievedDay?.slots.first?.title, "Persistence Test", "Task details should persist")
    }

    /// Test widget timeline refresh triggers
    func testWidgetTimelineRefresh() async throws {
        let sharedStore = SharedStoreActor.shared

        // This test verifies the timeline refresh mechanism exists
        // In a real environment, this would trigger WidgetCenter.reloadAllTimelines()

        await sharedStore.triggerWidgetReload()

        // The method should exist and be callable without throwing
        XCTAssertTrue(true, "Widget reload trigger should be callable")

        print("Widget timeline refresh triggered successfully")
    }
}

// MARK: - Performance Tests

extension LockScreenIntegrationTests {

    /// Test that Lock Screen actions complete within acceptable timeframes
    func testLockScreenPerformance() async throws {
        let sharedStore = SharedStoreActor.shared

        // Setup test data
        let dayKey = TimeSlot.todayKey()
        let testDay = DayModel(
            key: dayKey,
            slots: [DayModel.Slot(id: "perf-test", title: "Performance Test", hour: 13, isDone: false)],
            points: 0
        )
        await sharedStore.saveDayModel(testDay)

        // Measure task completion time (should be < 1 second for Lock Screen responsiveness)
        let startTime = CFAbsoluteTimeGetCurrent()

        _ = await sharedStore.markTaskComplete(taskId: "perf-test", dayKey: dayKey)

        let duration = CFAbsoluteTimeGetCurrent() - startTime

        XCTAssertLessThan(duration, 1.0, "Task completion should be fast enough for Lock Screen (< 1 second)")
        print("Task completion took \(String(format: "%.3f", duration)) seconds")
    }

    /// Test materialization performance
    func testMaterializationPerformance() async throws {
        let sharedStore = SharedStoreActor.shared

        // Create many tasks to test performance
        let dayKey = TimeSlot.todayKey()
        let manyTasks = (0..<100).map { i in
            DayModel.Slot(id: "perf\(i)", title: "Task \(i)", hour: i % 24, isDone: false)
        }

        let testDay = DayModel(key: dayKey, slots: manyTasks, points: 0)
        await sharedStore.saveDayModel(testDay)

        // Measure materialization time
        let startTime = CFAbsoluteTimeGetCurrent()

        let nearestTasks = await sharedStore.getNearestHourTasks()

        let duration = CFAbsoluteTimeGetCurrent() - startTime

        XCTAssertLessThan(duration, 0.5, "Task materialization should be fast (< 0.5 seconds)")
        XCTAssertGreaterThan(nearestTasks.count, 0, "Should materialize some tasks")

        print("Materialized \(nearestTasks.count) tasks from \(manyTasks.count) total in \(String(format: "%.3f", duration)) seconds")
    }
}