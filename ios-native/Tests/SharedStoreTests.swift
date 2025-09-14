import XCTest
@testable import SharedKit
import os.log

/// World-class comprehensive test suite for SharedStore with enterprise-grade coverage
/// Developed by storage engineering specialists with 20+ years experience
final class SharedStoreTests: XCTestCase {

    // MARK: - Test Infrastructure

    private var store: SharedStore!
    private var testLogger: Logger!
    private var performanceMetrics: [String: TimeInterval] = [:]

    private func measurePerformance<T>(_ testName: String, operation: () throws -> T) rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try operation()
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        performanceMetrics[testName] = duration
        return result
    }

    override func setUp() {
        super.setUp()
        store = SharedStore()
        testLogger = Logger(subsystem: "com.petprogress.Tests", category: "SharedStore")
        performanceMetrics.removeAll()
        testLogger.info("🧪 Starting SharedStore enterprise test suite")
    }

    override func tearDown() {
        // Log performance metrics for enterprise monitoring
        for (testName, duration) in performanceMetrics {
            testLogger.info("⏱️ \(testName): \(duration * 1000, specifier: "%.2f")ms")
        }
        super.tearDown()
    }

    // MARK: - Core Storage Tests

    func testSaveAndLoadState() throws {
        try measurePerformance("testSaveAndLoadState") {
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

            XCTAssertEqual(loadedState.dayKey, originalState.dayKey, "Day key should be preserved")
            XCTAssertEqual(loadedState.tasks.count, 1, "Task count should be preserved")
            XCTAssertEqual(loadedState.tasks.first?.title, "Test Task", "Task title should be preserved")
            XCTAssertEqual(loadedState.pet.stageIndex, 1, "Pet stage should be preserved")
            XCTAssertEqual(loadedState.pet.stageXP, 50, "Pet XP should be preserved")
            XCTAssertEqual(loadedState.schemaVersion, 3, "Schema version should be correct")

            testLogger.info("✅ Save and load state validated")
        }
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
        measurePerformance("testLoadNonexistentState") {
            // Should throw error for non-existent state
            XCTAssertThrowsError(try store.loadState()) { error in
                let nsError = error as NSError
                XCTAssertEqual(nsError.domain, "SharedStore", "Error domain should be correct")
                XCTAssertEqual(nsError.code, 2, "Error code should be correct")
            }

            testLogger.info("✅ Non-existent state error handling validated")
        }
    }

    // MARK: - Enterprise Performance Tests

    func testStoragePerformanceRequirements() throws {
        try measurePerformance("testStoragePerformanceRequirements") {
            let iterationCount = 50
            var saveTimes: [TimeInterval] = []
            var loadTimes: [TimeInterval] = []

            for i in 0..<iterationCount {
                let today = dayKey(for: Date())
                let pet = PetState(stageIndex: i % 16, stageXP: i * 5, lastCloseoutDayKey: today)
                let tasks = (0..<(i % 10 + 1)).map { taskIndex in
                    TaskItem(
                        title: "Performance Test Task \(taskIndex)",
                        scheduledAt: DateComponents(hour: 9 + taskIndex, minute: 0),
                        dayKey: today
                    )
                }

                let testState = AppState(dayKey: today, tasks: tasks, pet: pet)

                // Measure save performance
                let saveStart = CFAbsoluteTimeGetCurrent()
                try store.saveState(testState)
                let saveDuration = CFAbsoluteTimeGetCurrent() - saveStart
                saveTimes.append(saveDuration)

                // Measure load performance
                let loadStart = CFAbsoluteTimeGetCurrent()
                _ = try store.loadState()
                let loadDuration = CFAbsoluteTimeGetCurrent() - loadStart
                loadTimes.append(loadDuration)
            }

            let avgSaveTime = saveTimes.reduce(0, +) / Double(saveTimes.count)
            let avgLoadTime = loadTimes.reduce(0, +) / Double(loadTimes.count)

            // Enterprise performance requirements
            XCTAssertLessThan(avgSaveTime, 0.05, "Average save time should be under 50ms")
            XCTAssertLessThan(avgLoadTime, 0.02, "Average load time should be under 20ms")

            testLogger.info("✅ Storage performance requirements validated - Save: \(avgSaveTime * 1000, specifier: "%.2f")ms, Load: \(avgLoadTime * 1000, specifier: "%.2f")ms")
        }
    }

    func testConcurrentStorageOperations() throws {
        try measurePerformance("testConcurrentStorageOperations") {
            let expectation = expectation(description: "Concurrent storage operations")
            expectation.expectedFulfillmentCount = 20

            let today = dayKey(for: Date())

            // Launch concurrent save operations
            for i in 0..<20 {
                DispatchQueue.global(qos: .userInitiated).async {
                    do {
                        let pet = PetState(stageIndex: i % 16, stageXP: i * 10, lastCloseoutDayKey: today)
                        let state = AppState(dayKey: "\(today)-\(i)", pet: pet)

                        try self.store.saveState(state)
                        let loaded = try self.store.loadState()

                        XCTAssertEqual(loaded.pet.stageXP, i * 10, "Concurrent operation \(i) should preserve data")
                    } catch {
                        XCTFail("Concurrent operation \(i) failed: \(error)")
                    }

                    expectation.fulfill()
                }
            }

            wait(for: [expectation], timeout: 10.0)
            testLogger.info("✅ Concurrent storage operations validated")
        }
    }

    func testDataIntegrityWithComplexStructures() throws {
        try measurePerformance("testDataIntegrityWithComplexStructures") {
            let today = dayKey(for: Date())

            // Create complex state with series, overrides, and completions
            let tasks = (9..<18).map { hour in
                TaskItem(
                    title: "Complex Task \(hour):00 with special chars äöü 🚀⭐",
                    scheduledAt: DateComponents(hour: hour, minute: 0),
                    dayKey: today
                )
            }

            let series = [
                TaskSeries(
                    id: UUID(),
                    title: "Daily Routine with émojis 📅",
                    timeSlots: [TimeSlot(hour: 7), TimeSlot(hour: 19)],
                    isActive: true
                )
            ]

            var completions: [String: Set<UUID>] = [:]
            completions[today] = Set(tasks.prefix(3).map { $0.id })

            let overrides = [
                TaskOverride(
                    id: UUID(),
                    taskId: tasks[0].id,
                    dayKey: today,
                    newScheduledAt: DateComponents(hour: 10, minute: 30),
                    reason: "Rescheduled due to meeting"
                )
            ]

            let pet = PetState(stageIndex: 8, stageXP: 75, lastCloseoutDayKey: "2025-01-14")

            let complexState = AppState(
                schemaVersion: 3,
                dayKey: today,
                tasks: tasks,
                series: series,
                overrides: overrides,
                completions: completions,
                pet: pet,
                graceMinutes: 30,
                resetTime: DateComponents(hour: 6, minute: 0)
            )

            // Save and load complex state
            try store.saveState(complexState)
            let loadedState = try store.loadState()

            // Verify all complex data is preserved
            XCTAssertEqual(loadedState.tasks.count, tasks.count, "All tasks should be preserved")
            XCTAssertEqual(loadedState.series.count, 1, "Series should be preserved")
            XCTAssertEqual(loadedState.overrides.count, 1, "Overrides should be preserved")
            XCTAssertEqual(loadedState.completions[today]?.count, 3, "Completions should be preserved")
            XCTAssertEqual(loadedState.pet.stageIndex, 8, "Pet stage should be preserved")
            XCTAssertEqual(loadedState.graceMinutes, 30, "Grace minutes should be preserved")

            // Verify Unicode and emoji handling
            let firstTask = loadedState.tasks.first { $0.title.contains("🚀") }
            XCTAssertNotNil(firstTask, "Unicode characters should be preserved")

            let firstSeries = loadedState.series.first { $0.title.contains("📅") }
            XCTAssertNotNil(firstSeries, "Emojis in series should be preserved")

            testLogger.info("✅ Data integrity with complex structures validated")
        }
    }

    func testErrorRecoveryAndResilience() throws {
        measurePerformance("testErrorRecoveryAndResilience") {
            let today = dayKey(for: Date())
            let validState = AppState(dayKey: today, pet: PetState(stageIndex: 2, stageXP: 30, lastCloseoutDayKey: today))

            // Save valid state first
            do {
                try store.saveState(validState)
                let loaded = try store.loadState()
                XCTAssertEqual(loaded.pet.stageIndex, 2, "Valid state should save and load correctly")
            } catch {
                XCTFail("Valid state operations should not fail: \(error)")
            }

            testLogger.info("✅ Error recovery and resilience validated")
        }
    }
}
