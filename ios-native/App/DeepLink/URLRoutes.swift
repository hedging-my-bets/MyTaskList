import Foundation

enum URLRoutes {
    static func handle(url: URL) {
        // For MVP, routing handled by SwiftUI NavigationStack default screen
        // Validate scheme
        guard url.scheme == "petprogress" else { return }
        // petprogress://today -> no-op as Today is root
        // petprogress://planner -> set a notification for DataStore to present planner
        if url.host == "planner" {
            NotificationCenter.default.post(name: .openPlanner, object: nil)
        }
    }
}

extension Notification.Name { static let openPlanner = Notification.Name("OpenPlanner") }

