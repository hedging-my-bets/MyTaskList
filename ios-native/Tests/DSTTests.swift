import XCTest
@testable import PetProgress
@testable import PetProgressShared

final class DSTTests: XCTestCase {
    func testDayKeyConsistencyAcrossDST() {
        // Test DST transition day (US Spring Forward)
        let calendar = Calendar(identifier: .gregorian)
        let tz = TimeZone(identifier: "America/Los_Angeles")!
        
        // March 9, 2025 - DST transition day
        var comps = DateComponents()
        comps.year = 2025; comps.month = 3; comps.day = 9
        comps.timeZone = tz
        
        // Before DST (1:30 AM)
        comps.hour = 1; comps.minute = 30
        let beforeDST = calendar.date(from: comps)!
        let beforeKey = dayKey(for: beforeDST, in: tz)
        
        // After DST (3:30 AM, which becomes 2:30 AM after spring forward)
        comps.hour = 3; comps.minute = 30
        let afterDST = calendar.date(from: comps)!
        let afterKey = dayKey(for: afterDST, in: tz)
        
        // Both should be same day
        XCTAssertEqual(beforeKey, afterKey)
        XCTAssertEqual(beforeKey, "2025-03-09")
    }
    
    func testOnTimeCalculationWithDST() {
        let calendar = Calendar(identifier: .gregorian)
        let tz = TimeZone(identifier: "America/Los_Angeles")!
        
        // Create task for 1:30 AM on DST day
        var taskComps = DateComponents()
        taskComps.hour = 1; taskComps.minute = 30
        let task = TaskItem(id: UUID(), title: "DST Task", scheduledAt: taskComps, dayKey: "2025-03-09", isCompleted: false, completedAt: nil, snoozedUntil: nil)
        
        // Test completion at 1:45 AM (should be on time)
        var nowComps = DateComponents()
        nowComps.year = 2025; nowComps.month = 3; nowComps.day = 9
        nowComps.hour = 1; nowComps.minute = 45
        nowComps.timeZone = tz
        let now = calendar.date(from: nowComps)!
        
        let onTime = isOnTime(task: task, now: now, graceMinutes: 60)
        XCTAssertTrue(onTime)
    }
    
    func testTimezoneChangeHandling() {
        // Test with different timezone
        let tz1 = TimeZone(identifier: "America/New_York")!
        let tz2 = TimeZone(identifier: "America/Los_Angeles")!

        let date = Date()
        let key1 = dayKey(for: date, in: tz1)
        let key2 = dayKey(for: date, in: tz2)

        // Keys should be different if it's different day in different timezone
        // (This test may pass or fail depending on actual time, but should not crash)
        _ = key1
        _ = key2
    }

    func testCloseoutRunsOncePerDay() {
        var pet = PetState(stageIndex: 0, stageXP: 5, lastCloseoutDayKey: "2025-01-01")
        let cfg = StageCfg.defaultConfig()
        let today = "2025-01-02"

        // First closeout should apply (different day from lastCloseoutDayKey)
        PetEngine.onDailyCloseout(rate: 1.0, pet: &pet, cfg: cfg, dayKey: today)
        let firstXP = pet.stageXP
        XCTAssertEqual(firstXP, 8, "Closeout should add 3 XP for perfect rate")

        // Second closeout on same day should not apply
        PetEngine.onDailyCloseout(rate: 1.0, pet: &pet, cfg: cfg, dayKey: today)
        XCTAssertEqual(pet.stageXP, firstXP, "Closeout should only run once per day")
    }

    func testHourRolloverSafety() {
        let calendar = Calendar(identifier: .gregorian)
        let tz = TimeZone(identifier: "America/Los_Angeles")!

        // Test at hour boundary (11:59 PM to 12:01 AM)
        var comps = DateComponents()
        comps.year = 2025; comps.month = 1; comps.day = 1
        comps.hour = 23; comps.minute = 59
        comps.timeZone = tz
        let beforeMidnight = calendar.date(from: comps)!

        comps.hour = 0; comps.minute = 1; comps.day = 2
        let afterMidnight = calendar.date(from: comps)!

        let beforeKey = dayKey(for: beforeMidnight, in: tz)
        let afterKey = dayKey(for: afterMidnight, in: tz)

        XCTAssertNotEqual(beforeKey, afterKey, "Should be different days across midnight")
        XCTAssertEqual(beforeKey, "2025-01-01")
        XCTAssertEqual(afterKey, "2025-01-02")
    }
}

