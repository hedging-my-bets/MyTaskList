# 🎯 PetProgress - Gamified Task Management with Lock Screen Widgets

[![iOS](https://img.shields.io/badge/iOS-17.0+-blue.svg)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

> Transform daily tasks into a delightful pet-raising adventure. Complete tasks directly from your iPhone Lock Screen and watch your virtual pet evolve in real-time.

## 🌟 Features

### 🔒 **Lock Screen Magic**
- **Zero App Opens Required**: Complete tasks directly from Lock Screen
- **Interactive Widgets**: Tap, skip, and navigate tasks without unlocking
- **Real-Time Pet Evolution**: Watch your pet grow as you complete tasks
- **5-Minute Auto-Refresh**: Always shows current tasks and pet state

### 🎮 **Gamification That Motivates**
- **16 Pet Evolution Stages**: From Frog to Gold CEO
- **Perfect Day Celebrations**: Confetti and bonus XP for completing all tasks
- **Streak Tracking**: Build momentum with consecutive perfect days
- **Grace Period Intelligence**: Tasks completed within grace window count as "on-time"

### ⚡ **Steve Jobs-Level Polish**
- **Sub-50ms Widget Loading**: Instant Lock Screen performance
- **Bulletproof Data Sync**: App and widget perfectly synchronized
- **Midnight Edge Cases**: Grace periods work correctly across day boundaries
- **Haptic Feedback**: Satisfying tactile response for every interaction

## 🚀 Quick Start

### Requirements
- iOS 17.0+ (Required for interactive Lock Screen widgets)
- iPhone only (iPad not supported)
- Xcode 15.0+

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/PetProgress.git
   cd PetProgress/ios-native
   ```

2. **Open in Xcode**
   ```bash
   open PetProgress.xcodeproj
   ```

3. **Configure App Group** (Critical!)
   - Enable App Groups capability for both App and Widget targets
   - Use identifier: `group.com.hedgingmybets.PetProgress`

4. **Build and Run**
   - Select iPhone simulator or device
   - Build and run the app
   - Add widget to Lock Screen via Settings > Wallpaper

### Adding Lock Screen Widget

1. Lock your iPhone
2. Long press on Lock Screen
3. Tap "Customize"
4. Tap "Add Widgets"
5. Find "PetProgress"
6. Add "Rectangular" widget for best experience

## 📱 How It Works

### 1. **Add Tasks in App**
```swift
// Tasks are scheduled by hour with grace periods
Task: "Focus work" at 2:00 PM
Grace Period: 60 minutes (configurable)
Completion Window: 2:00 PM - 3:00 PM
```

### 2. **Complete from Lock Screen**
- **Tap Circle**: Mark current task done
- **◀ ▶ Buttons**: Navigate between tasks
- **✅ Button**: Complete focused task
- **✖ Button**: Skip current task

### 3. **Watch Pet Evolve**
```
Task Completion → XP Award → Stage Progression → Pet Evolution
     ↓              ↓            ↓               ↓
   5-10 XP      → Accumulate → Threshold → New Pet Image
```

### 4. **Perfect Day Bonus**
- Complete ALL tasks in a day
- Earn 50+ bonus XP (scales with streak)
- Trigger celebration animation
- Build consecutive day streaks

## 🏗️ Architecture

### Core Components

```
PetProgress/
├── App/                     # Main iOS application
│   ├── Sources/
│   │   ├── DataStore.swift         # Core state management
│   │   ├── CelebrationSystem.swift # Haptics & animations
│   │   └── AppIntents.swift        # Lock Screen intents
│   └── Assets.xcassets/     # Pet images & app icons
├── Widget/                  # Lock Screen widgets
│   └── Sources/
│       ├── PetProgressWidget.swift     # Widget configuration
│       └── Views/                       # Widget UI components
└── SharedKit/              # Shared framework
    └── Sources/SharedKit/
        ├── Models/                 # Data models
        ├── PetEvolutionEngine.swift # XP calculations
        ├── PerfectDayTracker.swift  # Streak system
        └── Storage/                 # App Group persistence
```

### Key Technologies

- **SwiftUI**: Declarative UI for app and widget
- **WidgetKit**: Interactive Lock Screen widgets (iOS 17+)
- **App Intents**: Button actions from Lock Screen
- **App Groups**: Data synchronization between app and widget
- **UserDefaults**: Lightweight persistence for settings and streaks

## 🎯 Grace Period Logic

One of PetProgress's most sophisticated features is intelligent grace period handling:

```swift
// Example: Task at 11:30 PM with 2-hour grace period
Task Time: 23:30 (11:30 PM)
Grace Period: 120 minutes
Completion Window: 23:30 → 01:30 (next day)

// The system correctly handles midnight crossing
if graceWindowEnd >= 24 * 60 {
    let nextDayEnd = graceWindowEnd - 24 * 60
    return (currentMinutes >= graceWindowStart) || (currentMinutes <= nextDayEnd)
}
```

This ensures users aren't penalized for completing late-night tasks after midnight.

## 🧪 Testing

### Critical Test Cases

```bash
# Grace Period Edge Cases
Task at 23:30 + 120min grace = valid until 01:30
Task at 23:45 + 60min grace = valid until 00:45
Task at 00:30 + 30min grace = valid until 01:00

# Widget Synchronization
1. Add task in app → Widget updates within 5 minutes
2. Complete task in widget → App reflects immediately
3. Background refresh → Widget stays current

# Perfect Day Detection
1. Complete all tasks before midnight
2. Trigger celebration with confetti
3. Award bonus XP (50 + streak multiplier)
4. Increment streak counter
```

### Running Tests

```bash
# Unit tests
xcodebuild test -scheme PetProgress -destination 'platform=iOS Simulator,name=iPhone 15'

# Widget tests
xcodebuild test -scheme Widget -destination 'platform=iOS Simulator,name=iPhone 15'

# Critical validation
swift CriticalValidation.swift
```

## 🎨 Customization

### Adding New Pet Stages

1. **Add images** to both `App/Assets.xcassets` and `Widget/Assets.xcassets`
2. **Update StageConfig.json**:
   ```json
   {
     "index": 16,
     "name": "Diamond Dragon",
     "threshold": 600,
     "asset": "pet_dragon"
   }
   ```
3. **Update WidgetImageOptimizer.swift** with new asset name

### Configuring Grace Periods

```swift
// In SettingsView.swift
Picker("Grace Minutes", selection: $graceMinutes) {
    Text("15 minutes").tag(15)   // Quick mode
    Text("30 minutes").tag(30)   // Default
    Text("60 minutes").tag(60)   // Relaxed
    Text("120 minutes").tag(120) // Very relaxed
}
```

## 🐛 Troubleshooting

### Widget Not Appearing
- Verify App Group is enabled for both targets
- Check bundle identifiers match between app and widget
- Restart iPhone after installation

### Tasks Not Syncing
- Ensure `group.com.hedgingmybets.PetProgress` App Group is configured
- Check UserDefaults permissions in Settings > Privacy
- Force-quit and restart the app

### Grace Period Issues
- Verify device time zone is correct
- Check grace period setting in app Settings
- Test with tasks scheduled 1-2 hours in advance

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Steve Jobs**: For setting the standard of excellence we aspire to reach
- **iOS Community**: For feedback and widget development best practices
- **Beta Testers**: For finding edge cases in grace period calculations

## 🔗 Links

- [App Store Listing](https://apps.apple.com/app/petprogress) (Coming Soon)
- [Widget Development Guide](docs/widget-development.md)
- [Contributing Guidelines](CONTRIBUTING.md)
- [Bug Reports](https://github.com/yourusername/PetProgress/issues)

---

**Built with ❤️ and obsessive attention to detail.**

*"Design is not just what it looks like and feels like. Design is how it works."* - Steve Jobs