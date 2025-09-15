# PetProgress - Manual Test Script (Critical Path P0)

## Test Environment Setup
- **Device**: iPhone 15 (physical device preferred)
- **iOS**: 17.0+ required for interactive widgets
- **Build**: Release configuration
- **Network**: Wi-Fi connected for Privacy Policy links

---

## Test 1: Fresh Install & Grace Minutes Setup

### Steps:
1. **Fresh Install**
   - Delete app if previously installed
   - Install from Xcode or TestFlight
   - Launch app for first time

2. **Grace Minutes Configuration**
   - Tap Settings → Grace Period
   - Verify default is 30 minutes
   - Change to 60 minutes
   - Exit Settings and return
   - Verify setting persisted

### Expected Results:
✅ App launches without crashes
✅ Settings shows Grace Period with help text
✅ Grace minutes setting persists across app restarts
✅ Help text: "Tasks completed within this window count as on-time"

---

## Test 2: Task Creation & Hour Bucketing

### Steps:
1. **Create 6 Tasks Across Day**
   - Morning: "Coffee & Planning" at 8:00 AM
   - Morning: "Deep Work Session" at 9:30 AM
   - Afternoon: "Team Standup" at 1:00 PM
   - Afternoon: "Project Review" at 3:30 PM
   - Evening: "Family Dinner" at 6:00 PM
   - Evening: "Evening Reflection" at 8:30 PM

2. **Verify Hour Bucketing**
   - Check tasks appear in correct time slots
   - Verify nearest-hour logic (±2 hour window)

### Expected Results:
✅ All 6 tasks created successfully
✅ Tasks appear in chronological order
✅ Hour bucketing groups nearby tasks correctly
✅ Widget shows tasks relevant to current hour window

---

## Test 3: Lock Screen Widget Interactions

### Steps:
1. **Add Widget to Lock Screen**
   - Long press Lock Screen → Customize
   - Add PetProgress widget (Rectangular)
   - Position below clock

2. **Test Interactive Buttons**
   - From Lock Screen (device locked)
   - Tap ○ circle on first incomplete task
   - Verify task becomes completed (✓ or struck through)
   - Tap ✗ X on second task
   - Verify task is marked skipped
   - Tap ▶ chevron right
   - Verify widget shows next window of tasks
   - Tap ◀ chevron left
   - Verify widget returns to previous window

3. **Test No App Launch**
   - Verify all interactions happen WITHOUT opening the app
   - App should remain closed throughout

### Expected Results:
✅ Widget buttons respond on Lock Screen
✅ Completion: Task shows ✓ checkmark or strike-through
✅ Skip: Task shows ✗ or grayed out
✅ Navigation: ▶ / ◀ cycles through task windows
✅ NO app launch during any interaction

---

## Test 4: Pet Evolution & Lock Screen Visibility

### Steps:
1. **Force Level Up**
   - Complete enough tasks to trigger stage advancement
   - Or manually adjust XP in debug if available

2. **Verify Evolution on Lock Screen**
   - Check AccessoryCircular widget shows new pet image
   - Verify stage indicator updates (S1 → S2, etc.)
   - Check progress ring reflects current stage progress

3. **Test De-evolution (if applicable)**
   - Skip multiple tasks to trigger stage reduction
   - Verify pet image changes to lower stage

### Expected Results:
✅ Pet image updates in Lock Screen widget after level up
✅ Stage indicator (S1-S16) reflects current evolution stage
✅ Progress ring shows accurate progress to next stage
✅ Changes visible within next hourly widget refresh

---

## Test 5: Settings & Privacy Policy

### Steps:
1. **Privacy Policy Access**
   - Open app → Settings
   - Tap "Privacy Policy"
   - Verify opens in Safari or in-app browser
   - Try both online URL and offline fallback

2. **Verify No Login Required**
   - Ensure policy loads without account creation
   - Verify accessibility within ≤2 taps from Settings

### Expected Results:
✅ Privacy Policy link present in Settings
✅ Opens policy content (online preferred, offline fallback)
✅ No login/account required
✅ Accessible in ≤2 taps: Settings → Privacy Policy

---

## Test 6: iPhone-Only Validation

### Steps:
1. **Build Validation**
   - Check build logs for iPad icon warnings
   - Verify no "missing iPad icon" messages
   - Confirm app only appears in iPhone App Store section

2. **Device Family Check**
   - Verify app only installs on iPhone
   - Check project settings: TARGETED_DEVICE_FAMILY = 1

### Expected Results:
✅ No iPad icon warnings in build logs
✅ App Store lists app as iPhone-only
✅ Build passes asset validation
✅ App targets iPhone exclusively

---

## Test 7: Deep Links & Widget URLs

### Steps:
1. **Widget Tap Navigation**
   - From Lock Screen widget, tap task row (not buttons)
   - Verify app opens to specific task or context
   - Check URL scheme: `petprogress://task?dayKey=...&hour=...`

2. **URL Parsing**
   - Test app handles deep links correctly
   - Verify navigation to appropriate task/view

### Expected Results:
✅ Tapping widget row opens app (not buttons)
✅ App navigates to correct task/context
✅ Deep link URLs parse correctly
✅ No crashes on malformed URLs

---

## Test 8: Haptics & Celebrations

### Steps:
1. **Task Completion Haptics**
   - Complete task from within app (not widget)
   - Feel for success haptic feedback
   - Verify notification-style vibration

2. **Level-Up Celebration**
   - Trigger pet evolution within app
   - Check for enhanced haptic pattern
   - Verify confetti or celebration animation
   - Test sound effects (if implemented)

### Expected Results:
✅ Task completion: Success haptic feedback
✅ Level up: Enhanced celebration haptics
✅ In-app celebrations feel delightful and responsive
✅ Celebration system toggleable in Settings (if implemented)

---

## Test 9: Task Templates

### Steps:
1. **Template Access**
   - Go to Add Task screen
   - Tap "Use Template" button
   - Verify template selection sheet appears

2. **Template Application**
   - Select "Morning Routine" template
   - Verify multiple tasks added with proper times
   - Check task details are pre-filled
   - Confirm ≤2 taps total: Use Template → Select

### Expected Results:
✅ Template button accessible in Add Task flow
✅ Template selection shows 3-5+ professional templates
✅ Applying template creates multiple related tasks
✅ Template application requires ≤2 taps

---

## Test 10: Hourly Timeline Validation

### Steps:
1. **Time-based Testing**
   - Set device clock to 1 minute before top of hour
   - Wait for hour transition
   - Verify widget updates at :00 minutes
   - Check timeline policy aligns with hour boundaries

2. **Grace Period Behavior**
   - Complete task within grace window
   - Verify counts as on-time
   - Complete task outside grace window
   - Verify late completion handling

### Expected Results:
✅ Widget updates precisely at top of hour (:00)
✅ Grace period affects task completion timing
✅ Nearest-hour tasks display correctly
✅ Timeline refreshes hourly (not every 15 minutes)

---

## Critical Acceptance Criteria Summary

**Widget Interactivity**: ○, ✗, ▶, ◀ buttons work on Lock Screen without app launch
**Nearest Hour**: Widget displays hour-relevant tasks, updates hourly
**Pet Evolution**: Stage art updates with level changes, visible on Lock Screen
**Settings Compliance**: Privacy Policy reachable, Grace minutes functional
**iPhone-only**: No iPad warnings, binary targets iPhone exclusively
**CI Stability**: Build passes with stable destinations, no asset warnings
**Haptics**: In-app completion feels responsive with celebration system
**Templates**: Professional templates accessible in ≤2 taps
**Deep Links**: Widget taps navigate to app correctly
**Atomic Operations**: No race conditions, widget reflects changes consistently

---

## Test Completion Checklist

- [ ] Test 1: Fresh Install & Grace Minutes ✅/❌
- [ ] Test 2: Task Creation & Hour Bucketing ✅/❌
- [ ] Test 3: Lock Screen Widget Interactions ✅/❌
- [ ] Test 4: Pet Evolution Visibility ✅/❌
- [ ] Test 5: Settings & Privacy Policy ✅/❌
- [ ] Test 6: iPhone-Only Validation ✅/❌
- [ ] Test 7: Deep Links & Widget URLs ✅/❌
- [ ] Test 8: Haptics & Celebrations ✅/❌
- [ ] Test 9: Task Templates ✅/❌
- [ ] Test 10: Hourly Timeline Validation ✅/❌

**Overall Status**: ✅ PASS / ❌ FAIL

**Notes**: _Document any issues or edge cases discovered_

---

## Final Sign-off

**Tester**: ________________
**Date**: ________________
**Build**: ________________
**Ready for App Store**: ✅ YES / ❌ NO
