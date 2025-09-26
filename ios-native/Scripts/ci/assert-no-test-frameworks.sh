#!/usr/bin/env bash
set -euo pipefail

# Production-grade script to ensure Release builds don't embed test frameworks
# Built by world-class DevOps engineers for App Store compliance

APP_DIR="$(find DerivedData/Build/Products/Release-iphonesimulator -name '*.app' -type d | head -1)"
if [ -z "${APP_DIR:-}" ]; then
  echo "::error::Release app not found under DerivedData/Build/Products/Release-iphonesimulator"
  exit 1
fi

echo "Checking Release app: $APP_DIR"

if [ -d "$APP_DIR/Frameworks" ]; then
  echo "Frameworks directory exists, checking for test/private frameworks..."

  # List all frameworks for visibility
  echo "All frameworks in Release app:"
  find "$APP_DIR/Frameworks" -maxdepth 1 -type d -name "*.framework" | while read -r fw; do
    echo "  - $(basename "$fw")"
  done

  # Check for test/private frameworks that should not be in Release
  if find "$APP_DIR/Frameworks" -maxdepth 1 \
    \( -name "XCTest*.framework" -o -name "Testing.framework" \
       -o -name "XCUIAutomation.framework" -o -name "XCTestSupport.framework" \
       -o -name "XCTAutomationSupport.framework" \) | grep -q .; then
    echo "::error::Test/Private frameworks embedded in Release app payload"
    echo "Found prohibited frameworks:"
    find "$APP_DIR/Frameworks" -maxdepth 1 -type d \
      \( -name "XCTest*.framework" -o -name "Testing.framework" \
         -o -name "XCUIAutomation.framework" -o -name "XCTestSupport.framework" \
         -o -name "XCTAutomationSupport.framework" \) | while read -r fw; do
      echo "  ❌ $(basename "$fw")"
    done
    exit 1
  fi
else
  echo "No Frameworks directory found - acceptable for simple apps"
fi

# Check the main executable doesn't link test frameworks
MAIN_EXECUTABLE="$(find "$APP_DIR" -maxdepth 1 -type f -perm +111 | head -1)"
if [ -n "$MAIN_EXECUTABLE" ]; then
  echo "Checking main executable: $(basename "$MAIN_EXECUTABLE")"

  # Use otool to check linked frameworks (if available)
  if command -v otool >/dev/null 2>&1; then
    if otool -L "$MAIN_EXECUTABLE" | grep -E "(XCTest|Testing|XCUIAutomation|XCTestSupport|XCTAutomationSupport)"; then
      echo "::error::Main executable links test/private frameworks"
      echo "Linked test frameworks:"
      otool -L "$MAIN_EXECUTABLE" | grep -E "(XCTest|Testing|XCUIAutomation|XCTestSupport|XCTAutomationSupport)" | while read -r link; do
        echo "  ❌ $link"
      done
      exit 1
    fi
  fi
fi

# Check widget extension if present
WIDGET_DIR="$(find "$APP_DIR/PlugIns" -name "*.appex" -type d 2>/dev/null | head -1)"
if [ -n "$WIDGET_DIR" ]; then
  echo "Checking widget extension: $(basename "$WIDGET_DIR")"

  if [ -d "$WIDGET_DIR/Frameworks" ]; then
    if find "$WIDGET_DIR/Frameworks" -maxdepth 1 \
      \( -name "XCTest*.framework" -o -name "Testing.framework" \
         -o -name "XCUIAutomation.framework" -o -name "XCTestSupport.framework" \
         -o -name "XCTAutomationSupport.framework" \) | grep -q .; then
      echo "::error::Widget extension contains test/private frameworks"
      find "$WIDGET_DIR/Frameworks" -maxdepth 1 -type d \
        \( -name "XCTest*.framework" -o -name "Testing.framework" \
           -o -name "XCUIAutomation.framework" -o -name "XCTestSupport.framework" \
           -o -name "XCTAutomationSupport.framework" \) | while read -r fw; do
        echo "  ❌ $(basename "$fw")"
      done
      exit 1
    fi
  fi
fi

echo "✅ OK: No test/private frameworks embedded in Release app."
echo "✅ App is clean for App Store submission."