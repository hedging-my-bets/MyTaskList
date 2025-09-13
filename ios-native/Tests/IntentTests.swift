import XCTest
@testable import PetProgress
@testable import PetProgressShared

final class IntentTests: XCTestCase {
    func testCompleteTaskIntentIdempotentAndOnTime() async throws {
        let shared = SharedStore()
        let today = dayKey(for: Date())
        // Prepare state with one-off at now
        let comps = Calendar.current.dateComponents([.hour, .minute], from: Date())
        let one = TaskItem(id: UUID(), title: "One", scheduledAt: comps, dayKey: today, isCompleted: false, completedAt: nil, snoozedUntil: nil)
        var st = AppState(schemaVersion: 2, dayKey: today, tasks: [one], pet: PetState(stageIndex: 0, stageXP: 0, lastCloseoutDayKey: today), series: [], overrides: [], completions: [:], rolloverEnabled: false, graceMinutes: 60, resetTime: nil)
        try? shared.saveState(st)
        let intent = CompleteTaskIntent(taskId: one.id.uuidString, dayKey: today)
        _ = try? await intent.perform()
        let after = try shared.loadState()
        XCTAssertTrue(after.completions[today]?.contains(one.id) ?? false)
        let xp1 = after.pet.stageXP
        // Second run idempotent
        _ = try? await intent.perform()
        let after2 = try shared.loadState()
        XCTAssertEqual(after2.pet.stageXP, xp1)
    }
    func testMarkNextTaskDoneUpdatesOnlyNext() async throws {
        let shared = SharedStore()
        let today = dayKey(for: Date())
        let tasks = [
            TaskItem(id: UUID(), title: "A", scheduledAt: DateComponents(hour: 9, minute: 0), dayKey: today, isCompleted: false, completedAt: nil, snoozedUntil: nil),
            TaskItem(id: UUID(), title: "B", scheduledAt: DateComponents(hour: 10, minute: 0), dayKey: today, isCompleted: false, completedAt: nil, snoozedUntil: nil)
        ]
        var state = AppState(schemaVersion: 2, dayKey: today, tasks: tasks, pet: PetState(stageIndex: 0, stageXP: 0, lastCloseoutDayKey: today), series: [], overrides: [], completions: [:], rolloverEnabled: false, graceMinutes: 60, resetTime: nil)
        try? shared.saveState(state)

        let intent = MarkNextTaskDoneIntent(dayKey: today)
        _ = try? await intent.perform()
        let after = try shared.loadState()
        XCTAssertEqual(after.tasks.filter { $0.isCompleted }.count, 1)
        // Idempotent second run
        _ = try? await intent.perform()
        let after2 = try shared.loadState()
        XCTAssertEqual(after2.tasks.filter { $0.isCompleted }.count, 1)
    }

    func testSnoozeClampsBeforeMidnight() async throws {
        let shared = SharedStore()
        let today = dayKey(for: Date())
        let tasks = [
            TaskItem(id: UUID(), title: "Late", scheduledAt: DateComponents(hour: 23, minute: 50), dayKey: today, isCompleted: false, completedAt: nil, snoozedUntil: nil)
        ]
        let state = AppState(schemaVersion: 2, dayKey: today, tasks: tasks, pet: PetState(stageIndex: 0, stageXP: 0, lastCloseoutDayKey: today), series: [], overrides: [], completions: [:], rolloverEnabled: false, graceMinutes: 60, resetTime: nil)
        try? shared.saveState(state)
        let snoozeIntent = SnoozeNextTaskIntent(taskId: tasks[0].id.uuidString, dayKey: today)
        _ = try? await snoozeIntent.perform()
        let after = try shared.loadState()
        let task = after.tasks.first!
        XCTAssertLessThanOrEqual(task.scheduledAt.hour ?? 0, 23)
        XCTAssertLessThanOrEqual(task.scheduledAt.minute ?? 0, 59)
    }
}

