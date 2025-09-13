import SwiftUI
import SharedKit

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
        }
    }
}