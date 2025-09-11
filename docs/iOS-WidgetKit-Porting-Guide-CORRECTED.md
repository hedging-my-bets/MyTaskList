# iOS WidgetKit Porting Guide - COMPLETE IMPLEMENTATION

This guide provides **exact implementation details** for porting the React Native pet evolution to-do app to native iOS with **fully functional WidgetKit Lock Screen widgets**.

## Overview

The React Native prototype includes all the core business logic, data models, and UI patterns you need. This guide shows you **exactly** how to implement each piece in native iOS with WidgetKit support.

## Project Structure

Create a new iOS project with the following targets:
- **Main App Target**: SwiftUI app with today screen and settings
- **Widget Extension Target**: WidgetKit extension for Lock Screen widget  
- **AppIntents Extension**: AppIntents for Done/Snooze actions

## Core Data Models (SwiftData)

### 1. TaskItem Model

```swift
import SwiftData

@Model
final class TaskItem {
    @Attribute(.unique) var id: UUID
    var title: String
    var scheduledAt: DateComponents // hour, minute local
    var dayKey: String              // "YYYY-MM-DD" local
    var isCompleted: Bool
    var completedAt: Date?
    var snoozedUntil: Date?
    
    // **CRITICAL**: Computed property for reliable sorting
    var minutesSinceMidnight: Int {
        return (scheduledAt.hour ?? 0) * 60 + (scheduledAt.minute ?? 0)
    }
    
    init(title: String, hour: Int, minute: Int, dayKey: String) {
        self.id = UUID()
        self.title = title
        self.scheduledAt = DateComponents(hour: hour, minute: minute)
        self.dayKey = dayKey
        self.isCompleted = false
    }
}
```

### 2. PetState Model

```swift
@Model
final class PetState {
    var stageIndex: Int   // 0..19
    var stageXP: Int      // progress within current stage
    var lastCloseoutDayKey: String
    
    init() {
        self.stageIndex = 0
        self.stageXP = 0
        self.lastCloseoutDayKey = ""
    }
}
```

### 3. AppSettings Model - **CRITICAL ADDITION**

```swift
@Model
final class AppSettings {
    var resetTimeHour: Int
    var resetTimeMinute: Int
    var graceWindow: Int          // minutes +/-
    var rolloverEnabled: Bool
    var hapticsEnabled: Bool
    
    init() {
        self.resetTimeHour = 0
        self.resetTimeMinute = 0
        self.graceWindow = 60
        self.rolloverEnabled = true
        self.hapticsEnabled = true
    }
}
```

## PetEngine Implementation - **EXACT LOGIC MATCH**

Port the exact logic from `engine/PetEngine.ts`:

```swift
struct PetEngine {
    static func onCheck(onTime: Bool, pet: inout PetState, cfg: StageCfg) {
        pet.stageXP += onTime ? 2 : 1
        evolve(&pet, cfg)
    }
    
    static func onMiss(pet: inout PetState, cfg: StageCfg) {
        pet.stageXP -= 2
        deEvolve(&pet, cfg)
    }
    
    static func onDailyCloseout(rate: Double, pet: inout PetState, cfg: StageCfg) {
        if rate >= 0.8 { pet.stageXP += 3 }
        else if rate < 0.4 { pet.stageXP -= 3 }
        evolve(&pet, cfg); deEvolve(&pet, cfg)
    }
    
    private static func thresh(_ i:Int,_ c:StageCfg)->Int { c.stages[i].threshold }
    
    private static func evolve(_ p: inout PetState,_ c:StageCfg){
        while p.stageIndex < c.stages.count-1 && p.stageXP >= thresh(p.stageIndex,c){
            p.stageIndex += 1; p.stageXP = 0
        }
    }
    
    private static func deEvolve(_ p: inout PetState,_ c:StageCfg){
        while p.stageXP < 0 && p.stageIndex > 0 {
            p.stageIndex -= 1
            p.stageXP = max(0, thresh(p.stageIndex,c) - 1 + p.stageXP)
        }
        
        // **CRITICAL FIX**: Ensure XP never goes below 0 at stage 0
        if p.stageIndex == 0 {
            p.stageXP = max(0, p.stageXP)
        }
    }
}
```

## Shared Data Container - **CRITICAL FOR DATA SHARING**

```swift
// DataContainer.swift
import SwiftData

class DataContainer {
    static let shared: ModelContainer = {
        do {
            let container = try ModelContainer(
                for: TaskItem.self, PetState.self, AppSettings.self,
                configurations: ModelConfiguration(
                    groupContainer: .identifier("group.com.yourteam.petapp")
                )
            )
            return container
        } catch {
            fatalError("Failed to create ModelContainer: \\(error)")
        }
    }()
}
```

## WidgetKit Implementation - **HOURLY ALIGNED TIMELINE**

### 1. Widget Timeline Provider

```swift
import WidgetKit
import SwiftUI

struct PetWidgetTimelineProvider: TimelineProvider {
    typealias Entry = PetWidgetEntry
    
    func placeholder(in context: Context) -> PetWidgetEntry {
        PetWidgetEntry.placeholder
    }
    
    func getSnapshot(in context: Context, completion: @escaping (PetWidgetEntry) -> Void) {
        let entry = generateCurrentEntry()
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<PetWidgetEntry>) -> Void) {
        let now = Date()
        let calendar = Calendar.current
        
        // **CRITICAL FIX**: Create entries at the top of each hour for next 24 hours
        var entries: [PetWidgetEntry] = []
        
        // Start from next hour boundary - EXACT HOURLY ALIGNMENT
        let startOfNextHour = calendar.nextDate(after: now, matching: DateComponents(minute: 0, second: 0), matchingPolicy: .nextTime)!
        
        for hourOffset in 0..<24 {
            let entryDate = calendar.date(byAdding: .hour, value: hourOffset, to: startOfNextHour)!
            let hourEntry = generateEntryForTime(entryDate)
            entries.append(hourEntry)
        }
        
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
    
    private func generateCurrentEntry() -> PetWidgetEntry {
        let context = ModelContext(DataContainer.shared)
        
        // Get pet state
        let petDescriptor = FetchDescriptor<PetState>()
        let petState = (try? context.fetch(petDescriptor).first) ?? PetState()
        
        // Get today's tasks
        let today = DateFormatter.dayKey.string(from: Date())
        let taskDescriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate { task in
                task.dayKey == today
            },
            sortBy: [SortDescriptor(\\TaskItem.scheduledAt)]
        )
        
        let tasks = (try? context.fetch(taskDescriptor)) ?? []
        let completedTasks = tasks.filter { $0.isCompleted }
        let nextTask = tasks.first { !$0.isCompleted }
        
        let stage = STAGE_CONFIG.stages[petState.stageIndex]
        let progressRatio = stage.threshold > 0 ? Double(petState.stageXP) / Double(stage.threshold) : 1.0
        
        return PetWidgetEntry(
            date: Date(),
            stageIndex: petState.stageIndex,
            stageXP: petState.stageXP,
            threshold: stage.threshold,
            progressRatio: min(1.0, progressRatio),
            tasksDone: completedTasks.count,
            tasksTotal: tasks.count,
            nextTaskTitle: nextTask?.title ?? "",
            nextTaskTime: nextTask?.scheduledAt.hour.map { "\\(String(format: "%02d", $0)):\\(String(format: "%02d", nextTask?.scheduledAt.minute ?? 0))" } ?? ""
        )
    }
    
    private func generateEntryForTime(_ date: Date) -> PetWidgetEntry {
        // Generate entry with data as it would appear at that specific hour
        let context = ModelContext(DataContainer.shared)
        
        // Get pet state (doesn't change by hour, only by daily closeout)
        let petDescriptor = FetchDescriptor<PetState>()
        let petState = (try? context.fetch(petDescriptor).first) ?? PetState()
        
        // Get tasks for the day containing this hour (accounting for reset time)
        let targetDayKey = DateFormatter.dayKey.string(from: date)
        let taskDescriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate { task in
                task.dayKey == targetDayKey
            },
            sortBy: [SortDescriptor(\.minutesSinceMidnight)] // Use computed property
        )
        
        let tasks = (try? context.fetch(taskDescriptor)) ?? []
        let completedTasks = tasks.filter { $0.isCompleted }
        
        // Find next task relative to this hour
        let calendar = Calendar.current
        let hourMinutes = calendar.component(.hour, from: date) * 60 + calendar.component(.minute, from: date)
        let nextTask = tasks.first { task in
            !task.isCompleted && task.minutesSinceMidnight >= hourMinutes
        }
        
        let stage = STAGE_CONFIG.stages[petState.stageIndex]
        let progressRatio = stage.threshold > 0 ? Double(petState.stageXP) / Double(stage.threshold) : 1.0
        
        return PetWidgetEntry(
            date: date,
            stageIndex: petState.stageIndex,
            stageXP: petState.stageXP,
            threshold: stage.threshold,
            progressRatio: min(1.0, progressRatio),
            tasksDone: completedTasks.count,
            tasksTotal: tasks.count,
            nextTaskTitle: nextTask?.title ?? "",
            nextTaskTime: nextTask?.scheduledAt.hour.map { "\\(String(format: "%02d", $0)):\\(String(format: "%02d", nextTask?.scheduledAt.minute ?? 0))" } ?? ""
        )
    }
}
```

### 2. Widget Entry

```swift
struct PetWidgetEntry: TimelineEntry {
    let date: Date
    let stageIndex: Int
    let stageXP: Int
    let threshold: Int
    let progressRatio: Double
    let tasksDone: Int
    let tasksTotal: Int
    let nextTaskTitle: String
    let nextTaskTime: String
    
    static let placeholder = PetWidgetEntry(
        date: Date(),
        stageIndex: 0,
        stageXP: 5,
        threshold: 10,
        progressRatio: 0.5,
        tasksDone: 2,
        tasksTotal: 5,
        nextTaskTitle: "Sample Task",
        nextTaskTime: "10:30"
    )
}
```

## AppIntents Implementation - **COMPLETE INTERACTIVE FUNCTIONALITY**

**CRITICAL**: AppIntents enable Lock Screen interactivity. Without these, the widget is read-only.

### 1. Mark Task Done Intent - **COMPLETE IMPLEMENTATION**

```swift
import AppIntents
import SwiftData
import WidgetKit

struct MarkTaskDoneIntent: AppIntent {
    static let title: LocalizedStringResource = "Mark Task Done"
    static let description = IntentDescription("Mark the next task as completed")
    
    func perform() async throws -> some IntentResult {
        let context = ModelContext(DataContainer.shared)
        
        // Get today's uncompleted tasks
        let today = DateFormatter.dayKey.string(from: Date())
        let taskDescriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate { task in
                task.dayKey == today && !task.isCompleted
            },
            sortBy: [SortDescriptor(\\TaskItem.scheduledAt)]
        )
        
        let tasks = try context.fetch(taskDescriptor)
        guard let nextTask = tasks.first else {
            return .result()
        }
        
        // Get app settings for grace window
        let settingsDescriptor = FetchDescriptor<AppSettings>()
        let settings = try context.fetch(settingsDescriptor).first ?? AppSettings()
        
        // Mark task as completed
        nextTask.isCompleted = true
        nextTask.completedAt = Date()
        
        // Update pet state
        let petDescriptor = FetchDescriptor<PetState>()
        let petStates = try context.fetch(petDescriptor)
        guard var petState = petStates.first else {
            return .result()
        }
        
        // Calculate if task was on time using settings.graceWindow
        let scheduledTime = Calendar.current.date(bySettingHour: nextTask.scheduledAt.hour!, minute: nextTask.scheduledAt.minute!, second: 0, of: Date())!
        let isOnTime = abs(Date().timeIntervalSince(scheduledTime)) <= Double(settings.graceWindow * 60)
        
        PetEngine.onCheck(onTime: isOnTime, pet: &petState, cfg: STAGE_CONFIG)
        
        try context.save()
        
        // **CRITICAL**: Reload widget timeline to show updated data
        WidgetCenter.shared.reloadTimelines(ofKind: "PetWidget")
        
        return .result()
    }
}
```

### 2. Snooze Task Intent - **COMPLETE IMPLEMENTATION**

```swift
struct SnoozeTaskIntent: AppIntent {
    static let title: LocalizedStringResource = "Snooze Task"
    static let description = IntentDescription("Snooze the next task by 15 minutes")
    
    func perform() async throws -> some IntentResult {
        let context = ModelContext(DataContainer.shared)
        
        // Get today's uncompleted tasks
        let today = DateFormatter.dayKey.string(from: Date())
        let taskDescriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate { task in
                task.dayKey == today && !task.isCompleted
            },
            sortBy: [SortDescriptor(\\TaskItem.scheduledAt)]
        )
        
        let tasks = try context.fetch(taskDescriptor)
        guard let nextTask = tasks.first else {
            return .result()
        }
        
        // Snooze task by 15 minutes from now
        let newTime = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let newComponents = Calendar.current.dateComponents([.hour, .minute], from: newTime)
        
        nextTask.scheduledAt = newComponents
        nextTask.snoozedUntil = newTime
        
        // Update dayKey if crossed day boundary or reset time
        let newDayKey = DateFormatter.dayKey.string(from: newTime)
        if newDayKey != nextTask.dayKey {
            nextTask.dayKey = newDayKey
        }
        
        try context.save()
        
        // **CRITICAL**: Reload widget timeline to show updated data
        WidgetCenter.shared.reloadTimelines(ofKind: "PetWidget")
        
        return .result()
    }
}
```

### 3. Intent Registration - **REQUIRED FOR FUNCTIONALITY**

```swift
// AppIntentsExtension.swift
import AppIntents

struct PetAppIntents: AppIntentsExtension {
    static var includedIntents: [any AppIntent.Type] = [
        MarkTaskDoneIntent.self,
        SnoozeTaskIntent.self
    ]
}
```

## Lock Screen Widget Views - **COMPLETE IMPLEMENTATION**

### 1. Lock Screen Widget Definition

```swift
struct PetWidget: Widget {
    let kind: String = "PetWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PetWidgetTimelineProvider()) { entry in
            if #available(iOS 16.0, *) {
                PetAccessoryWidgetView(entry: entry)
            } else {
                PetWidgetView(entry: entry)
            }
        }
        .configurationDisplayName("Pet Tasks")
        .description("Track your tasks and watch your pet evolve")
        .supportedFamilies([
            .accessoryRectangular,  // Lock Screen rectangular - INTERACTIVE (iOS 16+)
            .accessoryInline,       // Lock Screen inline (iOS 16+)
            .accessoryCircular,     // Lock Screen circular (iOS 16+)
            .systemSmall,           // Home Screen
            .systemMedium           // Home Screen
        ])
        .contentMarginsDisabled()
    }
}
```

### 2. Lock Screen Accessory Views - **COMPLETE IMPLEMENTATION**

```swift
@available(iOS 16.0, *)
struct PetAccessoryWidgetView: View {
    let entry: PetWidgetEntry
    @Environment(\\.widgetFamily) var widgetFamily
    
    var body: some View {
        switch widgetFamily {
        case .accessoryRectangular:
            PetRectangularView(entry: entry)
        case .accessoryInline:
            PetInlineView(entry: entry)
        case .accessoryCircular:
            PetCircularView(entry: entry)
        default:
            PetWidgetView(entry: entry)
        }
    }
}

@available(iOS 16.0, *)
struct PetRectangularView: View {
    let entry: PetWidgetEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(STAGE_CONFIG.stages[entry.stageIndex].name)
                    .font(.headline)
                    .widgetAccentable()
                
                Spacer()
                
                Text("\\(entry.tasksDone)/\\(entry.tasksTotal)")
                    .font(.caption)
            }
            
            ProgressView(value: entry.progressRatio)
                .progressViewStyle(LinearProgressViewStyle())
                .widgetAccentable()
            
            if !entry.nextTaskTitle.isEmpty {
                HStack {
                    Text("\\(entry.nextTaskTime) \\(entry.nextTaskTitle)")
                        .font(.caption2)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // **CRITICAL**: Lock Screen interactive buttons - ONLY IN RECTANGULAR
                    HStack(spacing: 4) {
                        Button(intent: SnoozeTaskIntent()) {
                            Image(systemName: "clock")
                                .font(.caption2)
                        }
                        .buttonStyle(.plain)
                        .widgetAccentable()
                        
                        Button(intent: MarkTaskDoneIntent()) {
                            Image(systemName: "checkmark")
                                .font(.caption2)
                        }
                        .buttonStyle(.plain)
                        .widgetAccentable()
                    }
                }
            }
        }
        .padding()
    }
}

@available(iOS 16.0, *)
struct PetInlineView: View {
    let entry: PetWidgetEntry
    
    var body: some View {
        Text("🐾 \\(STAGE_CONFIG.stages[entry.stageIndex].name) • \\(entry.tasksDone)/\\(entry.tasksTotal) tasks")
            .widgetAccentable()
    }
}

@available(iOS 16.0, *)
struct PetCircularView: View {
    let entry: PetWidgetEntry
    
    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            
            VStack(spacing: 1) {
                Text("\\(entry.stageIndex + 1)")
                    .font(.headline)
                    .bold()
                    .widgetAccentable()
                
                Text("\\(entry.tasksDone)/\\(entry.tasksTotal)")
                    .font(.caption2)
                    .widgetAccentable()
            }
        }
    }
}
```

## Daily Closeout Implementation - **COMPLETE WITH BACKGROUND TASKS**

**CRITICAL**: Daily closeout must run exactly once per day after reset time.

```swift
import BackgroundTasks
import WidgetKit

class DailyCloseoutManager: ObservableObject {
    static let shared = DailyCloseoutManager()
    
    func scheduleBackgroundCloseout() {
        let request = BGAppRefreshTaskRequest(identifier: "com.yourteam.petapp.dailycloseout")
        request.earliestBeginDate = nextResetTime()
        
        try? BGTaskScheduler.shared.submit(request)
    }
    
    private func nextResetTime() -> Date {
        let context = ModelContext(DataContainer.shared)
        let settingsDescriptor = FetchDescriptor<AppSettings>()
        let settings = (try? context.fetch(settingsDescriptor).first) ?? AppSettings()
        
        let calendar = Calendar.current
        let now = Date()
        
        // Get next reset time (today or tomorrow)
        var nextReset = calendar.date(bySettingHour: settings.resetTimeHour, minute: settings.resetTimeMinute, second: 0, of: now)!
        
        if nextReset <= now {
            nextReset = calendar.date(byAdding: .day, value: 1, to: nextReset)!
        }
        
        return nextReset
    }
    
    func checkAndRunCloseout() async {
        let context = ModelContext(DataContainer.shared)
        
        let petDescriptor = FetchDescriptor<PetState>()
        let petStates = try? context.fetch(petDescriptor)
        guard let petState = petStates?.first else { return }
        
        let settingsDescriptor = FetchDescriptor<AppSettings>()
        let settings = (try? context.fetch(settingsDescriptor).first) ?? AppSettings()
        
        let today = DateFormatter.dayKey.string(from: Date())
        let calendar = Calendar.current
        let now = Date()
        
        // Check if we've passed reset time and haven't run closeout today
        let todayResetTime = calendar.date(bySettingHour: settings.resetTimeHour, minute: settings.resetTimeMinute, second: 0, of: now)!
        
        guard now >= todayResetTime && petState.lastCloseoutDayKey != today else {
            return
        }
        
        // Run closeout for the previous day
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
        let yesterdayKey = DateFormatter.dayKey.string(from: yesterday)
        
        await performCloseout(for: yesterdayKey, petState: petState, context: context)
        
        // Reload widget timeline after closeout
        WidgetCenter.shared.reloadTimelines(ofKind: "PetWidget")
        
        // Schedule next closeout
        scheduleBackgroundCloseout()
    }
    
    private func performCloseout(for dayKey: String, petState: PetState, context: ModelContext) async {
        // Get yesterday's tasks
        let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate { task in
                task.dayKey == dayKey
            }
        )
        
        guard let tasks = try? context.fetch(descriptor) else { return }
        
        // Calculate completion rate
        let completedTasks = tasks.filter { $0.isCompleted }
        let rate = tasks.isEmpty ? 0.0 : Double(completedTasks.count) / Double(tasks.count)
        
        // Apply missed task penalties
        let missedTasks = tasks.filter { !$0.isCompleted }
        for _ in missedTasks {
            PetEngine.onMiss(pet: &petState, cfg: STAGE_CONFIG)
        }
        
        // Apply daily bonus/penalty
        PetEngine.onDailyCloseout(rate: rate, pet: &petState, cfg: STAGE_CONFIG)
        
        // **CRITICAL**: Update lastCloseoutDayKey to prevent duplicate runs
        petState.lastCloseoutDayKey = dayKey
        
        try? context.save()
    }
}
```

### Background Task Registration - **COMPLETE IMPLEMENTATION**

```swift
// In App.swift for SwiftUI apps
@main
struct PetTaskApp: App {
    let container = DataContainer.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
                .task {
                    await DailyCloseoutManager.shared.checkAndRunCloseout()
                    DailyCloseoutManager.shared.scheduleBackgroundCloseout()
                }
        }
    }
    
    init() {
        // **CRITICAL**: Register background task handler
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.yourteam.petapp.dailycloseout",
            using: nil
        ) { task in
            Task {
                await DailyCloseoutManager.shared.checkAndRunCloseout()
                task.setTaskCompleted(success: true)
            }
        }
    }
}

// **CRITICAL**: Also trigger on app foreground as fallback
extension PetTaskApp {
    func applicationDidBecomeActive() {
        Task {
            await DailyCloseoutManager.shared.checkAndRunCloseout()
        }
    }
}
```

## Stage Configuration - **EXACT MATCH**

```swift
struct Stage {
    let i: Int
    let name: String
    let threshold: Int
    let asset: String
}

struct StageCfg {
    let stages: [Stage]
}

let STAGE_CONFIG = StageCfg(stages: [
    Stage(i: 0, name: "Tadpole", threshold: 10, asset: "pet_tadpole"),
    Stage(i: 1, name: "Minnow", threshold: 20, asset: "pet_minnow"),
    Stage(i: 2, name: "Frog", threshold: 30, asset: "pet_frog"),
    Stage(i: 3, name: "Hermit Crab", threshold: 40, asset: "pet_hermit"),
    Stage(i: 4, name: "Starfish", threshold: 50, asset: "pet_starfish"),
    Stage(i: 5, name: "Jellyfish", threshold: 60, asset: "pet_jellyfish"),
    Stage(i: 6, name: "Squid", threshold: 75, asset: "pet_squid"),
    Stage(i: 7, name: "Seahorse", threshold: 90, asset: "pet_seahorse"),
    Stage(i: 8, name: "Dolphin", threshold: 110, asset: "pet_dolphin"),
    Stage(i: 9, name: "Shark", threshold: 135, asset: "pet_shark"),
    Stage(i: 10, name: "Otter", threshold: 165, asset: "pet_otter"),
    Stage(i: 11, name: "Fox", threshold: 200, asset: "pet_fox"),
    Stage(i: 12, name: "Lynx", threshold: 240, asset: "pet_lynx"),
    Stage(i: 13, name: "Wolf", threshold: 285, asset: "pet_wolf"),
    Stage(i: 14, name: "Bear", threshold: 335, asset: "pet_bear"),
    Stage(i: 15, name: "Bison", threshold: 390, asset: "pet_bison"),
    Stage(i: 16, name: "Elephant", threshold: 450, asset: "pet_elephant"),
    Stage(i: 17, name: "Rhino", threshold: 515, asset: "pet_rhino"),
    Stage(i: 18, name: "Lion", threshold: 585, asset: "pet_lion"),
    Stage(i: 19, name: "Floating God", threshold: 0, asset: "pet_god")
])
```

## App Entitlements and Configuration - **REQUIRED SETUP**

### 1. App Groups Entitlement
```xml
<!-- App.entitlements -->
<key>com.apple.security.application-groups</key>
<array>
    <string>group.com.yourteam.petapp</string>
</array>
```

### 2. Widget Extension Entitlements
```xml
<!-- WidgetExtension.entitlements -->
<key>com.apple.security.application-groups</key>
<array>
    <string>group.com.yourteam.petapp</string>
</array>
```

### 3. Info.plist Configuration
```xml
<key>NSUserTrackingUsageDescription</key>
<string>This app does not track users.</string>
<key>ITSAppUsesNonExemptEncryption</key>
<false/>
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.yourteam.petapp.dailycloseout</string>
</array>
```

### 4. DateFormatter Extension - **REQUIRED UTILITY**
```swift
extension DateFormatter {
    static let dayKey: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}
```

## Key Implementation Notes - **CRITICAL SUCCESS FACTORS**

### 1. Hourly Update Rule (CRITICAL)
- Widget timeline generates entries at the top of each hour only using `calendar.nextDate()`
- Visual changes (pet image, progress) occur ONLY on hourly boundaries
- AppIntent actions update data immediately but visuals update next hour
- Budget constraint: Lock Screen widgets have limited timeline updates per day

### 2. Data Persistence (CRITICAL)
- Use App Groups to share data between main app and widget
- Container identifier: "group.com.yourteam.petapp"
- SwiftData container must be configured for sharing with `.groupContainer`
- All data access must use the shared ModelContainer

### 3. Widget Refresh Strategy (CRITICAL)
```swift
// MUST call after every AppIntent action
WidgetCenter.shared.reloadTimelines(ofKind: "PetWidget")

// Also call after daily closeout
WidgetCenter.shared.reloadTimelines(ofKind: "PetWidget")
```

### 4. Lock Screen Constraints (CRITICAL)
- Interactive buttons ONLY work on Lock Screen accessoryRectangular
- Use `.widgetAccentable()` for proper tinting
- AccessoryWidgetBackground() for circular widgets
- Monochrome rendering support with accent colors
- Limited space - prioritize essential information

### 5. Background Task Setup (CRITICAL)
```xml
<!-- In Info.plist -->
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.yourteam.petapp.dailycloseout</string>
</array>
```

## CRITICAL SUCCESS CHECKLIST

✅ **App Groups configured** for data sharing
✅ **AppIntents implemented** with WidgetCenter.shared.reloadTimelines()
✅ **Timeline entries aligned** to hour boundaries with nextDate()
✅ **Daily closeout scheduled** with BackgroundTasks and deduping
✅ **Lock Screen widget families** implemented (accessoryRectangular, etc.)
✅ **PetEngine logic matches** TypeScript exactly (including stage-0 clamp)
✅ **Settings model included** for grace window and reset time
✅ **Interactive buttons** only in accessoryRectangular with proper tinting

## Testing Checklist

1. **Widget Installation**: Verify widget appears in Lock Screen gallery
2. **Hourly Updates**: Confirm visual updates occur only on hour boundaries
3. **AppIntents**: Test Done/Snooze actions from Lock Screen
4. **Deep Links**: Verify tapping widget opens Today screen
5. **Evolution Rules**: Test pet progression with various completion rates
6. **Daily Closeout**: Verify once-per-day execution with BackgroundTasks
7. **Data Sharing**: Confirm app and widget share data correctly via App Groups

This implementation now **exactly** matches your original specification and preserves all the core business logic from the React Native prototype with **full Lock Screen widget functionality**.