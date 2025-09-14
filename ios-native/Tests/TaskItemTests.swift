import XCTest
@testable import SharedKit

final class TaskItemTests: XCTestCase {

    func testTaskItemInitialization() {
        let task = TaskItem(
            title: "Test Task",
            scheduledAt: DateComponents(hour: 9, minute: 30),
            dayKey: "2025-01-01"
        )

        XCTAssertFalse(task.title.isEmpty)
        XCTAssertEqual(task.scheduledAt.hour, 9)
        XCTAssertEqual(task.scheduledAt.minute, 30)
        XCTAssertEqual(task.dayKey, "2025-01-01")
        XCTAssertFalse(task.isCompleted)
        XCTAssertNil(task.completedAt)
    }

    func testTaskItemValidation() {
        // Valid task
        let validTask = TaskItem(
            title: "Valid Task",
            scheduledAt: DateComponents(hour: 12, minute: 0),
            dayKey: "2025-01-01"
        )
        XCTAssertTrue(validTask.isValid)

        // Invalid title (empty after trimming)
        let invalidTitleTask = TaskItem(
            title: "   ",
            scheduledAt: DateComponents(hour: 12, minute: 0),
            dayKey: "2025-01-01"
        )
        XCTAssertFalse(invalidTitleTask.isValid)

        // Invalid dayKey
        let invalidDayKeyTask = TaskItem(
            title: "Test",
            scheduledAt: DateComponents(hour: 12, minute: 0),
            dayKey: "invalid"
        )
        XCTAssertFalse(invalidDayKeyTask.isValid)

        // Invalid hour
        let invalidHourTask = TaskItem(
            title: "Test",
            scheduledAt: DateComponents(hour: 25, minute: 0),
            dayKey: "2025-01-01"
        )
        // Should be clamped to 23
        XCTAssertEqual(invalidHourTask.scheduledAt.hour, 23)
    }

    func testTaskItemTimeBounds() {
        // Test hour clamping
        let taskWithInvalidHour = TaskItem(
            title: "Test",
            scheduledAt: DateComponents(hour: 30, minute: 0),
            dayKey: "2025-01-01"
        )
        XCTAssertEqual(taskWithInvalidHour.scheduledAt.hour, 23)

        // Test minute clamping
        let taskWithInvalidMinute = TaskItem(
            title: "Test",
            scheduledAt: DateComponents(hour: 10, minute: 70),
            dayKey: "2025-01-01"
        )
        XCTAssertEqual(taskWithInvalidMinute.scheduledAt.minute, 59)

        // Test negative values
        let taskWithNegativeTime = TaskItem(
            title: "Test",
            scheduledAt: DateComponents(hour: -5, minute: -10),
            dayKey: "2025-01-01"
        )
        XCTAssertEqual(taskWithNegativeTime.scheduledAt.hour, 0)
        XCTAssertEqual(taskWithNegativeTime.scheduledAt.minute, 0)
    }

    func testTaskItemTitleTrimming() {
        let taskWithWhitespace = TaskItem(
            title: "  Task Title  ",
            scheduledAt: DateComponents(hour: 10, minute: 0),
            dayKey: "2025-01-01"
        )
        XCTAssertEqual(taskWithWhitespace.title, "Task Title")
    }

    func testTaskItemCodable() throws {
        let originalTask = TaskItem(
            title: "Codable Test",
            scheduledAt: DateComponents(hour: 14, minute: 30),
            dayKey: "2025-01-01"
        )

        let encoded = try JSONEncoder().encode(originalTask)
        let decodedTask = try JSONDecoder().decode(TaskItem.self, from: encoded)

        XCTAssertEqual(originalTask.id, decodedTask.id)
        XCTAssertEqual(originalTask.title, decodedTask.title)
        XCTAssertEqual(originalTask.scheduledAt.hour, decodedTask.scheduledAt.hour)
        XCTAssertEqual(originalTask.scheduledAt.minute, decodedTask.scheduledAt.minute)
        XCTAssertEqual(originalTask.dayKey, decodedTask.dayKey)
        XCTAssertEqual(originalTask.isCompleted, decodedTask.isCompleted)
    }
}