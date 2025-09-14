import Foundation

/// Simple validation tests for SharedKit components
public struct ValidationTests {
    public static func runAll() {
        testPetEvolutionEngine()
        testSharedStore()
        testTimeSlot()
        print("All validation tests passed ✓")
    }

    private static func testPetEvolutionEngine() {
        let engine = PetEvolutionEngine()

        // Test stage progression
        assert(engine.stageIndex(for: 0) == 0, "Stage 0 test failed")
        assert(engine.stageIndex(for: 10) == 1, "Stage 1 test failed")
        assert(engine.stageIndex(for: 675) == 15, "Stage 15 test failed")

        // Test regression (clamping)
        assert(engine.clamped(-10) == 0, "Regression test failed")
        assert(engine.clamped(1000) == 1000, "Large value test failed")

        // Test image names
        assert(engine.imageName(for: 0) == "pet_baby", "Image name test failed")
        assert(engine.imageName(for: 675) == "pet_gold", "Gold stage image test failed")

        print("PetEvolutionEngine tests passed ✓")
    }

    private static func testSharedStore() {
        let store = SharedStore.shared
        let testKey = "test_day_\(Int(Date().timeIntervalSince1970))"

        // Test day creation and loading
        let day = DayModel(key: testKey, slots: [
            DayModel.Slot(hour: 9, title: "Test task", isDone: false)
        ], points: 50)

        store.saveDay(day)
        let loaded = store.loadDay(key: testKey)
        assert(loaded?.key == testKey, "Day save/load test failed")
        assert(loaded?.points == 50, "Points save/load test failed")

        print("SharedStore tests passed ✓")
    }

    private static func testTimeSlot() {
        let now = Date()
        let dayKey = TimeSlot.dayKey(for: now)
        let hourIndex = TimeSlot.hourIndex(for: now)

        assert(!dayKey.isEmpty, "Day key generation failed")
        assert(hourIndex >= 0 && hourIndex <= 23, "Hour index out of range")

        print("TimeSlot tests passed ✓")
    }
}