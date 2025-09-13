import Foundation

public func dayKey(for date: Date, in tz: TimeZone = .current) -> String {
    var cal = Calendar.current
    cal.timeZone = tz
    let comps = cal.dateComponents([.year, .month, .day], from: date)
    let y = comps.year ?? 0
    let m = comps.month ?? 0
    let d = comps.day ?? 0
    return String(format: "%04d-%02d-%02d", y, m, d)
}

public func isOnTime(task: TaskItem, now: Date, graceMinutes: Int = 60) -> Bool {
    var cal = Calendar.current

    // Use task's timezone if available, otherwise current
    if let taskTimeZone = task.scheduledAt.timeZone {
        cal.timeZone = taskTimeZone
    }

    let due = cal.date(bySettingHour: task.scheduledAt.hour ?? 0, minute: task.scheduledAt.minute ?? 0, second: 0, of: now) ?? now
    let windowStart = due.addingTimeInterval(TimeInterval(-graceMinutes * 60))
    let windowEnd = due.addingTimeInterval(TimeInterval(graceMinutes * 60))
    return now >= windowStart && now <= windowEnd
}

public func dateFor(dayKey: String, time: DateComponents) -> Date? {
    let components = dayKey.split(separator: "-").compactMap { Int($0) }
    guard components.count == 3 else { return nil }

    var cal = Calendar.current
    cal.timeZone = .current

    var dateComps = DateComponents()
    dateComps.year = components[0]
    dateComps.month = components[1]
    dateComps.day = components[2]
    dateComps.hour = time.hour ?? 0
    dateComps.minute = time.minute ?? 0

    return cal.date(from: dateComps)
}