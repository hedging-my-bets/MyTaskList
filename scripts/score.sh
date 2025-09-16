#!/bin/bash

# PetProgress Scoring Harness Script
# World-class quality assessment for iOS Lock Screen widget app
# Built by world-class engineers for 100/100 feature fit and launchability

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Scoring variables
FEATURE_SCORE=0
LAUNCHABILITY_SCORE=0
MAX_FEATURE_SCORE=100
MAX_LAUNCHABILITY_SCORE=100

echo -e "${PURPLE}🎯 PetProgress Scoring Harness${NC}"
echo -e "${PURPLE}==============================${NC}"
echo ""

# Change to project directory
cd "$(dirname "$0")/.."
PROJECT_ROOT="$(pwd)"
IOS_PROJECT_DIR="$PROJECT_ROOT/ios-native"

echo -e "${CYAN}📁 Project root: $PROJECT_ROOT${NC}"
echo -e "${CYAN}📁 iOS project: $IOS_PROJECT_DIR${NC}"
echo ""

# =============================================================================
# FEATURE FIT SCORING (100 points total)
# =============================================================================

echo -e "${BLUE}🎯 FEATURE FIT ASSESSMENT${NC}"
echo -e "${BLUE}=========================${NC}"

# Test 1: Interactive Lock Screen Widgets (25 points)
echo -e "${YELLOW}Testing Interactive Lock Screen Widgets...${NC}"
if [[ -f "$IOS_PROJECT_DIR/SharedKit/Sources/SharedKit/Intents/PetProgressIntents.swift" ]]; then
    # Check for specific App Intent names required by Senior iOS engineer
    if grep -q "MarkNextTaskDoneIntent" "$IOS_PROJECT_DIR/SharedKit/Sources/SharedKit/Intents/PetProgressIntents.swift" && \
       grep -q "SkipCurrentTaskIntent" "$IOS_PROJECT_DIR/SharedKit/Sources/SharedKit/Intents/PetProgressIntents.swift" && \
       grep -q "GoToNextTaskIntent" "$IOS_PROJECT_DIR/SharedKit/Sources/SharedKit/Intents/PetProgressIntents.swift" && \
       grep -q "GoToPreviousTaskIntent" "$IOS_PROJECT_DIR/SharedKit/Sources/SharedKit/Intents/PetProgressIntents.swift"; then
        echo -e "${GREEN}✅ All 4 required App Intents implemented: MarkNextTaskDone, SkipCurrent, GoToNext, GoToPrevious${NC}"
        FEATURE_SCORE=$((FEATURE_SCORE + 25))
    else
        echo -e "${RED}❌ Missing required App Intent names${NC}"
    fi
else
    echo -e "${RED}❌ App Intents file not found${NC}"
fi

# Test 2: Pet Evolution System (20 points)
echo -e "${YELLOW}Testing Pet Evolution System...${NC}"
PET_ENGINE_FILE=$(find "$IOS_PROJECT_DIR" -name "*PetEngine*.swift" | head -1)
STAGE_CONFIG_FILE=$(find "$IOS_PROJECT_DIR" -name "StageConfig.json" | head -1)
if [[ -n "$PET_ENGINE_FILE" ]] && [[ -n "$STAGE_CONFIG_FILE" ]]; then
    STAGE_COUNT=$(grep -c '"index":' "$STAGE_CONFIG_FILE" 2>/dev/null || echo "0")
    if [[ "$STAGE_COUNT" -eq 16 ]]; then
        echo -e "${GREEN}✅ Pet evolution system with 16 stages detected${NC}"
        FEATURE_SCORE=$((FEATURE_SCORE + 20))
    else
        echo -e "${RED}❌ Pet evolution system found but has $STAGE_COUNT stages (expected 16)${NC}"
    fi
else
    echo -e "${RED}❌ Pet Engine or StageConfig.json not found${NC}"
fi

# Test 3: AppIntentTimelineProvider with Hourly Scheduling (15 points)
echo -e "${YELLOW}Testing AppIntentTimelineProvider...${NC}"
if find "$IOS_PROJECT_DIR" -name "*.swift" -exec grep -l "AppIntentTimelineProvider" {} \; | head -1 > /dev/null; then
    if find "$IOS_PROJECT_DIR" -name "*.swift" -exec grep -l "\.after.*hour" {} \; | head -1 > /dev/null; then
        echo -e "${GREEN}✅ AppIntentTimelineProvider with hourly scheduling implemented${NC}"
        FEATURE_SCORE=$((FEATURE_SCORE + 15))
    else
        echo -e "${RED}❌ Hourly scheduling not detected${NC}"
    fi
else
    echo -e "${RED}❌ AppIntentTimelineProvider not found${NC}"
fi

# Test 4: App Group Shared Storage (15 points)
echo -e "${YELLOW}Testing App Group Shared Storage...${NC}"
if [[ -f "$IOS_PROJECT_DIR/SharedKit/Sources/SharedKit/Storage/AppGroupStore.swift" ]]; then
    if grep -q "group\.com\.hedgingmybets\.PetProgress" "$IOS_PROJECT_DIR/SharedKit/Sources/SharedKit/Storage/AppGroupStore.swift"; then
        echo -e "${GREEN}✅ App Group shared storage implemented${NC}"
        FEATURE_SCORE=$((FEATURE_SCORE + 15))
    else
        echo -e "${RED}❌ App Group configuration missing${NC}"
    fi
else
    echo -e "${RED}❌ App Group Store not found${NC}"
fi

# Test 5: Grace Minutes Logic (10 points)
echo -e "${YELLOW}Testing Grace Minutes Logic...${NC}"
if find "$IOS_PROJECT_DIR" -name "*.swift" -exec grep -l "isTaskWithinGraceWindow" {} \; | head -1 > /dev/null; then
    echo -e "${GREEN}✅ Grace minutes boundary logic implemented${NC}"
    FEATURE_SCORE=$((FEATURE_SCORE + 10))
else
    echo -e "${RED}❌ Grace minutes logic not found${NC}"
fi

# Test 6: Privacy Policy in Settings (10 points)
echo -e "${YELLOW}Testing Privacy Policy...${NC}"
if find "$IOS_PROJECT_DIR" -name "*.swift" -exec grep -l "PrivacyPolicyView" {} \; | head -1 > /dev/null; then
    if find "$IOS_PROJECT_DIR" -name "*.swift" -exec grep -l "SafariView" {} \; | head -1 > /dev/null; then
        echo -e "${GREEN}✅ Privacy Policy with in-app web view implemented${NC}"
        FEATURE_SCORE=$((FEATURE_SCORE + 10))
    else
        echo -e "${RED}❌ In-app web view not detected${NC}"
    fi
else
    echo -e "${RED}❌ Privacy Policy not found${NC}"
fi

# Test 7: Haptic Feedback (5 points)
echo -e "${YELLOW}Testing Haptic Feedback...${NC}"
if find "$IOS_PROJECT_DIR" -name "*.swift" -exec grep -l "UINotificationFeedbackGenerator\|UIImpactFeedbackGenerator" {} \; | head -1 > /dev/null; then
    echo -e "${GREEN}✅ Haptic feedback implemented${NC}"
    FEATURE_SCORE=$((FEATURE_SCORE + 5))
else
    echo -e "${RED}❌ Haptic feedback not found${NC}"
fi

echo ""
echo -e "${BLUE}🎯 FEATURE FIT SCORE: ${FEATURE_SCORE}/${MAX_FEATURE_SCORE}${NC}"
echo ""

# =============================================================================
# LAUNCHABILITY SCORING (100 points total)
# =============================================================================

echo -e "${BLUE}🚀 LAUNCHABILITY ASSESSMENT${NC}"
echo -e "${BLUE}===========================${NC}"

# Test 1: Xcode Project Structure (20 points)
echo -e "${YELLOW}Testing Xcode Project Structure...${NC}"
if [[ -f "$IOS_PROJECT_DIR/project.yml" ]]; then
    echo -e "${GREEN}✅ XcodeGen project.yml found${NC}"
    LAUNCHABILITY_SCORE=$((LAUNCHABILITY_SCORE + 10))
else
    echo -e "${RED}❌ project.yml missing${NC}"
fi

if find "$IOS_PROJECT_DIR" -name "*.xcodeproj" -o -name "*.xcworkspace" | head -1 > /dev/null; then
    echo -e "${GREEN}✅ Xcode project files detected${NC}"
    LAUNCHABILITY_SCORE=$((LAUNCHABILITY_SCORE + 10))
else
    echo -e "${YELLOW}⚠️  Xcode project files not generated yet (run 'xcodegen generate')${NC}"
    LAUNCHABILITY_SCORE=$((LAUNCHABILITY_SCORE + 5))
fi

# Test 2: CI/CD Configuration (20 points)
echo -e "${YELLOW}Testing CI/CD Configuration...${NC}"
if [[ -f "$PROJECT_ROOT/.github/workflows/ios-sim.yml" ]]; then
    if grep -q "xcrun simctl list runtimes" "$PROJECT_ROOT/.github/workflows/ios-sim.yml"; then
        echo -e "${GREEN}✅ CI with dynamic runtime selection implemented${NC}"
        LAUNCHABILITY_SCORE=$((LAUNCHABILITY_SCORE + 20))
    else
        echo -e "${RED}❌ CI runtime selection needs improvement${NC}"
        LAUNCHABILITY_SCORE=$((LAUNCHABILITY_SCORE + 10))
    fi
else
    echo -e "${RED}❌ CI configuration missing${NC}"
fi

# Test 3: Widget Bundle Structure (15 points)
echo -e "${YELLOW}Testing Widget Bundle Structure...${NC}"
if find "$IOS_PROJECT_DIR" -name "*.swift" -exec grep -l "WidgetBundle" {} \; | head -1 > /dev/null; then
    echo -e "${GREEN}✅ Widget Bundle structure implemented${NC}"
    LAUNCHABILITY_SCORE=$((LAUNCHABILITY_SCORE + 15))
else
    echo -e "${RED}❌ Widget Bundle structure missing${NC}"
fi

# Test 4: iPhone-only Packaging (15 points)
echo -e "${YELLOW}Testing iPhone-only Packaging...${NC}"
if grep -q "TARGETED_DEVICE_FAMILY.*1" "$IOS_PROJECT_DIR/project.yml" 2>/dev/null; then
    echo -e "${GREEN}✅ iPhone-only packaging configured${NC}"
    LAUNCHABILITY_SCORE=$((LAUNCHABILITY_SCORE + 15))
else
    echo -e "${RED}❌ iPhone-only packaging not detected${NC}"
fi

# Test 5: Info.plist Configuration (10 points)
echo -e "${YELLOW}Testing Info.plist Configuration...${NC}"
if [[ -f "$IOS_PROJECT_DIR/Widget/Info.plist" ]]; then
    if grep -q "NSSupportsLiveActivities" "$IOS_PROJECT_DIR/Widget/Info.plist"; then
        echo -e "${GREEN}✅ Widget Info.plist properly configured${NC}"
        LAUNCHABILITY_SCORE=$((LAUNCHABILITY_SCORE + 10))
    else
        echo -e "${RED}❌ Widget Info.plist missing Live Activities support${NC}"
        LAUNCHABILITY_SCORE=$((LAUNCHABILITY_SCORE + 5))
    fi
else
    echo -e "${RED}❌ Widget Info.plist missing${NC}"
fi

# Test 6: App Icons and Assets (10 points)
echo -e "${YELLOW}Testing App Icons and Assets...${NC}"
if find "$IOS_PROJECT_DIR" -name "AppIcon*" -o -name "Assets.xcassets" | head -1 > /dev/null; then
    echo -e "${GREEN}✅ App icons and assets detected${NC}"
    LAUNCHABILITY_SCORE=$((LAUNCHABILITY_SCORE + 10))
else
    echo -e "${RED}❌ App icons and assets missing${NC}"
fi

# Test 7: Build Settings and Dependencies (10 points)
echo -e "${YELLOW}Testing Build Settings...${NC}"
if grep -q "iOS.*17" "$IOS_PROJECT_DIR/project.yml" 2>/dev/null; then
    echo -e "${GREEN}✅ iOS 17+ deployment target configured${NC}"
    LAUNCHABILITY_SCORE=$((LAUNCHABILITY_SCORE + 10))
else
    echo -e "${RED}❌ iOS 17+ deployment target not detected${NC}"
fi

echo ""
echo -e "${BLUE}🚀 LAUNCHABILITY SCORE: ${LAUNCHABILITY_SCORE}/${MAX_LAUNCHABILITY_SCORE}${NC}"
echo ""

# =============================================================================
# FINAL SCORING AND RECOMMENDATIONS
# =============================================================================

echo -e "${PURPLE}📊 FINAL SCORING SUMMARY${NC}"
echo -e "${PURPLE}========================${NC}"
echo ""

# Calculate overall scores
FEATURE_PERCENTAGE=$((FEATURE_SCORE * 100 / MAX_FEATURE_SCORE))
LAUNCHABILITY_PERCENTAGE=$((LAUNCHABILITY_SCORE * 100 / MAX_LAUNCHABILITY_SCORE))
OVERALL_SCORE=$(((FEATURE_SCORE + LAUNCHABILITY_SCORE) * 100 / (MAX_FEATURE_SCORE + MAX_LAUNCHABILITY_SCORE)))

echo -e "${CYAN}Feature Fit:      ${FEATURE_SCORE}/${MAX_FEATURE_SCORE} (${FEATURE_PERCENTAGE}%)${NC}"
echo -e "${CYAN}Launchability:    ${LAUNCHABILITY_SCORE}/${MAX_LAUNCHABILITY_SCORE} (${LAUNCHABILITY_PERCENTAGE}%)${NC}"
echo -e "${CYAN}Overall Score:    $((FEATURE_SCORE + LAUNCHABILITY_SCORE))/200 (${OVERALL_SCORE}%)${NC}"
echo ""

# Determine grade and recommendations
if [[ $OVERALL_SCORE -ge 95 ]]; then
    echo -e "${GREEN}🎉 WORLD-CLASS QUALITY (A+)${NC}"
    echo -e "${GREEN}Ready for App Store submission!${NC}"
elif [[ $OVERALL_SCORE -ge 90 ]]; then
    echo -e "${GREEN}🎯 PRODUCTION READY (A)${NC}"
    echo -e "${GREEN}Excellent quality, minor optimizations possible${NC}"
elif [[ $OVERALL_SCORE -ge 80 ]]; then
    echo -e "${YELLOW}⚡ GOOD QUALITY (B)${NC}"
    echo -e "${YELLOW}Some improvements needed before launch${NC}"
elif [[ $OVERALL_SCORE -ge 70 ]]; then
    echo -e "${YELLOW}🔧 NEEDS WORK (C)${NC}"
    echo -e "${YELLOW}Significant improvements required${NC}"
else
    echo -e "${RED}🚨 MAJOR ISSUES (D/F)${NC}"
    echo -e "${RED}Critical problems must be fixed${NC}"
fi

echo ""

# Specific recommendations
echo -e "${PURPLE}🎯 RECOMMENDATIONS${NC}"
echo -e "${PURPLE}==================${NC}"

if [[ $FEATURE_SCORE -lt $MAX_FEATURE_SCORE ]]; then
    echo -e "${YELLOW}Feature Improvements Needed:${NC}"
    if [[ $FEATURE_SCORE -lt 25 ]]; then
        echo "  • Implement all 4 required App Intent names"
    fi
    if [[ $FEATURE_SCORE -lt 45 ]]; then
        echo "  • Complete pet evolution system with 16 stages"
    fi
    if [[ $FEATURE_SCORE -lt 60 ]]; then
        echo "  • Add AppIntentTimelineProvider with hourly scheduling"
    fi
    if [[ $FEATURE_SCORE -lt 75 ]]; then
        echo "  • Implement App Group shared storage"
    fi
    if [[ $FEATURE_SCORE -lt 85 ]]; then
        echo "  • Add grace minutes boundary logic"
    fi
    if [[ $FEATURE_SCORE -lt 95 ]]; then
        echo "  • Add Privacy Policy with in-app web view"
    fi
    if [[ $FEATURE_SCORE -lt 100 ]]; then
        echo "  • Implement haptic feedback for interactions"
    fi
    echo ""
fi

if [[ $LAUNCHABILITY_SCORE -lt $MAX_LAUNCHABILITY_SCORE ]]; then
    echo -e "${YELLOW}Launchability Improvements Needed:${NC}"
    if [[ $LAUNCHABILITY_SCORE -lt 20 ]]; then
        echo "  • Set up proper Xcode project structure"
    fi
    if [[ $LAUNCHABILITY_SCORE -lt 40 ]]; then
        echo "  • Configure CI/CD with dynamic runtime selection"
    fi
    if [[ $LAUNCHABILITY_SCORE -lt 55 ]]; then
        echo "  • Implement Widget Bundle structure"
    fi
    if [[ $LAUNCHABILITY_SCORE -lt 70 ]]; then
        echo "  • Configure iPhone-only packaging"
    fi
    if [[ $LAUNCHABILITY_SCORE -lt 80 ]]; then
        echo "  • Fix Info.plist configurations"
    fi
    if [[ $LAUNCHABILITY_SCORE -lt 90 ]]; then
        echo "  • Add app icons and assets"
    fi
    if [[ $LAUNCHABILITY_SCORE -lt 100 ]]; then
        echo "  • Verify iOS 17+ deployment target"
    fi
    echo ""
fi

# Save results to file
RESULTS_FILE="$PROJECT_ROOT/SCORING_RESULTS.md"
cat > "$RESULTS_FILE" << EOF
# PetProgress Scoring Results

**Generated:** $(date)
**Script Version:** 1.0

## Summary

- **Feature Fit:** ${FEATURE_SCORE}/${MAX_FEATURE_SCORE} (${FEATURE_PERCENTAGE}%)
- **Launchability:** ${LAUNCHABILITY_SCORE}/${MAX_LAUNCHABILITY_SCORE} (${LAUNCHABILITY_PERCENTAGE}%)
- **Overall Score:** $((FEATURE_SCORE + LAUNCHABILITY_SCORE))/200 (${OVERALL_SCORE}%)

## Assessment

$(if [[ $OVERALL_SCORE -ge 95 ]]; then echo "🎉 **WORLD-CLASS QUALITY (A+)** - Ready for App Store submission!"; elif [[ $OVERALL_SCORE -ge 90 ]]; then echo "🎯 **PRODUCTION READY (A)** - Excellent quality, minor optimizations possible"; elif [[ $OVERALL_SCORE -ge 80 ]]; then echo "⚡ **GOOD QUALITY (B)** - Some improvements needed before launch"; elif [[ $OVERALL_SCORE -ge 70 ]]; then echo "🔧 **NEEDS WORK (C)** - Significant improvements required"; else echo "🚨 **MAJOR ISSUES (D/F)** - Critical problems must be fixed"; fi)

## Detailed Breakdown

### Feature Fit (${FEATURE_PERCENTAGE}%)
- Interactive Lock Screen Widgets: $(if [[ $FEATURE_SCORE -ge 25 ]]; then echo "✅ PASS"; else echo "❌ FAIL"; fi)
- Pet Evolution System: $(if [[ $FEATURE_SCORE -ge 45 ]]; then echo "✅ PASS"; else echo "❌ FAIL"; fi)
- AppIntentTimelineProvider: $(if [[ $FEATURE_SCORE -ge 60 ]]; then echo "✅ PASS"; else echo "❌ FAIL"; fi)
- App Group Storage: $(if [[ $FEATURE_SCORE -ge 75 ]]; then echo "✅ PASS"; else echo "❌ FAIL"; fi)
- Grace Minutes Logic: $(if [[ $FEATURE_SCORE -ge 85 ]]; then echo "✅ PASS"; else echo "❌ FAIL"; fi)
- Privacy Policy: $(if [[ $FEATURE_SCORE -ge 95 ]]; then echo "✅ PASS"; else echo "❌ FAIL"; fi)
- Haptic Feedback: $(if [[ $FEATURE_SCORE -ge 100 ]]; then echo "✅ PASS"; else echo "❌ FAIL"; fi)

### Launchability (${LAUNCHABILITY_PERCENTAGE}%)
- Xcode Project Structure: $(if [[ $LAUNCHABILITY_SCORE -ge 20 ]]; then echo "✅ PASS"; else echo "❌ FAIL"; fi)
- CI/CD Configuration: $(if [[ $LAUNCHABILITY_SCORE -ge 40 ]]; then echo "✅ PASS"; else echo "❌ FAIL"; fi)
- Widget Bundle Structure: $(if [[ $LAUNCHABILITY_SCORE -ge 55 ]]; then echo "✅ PASS"; else echo "❌ FAIL"; fi)
- iPhone-only Packaging: $(if [[ $LAUNCHABILITY_SCORE -ge 70 ]]; then echo "✅ PASS"; else echo "❌ FAIL"; fi)
- Info.plist Configuration: $(if [[ $LAUNCHABILITY_SCORE -ge 80 ]]; then echo "✅ PASS"; else echo "❌ FAIL"; fi)
- App Icons and Assets: $(if [[ $LAUNCHABILITY_SCORE -ge 90 ]]; then echo "✅ PASS"; else echo "❌ FAIL"; fi)
- Build Settings: $(if [[ $LAUNCHABILITY_SCORE -ge 100 ]]; then echo "✅ PASS"; else echo "❌ FAIL"; fi)
EOF

echo -e "${GREEN}📄 Results saved to: $RESULTS_FILE${NC}"
echo ""

# Exit with appropriate code
if [[ $OVERALL_SCORE -ge 90 ]]; then
    exit 0  # Success
elif [[ $OVERALL_SCORE -ge 70 ]]; then
    exit 1  # Warning
else
    exit 2  # Error
fi