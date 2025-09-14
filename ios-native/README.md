# Pet Progress - iOS 17+ Interactive Widget App

A gamified task tracking app for iOS 17+ featuring interactive widgets, pet evolution, and a clean SharedKit architecture.

## 🎯 Features

- **Interactive Widgets**: iOS 17+ widgets with Button(intent:) for lock-screen interaction
- **Pet Evolution**: 16-stage pet progression system based on task completion
- **Smart Scheduling**: DST-safe timeline with automatic hourly refresh
- **App Group Storage**: Seamless data sharing between app and widget
- **3-Row Task Feed**: Clean, focused task display showing next 3 tasks
- **App Intents**: Complete, Snooze, and Mark-Next actions from widgets

## 🏗 Architecture

### SharedKit Framework
Eliminates dependency cycles by providing shared components:
- **TimeSlot**: DST-safe time utilities
- **DayModel**: Task and progress data structures
- **PetEvolutionEngine**: 16-stage pet progression logic
- **SharedStore**: App Group persistence layer
- **TaskPlanner**: Intelligent task scheduling
- **AssetPipeline**: Deterministic asset management with SF Symbol fallbacks

### Target Dependencies
```
App ←→ SharedKit ←→ Widget
```
Clean separation with no cycles between App and Widget targets.

## 🎨 Pet Evolution Stages (Updated)

| Stage | Name | Points | Description |
|-------|------|--------|-------------|
| 0 | Baby | 0 | Starting stage |
| 1 | Toddler | 10 | First milestone |
| 2 | Frog | 25 | Amphibian phase |
| 3 | Hermit | 45 | Introvert period |
| 4 | Seahorse | 70 | Ocean explorer |
| 5 | Dolphin | 100 | Intelligent swimmer |
| 6 | Alligator | 135 | Apex predator |
| 7 | Beaver | 175 | Master builder |
| 8 | Wolf | 220 | Pack leader |
| 9 | Bear | 270 | Forest guardian |
| 10 | Bison | 325 | Plains wanderer |
| 11 | Elephant | 385 | Gentle giant |
| 12 | Rhino | 450 | Armored tank |
| 13 | Adult | 520 | Mature form |
| 14 | CEO | 595 | Business leader |
| 15 | Gold | 675 | Ultimate achievement |

### What it does
- **Hourly widget visuals**: Pet image and progress only change on the top of each hour timeline tick.
- **16-stage evolution/de-evolution**: From ocean to land to people to boss. Thresholds from StageConfig.json.
- **Done/Snooze from Lock Screen**: Via AppIntents buttons; no notifications.
- **Daily closeout**: On next app launch after local midnight, compute completion rate, apply bonus/penalty, evolve/de-evolve, archive/seed.

### Build locally
1. **Apple Developer Setup**:
   - Create App IDs: `com.yourco.petprogress` and `com.yourco.petprogress.widget`
   - Create App Group: `group.com.petprogress.app`
   - Attach App Group to both App IDs
   - Replace `YOUR_ACTUAL_TEAM_ID` in `project.yml` with your actual Team ID

2. **Build Steps**:
   - `brew install xcodegen`
   - `cd ios-native && xcodegen generate`
   - Open the generated `.xcodeproj` in Xcode and run the `PetProgress` scheme on iOS 17+.

### Run tests
```
cd ios-native
xcodebuild test -scheme PetProgress -destination "platform=iOS Simulator,name=iPhone 15"
```

### App Group shared storage
- Single JSON blob `State.json` stored in App Group `group.com.yourco.petprogress`.
- Access via `SharedStore` with atomic writes (temp then replace) and a serial queue.
- Schema: tasks, pet, dayKey, schemaVersion, rolloverEnabled.

### Lock Screen widget
- Families: `.accessoryRectangular`, `.systemSmall`.
- Timeline: 24 entries at the top of each hour; policy `.atEnd`.
- Shows pet image, progress bar, `X/Y today`, and `HH:mm • title`.
- Tapping non-button areas deep links to `petprogress://today`.

### Privacy Policy
**Data Not Collected**: This app does not collect, store, or transmit any personal information. All data is stored locally on-device only. No analytics, no crash reporting, no network requests.

### App Review Notes
Widget visuals update hourly via WidgetKit timeline; user interactions via AppIntents update state immediately, and visuals reflect on the next hourly refresh. No background polling, no remote data.

### Build Steps
1. **Windows asset prep**:
   - Install Python + Pillow: `pip install pillow`
   - Place pet PNGs in `ios-native/ArtSources/` (1024x1024 transparent)
   - Place app icon at `ios-native/ArtSources/appicon/appicon.png` (1024x1024)
   - Run: `python ios-native/Tools/build_assets.py`

2. **macOS build**:
   - `brew install xcodegen`
   - `cd ios-native && xcodegen generate`
   - Open generated `.xcodeproj` in Xcode and build for iOS 17+

### App Review Notes
Widget visuals update hourly via WidgetKit timeline; user interactions via AppIntents update state immediately, and visuals reflect on the next hourly refresh. No background polling, no remote data.

### Screenshot Checklist
- Lock Screen rectangular widget showing pet, progress, and tasks
- In-app Today screen with pet evolution
- Planner screen with recurring tasks
- Settings screen with configuration options

### No notifications
This MVP has no notifications or background polling.

### Verify hourly-only visuals
1. Add the Lock Screen widget.
2. Observe that pet/progress only change at the next hourly tick (not immediately upon actions).

### CI
GitHub Actions workflow at `ios-native/.github/workflows/ios-sim.yml` builds and runs tests on `macos-latest` with iPhone 15 simulator.

## Definition of Done (Production Ready)

✅ Assets generated via build_assets.py (16 stages @1x/2x/3x, app icon sizes).
✅ StageConfig (App + Widget) matches the 16-stage order above; thresholds applied.
✅ Shared catalog has imagesets for all 16 assets (real or placeholder).
✅ Provider uses dayKey(for: entry.date); intents are idempotent; no forced widget reloads.
✅ 3-row widget with per-row complete + Snooze works.
✅ Planner recurrence + per-day overrides + one-offs persist.
✅ Settings (grace/reset/rollover) honored by intents/provider/closeout.
✅ PetEngine evolve/de-evolve math passes tests; final stage terminal.
✅ CI (simulator) build + tests are green.
✅ README updated with 16 stages and review notes.

