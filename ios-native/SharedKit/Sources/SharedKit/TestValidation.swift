import Foundation

/// Simple test runner for manual validation
public struct TestValidation {
    public static func runBasicTests() {
        print("🧪 Running SharedKit validation tests...")

        testTimeSlot()
        testPetEvolution()
        testSharedStore()
        testTaskPlanner()
        testAssetPipeline()

        print("✅ All validation tests passed!")
    }

    private static func testTimeSlot() {
        let now = Date()
        let dayKey = TimeSlot.dayKey(for: now)
        let hourIndex = TimeSlot.hourIndex(for: now)
        let nextHour = TimeSlot.nextHour(after: now)

        assert(!dayKey.isEmpty, "Day key should not be empty")
        assert(hourIndex >= 0 && hourIndex <= 23, "Hour index should be 0-23")
        assert(nextHour > now, "Next hour should be in the future")

        print("✓ TimeSlot tests passed")
    }

    private static func testPetEvolution() {
        let engine = PetEvolutionEngine()

        assert(engine.stageIndex(for: 0) == 0, "Stage 0 test failed")
        assert(engine.stageIndex(for: 10) == 1, "Stage 1 test failed")
        assert(engine.stageIndex(for: 675) == 15, "Stage 15 test failed")
        assert(engine.clamped(-10) == 0, "Clamping test failed")

        print("✓ PetEvolution tests passed")
    }

    private static func testSharedStore() {
        let store = SharedStore.shared
        let testKey = "validation_test_\(Int(Date().timeIntervalSince1970))"

        let day = DayModel(
            key: testKey,
            slots: [DayModel.Slot(hour: 9, title: "Test", isDone: false)],
            points: 50
        )

        store.saveDay(day)
        let loaded = store.loadDay(key: testKey)

        assert(loaded?.key == testKey, "Save/load test failed")
        assert(loaded?.points == 50, "Points persistence failed")

        print("✓ SharedStore tests passed")
    }

    private static func testTaskPlanner() {
        let planner = TaskPlanner.shared
        let schedule = planner.createDailySchedule()

        assert(!schedule.slots.isEmpty, "Schedule creation failed")
        assert(schedule.points == 0, "Initial points should be 0")

        let next3 = planner.getNext3Tasks(from: schedule)
        assert(next3.count <= 3, "Next 3 tasks count incorrect")

        print("✓ TaskPlanner tests passed")
    }

    private static func testAssetPipeline() {
        let pipeline = AssetPipeline.shared

        assert(pipeline.imageName(for: 0) == "pet_baby", "Baby stage failed")
        assert(pipeline.imageName(for: 15) == "pet_gold", "Gold stage failed")

        let validation = pipeline.validate()
        assert(validation.totalStages == 16, "Stage count incorrect")

        print("✓ AssetPipeline tests passed")
    }
}
