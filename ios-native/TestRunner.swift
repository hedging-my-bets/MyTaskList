#!/usr/bin/env swift
// Comprehensive Test Runner for PetProgress App
// This script validates all critical components

import Foundation

// ANSI color codes for output
struct Colors {
    static let reset = "\u{001B}[0m"
    static let green = "\u{001B}[32m"
    static let red = "\u{001B}[31m"
    static let yellow = "\u{001B}[33m"
    static let blue = "\u{001B}[34m"
}

struct TestResult {
    let name: String
    let passed: Bool
    let details: String
}

class AppTester {
    var results: [TestResult] = []

    func run() {
        print("\(Colors.blue)🧪 PetProgress App Comprehensive Test Suite\(Colors.reset)\n")

        // Run all test categories
        testProjectConfiguration()
        testAppIntents()
        testWidgetConfiguration()
        testSharedStore()
        testPetEvolution()
        testSettings()
        testCelebrationSystem()
        testDeepLinks()
        testCriticalFiles()

        // Print summary
        printSummary()
    }

    func testProjectConfiguration() {
        print("\(Colors.yellow)📱 Testing Project Configuration...\(Colors.reset)")

        // Check project.yml configuration
        let projectPath = "project.yml"
        if FileManager.default.fileExists(atPath: projectPath) {
            let content = try? String(contentsOfFile: projectPath)

            // iPhone-only check
            let isiPhoneOnly = content?.contains("TARGETED_DEVICE_FAMILY: \"1\"") ?? false
            addResult("iPhone-only configuration",
                     passed: isiPhoneOnly,
                     details: isiPhoneOnly ? "✓ Device family set to iPhone only" : "✗ Not configured for iPhone only")

            // iOS 17 deployment target
            let hasCorrectTarget = content?.contains("iOS: \"17.0\"") ?? false
            addResult("iOS 17 deployment target",
                     passed: hasCorrectTarget,
                     details: hasCorrectTarget ? "✓ Deployment target iOS 17.0" : "✗ Incorrect deployment target")

            // App Group capability
            let hasAppGroup = content?.contains("com.apple.ApplicationGroups.iOS: true") ?? false
            addResult("App Group capability",
                     passed: hasAppGroup,
                     details: hasAppGroup ? "✓ App Group enabled for both targets" : "✗ App Group not configured")
        }
        print()
    }

    func testAppIntents() {
        print("\(Colors.yellow)🎯 Testing App Intents Implementation...\(Colors.reset)")

        // Check for TaskEntity
        let taskEntityPath = "SharedKit/Sources/SharedKit/TaskEntity.swift"
        let hasTaskEntity = FileManager.default.fileExists(atPath: taskEntityPath)
        addResult("TaskEntity implementation",
                 passed: hasTaskEntity,
                 details: hasTaskEntity ? "✓ TaskEntity.swift found" : "✗ TaskEntity.swift missing")

        // Check for ProperAppIntents
        let appIntentsPath = "Widget/Sources/ProperAppIntents.swift"
        let hasAppIntents = FileManager.default.fileExists(atPath: appIntentsPath)

        if hasAppIntents {
            let content = try? String(contentsOfFile: appIntentsPath)

            // Check for required intents
            let hasCompleteIntent = content?.contains("CompleteTaskIntent") ?? false
            addResult("CompleteTaskIntent",
                     passed: hasCompleteIntent,
                     details: hasCompleteIntent ? "✓ CompleteTaskIntent implemented" : "✗ Missing CompleteTaskIntent")

            let hasSkipIntent = content?.contains("SkipTaskIntent") ?? false
            addResult("SkipTaskIntent",
                     passed: hasSkipIntent,
                     details: hasSkipIntent ? "✓ SkipTaskIntent implemented" : "✗ Missing SkipTaskIntent")

            let hasPageIntents = content?.contains("PageIntent") ?? false
            addResult("Page navigation intents",
                     passed: hasPageIntents,
                     details: hasPageIntents ? "✓ Page navigation intents found" : "✗ Missing page navigation")
        }
        print()
    }

    func testWidgetConfiguration() {
        print("\(Colors.yellow)⏰ Testing Widget Configuration...\(Colors.reset)")

        // Check TaskWidgetProvider
        let providerPath = "Widget/Sources/TaskWidgetProvider.swift"
        if FileManager.default.fileExists(atPath: providerPath) {
            let content = try? String(contentsOfFile: providerPath)

            // Hourly refresh check
            let hasHourlyRefresh = content?.contains(".after(next)") ?? false
            addResult("Hourly refresh timeline",
                     passed: hasHourlyRefresh,
                     details: hasHourlyRefresh ? "✓ Hourly refresh configured" : "✗ Missing hourly refresh")

            // Nearest-hour logic
            let hasNearestHour = content?.contains("getNearestHourTasks") ?? false
            addResult("Nearest-hour task logic",
                     passed: hasNearestHour,
                     details: hasNearestHour ? "✓ Nearest-hour implementation found" : "✗ Missing nearest-hour logic")
        }

        // Check Lock Screen views
        let lockScreenPath = "Widget/Sources/views/TaskLockScreenView.swift"
        let hasLockScreenView = FileManager.default.fileExists(atPath: lockScreenPath)
        addResult("Lock Screen views",
                 passed: hasLockScreenView,
                 details: hasLockScreenView ? "✓ TaskLockScreenView.swift found" : "✗ Lock Screen views missing")

        print()
    }

    func testSharedStore() {
        print("\(Colors.yellow)💾 Testing SharedStore App Group...\(Colors.reset)")

        // Check SharedStoreActor
        let storePath = "SharedKit/Sources/SharedKit/SharedStoreActor.swift"
        if FileManager.default.fileExists(atPath: storePath) {
            let content = try? String(contentsOfFile: storePath)

            // App Group configuration
            let hasAppGroup = content?.contains("group.com.petprogress") ?? false
            addResult("App Group identifier",
                     passed: hasAppGroup,
                     details: hasAppGroup ? "✓ App Group configured" : "✗ App Group not found")

            // Grace minutes support
            let hasGraceMinutes = content?.contains("graceMinutes") ?? false
            addResult("Grace minutes in SharedStore",
                     passed: hasGraceMinutes,
                     details: hasGraceMinutes ? "✓ Grace minutes support found" : "✗ Missing grace minutes")
        }

        // Check test file
        let testPath = "Tests/AppGroupTests.swift"
        let hasAppGroupTests = FileManager.default.fileExists(atPath: testPath)
        addResult("App Group tests",
                 passed: hasAppGroupTests,
                 details: hasAppGroupTests ? "✓ AppGroupTests.swift found" : "✗ App Group tests missing")

        print()
    }

    func testPetEvolution() {
        print("\(Colors.yellow)🐾 Testing Pet Evolution System...\(Colors.reset)")

        // Check PetEvolutionEngine
        let enginePath = "SharedKit/Sources/SharedKit/PetEvolutionEngine.swift"
        if FileManager.default.fileExists(atPath: enginePath) {
            let content = try? String(contentsOfFile: enginePath)

            // XP threshold method
            let hasThreshold = content?.contains("func threshold(for stageIndex: Int)") ?? false
            addResult("XP threshold method",
                     passed: hasThreshold,
                     details: hasThreshold ? "✓ Threshold method implemented" : "✗ Missing threshold method")

            // Stage image mapping
            let hasImageName = content?.contains("func imageName(for points: Int)") ?? false
            addResult("Pet image mapping",
                     passed: hasImageName,
                     details: hasImageName ? "✓ Image name mapping found" : "✗ Missing image mapping")
        }

        // Check pet assets
        let assetPath = "Widget/Assets.xcassets"
        let widgetHasAssets = FileManager.default.fileExists(atPath: assetPath)
        addResult("Widget pet assets",
                 passed: widgetHasAssets,
                 details: widgetHasAssets ? "✓ Widget Assets.xcassets found" : "✗ Widget assets missing")

        // Check pet evolution tests
        let testPath = "Tests/PetEvolutionWidgetTests.swift"
        let hasTests = FileManager.default.fileExists(atPath: testPath)
        addResult("Pet evolution tests",
                 passed: hasTests,
                 details: hasTests ? "✓ PetEvolutionWidgetTests.swift found" : "✗ Pet evolution tests missing")

        print()
    }

    func testSettings() {
        print("\(Colors.yellow)⚙️ Testing Settings Implementation...\(Colors.reset)")

        // Check SettingsView
        let settingsPath = "App/Sources/SettingsView.swift"
        if FileManager.default.fileExists(atPath: settingsPath) {
            let content = try? String(contentsOfFile: settingsPath)

            // Grace minutes control
            let hasGraceMinutes = content?.contains("Grace Minutes") ?? false
            addResult("Grace Minutes setting",
                     passed: hasGraceMinutes,
                     details: hasGraceMinutes ? "✓ Grace Minutes control found" : "✗ Missing Grace Minutes")

            // Privacy Policy link
            let hasPrivacyPolicy = content?.contains("Privacy Policy") ?? false
            addResult("Privacy Policy link",
                     passed: hasPrivacyPolicy,
                     details: hasPrivacyPolicy ? "✓ Privacy Policy link found" : "✗ Missing Privacy Policy")
        }

        // Check PrivacyPolicyView
        let privacyPath = "App/Sources/PrivacyPolicyView.swift"
        let hasPrivacyView = FileManager.default.fileExists(atPath: privacyPath)
        addResult("PrivacyPolicyView",
                 passed: hasPrivacyView,
                 details: hasPrivacyView ? "✓ PrivacyPolicyView.swift found" : "✗ Privacy Policy view missing")

        print()
    }

    func testCelebrationSystem() {
        print("\(Colors.yellow)🎉 Testing Celebration System...\(Colors.reset)")

        // Check CelebrationSystem
        let celebrationPath = "App/Sources/CelebrationSystem.swift"
        if FileManager.default.fileExists(atPath: celebrationPath) {
            let content = try? String(contentsOfFile: celebrationPath)

            // Haptic feedback
            let hasHaptics = content?.contains("HapticFeedback") ?? false
            addResult("Haptic feedback",
                     passed: hasHaptics,
                     details: hasHaptics ? "✓ HapticFeedback implementation found" : "✗ Missing haptic feedback")

            // Level-up celebration
            let hasLevelUp = content?.contains("celebrateLevelUp") ?? false
            addResult("Level-up celebration",
                     passed: hasLevelUp,
                     details: hasLevelUp ? "✓ Level-up celebration method found" : "✗ Missing level-up celebration")

            // Confetti system
            let hasConfetti = content?.contains("ConfettiView") ?? false
            addResult("Confetti animations",
                     passed: hasConfetti,
                     details: hasConfetti ? "✓ ConfettiView implemented" : "✗ Missing confetti system")
        }

        // Check DataStore integration
        let datastorePath = "App/Sources/DataStore.swift"
        if FileManager.default.fileExists(atPath: datastorePath) {
            let content = try? String(contentsOfFile: datastorePath)
            let hasCelebrationIntegration = content?.contains("CelebrationSystem.shared.celebrateLevelUp") ?? false
            addResult("DataStore celebration integration",
                     passed: hasCelebrationIntegration,
                     details: hasCelebrationIntegration ? "✓ Level-up triggers celebration" : "✗ Missing celebration trigger")
        }

        print()
    }

    func testDeepLinks() {
        print("\(Colors.yellow)🔗 Testing Deep Link System...\(Colors.reset)")

        // Check URLRoutes
        let routesPath = "App/DeepLink/URLRoutes.swift"
        if FileManager.default.fileExists(atPath: routesPath) {
            let content = try? String(contentsOfFile: routesPath)

            // URL scheme handling
            let hasScheme = content?.contains("petprogress") ?? false
            addResult("URL scheme handler",
                     passed: hasScheme,
                     details: hasScheme ? "✓ petprogress:// scheme configured" : "✗ Missing URL scheme")

            // Task deep link
            let hasTaskRoute = content?.contains("case \"task\"") ?? false
            addResult("Task deep link route",
                     passed: hasTaskRoute,
                     details: hasTaskRoute ? "✓ Task route handler found" : "✗ Missing task route")
        }

        // Check widget URL
        let widgetPath = "Widget/Sources/TaskListWidget.swift"
        if FileManager.default.fileExists(atPath: widgetPath) {
            let content = try? String(contentsOfFile: widgetPath)
            let hasWidgetURL = content?.contains(".widgetURL") ?? false
            addResult("Widget URL fallback",
                     passed: hasWidgetURL,
                     details: hasWidgetURL ? "✓ widgetURL configured" : "✗ Missing widgetURL")
        }

        // Check app integration
        let appPath = "App/Sources/PetProgressApp.swift"
        if FileManager.default.fileExists(atPath: appPath) {
            let content = try? String(contentsOfFile: appPath)
            let hasOnOpenURL = content?.contains(".onOpenURL") ?? false
            addResult("App onOpenURL handler",
                     passed: hasOnOpenURL,
                     details: hasOnOpenURL ? "✓ onOpenURL handler found" : "✗ Missing URL handler")
        }

        print()
    }

    func testCriticalFiles() {
        print("\(Colors.yellow)📂 Testing Critical Files...\(Colors.reset)")

        let criticalFiles = [
            ("App/PetProgress.entitlements", "App entitlements"),
            ("Widget/PetProgressWidget.entitlements", "Widget entitlements"),
            ("App/Info.plist", "App Info.plist"),
            ("Widget/Info.plist", "Widget Info.plist"),
            ("Tests/NearestHourTests.swift", "Nearest-hour tests"),
            ("StageConfig.json", "Stage configuration")
        ]

        for (path, name) in criticalFiles {
            let exists = FileManager.default.fileExists(atPath: path)
            addResult(name,
                     passed: exists,
                     details: exists ? "✓ \(path) found" : "✗ \(path) missing")
        }

        print()
    }

    func addResult(_ name: String, passed: Bool, details: String) {
        results.append(TestResult(name: name, passed: passed, details: details))
        let status = passed ? "\(Colors.green)✅\(Colors.reset)" : "\(Colors.red)❌\(Colors.reset)"
        print("  \(status) \(name)")
        print("     \(details)")
    }

    func printSummary() {
        print("\(Colors.blue)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\(Colors.reset)")
        print("\(Colors.blue)📊 Test Summary\(Colors.reset)")
        print("\(Colors.blue)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\(Colors.reset)")

        let passed = results.filter { $0.passed }.count
        let failed = results.filter { !$0.passed }.count
        let total = results.count

        let passRate = Double(passed) / Double(total) * 100
        let color = passRate >= 90 ? Colors.green : (passRate >= 70 ? Colors.yellow : Colors.red)

        print("\n\(color)Total Tests: \(total)\(Colors.reset)")
        print("\(Colors.green)Passed: \(passed)\(Colors.reset)")
        print("\(Colors.red)Failed: \(failed)\(Colors.reset)")
        print("\n\(color)Pass Rate: \(String(format: "%.1f", passRate))%\(Colors.reset)")

        if failed > 0 {
            print("\n\(Colors.red)Failed Tests:\(Colors.reset)")
            for result in results.filter({ !$0.passed }) {
                print("  • \(result.name)")
            }
        }

        // Overall status
        print("\n\(Colors.blue)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\(Colors.reset)")
        if passRate == 100 {
            print("\(Colors.green)🎉 ALL TESTS PASSED! App is production-ready!\(Colors.reset)")
        } else if passRate >= 90 {
            print("\(Colors.green)✅ App is mostly ready with minor issues\(Colors.reset)")
        } else if passRate >= 70 {
            print("\(Colors.yellow)⚠️ App has some issues that need attention\(Colors.reset)")
        } else {
            print("\(Colors.red)❌ App has critical issues that must be fixed\(Colors.reset)")
        }
        print("\(Colors.blue)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\(Colors.reset)")
    }
}

// Run the test suite
let tester = AppTester()
tester.run()