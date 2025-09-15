# App Store Reviewer Guide - PetProgress

## Quick Overview for App Store Review Team

**PetProgress** is an iOS productivity app featuring an interactive Lock Screen widget that helps users complete tasks and evolve a virtual pet. This guide helps reviewers quickly understand and test all functionality.

---

## 🎯 Core Functionality (30 seconds to test)

### Primary Feature: Lock Screen Widget Interaction
1. **Install the app** on iPhone (iOS 17+ required)
2. **Add Lock Screen widget**: Long press Lock Screen → Customize → Add Widget → PetProgress
3. **Create a task**: Open app → Tap "+" → Add task for current hour
4. **Test Lock Screen completion**: On Lock Screen, tap the widget to complete the task
5. **Verify pet evolution**: Pet should gain XP and potentially level up

**Expected Result**: Task completion works without opening the app, pet shows evolution progress.

---

## 📱 Complete Testing Checklist

### Essential Features (Test These First)

#### ✅ Lock Screen Widget Functionality
- [ ] Widget appears correctly on Lock Screen (circular, rectangular, inline sizes)
- [ ] Tapping widget completes current task without opening app
- [ ] Widget updates to show next task or empty state
- [ ] Pet image updates to reflect current evolution stage
- [ ] Haptic feedback occurs on task completion

#### ✅ Pet Evolution System
- [ ] Pet starts at Stage 1 (basic appearance)
- [ ] Completing tasks awards XP points
- [ ] Pet evolves to next stage when threshold reached
- [ ] Stage progression is visually clear (1 → 2 → 3, etc.)
- [ ] Celebration appears on level up (once per stage)

#### ✅ App Group Data Sharing
- [ ] Tasks created in main app appear in widget
- [ ] Task completion in widget updates main app
- [ ] Pet evolution syncs between app and widget
- [ ] Data persists across app launches

#### ✅ iPhone-Only Configuration
- [ ] App only installs on iPhone (not iPad)
- [ ] All screens properly sized for iPhone
- [ ] Widget only appears in iPhone widget gallery

### Settings & Privacy

#### ✅ Grace Period Configuration
- [ ] Settings shows Grace Minutes slider (15-60 min)
- [ ] Changing grace period affects task timing
- [ ] Default value is 30 minutes

#### ✅ Privacy Policy Access
- [ ] Settings → Privacy Policy opens web view
- [ ] Policy loads from hosted URL: https://hedging-my-bets.github.io/MyTaskList/privacy-policy.html
- [ ] If network fails, shows fallback local policy
- [ ] Policy clearly states "data stays on device"

### App Store Compliance

#### ✅ Required Functionality
- [ ] App works immediately after installation
- [ ] No account creation required
- [ ] No third-party login requirements
- [ ] All advertised features function as described

#### ✅ Data Privacy
- [ ] No data transmitted to external servers
- [ ] Uses only App Group and iCloud (user controlled)
- [ ] No tracking or analytics frameworks
- [ ] Clear privacy messaging in app and policy

---

## 🔧 Quick Test Scenarios

### Scenario 1: First Time User (2 minutes)
1. Install and launch app
2. App should show welcome/onboarding (if any)
3. Create first task: "Test task" for current hour
4. Add Lock Screen widget (circular recommended)
5. Go to Lock Screen, tap widget to complete task
6. Return to app - pet should have gained XP

### Scenario 2: Widget Sizes (1 minute)
1. Add all three widget sizes to Lock Screen:
   - Circular (shows pet + time/status)
   - Rectangular (shows "Next at 3pm" + pet)
   - Inline (shows "Next: Task name")
2. Verify each displays appropriate information
3. Test tap functionality on circular widget

### Scenario 3: Time-Based Behavior (3 minutes)
1. Create tasks for different hours (e.g., 2pm, 4pm, 6pm)
2. Observe widget behavior at different times:
   - Shows current task when within grace period
   - Shows "Next at Xpm" when no current task
   - Shows "All done" when all tasks completed
3. Test grace period: complete task late, should still award reduced XP

### Scenario 4: Data Persistence (1 minute)
1. Create tasks and complete some
2. Force close app completely
3. Relaunch app - progress should be maintained
4. Check widget still shows correct state

---

## ⚠️ Known Limitations (Intentional Design)

1. **iPhone Only**: Deliberately designed for iPhone Lock Screen widgets
2. **iOS 17+ Required**: Uses new interactive widget features
3. **No Account System**: Privacy-first design, everything local
4. **Limited Task Types**: Focus on time-based productivity tasks
5. **No Cloud Backup**: Data stays on device (with iCloud sync if enabled)

---

## 🚨 Critical Review Points

### App Store Guidelines Compliance

#### 4.0 - Design
- ✅ Native iOS design using SwiftUI
- ✅ Follows Apple Human Interface Guidelines
- ✅ Professional visual design and user experience
- ✅ Appropriate use of system fonts, colors, and spacing

#### 1.1.6 - Include Sufficient Content
- ✅ Full productivity app with widget, pet system, task management
- ✅ Meaningful user experience beyond basic widget functionality
- ✅ Substantial feature set justifying App Store presence

#### 3.2.2 - Unacceptable Business Models
- ✅ No gambling or games of chance
- ✅ Simple productivity app with optional cosmetic progression
- ✅ No real money transactions or in-app purchases

#### 5.1.1 - Privacy Data Collection and Storage
- ✅ All data stored locally on device
- ✅ Clear privacy policy accessible in Settings
- ✅ No third-party data collection or sharing
- ✅ App Group only for widget functionality

#### 2.5.1 - Software Requirements
- ✅ Uses public iOS APIs only
- ✅ Built with official Xcode and Swift
- ✅ No private API usage or reverse engineering
- ✅ Proper App Extensions implementation

---

## 📋 Testing Requirements Checklist

### Required Tests for Approval

#### Core Functionality (Must Pass)
- [ ] App launches successfully on iPhone
- [ ] Widget can be added to Lock Screen
- [ ] Widget tap completes tasks without opening app
- [ ] Pet evolution system works correctly
- [ ] Data persists between sessions
- [ ] Privacy Policy is accessible and complete

#### iOS Integration (Must Pass)
- [ ] Uses system widgets framework properly
- [ ] Respects iOS notification and widget guidelines
- [ ] Handles low power mode gracefully
- [ ] Memory usage is reasonable (< 50MB typical)
- [ ] No crashes during normal operation

#### User Experience (Must Pass)
- [ ] Intuitive navigation and task creation
- [ ] Clear visual feedback for all actions
- [ ] Helpful empty states and onboarding
- [ ] Professional visual design quality
- [ ] All text readable and properly localized

### Performance Benchmarks
- **Widget tap response**: < 1 second
- **App launch time**: < 3 seconds
- **Task creation**: < 2 seconds
- **Memory usage**: < 50MB standard operation
- **Battery impact**: Minimal (optimized for Lock Screen use)

---

## 💡 Reviewer Tips

### Testing Environment
- **Device**: iPhone 12 or newer recommended (iOS 17 support)
- **Time**: Test at different times of day to see time-based behavior
- **Duration**: Allow 10-15 minutes for thorough testing

### Common Questions Answered

**Q: Why iPhone only?**
A: Lock Screen widgets are optimized for iPhone form factor and usage patterns.

**Q: Does this collect user data?**
A: No, all data stays on device. Privacy policy clearly states this.

**Q: Is this a game?**
A: No, it's a productivity app with optional pet progression for motivation.

**Q: Does the widget work offline?**
A: Yes, completely offline. Only Privacy Policy requires internet (with local fallback).

### Red Flags to Look For (Should Not Occur)
- ❌ App crashes on launch
- ❌ Widget doesn't respond to taps
- ❌ Data lost between app sessions
- ❌ Privacy Policy inaccessible
- ❌ Excessive memory usage or battery drain
- ❌ iPad installation (should be blocked)

---

## 🆘 Support Information

If reviewers encounter issues:

1. **Reset test data**: Delete and reinstall app
2. **Widget issues**: Remove and re-add widget to Lock Screen
3. **Common iOS troubleshooting**: Restart device if needed

The app is designed to work reliably out of the box with no configuration required.

---

**App Version**: 1.0
**iOS Requirements**: 17.0+
**Device Support**: iPhone only
**Languages**: English
**Category**: Productivity