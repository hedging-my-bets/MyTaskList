import XCTest
@testable import SharedKit

final class SharedStoreTests: XCTestCase {
    var store: SharedStore!

    override func setUp() {
        super.setUp()
        store = SharedStore()
    }

    func testSaveAndLoadState() throws {
        let today = dayKey(for: Date())
        let pet = PetState(stageIndex: 1, stageXP: 50, lastCloseoutDayKey: today)
        let task = TaskItem(
            title: "Test Task",
            scheduledAt: DateComponents(hour: 10, minute: 0),
            dayKey: today
        )

        let originalState = AppState(
            dayKey: today,
            tasks: [task],
            pet: pet
        )

        // Save state
        try store.saveState(originalState)

        // Load state
        let loadedState = try store.loadState()

        XCTAssertEqual(loadedState.dayKey, originalState.dayKey)
        XCTAssertEqual(loadedState.tasks.count, 1)
        XCTAssertEqual(loadedState.tasks.first?.title, "Test Task")
        XCTAssertEqual(loadedState.pet.stageIndex, 1)
        XCTAssertEqual(loadedState.pet.stageXP, 50)
        XCTAssertEqual(loadedState.schemaVersion, 3)
    }

    func testSchemaVersionUpdating() throws {
        let today = dayKey(for: Date())
        let pet = PetState(stageIndex: 0, stageXP: 0, lastCloseoutDayKey: today)

        // Create state with old schema version
        var oldState = AppState(
            schemaVersion: 1,
            dayKey: today,
            pet: pet
        )

        // Simulate old state without series/overrides
        oldState.series = []
        oldState.overrides = []
        oldState.completions = [:]
        oldState.graceMinutes = 0 // Invalid value to test migration

        try store.saveState(oldState)

        // Load should trigger migration
        let migratedState = try store.loadState()

        XCTAssertEqual(migratedState.schemaVersion, 3)
        XCTAssertEqual(migratedState.graceMinutes, 60) // Should be set to default
        XCTAssertNotNil(migratedState.resetTime.hour)
        XCTAssertNotNil(migratedState.resetTime.minute)
    }

    func testAtomicSave() throws {
        let today = dayKey(for: Date())
        let pet = PetState(stageIndex: 0, stageXP: 0, lastCloseoutDayKey: today)
        let state = AppState(dayKey: today, pet: pet)

        // Multiple saves should not corrupt data
        try store.saveState(state)
        try store.saveState(state)
        try store.saveState(state)

        let loadedState = try store.loadState()
        XCTAssertEqual(loadedState.dayKey, today)
        XCTAssertEqual(loadedState.schemaVersion, 3)
    }

    func testLoadNonexistentState() {
        // Should throw error for non-existent state
        XCTAssertThrowsError(try store.loadState()) { error in
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "SharedStore")
            XCTAssertEqual(nsError.code, 2)
        }
    }
}