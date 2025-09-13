import XCTest
@testable import PetProgress
@testable import PetProgressShared

final class MaterializerTests: XCTestCase {
    func testSeriesMaterialization() {
        let monday = "2025-03-03" // Monday
        let tseries = TaskSeries(title: "Gym", daysOfWeek: [2,4,6], time: DateComponents(hour: 7, minute: 0))
        let st = AppState(schemaVersion: 2, dayKey: monday, tasks: [], pet: PetState(stageIndex: 0, stageXP: 0, lastCloseoutDayKey: monday), series: [tseries], overrides: [], completions: [:], rolloverEnabled: false, graceMinutes: 60, resetTime: nil)
        let mats = materializeTasks(for: monday, in: st)
        XCTAssertEqual(mats.count, 1)
        XCTAssertEqual(mats.first?.title, "Gym")
    }

    func testOverrideDelete() {
        let monday = "2025-03-03"
        var s = TaskSeries(title: "Gym", daysOfWeek: [2], time: DateComponents(hour: 7, minute: 0))
        let ov = TaskInstanceOverride(seriesId: s.id, dayKey: monday, isDeleted: true)
        let st = AppState(schemaVersion: 2, dayKey: monday, tasks: [], pet: PetState(stageIndex: 0, stageXP: 0, lastCloseoutDayKey: monday), series: [s], overrides: [ov], completions: [:], rolloverEnabled: false, graceMinutes: 60, resetTime: nil)
        let mats = materializeTasks(for: monday, in: st)
        XCTAssertEqual(mats.count, 0)
    }

    func testOneOffOnlySunday() {
        let sunday = "2025-03-02"
        let one = TaskItem(id: UUID(), title: "Errand", scheduledAt: DateComponents(hour: 9, minute: 0), dayKey: sunday, isCompleted: false, completedAt: nil, snoozedUntil: nil)
        let st = AppState(schemaVersion: 2, dayKey: sunday, tasks: [one], pet: PetState(stageIndex: 0, stageXP: 0, lastCloseoutDayKey: sunday), series: [], overrides: [], completions: [:], rolloverEnabled: false, graceMinutes: 60, resetTime: nil)
        let mats = materializeTasks(for: sunday, in: st)
        XCTAssertEqual(mats.count, 1)
        XCTAssertEqual(mats.first?.title, "Errand")
    }

    func testThreeTasksAround() {
        let dk = dayKey(for: Date())
        let tasks = [
            MaterializedTask(id: UUID(), origin: .oneOff(UUID()), title: "A", time: DateComponents(hour: 5, minute: 0), isCompleted: false),
            MaterializedTask(id: UUID(), origin: .oneOff(UUID()), title: "B", time: DateComponents(hour: 6, minute: 0), isCompleted: false),
            MaterializedTask(id: UUID(), origin: .oneOff(UUID()), title: "C", time: DateComponents(hour: 7, minute: 30), isCompleted: false)
        ]
        var comps = DateComponents()
        comps.hour = 6; comps.minute = 5
        let cal = Calendar.current
        let now = cal.date(from: comps) ?? Date()
        let rows = threeTasksAround(now: now, tasks: tasks)
        XCTAssertEqual(rows.count, 3)
        XCTAssertEqual(rows[1].title, "B")
    }
}



