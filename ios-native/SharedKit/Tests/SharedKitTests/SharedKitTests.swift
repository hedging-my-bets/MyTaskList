import XCTest
@testable import SharedKit
import Foundation

class SharedKitTests: XCTestCase {

    override func setUpWithError() throws {
        // Clean up any existing test data
        let testKey = "test_day_\(Int(Date().timeIntervalSince1970))"
        UserDefaults.standard.removeObject(forKey: "day_\(testKey)")
    }

    // MARK: - TimeSlot Tests

    func testTimeSlotDayKey() {
        let date = Date(timeIntervalSince1970: 1640995200) // 2022-01-01 00:00:00 UTC
        let dayKey = TimeSlot.dayKey(for: date)
        XCTAssertFalse(dayKey.isEmpty)
        XCTAssertTrue(dayKey.contains("2022") || dayKey.contains("2021")) // Account for timezone differences
    }

    func testTimeSlotHourIndex() {
        let calendar = Calendar.current
        let date = calendar.date(bySettingHour: 14, minute: 30, second: 0, of: Date())!
        let hourIndex = TimeSlot.hourIndex(for: date)
        XCTAssertEqual(hourIndex, 14)
    }

    func testTimeSlotNextHour() {
        let now = Date()
        let nextHour = TimeSlot.nextHour(after: now)
        XCTAssertGreaterThan(nextHour, now)

        let timeDifference = nextHour.timeIntervalSince(now)
        XCTAssertGreaterThan(timeDifference, 0)
        XCTAssertLessThanOrEqual(timeDifference, 3660) // At most 1 hour and 1 minute
    }

    // MARK: - DayModel Tests

    func testDayModelCreation() {
        let slot = DayModel.Slot(hour: 9, title: "Morning task", isDone: false)
        let dayModel = DayModel(key: "2022-01-01", slots: [slot], points: 50)

        XCTAssertEqual(dayModel.key, "2022-01-01")
        XCTAssertEqual(dayModel.slots.count, 1)
        XCTAssertEqual(dayModel.points, 50)
        XCTAssertEqual(dayModel.slots.first?.hour, 9)
        XCTAssertEqual(dayModel.slots.first?.title, "Morning task")
        XCTAssertFalse(dayModel.slots.first?.isDone ?? true)
    }

    func testDayModelCodable() throws {
        let slot = DayModel.Slot(hour: 14, title: "Afternoon task", isDone: true)
        let originalDay = DayModel(key: "test-day", slots: [slot], points: 125)

        let encoded = try JSONEncoder().encode(originalDay)
        let decoded = try JSONDecoder().decode(DayModel.self, from: encoded)

        XCTAssertEqual(decoded.key, originalDay.key)
        XCTAssertEqual(decoded.slots.count, originalDay.slots.count)
        XCTAssertEqual(decoded.points, originalDay.points)
        XCTAssertEqual(decoded.slots.first?.hour, originalDay.slots.first?.hour)
        XCTAssertEqual(decoded.slots.first?.isDone, originalDay.slots.first?.isDone)
    }

    // MARK: - StageConfig Tests

    func testStageConfigDefault() {
        let config = StageConfig.defaultConfig()
        XCTAssertEqual(config.stages.count, 16)

        // Test that thresholds are strictly increasing
        for i in 1..<config.stages.count {
            XCTAssertGreaterThan(
                config.stages[i].threshold,
                config.stages[i-1].threshold,
                "Stage \(i) threshold should be greater than stage \(i-1)"
            )
        }

        // Test first and last stages
        XCTAssertEqual(config.stages.first?.threshold, 0)
        XCTAssertEqual(config.stages.first?.name, "pet_baby")
        XCTAssertEqual(config.stages.last?.name, "pet_gold")
    }

    // MARK: - PetEvolutionEngine Tests

    func testPetEvolutionStageProgression() {
        let engine = PetEvolutionEngine()

        XCTAssertEqual(engine.stageIndex(for: 0), 0)     // pet_baby
        XCTAssertEqual(engine.stageIndex(for: 10), 1)    // pet_toddler
        XCTAssertEqual(engine.stageIndex(for: 25), 2)    // pet_frog
        XCTAssertEqual(engine.stageIndex(for: 675), 15)  // pet_gold
        XCTAssertEqual(engine.stageIndex(for: 1000), 15) // Capped at max stage
    }

    func testPetEvolutionRegression() {
        let engine = PetEvolutionEngine()

        XCTAssertEqual(engine.clamped(-10), 0)
        XCTAssertEqual(engine.clamped(0), 0)
        XCTAssertEqual(engine.clamped(50), 50)
        XCTAssertEqual(engine.clamped(1000), 1000)
    }

    func testPetEvolutionImageNames() {
        let engine = PetEvolutionEngine()

        XCTAssertEqual(engine.imageName(for: 0), "pet_baby")
        XCTAssertEqual(engine.imageName(for: 675), "pet_gold")
        XCTAssertEqual(engine.imageName(for: -10), "pet_baby") // Clamped to 0
    }

    // MARK: - SharedStore Tests

    func testSharedStoreSaveAndLoad() {
        let store = SharedStore.shared
        let testKey = "test_\(Int(Date().timeIntervalSince1970))"

        let slot = DayModel.Slot(hour: 10, title: "Test task", isDone: false)
        let originalDay = DayModel(key: testKey, slots: [slot], points: 75)

        store.saveDay(originalDay)
        let loadedDay = store.loadDay(key: testKey)

        XCTAssertNotNil(loadedDay)
        XCTAssertEqual(loadedDay?.key, testKey)
        XCTAssertEqual(loadedDay?.slots.count, 1)
        XCTAssertEqual(loadedDay?.points, 75)
    }

    func testSharedStoreMarkNextDone() {
        let store = SharedStore.shared
        let testKey = "test_mark_\(Int(Date().timeIntervalSince1970))"

        let slots = [
            DayModel.Slot(hour: 9, title: "Task 1", isDone: false),
            DayModel.Slot(hour: 14, title: "Task 2", isDone: false)
        ]
        let originalDay = DayModel(key: testKey, slots: slots, points: 0)
        store.saveDay(originalDay)

        // Mock current time to be 9 AM
        let mockTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!
        let updatedDay = store.markNextDone(for: testKey, now: mockTime)

        XCTAssertNotNil(updatedDay)
        XCTAssertTrue(updatedDay!.slots[0].isDone) // First task should be marked done
        XCTAssertFalse(updatedDay!.slots[1].isDone) // Second task should remain undone
        XCTAssertEqual(updatedDay!.points, 5) // Should have gained 5 points
    }

    func testSharedStorePointsMutation() {
        let store = SharedStore.shared
        let testKey = "test_points_\(Int(Date().timeIntervalSince1970))"

        // Test set points
        store.set(points: 100, for: testKey)
        let day1 = store.loadDay(key: testKey)
        XCTAssertEqual(day1?.points, 100)

        // Test advance points
        store.advance(by: 25, dayKey: testKey)
        let day2 = store.loadDay(key: testKey)
        XCTAssertEqual(day2?.points, 125)

        // Test regress points
        store.regress(by: 50, dayKey: testKey)
        let day3 = store.loadDay(key: testKey)
        XCTAssertEqual(day3?.points, 75)

        // Test regress below zero (should clamp to 0)
        store.regress(by: 100, dayKey: testKey)
        let day4 = store.loadDay(key: testKey)
        XCTAssertEqual(day4?.points, 0)
    }

    // MARK: - TaskPlanner Tests

    func testTaskPlannerCreateDailySchedule() {
        let planner = TaskPlanner.shared
        let schedule = planner.createDailySchedule(startHour: 9, endHour: 17, taskCount: 3)

        XCTAssertEqual(schedule.slots.count, 3)
        XCTAssertEqual(schedule.points, 0)

        // Check that tasks are distributed across the time range
        let hours = schedule.slots.map { $0.hour }.sorted()
        XCTAssertGreaterThanOrEqual(hours.first!, 9)
        XCTAssertLessThanOrEqual(hours.last!, 17)
    }

    func testTaskPlannerNext3Tasks() {
        let planner = TaskPlanner.shared

        let slots = [
            DayModel.Slot(hour: 8, title: "Early task", isDone: true),   // Past, done
            DayModel.Slot(hour: 10, title: "Current task", isDone: false), // Current/future
            DayModel.Slot(hour: 14, title: "Afternoon task", isDone: false),
            DayModel.Slot(hour: 18, title: "Evening task", isDone: false)
        ]
        let dayModel = DayModel(key: "test", slots: slots, points: 0)

        // Mock current time to be 9 AM
        let mockTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!
        let next3 = planner.getNext3Tasks(from: dayModel, currentTime: mockTime)

        XCTAssertEqual(next3.count, 3) // Should get 3 remaining tasks
        XCTAssertEqual(next3[0].hour, 10) // First should be the 10 AM task
        XCTAssertEqual(next3[1].hour, 14) // Second should be the 2 PM task
        XCTAssertEqual(next3[2].hour, 18) // Third should be the 6 PM task
    }

    // MARK: - AssetPipeline Tests

    func testAssetPipelineImageNames() {
        let pipeline = AssetPipeline.shared

        XCTAssertEqual(pipeline.imageName(for: 0), "pet_baby")
        XCTAssertEqual(pipeline.imageName(for: 15), "pet_gold")
        XCTAssertEqual(pipeline.imageName(for: -1), "pet_baby") // Should clamp to 0
        XCTAssertEqual(pipeline.imageName(for: 20), "pet_gold") // Should clamp to 15
    }

    func testAssetPipelineValidation() {
        let pipeline = AssetPipeline.shared
        let result = pipeline.validate()

        XCTAssertEqual(result.totalStages, 16)
        XCTAssertEqual(result.availableAssets.count + result.missingAssets.count, 16)
        XCTAssertGreaterThanOrEqual(result.completionPercentage, 0.0)
        XCTAssertLessThanOrEqual(result.completionPercentage, 100.0)
    }

    // MARK: - Integration Tests

    func testFullWorkflow() {
        let store = SharedStore.shared
        let engine = PetEvolutionEngine()
        let planner = TaskPlanner.shared

        let testKey = "integration_\(Int(Date().timeIntervalSince1970))"

        // Create a schedule
        let schedule = planner.createDailySchedule(startHour: 9, endHour: 15, taskCount: 3)
        store.saveDay(schedule)

        // Complete first task
        let mockTime = Calendar.current.date(bySettingHour: 9, minute: 30, second: 0, of: Date())!
        let afterFirstTask = store.markNextDone(for: testKey, now: mockTime)

        XCTAssertNotNil(afterFirstTask)
        XCTAssertEqual(afterFirstTask!.points, 5) // Should have gained points

        let stage = engine.stageIndex(for: afterFirstTask!.points)
        XCTAssertGreaterThanOrEqual(stage, 0)
        XCTAssertLessThanOrEqual(stage, 15)

        // Get remaining tasks
        let remaining = planner.getNext3Tasks(from: afterFirstTask!, currentTime: mockTime)
        XCTAssertEqual(remaining.count, 2) // Should have 2 tasks left
    }
}