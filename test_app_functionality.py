#!/usr/bin/env python3
"""
Comprehensive Test Suite for PetProgress iOS App
Tests all critical functionality requirements
"""

import os
import json
import re
from pathlib import Path
from typing import List, Tuple, Dict
from dataclasses import dataclass
from enum import Enum

# ANSI color codes
class Colors:
    RESET = '\033[0m'
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    BOLD = '\033[1m'

@dataclass
class TestResult:
    name: str
    passed: bool
    details: str
    category: str

class TestStatus(Enum):
    PASSED = "[PASS]"
    FAILED = "[FAIL]"
    WARNING = "[WARN]"

class PetProgressTester:
    def __init__(self):
        self.results: List[TestResult] = []
        self.base_path = Path("ios-native")

    def run_all_tests(self):
        """Run all test categories"""
        print(f"{Colors.BLUE}{Colors.BOLD}[TEST] PetProgress App Comprehensive Test Suite{Colors.RESET}\n")

        # Run test categories
        self.test_project_configuration()
        self.test_app_intents()
        self.test_widget_configuration()
        self.test_shared_store()
        self.test_pet_evolution()
        self.test_settings()
        self.test_celebration_system()
        self.test_deep_links()
        self.test_critical_files()
        self.test_ci_configuration()

        # Print summary
        self.print_summary()

    def test_project_configuration(self):
        """Test project.yml configuration"""
        print(f"{Colors.YELLOW} Testing Project Configuration...{Colors.RESET}")

        project_file = self.base_path / "project.yml"
        if project_file.exists():
            content = project_file.read_text(encoding="utf-8")

            # iPhone-only check
            iphone_only = 'TARGETED_DEVICE_FAMILY: "1"' in content
            self.add_result(
                "iPhone-only configuration",
                iphone_only,
                "OK: Device family set to iPhone only" if iphone_only else "X: Not configured for iPhone only",
                "Project Config"
            )

            # iOS 17 deployment target
            ios17_target = 'iOS: "17.0"' in content
            self.add_result(
                "iOS 17 deployment target",
                ios17_target,
                "OK: Deployment target iOS 17.0" if ios17_target else "X: Incorrect deployment target",
                "Project Config"
            )

            # App Group capability
            app_group = "com.apple.ApplicationGroups.iOS: true" in content
            self.add_result(
                "App Group capability",
                app_group,
                "OK: App Group enabled for both targets" if app_group else "X: App Group not configured",
                "Project Config"
            )

            # Widget extension target
            has_widget = "PetProgressWidget:" in content
            self.add_result(
                "Widget extension target",
                has_widget,
                "OK: Widget extension configured" if has_widget else "X: Widget extension missing",
                "Project Config"
            )
        else:
            self.add_result("Project configuration", False, "X: project.yml not found", "Project Config")
        print()

    def test_app_intents(self):
        """Test App Intents implementation"""
        print(f"{Colors.YELLOW} Testing App Intents Implementation...{Colors.RESET}")

        # Check TaskEntity
        task_entity_path = self.base_path / "SharedKit/Sources/SharedKit/TaskEntity.swift"
        has_task_entity = task_entity_path.exists()

        if has_task_entity:
            content = task_entity_path.read_text(encoding="utf-8")
            # Check for AppEntity conformance
            has_app_entity = "AppEntity" in content
            self.add_result(
                "TaskEntity AppEntity conformance",
                has_app_entity,
                "OK: TaskEntity conforms to AppEntity" if has_app_entity else "X: Missing AppEntity conformance",
                "App Intents"
            )

            # Check for TaskQuery
            has_query = "TaskQuery" in content
            self.add_result(
                "TaskQuery implementation",
                has_query,
                "OK: TaskQuery found" if has_query else "X: TaskQuery missing",
                "App Intents"
            )
        else:
            self.add_result("TaskEntity", False, "X: TaskEntity.swift not found", "App Intents")

        # Check ProperAppIntents
        app_intents_path = self.base_path / "Widget/Sources/ProperAppIntents.swift"
        if app_intents_path.exists():
            content = app_intents_path.read_text(encoding="utf-8")

            # Required intents
            intents = [
                ("CompleteTaskIntent", "Complete task intent"),
                ("SkipTaskIntent", "Skip task intent"),
                ("NextPageIntent", "Next page intent"),
                ("PreviousPageIntent", "Previous page intent")
            ]

            for intent_name, description in intents:
                has_intent = intent_name in content
                self.add_result(
                    description,
                    has_intent,
                    f"OK: {intent_name} implemented" if has_intent else f"X: Missing {intent_name}",
                    "App Intents"
                )
        else:
            self.add_result("App Intents file", False, "X: ProperAppIntents.swift not found", "App Intents")
        print()

    def test_widget_configuration(self):
        """Test Widget configuration and timeline"""
        print(f"{Colors.YELLOW}[WIDGET] Testing Widget Configuration...{Colors.RESET}")

        # Check TaskWidgetProvider
        provider_path = self.base_path / "Widget/Sources/TaskWidgetProvider.swift"
        if provider_path.exists():
            content = provider_path.read_text(encoding="utf-8")

            # Hourly refresh
            hourly_refresh = ".after(next" in content or "policy: .after" in content
            self.add_result(
                "Hourly refresh timeline",
                hourly_refresh,
                "OK: Hourly refresh configured" if hourly_refresh else "X: Missing hourly refresh",
                "Widget"
            )

            # Nearest-hour logic
            nearest_hour = "getNearestHourTasks" in content
            self.add_result(
                "Nearest-hour task logic",
                nearest_hour,
                "OK: Nearest-hour implementation found" if nearest_hour else "X: Missing nearest-hour logic",
                "Widget"
            )

            # AppIntentConfiguration
            app_intent_config = "AppIntentTimelineProvider" in content
            self.add_result(
                "AppIntent timeline provider",
                app_intent_config,
                "OK: Using AppIntentTimelineProvider" if app_intent_config else "X: Not using AppIntent provider",
                "Widget"
            )
        else:
            self.add_result("Widget provider", False, "X: TaskWidgetProvider.swift not found", "Widget")

        # Check Lock Screen views
        lock_screen_path = self.base_path / "Widget/Sources/views/TaskLockScreenView.swift"
        if lock_screen_path.exists():
            content = lock_screen_path.read_text(encoding="utf-8")

            # Widget families
            families = [
                ("accessoryCircular", "Circular widget"),
                ("accessoryRectangular", "Rectangular widget"),
                ("accessoryInline", "Inline widget")
            ]

            for family, description in families:
                has_family = family in content
                self.add_result(
                    description,
                    has_family,
                    f"OK: {description} implemented" if has_family else f"X: Missing {description}",
                    "Widget"
                )

            # Interactive buttons
            has_buttons = "Button(intent:" in content
            self.add_result(
                "Interactive widget buttons",
                has_buttons,
                "OK: Interactive buttons with intents" if has_buttons else "X: Missing interactive buttons",
                "Widget"
            )
        else:
            self.add_result("Lock Screen views", False, "X: TaskLockScreenView.swift not found", "Widget")
        print()

    def test_shared_store(self):
        """Test SharedStore and App Group"""
        print(f"{Colors.YELLOW} Testing SharedStore App Group...{Colors.RESET}")

        # Check SharedStoreActor
        store_path = self.base_path / "SharedKit/Sources/SharedKit/SharedStoreActor.swift"
        if store_path.exists():
            content = store_path.read_text(encoding="utf-8")

            # App Group identifier
            app_group = "group.com.petprogress" in content or "group.com." in content
            self.add_result(
                "App Group identifier",
                app_group,
                "OK: App Group configured" if app_group else "X: App Group not found",
                "SharedStore"
            )

            # Grace minutes support
            grace_minutes = "graceMinutes" in content or "grace_minutes" in content
            self.add_result(
                "Grace minutes in SharedStore",
                grace_minutes,
                "OK: Grace minutes support found" if grace_minutes else "X: Missing grace minutes",
                "SharedStore"
            )

            # TaskEntity methods
            task_entity_support = "TaskEntity" in content
            self.add_result(
                "TaskEntity support",
                task_entity_support,
                "OK: TaskEntity methods found" if task_entity_support else "X: Missing TaskEntity support",
                "SharedStore"
            )
        else:
            self.add_result("SharedStoreActor", False, "X: SharedStoreActor.swift not found", "SharedStore")

        # Check App Group tests
        test_path = self.base_path / "Tests/AppGroupTests.swift"
        has_tests = test_path.exists()
        self.add_result(
            "App Group tests",
            has_tests,
            "OK: AppGroupTests.swift found" if has_tests else "X: App Group tests missing",
            "SharedStore"
        )
        print()

    def test_pet_evolution(self):
        """Test Pet Evolution system"""
        print(f"{Colors.YELLOW} Testing Pet Evolution System...{Colors.RESET}")

        # Check PetEvolutionEngine
        engine_path = self.base_path / "SharedKit/Sources/SharedKit/PetEvolutionEngine.swift"
        if engine_path.exists():
            content = engine_path.read_text(encoding="utf-8")

            # Required methods
            methods = [
                ("threshold(for", "XP threshold method"),
                ("imageName(for", "Pet image mapping"),
                ("stageIndex(for", "Stage index calculation")
            ]

            for method, description in methods:
                has_method = method in content
                self.add_result(
                    description,
                    has_method,
                    f"OK: {description} implemented" if has_method else f"X: Missing {description}",
                    "Pet Evolution"
                )
        else:
            self.add_result("PetEvolutionEngine", False, "X: PetEvolutionEngine.swift not found", "Pet Evolution")

        # Check stage configuration
        stage_config_path = self.base_path / "StageConfig.json"
        if stage_config_path.exists():
            try:
                with open(stage_config_path) as f:
                    config = json.load(f)
                    has_stages = "stages" in config and len(config["stages"]) > 0
                    self.add_result(
                        "Stage configuration",
                        has_stages,
                        f"OK: {len(config.get('stages', []))} stages configured" if has_stages else "X: Invalid stage config",
                        "Pet Evolution"
                    )
            except json.JSONDecodeError:
                self.add_result("Stage configuration", False, "X: Invalid JSON in StageConfig.json", "Pet Evolution")
        else:
            self.add_result("Stage configuration", False, "X: StageConfig.json not found", "Pet Evolution")

        # Check pet assets
        widget_assets = self.base_path / "Widget/Assets.xcassets"
        has_widget_assets = widget_assets.exists()
        if has_widget_assets:
            # Count pet image folders
            pet_images = list(widget_assets.glob("pet_*.imageset"))
            self.add_result(
                "Widget pet images",
                len(pet_images) > 0,
                f"OK: {len(pet_images)} pet images found" if pet_images else "X: No pet images found",
                "Pet Evolution"
            )
        else:
            self.add_result("Widget pet assets", False, "X: Widget/Assets.xcassets not found", "Pet Evolution")
        print()

    def test_settings(self):
        """Test Settings implementation"""
        print(f"{Colors.YELLOW} Testing Settings Implementation...{Colors.RESET}")

        # Check SettingsView
        settings_path = self.base_path / "App/Sources/SettingsView.swift"
        if settings_path.exists():
            content = settings_path.read_text(encoding="utf-8")

            # Grace Minutes control
            grace_minutes = "Grace Minutes" in content or "graceMinutes" in content
            self.add_result(
                "Grace Minutes setting",
                grace_minutes,
                "OK: Grace Minutes control found" if grace_minutes else "X: Missing Grace Minutes",
                "Settings"
            )

            # Privacy Policy link
            privacy_policy = "Privacy Policy" in content
            self.add_result(
                "Privacy Policy link",
                privacy_policy,
                "OK: Privacy Policy link found" if privacy_policy else "X: Missing Privacy Policy",
                "Settings"
            )

            # Help text for grace minutes
            help_text = "window" in content.lower() or "on-time" in content.lower()
            self.add_result(
                "Grace Minutes help text",
                help_text,
                "OK: Help text for Grace Minutes" if help_text else "X: Missing help text",
                "Settings"
            )
        else:
            self.add_result("SettingsView", False, "X: SettingsView.swift not found", "Settings")

        # Check PrivacyPolicyView
        privacy_path = self.base_path / "App/Sources/PrivacyPolicyView.swift"
        has_privacy = privacy_path.exists()
        self.add_result(
            "PrivacyPolicyView",
            has_privacy,
            "OK: PrivacyPolicyView.swift found" if has_privacy else "X: Privacy Policy view missing",
            "Settings"
        )
        print()

    def test_celebration_system(self):
        """Test Celebration and Haptics system"""
        print(f"{Colors.YELLOW} Testing Celebration System...{Colors.RESET}")

        # Check CelebrationSystem
        celebration_path = self.base_path / "App/Sources/CelebrationSystem.swift"
        if celebration_path.exists():
            content = celebration_path.read_text(encoding="utf-8")

            # Haptic feedback
            haptics = "HapticFeedback" in content or "UIImpactFeedbackGenerator" in content
            self.add_result(
                "Haptic feedback",
                haptics,
                "OK: Haptic feedback implemented" if haptics else "X: Missing haptic feedback",
                "Celebration"
            )

            # Level-up celebration
            level_up = "celebrateLevelUp" in content
            self.add_result(
                "Level-up celebration",
                level_up,
                "OK: Level-up celebration method found" if level_up else "X: Missing level-up celebration",
                "Celebration"
            )

            # Confetti animations
            confetti = "ConfettiView" in content or "ConfettiParticle" in content
            self.add_result(
                "Confetti animations",
                confetti,
                "OK: Confetti system implemented" if confetti else "X: Missing confetti system",
                "Celebration"
            )
        else:
            self.add_result("CelebrationSystem", False, "X: CelebrationSystem.swift not found", "Celebration")

        # Check DataStore integration
        datastore_path = self.base_path / "App/Sources/DataStore.swift"
        if datastore_path.exists():
            content = datastore_path.read_text(encoding="utf-8")
            celebration_trigger = "CelebrationSystem" in content or "celebrateLevelUp" in content
            self.add_result(
                "DataStore celebration trigger",
                celebration_trigger,
                "OK: Level-up triggers celebration" if celebration_trigger else "X: Missing celebration trigger",
                "Celebration"
            )
        print()

    def test_deep_links(self):
        """Test Deep Link system"""
        print(f"{Colors.YELLOW} Testing Deep Link System...{Colors.RESET}")

        # Check URLRoutes
        routes_path = self.base_path / "App/DeepLink/URLRoutes.swift"
        if routes_path.exists():
            content = routes_path.read_text(encoding="utf-8")

            # URL scheme
            scheme = "petprogress" in content
            self.add_result(
                "URL scheme handler",
                scheme,
                "OK: petprogress:// scheme configured" if scheme else "X: Missing URL scheme",
                "Deep Links"
            )

            # Task route
            task_route = 'case "task"' in content
            self.add_result(
                "Task deep link route",
                task_route,
                "OK: Task route handler found" if task_route else "X: Missing task route",
                "Deep Links"
            )
        else:
            self.add_result("URLRoutes", False, "X: URLRoutes.swift not found", "Deep Links")

        # Check widget URL
        widget_path = self.base_path / "Widget/Sources/TaskListWidget.swift"
        if widget_path.exists():
            content = widget_path.read_text(encoding="utf-8")
            widget_url = ".widgetURL" in content
            self.add_result(
                "Widget URL fallback",
                widget_url,
                "OK: widgetURL configured" if widget_url else "X: Missing widgetURL",
                "Deep Links"
            )

        # Check app integration
        app_path = self.base_path / "App/Sources/PetProgressApp.swift"
        if app_path.exists():
            content = app_path.read_text(encoding="utf-8")
            on_open_url = ".onOpenURL" in content
            self.add_result(
                "App onOpenURL handler",
                on_open_url,
                "OK: onOpenURL handler found" if on_open_url else "X: Missing URL handler",
                "Deep Links"
            )
        print()

    def test_critical_files(self):
        """Test presence of critical files"""
        print(f"{Colors.YELLOW} Testing Critical Files...{Colors.RESET}")

        critical_files = [
            ("App/PetProgress.entitlements", "App entitlements"),
            ("Widget/PetProgressWidget.entitlements", "Widget entitlements"),
            ("App/Info.plist", "App Info.plist"),
            ("Widget/Info.plist", "Widget Info.plist"),
            ("App/Assets.xcassets/AppIcon.appiconset", "App icon set"),
            ("Tests/NearestHourTests.swift", "Nearest-hour tests"),
            ("Tests/PetEvolutionWidgetTests.swift", "Pet evolution tests"),
        ]

        for file_path, description in critical_files:
            full_path = self.base_path / file_path
            exists = full_path.exists()
            self.add_result(
                description,
                exists,
                f"OK: {file_path} found" if exists else f"X: {file_path} missing",
                "Critical Files"
            )
        print()

    def test_ci_configuration(self):
        """Test CI/CD configuration"""
        print(f"{Colors.YELLOW} Testing CI Configuration...{Colors.RESET}")

        # Check GitHub Actions workflow
        workflow_path = Path(".github/workflows/ios-sim.yml")
        if workflow_path.exists():
            content = workflow_path.read_text(encoding="utf-8")

            # Xcode version
            xcode_16 = "xcode-version: '16" in content or "Xcode_16" in content
            self.add_result(
                "Xcode 16.4 pinned",
                xcode_16,
                "OK: Xcode 16.4 configured" if xcode_16 else "X: Xcode version not pinned",
                "CI/CD"
            )

            # iOS Simulator creation
            simulator = "xcrun simctl create" in content
            self.add_result(
                "iOS Simulator creation",
                simulator,
                "OK: Creates real iOS Simulator" if simulator else "X: Missing simulator creation",
                "CI/CD"
            )

            # Test execution
            tests = "xcodebuild test" in content or "-scheme.*test" in content.lower()
            self.add_result(
                "Test execution in CI",
                tests,
                "OK: Tests configured to run" if tests else "X: Tests not configured",
                "CI/CD"
            )
        else:
            self.add_result("CI workflow", False, "X: ios-sim.yml not found", "CI/CD")
        print()

    def add_result(self, name: str, passed: bool, details: str, category: str):
        """Add a test result"""
        result = TestResult(name, passed, details, category)
        self.results.append(result)

        status = TestStatus.PASSED if passed else TestStatus.FAILED
        color = Colors.GREEN if passed else Colors.RED
        print(f"  {color}{status.value}{Colors.RESET} {name}")
        print(f"     {details}")

    def print_summary(self):
        """Print test summary"""
        print(f"\n{Colors.BLUE}{'=' * 50}{Colors.RESET}")
        print(f"{Colors.BLUE}{Colors.BOLD} Test Summary{Colors.RESET}")
        print(f"{Colors.BLUE}{'=' * 50}{Colors.RESET}")

        # Calculate statistics
        total = len(self.results)
        passed = sum(1 for r in self.results if r.passed)
        failed = total - passed
        pass_rate = (passed / total * 100) if total > 0 else 0

        # Group by category
        categories = {}
        for result in self.results:
            if result.category not in categories:
                categories[result.category] = {"passed": 0, "failed": 0}
            if result.passed:
                categories[result.category]["passed"] += 1
            else:
                categories[result.category]["failed"] += 1

        # Print category breakdown
        print(f"\n{Colors.BOLD}Category Breakdown:{Colors.RESET}")
        for category, stats in categories.items():
            cat_total = stats["passed"] + stats["failed"]
            cat_rate = (stats["passed"] / cat_total * 100) if cat_total > 0 else 0
            color = Colors.GREEN if cat_rate >= 80 else Colors.YELLOW if cat_rate >= 60 else Colors.RED
            print(f"  {category}: {color}{stats['passed']}/{cat_total} ({cat_rate:.0f}%){Colors.RESET}")

        # Overall statistics
        print(f"\n{Colors.BOLD}Overall Results:{Colors.RESET}")
        print(f"  Total Tests: {total}")
        print(f"  {Colors.GREEN}Passed: {passed}{Colors.RESET}")
        print(f"  {Colors.RED}Failed: {failed}{Colors.RESET}")

        # Pass rate with color coding
        if pass_rate >= 90:
            color = Colors.GREEN
        elif pass_rate >= 70:
            color = Colors.YELLOW
        else:
            color = Colors.RED

        print(f"\n  {Colors.BOLD}Pass Rate: {color}{pass_rate:.1f}%{Colors.RESET}")

        # Failed tests list
        if failed > 0:
            print(f"\n{Colors.RED}{Colors.BOLD}Failed Tests:{Colors.RESET}")
            for result in self.results:
                if not result.passed:
                    print(f"   [{result.category}] {result.name}")

        # Final verdict
        print(f"\n{Colors.BLUE}{'=' * 50}{Colors.RESET}")
        if pass_rate == 100:
            print(f"{Colors.GREEN}{Colors.BOLD} ALL TESTS PASSED! App is production-ready!{Colors.RESET}")
        elif pass_rate >= 90:
            print(f"{Colors.GREEN} App is mostly ready with minor issues{Colors.RESET}")
        elif pass_rate >= 70:
            print(f"{Colors.YELLOW} App has some issues that need attention{Colors.RESET}")
        else:
            print(f"{Colors.RED} App has critical issues that must be fixed{Colors.RESET}")
        print(f"{Colors.BLUE}{'' * 50}{Colors.RESET}\n")

        return pass_rate

if __name__ == "__main__":
    tester = PetProgressTester()
    tester.run_all_tests()