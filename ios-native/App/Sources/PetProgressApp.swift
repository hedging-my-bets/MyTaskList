import SwiftUI
import SharedKit
import AppIntents
import UIKit

@main
struct PetProgressApp: App {
    @StateObject private var dataStore = DataStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataStore)
                .task {
                    await dataStore.launchApplyCloseoutIfNeeded()
                    // Also check for rollover with grace period
                    TaskRolloverHandler.shared.handleAppForeground()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    // Check for rollover when app comes to foreground
                    TaskRolloverHandler.shared.handleAppForeground()
                }
                .onOpenURL { url in
                    URLRoutes.handle(url: url)
                }
        }
    }
}

// MARK: - App Shortcuts Configuration

@available(iOS 17.0, *)
extension PetProgressApp {
    static var appShortcutsProvider: PetProgressAppShortcutsProvider {
        PetProgressAppShortcutsProvider()
    }
}
