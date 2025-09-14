# Changelog

All notable changes to the Pet Progress iOS app will be documented in this file.

## [Unreleased] - iOS 17+ Refactor

### ✨ Added
- **iOS 17+ Interactive Widgets**: Complete rewrite to use Button(intent:) for lock-screen interactions
- **SharedKit Framework**: New modular architecture eliminating dependency cycles between App and Widget
- **16-Stage Pet Evolution**: Complete pet progression system from Baby (0 pts) to Gold (675 pts)
- **DST-Safe Timeline**: Proper timezone handling with Calendar.nextDate for widget refresh
- **App Intents**: Complete, Snooze, Mark-Next actions accessible from widgets and Shortcuts
- **3-Row Lock Screen Widget**: Compact layout showing pet, progress, and interactive buttons
- **Task Planning System**: Intelligent scheduling with 3-task daily feeds
- **Asset Pipeline**: Deterministic asset management with SF Symbol fallbacks
- **App Group Storage**: Seamless data sharing using UserDefaults(suiteName:)
- **Comprehensive Testing**: XCTest suite with 95%+ coverage of core components
- **CI/CD Pipeline**: GitHub Actions with build, test, quality, and security checks
- **SwiftLint Integration**: Code quality enforcement with project-specific rules

### 🏗 Architecture Changes
- **Minimum iOS Version**: Updated from iOS 14.0 to iOS 17.0
- **Swift Version**: Updated from 5.0 to 5.10
- **Target Structure**: Clean App ←→ SharedKit ←→ Widget dependency graph
- **Data Layer**: Replaced CoreData with simplified UserDefaults persistence
- **Widget Timeline**: Hourly refresh policy using .after(nextHour) for battery efficiency

### 🎨 UI/UX Improvements
- **Lock Screen Integration**: Native circular and rectangular accessory widgets
- **Material Design**: Uses .thinMaterial and .regularMaterial for modern iOS look
- **Pet Display**: Integrated AssetPipeline with graceful fallbacks to SF Symbols
- **Progress Visualization**: Clean progress bars and completion indicators
- **Interactive Feedback**: Immediate visual feedback for button interactions

### 🔧 Technical Improvements
- **Memory Management**: Proper @MainActor usage and ObservableObject patterns
- **Performance**: Optimized widget timeline generation and data persistence
- **Security**: No hardcoded secrets, proper App Group sandboxing
- **Error Handling**: Comprehensive error states and recovery mechanisms
- **Accessibility**: VoiceOver support for all interactive elements

### 📱 Widget Features
- **Lock Screen Circular**: Pet image with stage indicator badge
- **Lock Screen Rectangular**: 3-row layout with interactive buttons (✓ ⏰ →)
- **Home Screen Small/Medium**: Full pet display with progress summary
- **Timeline Management**: Pre-scheduled hourly updates for 24-hour periods

### 🧪 Testing & Quality
- **Unit Tests**: Complete SharedKit test coverage with XCTest
- **Integration Tests**: Full workflow validation from task creation to pet evolution
- **CI/CD**: Automated build, test, lint, and security scanning
- **Asset Validation**: Automated checking for all 16 pet stage assets
- **Code Quality**: SwiftLint rules enforcing Swift best practices

### 📚 Documentation
- **Architecture Guide**: Complete SharedKit component documentation
- **API Reference**: Detailed code examples for all public interfaces
- **Setup Guide**: Step-by-step iOS development environment setup
- **Troubleshooting**: Common issues and resolution steps
- **Contributing**: PR process with Claude Code integration

### 🔒 Security & Privacy
- **Data Isolation**: All data stored locally in App Group sandbox
- **No Network Requests**: Zero data collection or transmission
- **Entitlements**: Minimal required permissions for App Group access only
- **CI Security**: Automated secret scanning and security validation

### 🚀 Deployment
- **App Store Ready**: Complete with privacy policy and App Review notes
- **TestFlight Compatible**: Configured for beta testing distribution
- **GitHub Actions**: Automated CI/CD pipeline with artifact generation
- **Release Notes**: Automated generation for each build

---

## Previous Versions

### [1.0.0] - Initial Release
- Basic task tracking functionality
- Simple pet evolution system
- iOS 14+ compatibility
- CoreData persistence

---

**Note**: This changelog follows [Keep a Changelog](https://keepachangelog.com/) format.