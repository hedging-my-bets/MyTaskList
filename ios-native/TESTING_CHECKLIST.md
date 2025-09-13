# Pet Progress - Pre-Launch Testing Checklist

## 📱 Device Testing (iOS 17.0+)

### Core Functionality
- [ ] App launches without crashes
- [ ] Pet displays correctly on Today screen
- [ ] Progress bar shows correct XP/threshold ratio
- [ ] Task creation (recurring + one-off) works
- [ ] Task completion updates progress
- [ ] Settings persist (grace period, reset time, rollover)

### Widget Testing
- [ ] Lock Screen widget appears and functions
- [ ] Widget shows correct pet stage and progress
- [ ] Task list displays 3 items around current time
- [ ] Complete/Snooze buttons work from Lock Screen
- [ ] Widget updates only on hourly timeline ticks (not immediately)

### Evolution Testing
- [ ] Pet evolves at correct XP thresholds
- [ ] Pet de-evolves when XP goes negative
- [ ] Gold stage (stage 19) is terminal - no further evolution
- [ ] Daily closeout applies bonuses/penalties correctly

### Data Persistence
- [ ] App data survives app restart
- [ ] Widget data syncs with main app
- [ ] Task completions persist across launches
- [ ] Settings changes are remembered

### Edge Cases
- [ ] DST timezone transitions handled correctly
- [ ] Midnight rollover works properly
- [ ] App behavior during low battery
- [ ] Memory usage stays reasonable
- [ ] Background app refresh disabled (no polling)

## ♿ Accessibility Testing

### VoiceOver
- [ ] Pet stage announced correctly ("Stage 5: Bear")
- [ ] Progress announced ("75% to next stage")
- [ ] Task completion status announced
- [ ] All buttons have proper labels
- [ ] Navigation works with VoiceOver

### Dynamic Type
- [ ] Text scales properly with Dynamic Type settings
- [ ] Layout doesn't break with larger text
- [ ] Buttons remain accessible with large text

### High Contrast
- [ ] Progress bars visible in both light/dark modes
- [ ] Check marks have sufficient contrast
- [ ] Text remains readable in all modes

## 🔒 Security & Privacy

### Data Handling
- [ ] No network requests made (check with Charles Proxy)
- [ ] All data stored locally only
- [ ] No analytics or tracking code
- [ ] App Group sharing works correctly

### Permissions
- [ ] No unnecessary permissions requested
- [ ] Only App Group entitlement present
- [ ] No background modes enabled

## 🧪 Automated Tests

### Run Test Suite
```bash
xcodebuild test -scheme PetProgress -destination "platform=iOS Simulator,name=iPhone 15"
```

### Test Coverage
- [ ] DST timezone handling tests pass
- [ ] Intent idempotency tests pass
- [ ] Asset loading tests pass
- [ ] Evolution logic tests pass

## 📸 Screenshot Capture

### Required Screenshots (6.5" iPhone)
1. [ ] Lock Screen widget (rectangular) - showing pet + tasks
2. [ ] Today screen - pet evolution display
3. [ ] Planner screen - recurring tasks view
4. [ ] Settings screen - configuration options

### Capture Process
1. Use Xcode Simulator (iPhone 15 Pro)
2. Set to 6.5" display mode
3. Take screenshots using Xcode → Debug → View UI Hierarchy
4. Or use Simulator menu → Device → Take Screenshot

## 🚀 Final Submission Prep

### App Store Connect
- [ ] Create app record in App Store Connect
- [ ] Upload all 4 screenshots
- [ ] Add description and keywords
- [ ] Set pricing and availability
- [ ] Add App Review notes about hourly widget updates

### Privacy Policy
- [ ] Host PrivacyPolicy.md at public URL
- [ ] Add URL to App Store Connect
- [ ] Verify "Data Not Collected" messaging

### Build Archive
- [ ] Clean build (Product → Clean)
- [ ] Archive (Product → Archive)
- [ ] Validate archive in Organizer
- [ ] Upload to App Store Connect

## ✅ Pre-Launch Checklist

- [ ] All automated tests pass
- [ ] Manual testing complete on physical device
- [ ] Accessibility testing passed
- [ ] Screenshots captured and uploaded
- [ ] Privacy policy hosted and linked
- [ ] App Store Connect record created
- [ ] Archive uploaded and processing
- [ ] TestFlight build tested (if using beta testing)

## 🚨 Common Issues to Watch For

1. **Widget not appearing**: Check widget gallery, ensure proper entitlements
2. **Assets not loading**: Verify asset catalog is included in both targets
3. **Signing issues**: Confirm Team ID and provisioning profiles
4. **Privacy policy**: Must be hosted publicly, not just local file
5. **Hourly updates**: Verify widget only refreshes on timeline ticks

