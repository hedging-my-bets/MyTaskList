# 🚀 PetProgress iOS App - World-Class Developer AI Prompt

## Executive Summary

You are developing **PetProgress**, an iPhone-only iOS 17+ task management app with gamified pet evolution mechanics and interactive Lock Screen widgets. This is a **polished, production-ready application** designed to ship on the App Store with Steve Jobs-level attention to detail, user experience, and technical excellence.

## 🎯 Core Vision & Product Requirements

### The Bar We're Holding (Must-Have Features)

1. **Lock Screen Widget Excellence**
   - Pet evolution/de-evolution visible on Lock Screen (pet image updates when XP crosses thresholds)
   - Nearest-hour task window on Lock Screen (respecting Grace Minutes)
   - Tap the circle on Lock Screen to mark done (no app open; update can be near-real time or hourly refresh)
   - Scroll/paginate Lock Screen tasks and mark items done/"X" skipped
   - Widget uses `AppIntentTimelineProvider` + App Intents for all actions
   - App Group shared storage for app↔widget state sync
   - Proper widget reload behavior (`WidgetCenter.reloadTimelines`) after actions

2. **iPhone-Only Focus**
   - Clean packaging with iPhone-only icons (no iPad assets/warnings)
   - `TARGETED_DEVICE_FAMILY: "1"` for all targets
   - No iPad compatibility layer or UI adaptations needed

3. **Essential Settings**
   - Privacy Policy link (explicitly requested) - opens in SafariView
   - Grace Minutes control (slider/stepper with brief help text)
   - Rollover toggle for incomplete tasks

4. **Pet Experience & Gamification**
   - Haptics on level-up and key actions
   - Level-up celebration with micro-animation/confetti
   - 16-stage evolution system (Baby → CEO)
   - De-evolution for missed tasks (respects grace period)

5. **Task Management**
   - Task creation with title, time, and recurrence
   - Template-based quick add (post-v1)
   - Task edit/delete functionality
   - Series management for recurring tasks
   - Grace period rollover logic for incomplete tasks

### Explicitly NOT Wanted
- In-app review prompts
- First-run explainer/onboarding
- Daily notification toggle
- Accessibility/i18n sprint
- Export JSON/UI tests/snapshots

## 🏗️ Technical Architecture

### Project Structure
```
MyTaskList/
├── ios-native/
│   ├── App/                         # Main iOS app
│   │   ├── Sources/
│   │   │   ├── PetProgressApp.swift # App entry point
│   │   │   ├── ContentView.swift    # Main UI
│   │   │   ├── DataStore.swift      # Core data management
│   │   │   ├── AppIntents.swift     # Lock Screen intents
│   │   │   ├── CelebrationSystem.swift # Haptics & celebrations
│   │   │   └── Views/               # UI components
│   │   └── Assets.xcassets/         # Pet images & app icons
│   ├── Widget/                      # Lock Screen widgets
│   │   └── Sources/
│   │       ├── PetProgressWidget.swift # Widget configuration
│   │       └── Views/               # Widget UI components
│   └── SharedKit/                   # Shared framework
│       └── Sources/SharedKit/
│           ├── Models/              # Data models
│           ├── SharedStore.swift    # App Group storage
│           ├── PetEvolutionEngine.swift # Pet XP/evolution logic
│           └── Utils/               # Utilities
```

### Key Technologies & Patterns

#### iOS 17+ Requirements
- **Minimum deployment**: iOS 17.0
- **Swift**: 5.9+
- **SwiftUI**: Exclusive UI framework
- **WidgetKit**: Interactive Lock Screen widgets
- **App Intents**: Lock Screen task actions
- **App Groups**: `group.com.hedgingmybets.PetProgress`

#### Core Systems

1. **Data Persistence**
   - `SharedStore`: Enterprise-grade App Group storage with atomic operations
   - `UserDefaults` with App Group suite for widget↔app sync
   - JSON encoding for complex models
   - Crash recovery and backup mechanisms

2. **Pet Evolution Engine**
   - 16 stages with XP thresholds: [0, 10, 25, 50, 100, 150, 225, 325, 450, 600, 800, 1050, 1350, 1700, 2100, 2550]
   - Emotional states: ecstatic, happy, content, neutral, worried, sad, frustrated
   - Personality traits affecting progression
   - De-evolution for missed tasks (respects grace minutes)
   - Performance-optimized with binary search for stage calculation

3. **Widget System**
   - `AppIntentTimelineProvider` for iOS 17+ interactivity
   - Hourly timeline entries aligned to top-of-hour
   - Interactive buttons: Previous (◀), Next (▶), Complete (✅), Skip (✖)
   - Shared focus index via App Group UserDefaults
   - Immediate refresh after actions via `WidgetCenter.reloadAllTimelines()`

4. **Task Management**
   - `TaskItem`: Individual task instances
   - `TaskSeries`: Recurring task templates
   - `DayModel`: Daily task aggregation
   - Grace period logic (30/60/90/120 minutes)
   - Rollover system for incomplete tasks

5. **Celebration System**
   - Haptic feedback patterns for different events
   - Confetti animations with varying styles
   - Sound effects (if available)
   - Celebration types: task_complete, level_up, perfect_day, streak, milestone

## 💻 Development Guidelines

### Code Quality Standards

1. **Steve Jobs Level Polish**
   - Every pixel matters - no visual glitches
   - Smooth 60fps animations
   - Instant haptic feedback
   - Graceful error handling
   - No crashes, ever

2. **Swift Best Practices**
   - Use `@MainActor` for UI code
   - Leverage Swift concurrency (async/await)
   - Proper error handling with Result types
   - Value types (structs) over reference types where appropriate
   - Protocol-oriented design

3. **SwiftUI Excellence**
   - Declarative, reactive UI
   - Custom view modifiers for reusability
   - Environment objects for dependency injection
   - Proper state management (@State, @StateObject, @ObservedObject)
   - Animation with `.withAnimation` for smooth transitions

4. **Performance Optimization**
   - Lazy loading for heavy resources
   - Image caching via `AssetPipeline`
   - Binary search for O(log n) stage lookups
   - Minimal widget timeline entries (2 per update)
   - Efficient App Group I/O with atomic operations

### Critical Implementation Details

#### Lock Screen Widget Interactivity
```swift
// Widget must use AppIntentConfiguration for iOS 17+
AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider())

// Interactive buttons in AccessoryRectangularView
Button(intent: CompleteTaskIntent(/* params */)) {
    Image(systemName: "checkmark.square.fill")
}
```

#### App Group Synchronization
```swift
// Always use App Group UserDefaults
let userDefaults = UserDefaults(suiteName: "group.com.hedgingmybets.PetProgress")

// Atomic updates with immediate widget refresh
SharedStore.shared.updateTaskCompletion(taskId: id)
WidgetCenter.shared.reloadAllTimelines()
```

#### Grace Period Logic
```swift
// Tasks completed within grace window count as on-time
let graceCutoff = scheduledTime.addingTimeInterval(TimeInterval(graceMinutes * 60))
let isOnTime = completionTime <= graceCutoff
```

#### Pet Evolution Calculation
```swift
// Efficient stage determination
let engine = PetEvolutionEngine()
let currentStage = engine.stageIndex(for: totalXP)
let imageName = engine.imageName(for: totalXP)
```

## 🚢 Shipping Checklist

### Before Every Major Change
1. **Run**: `xcodebuild -scheme PetProgress -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 15'`
2. **Test**: Lock Screen widget interactivity
3. **Verify**: No iPad warnings in build output
4. **Check**: App Group data persistence
5. **Validate**: Pet evolution/de-evolution logic
6. **Confirm**: Haptics and celebrations trigger

### Production Requirements
- [ ] App icons complete (iPhone sizes only)
- [ ] Privacy Policy accessible in Settings
- [ ] Grace Minutes configurable (30/60/90/120)
- [ ] Lock Screen widget fully interactive
- [ ] Pet evolution visually updates
- [ ] Rollover logic working correctly
- [ ] Haptic feedback functional
- [ ] No crashes in 1-hour stress test

## 🎨 Design Philosophy

### User Experience Principles
1. **Delight through gamification** - Every task completion should feel rewarding
2. **Frictionless interaction** - Lock Screen actions without opening app
3. **Visual progression** - Pet evolution as motivation
4. **Forgiveness** - Grace periods prevent frustration
5. **Simplicity** - No unnecessary features or settings

### Technical Excellence
1. **Reliability** - Enterprise-grade storage with crash recovery
2. **Performance** - Instant response, smooth animations
3. **Efficiency** - Minimal battery/memory impact
4. **Maintainability** - Clean architecture, well-documented
5. **Scalability** - Prepared for future features

## 🔧 Common Tasks & Solutions

### Adding a New Pet Stage
1. Add image to `App/Assets.xcassets/` and `Widget/Assets.xcassets/`
2. Update `StageConfig.json` with new threshold
3. Test evolution/de-evolution boundaries
4. Verify widget image loading

### Debugging Widget Issues
1. Check App Group configuration in entitlements
2. Verify `WidgetCenter.reloadAllTimelines()` calls
3. Use Console.app to view widget logs
4. Test with Xcode's widget preview

### Implementing New Celebrations
1. Add case to `CelebrationType` enum
2. Define haptic pattern and duration
3. Create confetti style if needed
4. Wire up to appropriate trigger

## 🚀 Advanced Features (Post-v1)

### Task Templates
- Quick-add common routines
- Customizable preset times
- Smart suggestions based on history

### Enhanced Analytics
- Task completion patterns
- Pet evolution trends
- Behavioral insights

### Social Features
- Share pet progress
- Compare with friends
- Achievement badges

## 📝 Final Notes

This is a **production iOS application** built with the highest standards of quality, performance, and user experience. Every line of code should be written as if Steve Jobs himself will review it. The app should feel magical - turning mundane task management into a delightful pet-raising experience.

**Remember**: Ship only when it's truly ready. A delayed app is eventually good, but a rushed app is forever bad.

---

*"Design is not just what it looks like and feels like. Design is how it works."* - Steve Jobs