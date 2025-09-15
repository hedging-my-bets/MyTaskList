import SwiftUI
import SharedKit
import AppIntents

@main
struct PetProgressApp: App {
    @StateObject private var dataStore = DataStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataStore)
                .task {
                    await dataStore.launchApplyCloseoutIfNeeded()
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
