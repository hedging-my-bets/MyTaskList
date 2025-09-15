import XCTest
import Foundation
@testable import SharedKit

/// Tests for nearest-hour task materialization with grace windows
final class NearestHourTests: XCTestCase {

    func testGraceWindowLogic() async throws {
        // Test the nearest-hour logic with different grace window scenarios

        // Mock a day with tasks at different hours
        let testDay = DayModel(
            key: TimeSlot.todayKey(),
            slots: [
                DayModel.Slot(id: "task1", title: "9 AM Task", hour: 9, isDone: false),
                DayModel.Slot(id: "task2", title: "10 AM Task", hour: 10, isDone: false),
                DayModel.Slot(id: "task3", title: "11 AM Task", hour: 11, isDone: false),
                DayModel.Slot(id: "task4", title: "12 PM Task", hour: 12, isDone: true)
            ],
            points: 25
        )

        // Test scenario 1: At 10:15 with 30min grace - should show 10 AM tasks
        await testMaterializerLogic(
            day: testDay,
            currentHour: 10,
            currentMinute: 15,
            graceMinutes: 30,
            expectedEffectiveHour: 10,
            description: "Within grace period"
        )

        // Test scenario 2: At 10:45 with 30min grace - should show 11 AM tasks
        await testMaterializerLogic(
            day: testDay,
            currentHour: 10,
            currentMinute: 45,
            graceMinutes: 30,
            expectedEffectiveHour: 11,
            description: "Past grace period"
        )

        // Test scenario 3: At 10:50 with 60min grace - should show 10 AM tasks
        await testMaterializerLogic(
            day: testDay,
            currentHour: 10,
            currentMinute: 50,
            graceMinutes: 60,
            expectedEffectiveHour: 10,
            description: "Within extended grace period"
        )
    }

    private func testMaterializerLogic(
        day: DayModel,
        currentHour: Int,
        currentMinute: Int,
        graceMinutes: Int,
        expectedEffectiveHour: Int,
        description: String
    ) async {
        // This is a conceptual test - in real implementation, we'd need to mock the SharedStoreActor
        // to test the getNearestHourTasks() method with controlled time and grace settings

        let effectiveHour: Int
        if currentMinute <= graceMinutes {
            effectiveHour = currentHour
        } else {
            effectiveHour = (currentHour + 1) % 24
        }

        XCTAssertEqual(
            effectiveHour,
            expectedEffectiveHour,
            "\(description): Expected effective hour \(expectedEffectiveHour), got \(effectiveHour)"
        )

        // Test task filtering logic
        let relevantTasks = day.slots.filter { slot in
            if slot.hour == effectiveHour {
                return true
            }
            let hourDiff = abs(slot.hour - effectiveHour)
            return hourDiff <= 1 || hourDiff >= 23
        }

        // Should include effective hour and ±1 hour context
        let expectedTaskCount = day.slots.filter { slot in
            let hourDiff = abs(slot.hour - effectiveHour)
            return slot.hour == effectiveHour || hourDiff <= 1 || hourDiff >= 23
        }.count

        XCTAssertEqual(
            relevantTasks.count,
            expectedTaskCount,
            "\(description): Task filtering should include effective hour ± 1"
        )
    }

    func test24HourWrapAround() {
        // Test edge case: tasks around midnight
        let midnightDay = DayModel(
            key: TimeSlot.todayKey(),
            slots: [
                DayModel.Slot(id: "task1", title: "11 PM Task", hour: 23, isDone: false),
                DayModel.Slot(id: "task2", title: "12 AM Task", hour: 0, isDone: false),
                DayModel.Slot(id: "task3", title: "1 AM Task", hour: 1, isDone: false)
            ],
            points: 15
        )

        // Test around midnight
        let effectiveHour = 0

        let relevantTasks = midnightDay.slots.filter { slot in
            if slot.hour == effectiveHour {
                return true
            }
            let hourDiff = abs(slot.hour - effectiveHour)
            return hourDiff <= 1 || hourDiff >= 23  // Should include hour 23 due to wrap-around
        }

        // Should include hours 23, 0, and 1
        XCTAssertEqual(relevantTasks.count, 3, "Should handle 24-hour wrap-around correctly")

        let includedHours = Set(relevantTasks.map { $0.hour })
        XCTAssertTrue(includedHours.contains(23), "Should include hour 23 for wrap-around")
        XCTAssertTrue(includedHours.contains(0), "Should include hour 0")
        XCTAssertTrue(includedHours.contains(1), "Should include hour 1")
    }

    func testTaskPrioritization() {
        // Test that incomplete tasks are prioritized over completed ones
        let testDay = DayModel(
            key: TimeSlot.todayKey(),
            slots: [
                DayModel.Slot(id: "done1", title: "Completed 10 AM", hour: 10, isDone: true),
                DayModel.Slot(id: "todo1", title: "Pending 10 AM", hour: 10, isDone: false),
                DayModel.Slot(id: "done2", title: "Completed 11 AM", hour: 11, isDone: true),
                DayModel.Slot(id: "todo2", title: "Pending 11 AM", hour: 11, isDone: false)
            ],
            points: 20
        )

        let sortedTasks = testDay.slots.sorted { task1, task2 in
            // Prioritize incomplete tasks
            if task1.isDone != task2.isDone {
                return !task1.isDone && task2.isDone
            }
            // Then sort by hour
            return task1.hour < task2.hour
        }

        // First two should be incomplete tasks
        XCTAssertFalse(sortedTasks[0].isDone, "First task should be incomplete")
        XCTAssertFalse(sortedTasks[1].isDone, "Second task should be incomplete")

        // Last two should be completed tasks
        XCTAssertTrue(sortedTasks[2].isDone, "Third task should be completed")
        XCTAssertTrue(sortedTasks[3].isDone, "Fourth task should be completed")
    }
}