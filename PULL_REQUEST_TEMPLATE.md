# Pull Request Template

## 📝 Description

Brief description of the changes in this PR.

## 🎯 Type of Change

- [ ] 🐛 Bug fix (non-breaking change which fixes an issue)
- [ ] ✨ New feature (non-breaking change which adds functionality)
- [ ] 💥 Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] 📚 Documentation (changes to documentation only)
- [ ] 🔧 Maintenance (dependency updates, CI changes, etc.)

## 🏗 Architecture Impact

- [ ] Changes to SharedKit framework
- [ ] Widget implementation updates
- [ ] App UI modifications
- [ ] Data persistence changes
- [ ] App Intents modifications

## ✅ Checklist

### Code Quality
- [ ] Code follows Swift style guidelines
- [ ] SwiftLint passes without warnings
- [ ] All tests pass (`xcodebuild test`)
- [ ] No hardcoded secrets or sensitive data

### Functionality
- [ ] iOS 17+ compatibility maintained
- [ ] Widget timeline refreshes properly
- [ ] App Group storage works correctly
- [ ] Pet evolution logic is correct
- [ ] App Intents function as expected

### Testing
- [ ] Added unit tests for new functionality
- [ ] Manual testing completed on device/simulator
- [ ] Widget testing on lock screen
- [ ] Edge cases covered (timezone changes, app backgrounding, etc.)

### Documentation
- [ ] Code is properly documented with comments
- [ ] README updated if necessary
- [ ] API changes documented
- [ ] Breaking changes noted in description

## 🧪 Testing

Describe how you tested your changes:

- [ ] Unit tests
- [ ] Manual testing on simulator
- [ ] Manual testing on device
- [ ] Widget testing
- [ ] Timeline validation

### Test Devices/Simulators
- [ ] iPhone 15 Simulator (iOS 17.0)
- [ ] iPhone Physical Device (iOS version: ___)
- [ ] iPad (if applicable)

## 📱 Widget Testing

If widget changes were made:
- [ ] Lock screen circular widget displays correctly
- [ ] Lock screen rectangular widget shows 3 rows properly
- [ ] Interactive buttons (Complete/Snooze/Mark-Next) work
- [ ] Home screen widgets display properly
- [ ] Timeline updates occur hourly

## 🎨 Pet Evolution Testing

If pet evolution changes were made:
- [ ] All 16 stages display correctly
- [ ] Point thresholds are accurate
- [ ] Asset pipeline fallbacks work
- [ ] Stage progression/regression functions properly

## 📊 Performance Impact

- [ ] No significant performance degradation
- [ ] Memory usage is reasonable
- [ ] Widget timeline generation is efficient
- [ ] App startup time not affected

## 🔒 Security Considerations

- [ ] No secrets committed to repository
- [ ] App Group configuration is secure
- [ ] Entitlements are minimal and necessary
- [ ] Data stays within App Group sandbox

## 📸 Screenshots

Include screenshots/videos if UI changes were made:

<!--
Add screenshots here showing:
- Before/after comparisons
- Widget layouts
- Pet evolution stages
- Any new UI elements
-->

## 🔗 Related Issues

Closes #(issue number)
Relates to #(issue number)

## 📋 Additional Notes

Any additional context, concerns, or considerations for reviewers.

## 🤖 Claude Code Review

This PR will be automatically reviewed by Claude Code for:
- Swift best practices
- iOS-specific patterns
- Architecture adherence
- Security considerations
- Performance implications

---

**Reviewer Checklist:**
- [ ] Code review completed
- [ ] Architecture review completed
- [ ] Security review completed
- [ ] Testing verification completed
- [ ] Documentation review completed