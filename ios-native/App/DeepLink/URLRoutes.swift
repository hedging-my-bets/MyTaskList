import Foundation

enum URLRoutes {
    static func handle(url: URL) {
        // Validate scheme
        guard url.scheme == "petprogress" else { return }

        switch url.host {
        case "planner":
            // petprogress://planner -> open planner view
            NotificationCenter.default.post(name: .openPlanner, object: nil)

        case "task":
            // petprogress://task?dayKey=2024-09-14&hour=10&title=Task%20Name
            // Extract task details from query parameters
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            let queryItems = components?.queryItems ?? []

            var taskInfo: [String: String] = [:]
            for item in queryItems {
                if let value = item.value {
                    taskInfo[item.name] = value
                }
            }

            // Post notification with task details for the app to handle
            NotificationCenter.default.post(
                name: .openTask,
                object: nil,
                userInfo: taskInfo
            )

        case "today", nil:
            // petprogress://today or petprogress:// -> no-op as Today is root
            break

        default:
            // Unknown route - ignore silently
            break
        }
    }
}

extension Notification.Name {
    static let openPlanner = Notification.Name("OpenPlanner")
    static let openTask = Notification.Name("OpenTask")
}

