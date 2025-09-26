import WidgetKit
import SwiftUI
import SharedKit
import AppIntents

/// Main Task List Widget with proper AppIntents configuration
@available(iOS 17.0, *)
struct TaskListWidget: Widget {
    let kind: String = "TaskListWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ConfigurationAppIntent.self,
            provider: TaskWidgetProvider()
        ) { entry in
            TaskLockScreenView(entry: entry)
                .widgetURL(deepLinkURL(for: entry))
        }
        .configurationDisplayName("Today's Tasks")
        .description("Check off tasks from your Lock Screen and watch your pet evolve")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline, .systemSmall])
    }

    private func deepLinkURL(for entry: TaskEntry) -> URL? {
        guard let currentTask = entry.tasks.first(where: { !$0.isDone }) else { return nil }

        var components = URLComponents()
        components.scheme = "petprogress"
        components.host = "task"
        components.queryItems = [
            URLQueryItem(name: "dayKey", value: currentTask.dayKey),
            URLQueryItem(name: "hour", value: String(currentTask.dueHour)),
            URLQueryItem(name: "title", value: currentTask.title),
            URLQueryItem(name: "id", value: currentTask.id)
        ]
        return components.url
    }
}

// Widget bundle moved to PetProgressWidget.swift to avoid duplicate @main declarations