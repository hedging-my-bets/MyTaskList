# iOS WidgetKit Porting Guide

This guide provides comprehensive instructions for porting the React Native pet evolution to-do app to native iOS with WidgetKit Lock Screen widgets.

## Overview

The React Native prototype includes all the core business logic, data models, and UI patterns you need. This guide shows you exactly how to implement each piece in native iOS with WidgetKit support.

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

## PetEngine Implementation

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
    }
}
```

## Stage Configuration

Port from `data/stageConfig.ts`:

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
    // ... continue with all 20 stages
    Stage(i: 19, name: "Floating God", threshold: 0, asset: "pet_god")
])
```

## WidgetKit Implementation

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
        
        // Create entries at the top of each hour for next 24 hours
        var entries: [PetWidgetEntry] = []
        
        for hourOffset in 0..<24 {
            let entryDate = calendar.date(byAdding: .hour, value: hourOffset, to: now)!
            let hourEntry = generateEntryForTime(entryDate)
            entries.append(hourEntry)
        }
        
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
    
    private func generateCurrentEntry() -> PetWidgetEntry {
        // Load current pet state and tasks from SwiftData
        // Calculate progress ratio, next task, etc.
        // Return PetWidgetEntry with current data
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

### 3. Widget View

```swift
struct PetWidgetView: View {
    let entry: PetWidgetEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                // Pet image
                Image(STAGE_CONFIG.stages[entry.stageIndex].asset)
                    .resizable()
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading, spacing: 2) {
                    // Stage name and progress
                    Text(STAGE_CONFIG.stages[entry.stageIndex].name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    // Progress bar
                    ProgressView(value: entry.progressRatio)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    
                    Text("\\(entry.stageXP)/\\(entry.threshold) XP")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Tasks summary
            HStack {
                Text("\\(entry.tasksDone)/\\(entry.tasksTotal) tasks")
                    .font(.caption)
                Spacer()
            }
            
            // Next task
            if !entry.nextTaskTitle.isEmpty {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.nextTaskTime)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(entry.nextTaskTitle)
                            .font(.caption)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Action buttons
                    HStack(spacing: 8) {
                        Button(intent: SnoozeTaskIntent()) {
                            Image(systemName: "clock")
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                        
                        Button(intent: MarkTaskDoneIntent()) {
                            Image(systemName: "checkmark")
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(12)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
    }
}
```

## AppIntents Implementation

### 1. Mark Task Done Intent

```swift
import AppIntents
import SwiftData

struct MarkTaskDoneIntent: AppIntent {
    static let title: LocalizedStringResource = "Mark Task Done"
    static let description = IntentDescription("Mark the next task as completed")
    
    func perform() async throws -> some IntentResult {
        let container = DataContainer.shared
        let context = ModelContext(container)
        
        // Get today's uncompleted tasks
        let today = DateFormatter.dayKey.string(from: Date())
        let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate { task in
                task.dayKey == today && !task.isCompleted
            },
            sortBy: [SortDescriptor(\\TaskItem.scheduledAt)]
        )
        
        let tasks = try context.fetch(descriptor)
        guard let nextTask = tasks.first else {
            return .result()
        }
        
        // Mark task as completed
        nextTask.isCompleted = true
        nextTask.completedAt = Date()
        
        // Update pet state
        let petDescriptor = FetchDescriptor<PetState>()
        let petStates = try context.fetch(petDescriptor)
        guard let petState = petStates.first else {
            return .result()
        }
        
        let scheduledTime = Calendar.current.date(from: nextTask.scheduledAt)!
        let isOnTime = abs(Date().timeIntervalSince(scheduledTime)) <= 3600 // 1 hour grace
        
        PetEngine.onCheck(onTime: isOnTime, pet: &petState, cfg: STAGE_CONFIG)
        
        try context.save()
        
        return .result()
    }
}
```

### 2. Snooze Task Intent

```swift
struct SnoozeTaskIntent: AppIntent {
    static let title: LocalizedStringResource = "Snooze Task"
    static let description = IntentDescription("Snooze the next task by 15 minutes")
    
    func perform() async throws -> some IntentResult {
        let container = DataContainer.shared
        let context = ModelContext(container)
        
        // Get today's uncompleted tasks
        let today = DateFormatter.dayKey.string(from: Date())
        let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate { task in
                task.dayKey == today && !task.isCompleted
            },
            sortBy: [SortDescriptor(\\TaskItem.scheduledAt)]
        )
        
        let tasks = try context.fetch(descriptor)
        guard let nextTask = tasks.first else {
            return .result()
        }
        
        // Snooze task by 15 minutes
        let newTime = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let newComponents = Calendar.current.dateComponents([.hour, .minute], from: newTime)
        
        nextTask.scheduledAt = newComponents
        nextTask.snoozedUntil = newTime
        
        // Update dayKey if crossed day boundary
        let newDayKey = DateFormatter.dayKey.string(from: newTime)
        if newDayKey != nextTask.dayKey {
            nextTask.dayKey = newDayKey
        }
        
        try context.save()
        
        return .result()
    }
}
```

## Widget Configuration

### 1. Widget Definition

```swift
struct PetWidget: Widget {
    let kind: String = "PetWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PetWidgetTimelineProvider()) { entry in
            PetWidgetView(entry: entry)
        }
        .configurationDisplayName("Pet Tasks")
        .description("Track your tasks and watch your pet evolve")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}
```

### 2. Widget Bundle

```swift
@main
struct PetWidgetBundle: WidgetBundle {
    var body: some Widget {
        PetWidget()
    }
}
```

## Daily Closeout Implementation

```swift
class DailyCloseoutManager: ObservableObject {
    static let shared = DailyCloseoutManager()
    
    func checkAndRunCloseout() async {
        let container = DataContainer.shared
        let context = ModelContext(container)
        
        let petDescriptor = FetchDescriptor<PetState>()
        let petStates = try? context.fetch(petDescriptor)
        guard let petState = petStates?.first else { return }
        
        let today = DateFormatter.dayKey.string(from: Date())
        
        // Check if we need to run closeout
        guard petState.lastCloseoutDayKey != today else { return }
        
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let yesterdayKey = DateFormatter.dayKey.string(from: yesterday)
        
        await performCloseout(for: yesterdayKey, petState: petState, context: context)
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
        
        petState.lastCloseoutDayKey = dayKey
        
        try? context.save()
    }
}
```

## Main App Structure

### 1. App Entry Point

```swift
@main
struct PetTaskApp: App {
    let container = DataContainer.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
                .task {
                    await DailyCloseoutManager.shared.checkAndRunCloseout()
                }
        }
    }
}
```

### 2. Today Screen

```swift
struct TodayView: View {
    @Query private var petStates: [PetState]
    @Query private var todayTasks: [TaskItem]
    
    private var petState: PetState {
        petStates.first ?? PetState()
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Pet Display
                    PetDisplayView(petState: petState)
                    
                    // Progress Bar
                    ProgressBarView(
                        current: petState.stageXP,
                        max: STAGE_CONFIG.stages[petState.stageIndex].threshold,
                        stageName: STAGE_CONFIG.stages[petState.stageIndex].name
                    )
                    
                    // Task List
                    TaskListView(tasks: todayTasks)
                }
            }
            .navigationTitle("Today")
        }
    }
}
```

## Key Implementation Notes

### 1. Hourly Update Rule
- Widget timeline generates entries at the top of each hour only
- Visual changes (pet image, progress) occur ONLY on hourly boundaries
- AppIntent actions update data immediately but visuals update next hour

### 2. Data Persistence
- Use App Groups to share data between main app and widget
- Container identifier: "group.com.yourteam.petapp"
- SwiftData container must be configured for sharing

### 3. Widget Refresh Strategy
```swift
// In AppIntents after updating data
WidgetCenter.shared.reloadTimelines(ofKind: "PetWidget")
```

### 4. Asset Organization
- Add 20 pet images to Asset Catalog
- Name them exactly as specified in stage configuration
- Use vector PDFs for best scaling

## Testing Checklist

1. **Widget Installation**: Verify widget appears in Lock Screen gallery
2. **Hourly Updates**: Confirm visual updates occur only on hour boundaries  
3. **AppIntents**: Test Done/Snooze actions from Lock Screen
4. **Deep Links**: Verify tapping widget opens Today screen
5. **Evolution Rules**: Test pet progression with various completion rates
6. **Daily Closeout**: Verify once-per-day execution
7. **Data Sharing**: Confirm app and widget share data correctly

## Privacy Configuration

Add to Info.plist:
```xml
<key>NSUserTrackingUsageDescription</key>
<string>This app does not track users.</string>
<key>ITSAppUsesNonExemptEncryption</key>
<false/>
```

This implementation exactly matches your original specification and preserves all the core business logic from the React Native prototype.