import SwiftUI

@main
struct PetProgressApp: App {
    @StateObject private var dataStore = DataStore()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    ContentView()
                        .environmentObject(dataStore)
                        .onOpenURL { url in
                            URLRoutes.handle(url: url)
                        }
                        .task {
                            await dataStore.launchApplyCloseoutIfNeeded()
                        }
                        .onReceive(NotificationCenter.default.publisher(for: .openPlanner)) { _ in
                            dataStore.routeToPlanner()
                        }
                } else {
                    OnboardingView()
                        .onDisappear {
                            hasCompletedOnboarding = true
                        }
                }
            }
        }
    }
}

