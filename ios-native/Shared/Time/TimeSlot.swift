import Foundation

enum TimeSlot {
    /// A stable, POSIX day key so tests don't wobble across locales/timezones.
    static func dayKey(for date: Date, timeZone: TimeZone) -> String {
        let cal = Calendar(identifier: .gregorian)
        var comps = cal.dateComponents(in: timeZone, from: date)
        let y = comps.year!, m = comps.month!, d = comps.day!
        return String(format: "%04d-%02d-%02d", y, m, d)
    }

    /// Hour index (0...23) using the provided timezone, tolerating DST gaps / folds.
    static func hourIndex(for date: Date, timeZone: TimeZone) -> Int {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        return cal.component(.hour, from: date)
    }

    /// Next top-of-hour after `date`, across DST transitions (spring gaps / fall folds).
    static func nextHour(after date: Date, timeZone: TimeZone) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        let comps = DateComponents(minute: 0, second: 0)
        // Advance by ~90 minutes, then snap forward to the next valid top-of-hour.
        let probe = date.addingTimeInterval(90 * 60)
        return cal.nextDate(after: probe,
                            matching: DateComponents(minute: 0, second: 0),
                            matchingPolicy: .nextTime,
                            repeatedTimePolicy: .first,
                            direction: .forward) ?? probe
    }

    /// Returns the next slot index (>= now), capped at 23.
    static func nextSlotIndex(on date: Date, timeZone: TimeZone) -> Int {
        min(23, hourIndex(for: date, timeZone: timeZone))
    }
}