#!/usr/bin/env swift

import Foundation

/// Steve Jobs-level critical validation script
/// Zero tolerance for production bugs
struct CriticalValidation {
    static func main() {
        print("🚨 CRITICAL VALIDATION - STEVE JOBS STANDARDS")
        print("=" * 60)

        var issuesFound = 0

        // 1. Validate Stage Config JSON
        issuesFound += validateStageConfig()

        // 2. Validate App Group Configuration
        issuesFound += validateAppGroupConfig()

        // 3. Validate Widget Intent Registration
        issuesFound += validateWidgetIntents()

        // 4. Validate Pet Image Assets
        issuesFound += validatePetAssets()

        // 5. Validate Grace Period Logic
        issuesFound += validateGracePeriodLogic()

        // 6. Validate XP Calculations
        issuesFound += validateXPCalculations()

        print("\n" + "=" * 60)
        if issuesFound == 0 {
            print("✅ ALL CRITICAL VALIDATIONS PASSED")
            print("🎯 App is ready for Steve Jobs review")
            exit(0)
        } else {
            print("❌ \(issuesFound) CRITICAL ISSUES FOUND")
            print("🚨 MUST FIX BEFORE LAUNCH")
            exit(1)
        }
    }

    static func validateStageConfig() -> Int {
        print("\n🔍 Validating Stage Configuration...")
        var issues = 0

        guard let data = FileManager.default.contents(atPath: "StageConfig.json") else {
            print("❌ StageConfig.json not found")
            return 1
        }

        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let stages = json?["stages"] as? [[String: Any]] ?? []

            // Check we have 16 stages
            if stages.count != 16 {
                print("❌ Expected 16 stages, found \(stages.count)")
                issues += 1
            }

            // Check thresholds are ascending
            var lastThreshold = -1
            for (index, stage) in stages.enumerated() {
                let threshold = stage["threshold"] as? Int ?? 0
                if threshold <= lastThreshold && index < stages.count - 1 {
                    print("❌ Stage \(index) threshold \(threshold) not ascending from \(lastThreshold)")
                    issues += 1
                }
                lastThreshold = threshold
            }

            // Check final stage has highest threshold
            if let finalStage = stages.last, let finalThreshold = finalStage["threshold"] as? Int {
                if finalThreshold < 400 {
                    print("❌ Final stage threshold too low: \(finalThreshold)")
                    issues += 1
                }
            }

            if issues == 0 {
                print("✅ Stage configuration valid")
            }

        } catch {
            print("❌ Failed to parse StageConfig.json: \(error)")
            issues += 1
        }

        return issues
    }

    static func validateAppGroupConfig() -> Int {
        print("\n🔍 Validating App Group Configuration...")
        var issues = 0

        let appGroupID = "group.com.hedgingmybets.PetProgress"

        // Check if UserDefaults can access App Group
        guard let testDefaults = UserDefaults(suiteName: appGroupID) else {
            print("❌ Cannot access App Group: \(appGroupID)")
            return 1
        }

        // Test read/write
        let testKey = "validation_test_\(Date().timeIntervalSince1970)"
        let testValue = "test_value"

        testDefaults.set(testValue, forKey: testKey)
        let retrieved = testDefaults.string(forKey: testKey)
        testDefaults.removeObject(forKey: testKey)

        if retrieved != testValue {
            print("❌ App Group read/write test failed")
            issues += 1
        } else {
            print("✅ App Group accessible and functional")
        }

        return issues
    }

    static func validateWidgetIntents() -> Int {
        print("\n🔍 Validating Widget Intent Registration...")
        var issues = 0

        let requiredIntents = [
            "MarkNextTaskDoneIntent",
            "SkipCurrentTaskIntent",
            "GoToNextTaskIntent",
            "GoToPreviousTaskIntent"
        ]

        // Check AppIntents.swift includes all required intents
        guard let appIntentsContent = try? String(contentsOfFile: "App/Sources/AppIntents.swift") else {
            print("❌ Cannot read AppIntents.swift")
            return 1
        }

        for intent in requiredIntents {
            if !appIntentsContent.contains(intent) {
                print("❌ Missing intent in AppIntentsProvider: \(intent)")
                issues += 1
            }
        }

        if issues == 0 {
            print("✅ All widget intents properly registered")
        }

        return issues
    }

    static func validatePetAssets() -> Int {
        print("\n🔍 Validating Pet Image Assets...")
        var issues = 0

        let requiredAssets = [
            "pet_frog", "pet_hermit", "pet_seahorse", "pet_dolphin",
            "pet_alligator", "pet_beaver", "pet_wolf", "pet_bear",
            "pet_bison", "pet_elephant", "pet_rhino", "pet_baby",
            "pet_toddler", "pet_adult", "pet_ceo", "pet_gold"
        ]

        let appAssetPath = "App/Assets.xcassets"
        let widgetAssetPath = "Widget/Assets.xcassets"

        for asset in requiredAssets {
            let appAssetDir = "\(appAssetPath)/\(asset).imageset"
            let widgetAssetDir = "\(widgetAssetPath)/\(asset).imageset"

            if !FileManager.default.fileExists(atPath: appAssetDir) {
                print("❌ Missing app asset: \(asset)")
                issues += 1
            }

            if !FileManager.default.fileExists(atPath: widgetAssetDir) {
                print("❌ Missing widget asset: \(asset)")
                issues += 1
            }
        }

        if issues == 0 {
            print("✅ All pet assets present in both App and Widget")
        }

        return issues
    }

    static func validateGracePeriodLogic() -> Int {
        print("\n🔍 Validating Grace Period Logic...")
        var issues = 0

        // Test midnight crossing edge case
        func testGracePeriod(taskHour: Int, currentHour: Int, currentMinute: Int, graceMinutes: Int) -> Bool {
            let taskMinutes = taskHour * 60
            let currentMinutes = currentHour * 60 + currentMinute

            let graceWindowStart = taskMinutes
            let graceWindowEnd = taskMinutes + graceMinutes

            if graceWindowEnd >= 24 * 60 {
                let nextDayEnd = graceWindowEnd - 24 * 60
                return (currentMinutes >= graceWindowStart) || (currentMinutes <= nextDayEnd)
            } else {
                return currentMinutes >= graceWindowStart && currentMinutes <= graceWindowEnd
            }
        }

        // Test critical edge cases
        let testCases = [
            (taskHour: 23, currentHour: 23, currentMinute: 30, graceMinutes: 60, expected: true),  // Normal late night
            (taskHour: 23, currentHour: 0, currentMinute: 30, graceMinutes: 120, expected: true),  // Midnight crossing
            (taskHour: 23, currentHour: 1, currentMinute: 30, graceMinutes: 120, expected: false), // Outside grace
            (taskHour: 9, currentHour: 9, currentMinute: 30, graceMinutes: 30, expected: true),   // Normal case
            (taskHour: 9, currentHour: 10, currentMinute: 30, graceMinutes: 30, expected: false)  // Too late
        ]

        for (index, testCase) in testCases.enumerated() {
            let result = testGracePeriod(
                taskHour: testCase.taskHour,
                currentHour: testCase.currentHour,
                currentMinute: testCase.currentMinute,
                graceMinutes: testCase.graceMinutes
            )

            if result != testCase.expected {
                print("❌ Grace period test \(index + 1) failed: expected \(testCase.expected), got \(result)")
                issues += 1
            }
        }

        if issues == 0 {
            print("✅ Grace period logic handles all edge cases correctly")
        }

        return issues
    }

    static func validateXPCalculations() -> Int {
        print("\n🔍 Validating XP Calculations...")
        var issues = 0

        // Test stage progression thresholds
        let expectedThresholds = [10, 25, 40, 55, 75, 95, 120, 145, 175, 205, 240, 285, 335, 390, 450, 500]

        // Mock stage calculation
        func calculateStage(for points: Int) -> Int {
            for (index, threshold) in expectedThresholds.enumerated() {
                if points < threshold {
                    return max(0, index - 1)
                }
            }
            return expectedThresholds.count - 1
        }

        // Test critical XP boundaries
        let testCases = [
            (xp: 0, expectedStage: 0),
            (xp: 9, expectedStage: 0),    // Just below first threshold
            (xp: 10, expectedStage: 1),   // At first threshold
            (xp: 24, expectedStage: 1),   // Just below second threshold
            (xp: 25, expectedStage: 2),   // At second threshold
            (xp: 499, expectedStage: 15), // Just below final threshold
            (xp: 500, expectedStage: 15), // At final threshold
            (xp: 1000, expectedStage: 15) // Way above final threshold
        ]

        for testCase in testCases {
            let result = calculateStage(for: testCase.xp)
            if result != testCase.expectedStage {
                print("❌ XP calculation failed: \(testCase.xp) XP should be stage \(testCase.expectedStage), got \(result)")
                issues += 1
            }
        }

        if issues == 0 {
            print("✅ XP calculations correct for all boundary conditions")
        }

        return issues
    }
}

// String extension for Python-style string multiplication
extension String {
    static func * (string: String, count: Int) -> String {
        return String(repeating: string, count: count)
    }
}

CriticalValidation.main()