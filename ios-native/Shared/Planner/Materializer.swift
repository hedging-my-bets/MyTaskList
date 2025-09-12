import Foundation

public struct MaterializedTask: Identifiable, Hashable {
    public enum Origin: Hashable { case series(UUID), oneOff(UUID) }
    public var id: UUID
    public var origin: Origin
    public var title: String
    public var time: DateComponents
    public var isCompleted: Bool
}

public func weekday(for dayKey: String) -> Int? {
    let parts = dayKey.split(separator: "-")
    guard parts.count == 3,
          let y = Int(parts[0]), let m = Int(parts[1]), let d = Int(parts[2]) else { return nil }
    var comps = DateComponents()
    comps.year = y; comps.month = m; comps.day = d
    let cal = Calendar.current
    guard let date = cal.date(from: comps) else { return nil }
    return cal.component(.weekday, from: date)
}

public func dateFor(dayKey: String, time: DateComponents) -> Date? {
    let parts = dayKey.split(separator: "-")
    guard parts.count == 3,
          let y = Int(parts[0]), let m = Int(parts[1]), let d = Int(parts[2]) else { return nil }
    var comps = DateComponents()
    comps.year = y; comps.month = m; comps.day = d
    comps.hour = time.hour; comps.minute = time.minute; comps.second = 0
    return Calendar.current.date(from: comps)
}

public func materializeTasks(for dayKey: String, in state: AppState) -> [MaterializedTask] {
    let completed: Set<UUID> = state.completions[dayKey] ?? []
    var result: [MaterializedTask] = []

    // One-offs
    for t in state.tasks.filter({ $0.dayKey == dayKey }) {
        let isDone = completed.contains(t.id)
        result.append(MaterializedTask(id: t.id, origin: .oneOff(t.id), title: t.title, time: t.scheduledAt, isCompleted: isDone))
    }

    // Series
    let w = weekday(for: dayKey)
    for s in state.series where s.isActive {
        guard let wd = w, s.daysOfWeek.contains(wd) else { continue }
        // overrides
        let ov = state.overrides.first(where: { $0.seriesId == s.id && $0.dayKey == dayKey })
        if ov?.isDeleted == true { continue }
        let title = ov?.title ?? s.title
        let time = ov?.time ?? s.time
        let instanceId = UUID(uuidString: dayKey + s.id.uuidString.hash.description) ?? UUID()
        let isDone = completed.contains(instanceId)
        result.append(MaterializedTask(id: instanceId, origin: .series(s.id), title: title, time: time, isCompleted: isDone))
    }

    return result.sorted { (l, r) in
        (l.time.hour ?? 0, l.time.minute ?? 0) < (r.time.hour ?? 0, r.time.minute ?? 0)
    }
}

public func nearestTaskIndex(now: Date, tasks: [MaterializedTask]) -> Int? {
    guard !tasks.isEmpty else { return nil }
    let cal = Calendar.current
    let distances: [(Int, TimeInterval)] = tasks.enumerated().compactMap { idx, t in
        guard let date = dateFor(dayKey: dayKey(for: now), time: t.time) else { return nil }
        return (idx, abs(date.timeIntervalSince(now)))
    }
    return distances.min(by: { $0.1 < $1.1 })?.0
}

public func threeTasksAround(now: Date, tasks: [MaterializedTask]) -> [MaterializedTask] {
    let sorted = tasks
    guard let mid = nearestTaskIndex(now: now, tasks: sorted) else { return [] }
    var indices: [Int] = [mid]
    if mid - 1 >= 0 { indices.insert(mid - 1, at: 0) }
    if mid + 1 < sorted.count { indices.append(mid + 1) }
    return indices.map { sorted[$0] }
}



