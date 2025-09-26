import SwiftUI
import SharedKit
import AppIntents
import UIKit

@main
struct PetProgressApp: App {
    var body: some Scene {
        WindowGroup {
            CompleteContentView()
        }
    }
}

// MARK: - App Shortcuts Configuration

@available(iOS 17.0, *)
extension PetProgressApp {
    static var appShortcutsProvider: PetProgressShortcuts {
        PetProgressShortcuts()
    }
}
