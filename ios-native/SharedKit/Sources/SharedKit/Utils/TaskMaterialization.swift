import Foundation

public func materializeTasks(for dayKey: String, in state: AppState) -> [MaterializedTask] {
    var materialized: [MaterializedTask] = []

    // Add one-off tasks for this day
    for task in state.tasks where task.dayKey == dayKey {
        let completed = state.completions[dayKey]?.contains(task.id) ?? false
        materialized.append(MaterializedTask(
            id: task.id,
            title: task.title,
            time: task.scheduledAt,
            isCompleted: completed,
            origin: .oneOff(task.id)
        ))
    }

    // Add series tasks for this day
    for series in state.series where series.isActive {
        if shouldGenerateSeriesTask(series: series, for: dayKey) {
            // Check for overrides
            let override = state.overrides.first { $0.seriesId == series.id && $0.dayKey == dayKey }

            // Skip if deleted
            if override?.isDeleted == true {
                continue
            }

            // Use override time if available, otherwise series time
            let time = override?.time ?? series.scheduledAt
            let completed = state.completions[dayKey]?.contains(series.id) ?? false

            materialized.append(MaterializedTask(
                id: series.id,
                title: series.title,
                time: time,
                isCompleted: completed,
                origin: .series(series.id)
            ))
        }
    }

    // Sort by time
    return materialized.sorted { l, r in
        let lTime = (l.time.hour ?? 0) * 60 + (l.time.minute ?? 0)
        let rTime = (r.time.hour ?? 0) * 60 + (r.time.minute ?? 0)
        return lTime < rTime
    }
}

private func shouldGenerateSeriesTask(series: TaskSeries, for dayKey: String) -> Bool {
    guard let date = dateFromDayKey(dayKey) else { return false }
    let calendar = Calendar.current
    let weekday = calendar.component(.weekday, from: date)

    switch series.frequency {
    case .daily:
        return true
    case .weekdays:
        return weekday >= 2 && weekday <= 6 // Monday-Friday
    case .weekly:
        return true // For now, generate every day (could be refined)
    case .monthly:
        return true // For now, generate every day (could be refined)
    }
}

private func dateFromDayKey(_ dayKey: String) -> Date? {
    let components = dayKey.split(separator: "-").compactMap { Int($0) }
    guard components.count == 3 else { return nil }

    let dateComponents = DateComponents(year: components[0], month: components[1], day: components[2])
    return Calendar.current.date(from: dateComponents)
}

public func nextUncompletedTask(for tasks: [TaskItem], dayKey: String) -> TaskItem? {
    tasks.filter { $0.dayKey == dayKey && !$0.isCompleted }
        .sorted { (l, r) in
            (l.scheduledAt.hour ?? 0, l.scheduledAt.minute ?? 0) < (r.scheduledAt.hour ?? 0, r.scheduledAt.minute ?? 0)
        }
        .first
}