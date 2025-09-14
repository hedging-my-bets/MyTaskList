import XCTest
@testable import PetProgress
@testable import SharedKit

@MainActor
final class DataStoreTests: XCTestCase {
    var dataStore: DataStore!

    override func setUp() async throws {
        await super.setUp()
        dataStore = DataStore()
    }

    func testInitialState() {
        XCTAssertNotNil(dataStore.state)
        XCTAssertEqual(dataStore.state.schemaVersion, 3)
        XCTAssertFalse(dataStore.state.dayKey.isEmpty)
        XCTAssertEqual(dataStore.state.pet.stageIndex, 0)
        XCTAssertEqual(dataStore.state.pet.stageXP, 0)
        XCTAssertFalse(dataStore.showPlanner)
        XCTAssertFalse(dataStore.showSettings)
    }

    func testAddValidTask() {
        let initialCount = dataStore.state.tasks.count

        let validTask = TaskItem(
            title: "Test Task",
            scheduledAt: DateComponents(hour: 10, minute: 0),
            dayKey: dataStore.state.dayKey
        )

        dataStore.addTask(validTask)

        XCTAssertEqual(dataStore.state.tasks.count, initialCount + 1)
        XCTAssertEqual(dataStore.state.tasks.last?.title, "Test Task")
    }

    func testAddInvalidTask() {
        let initialCount = dataStore.state.tasks.count

        let invalidTask = TaskItem(
            title: "", // Invalid empty title
            scheduledAt: DateComponents(hour: 10, minute: 0),
            dayKey: dataStore.state.dayKey
        )

        dataStore.addTask(invalidTask)

        // Should not add invalid task
        XCTAssertEqual(dataStore.state.tasks.count, initialCount)
    }

    func testDeleteTask() {
        let task = TaskItem(
            title: "Task to Delete",
            scheduledAt: DateComponents(hour: 10, minute: 0),
            dayKey: dataStore.state.dayKey
        )

        dataStore.addTask(task)
        let initialCount = dataStore.state.tasks.count

        dataStore.deleteTask(task.id)

        XCTAssertEqual(dataStore.state.tasks.count, initialCount - 1)
        XCTAssertFalse(dataStore.state.tasks.contains { $0.id == task.id })
    }

    func testMarkTaskDone() {
        let task = TaskItem(
            title: "Task to Complete",
            scheduledAt: DateComponents(hour: 10, minute: 0),
            dayKey: dataStore.state.dayKey
        )

        dataStore.addTask(task)

        dataStore.markDone(taskID: task.id)

        let dayKey = dataStore.state.dayKey
        let completedTasks = dataStore.state.completions[dayKey] ?? Set<UUID>()
        XCTAssertTrue(completedTasks.contains(task.id))
    }

    func testTaskCounts() {
        let today = dataStore.state.dayKey

        let task1 = TaskItem(title: "Task 1", scheduledAt: DateComponents(hour: 9, minute: 0), dayKey: today)
        let task2 = TaskItem(title: "Task 2", scheduledAt: DateComponents(hour: 10, minute: 0), dayKey: today)
        let task3 = TaskItem(title: "Task 3", scheduledAt: DateComponents(hour: 11, minute: 0), dayKey: today)

        dataStore.addTask(task1)
        dataStore.addTask(task2)
        dataStore.addTask(task3)

        XCTAssertEqual(dataStore.tasksTotal, 3)
        XCTAssertEqual(dataStore.tasksDone, 0)

        dataStore.markDone(taskID: task1.id)
        dataStore.markDone(taskID: task2.id)

        XCTAssertEqual(dataStore.tasksTotal, 3)
        XCTAssertEqual(dataStore.tasksDone, 2)
    }

    func testSnoozeTask() {
        let task = TaskItem(
            title: "Task to Snooze",
            scheduledAt: DateComponents(hour: 10, minute: 0),
            dayKey: dataStore.state.dayKey
        )

        dataStore.addTask(task)

        dataStore.snooze(taskID: task.id, minutes: 15)

        // Task should be updated with new time
        let updatedTask = dataStore.state.tasks.first { $0.id == task.id }
        XCTAssertNotNil(updatedTask)
        // Time should be snoozed forward
        XCTAssertTrue((updatedTask?.scheduledAt.minute ?? 0) >= 15 ||
                     (updatedTask?.scheduledAt.hour ?? 0) > 10)
    }

    func testUpdateSettings() {
        dataStore.updateGraceMinutes(90)
        XCTAssertEqual(dataStore.state.graceMinutes, 90)

        dataStore.updateRolloverEnabled(true)
        XCTAssertTrue(dataStore.state.rolloverEnabled)

        let newResetTime = DateComponents(hour: 6, minute: 0)
        dataStore.updateResetTime(newResetTime)
        XCTAssertEqual(dataStore.state.resetTime.hour, 6)
        XCTAssertEqual(dataStore.state.resetTime.minute, 0)
    }

    func testResetAllData() {
        // Add some data
        let task = TaskItem(title: "Test", scheduledAt: DateComponents(hour: 10, minute: 0), dayKey: dataStore.state.dayKey)
        dataStore.addTask(task)
        dataStore.updateGraceMinutes(90)

        // Reset
        dataStore.resetAllData()

        // Should be back to initial state
        XCTAssertTrue(dataStore.state.tasks.isEmpty)
        XCTAssertEqual(dataStore.state.graceMinutes, 60) // Default value
        XCTAssertEqual(dataStore.state.pet.stageIndex, 0)
        XCTAssertEqual(dataStore.state.pet.stageXP, 0)
    }
}
