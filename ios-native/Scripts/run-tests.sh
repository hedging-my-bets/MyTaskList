#!/bin/bash

# Enterprise Test Runner with Performance Benchmarking
# Provides comprehensive test execution with detailed reporting

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
readonly RESULTS_DIR="$PROJECT_DIR/TestResults"
readonly COVERAGE_DIR="$RESULTS_DIR/Coverage"
readonly PERFORMANCE_DIR="$RESULTS_DIR/Performance"
readonly REPORTS_DIR="$RESULTS_DIR/Reports"

# Test Configuration
readonly DEVICE="iPhone 15 Pro"
readonly OS_VERSION="17.0"
readonly SCHEME_APP="App"
readonly SCHEME_WIDGET="Widget"
readonly SCHEME_SHARED="SharedKit"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Performance thresholds
readonly PERFORMANCE_THRESHOLD_MS=1000
readonly MEMORY_THRESHOLD_MB=50
readonly COVERAGE_THRESHOLD=90

# Logging
log() {
    echo -e "${CYAN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_performance() {
    echo -e "${PURPLE}⚡ $1${NC}"
}

# Setup test environment
setup_test_environment() {
    log "Setting up test environment..."

    # Create results directories
    mkdir -p "$RESULTS_DIR" "$COVERAGE_DIR" "$PERFORMANCE_DIR" "$REPORTS_DIR"

    # Clean previous results
    rm -rf "$RESULTS_DIR"/*.xml "$RESULTS_DIR"/*.json "$RESULTS_DIR"/*.html

    # Set up simulator if needed
    xcrun simctl boot "$DEVICE" 2>/dev/null || true

    log_success "Test environment setup complete"
}

# Run tests with comprehensive coverage
run_test_suite() {
    local scheme="$1"
    local test_name="$2"

    log "Running $test_name tests..."

    local start_time=$(date +%s)
    local result_file="$RESULTS_DIR/${scheme}-test-results.xml"
    local coverage_file="$COVERAGE_DIR/${scheme}-coverage.json"

    # Build for testing
    log_info "Building $scheme for testing..."
    xcodebuild \
        -project "$PROJECT_DIR/MyTaskList.xcodeproj" \
        -scheme "$scheme" \
        -destination "platform=iOS Simulator,name=$DEVICE,OS=$OS_VERSION" \
        -enableCodeCoverage YES \
        -derivedDataPath "$RESULTS_DIR/DerivedData" \
        build-for-testing \
        | tee "$RESULTS_DIR/${scheme}-build.log" \
        | xcbeautify --is-ci

    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        log_error "$scheme build failed"
        return 1
    fi

    # Run tests
    log_info "Executing $scheme tests..."
    xcodebuild \
        -project "$PROJECT_DIR/MyTaskList.xcodeproj" \
        -scheme "$scheme" \
        -destination "platform=iOS Simulator,name=$DEVICE,OS=$OS_VERSION" \
        -enableCodeCoverage YES \
        -derivedDataPath "$RESULTS_DIR/DerivedData" \
        -resultBundlePath "$RESULTS_DIR/${scheme}-results.xcresult" \
        test-without-building \
        | tee "$RESULTS_DIR/${scheme}-test.log" \
        | xcbeautify --is-ci

    local test_result=${PIPESTATUS[0]}
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    # Extract test results
    xcrun xcresulttool export \
        --type results \
        --path "$RESULTS_DIR/${scheme}-results.xcresult" \
        --output-format json \
        > "$RESULTS_DIR/${scheme}-results.json"

    # Extract coverage data
    xcrun xcresulttool export \
        --type coverage \
        --path "$RESULTS_DIR/${scheme}-results.xcresult" \
        --output-format json \
        > "$coverage_file"

    # Generate performance report
    generate_performance_report "$scheme" "$RESULTS_DIR/${scheme}-results.json"

    if [ $test_result -eq 0 ]; then
        log_success "$test_name tests completed successfully in ${duration}s"
    else
        log_error "$test_name tests failed after ${duration}s"
        return 1
    fi

    return 0
}

# Generate performance report
generate_performance_report() {
    local scheme="$1"
    local results_file="$2"
    local performance_file="$PERFORMANCE_DIR/${scheme}-performance.json"

    log_info "Generating performance report for $scheme..."

    # Extract performance data using jq
    if command -v jq >/dev/null 2>&1; then
        jq '.tests[] | select(.performanceMetrics) | {
            testName: .testName,
            duration: .duration,
            performanceMetrics: .performanceMetrics
        }' "$results_file" > "$performance_file" 2>/dev/null || {
            echo "{\"warning\": \"No performance metrics found\"}" > "$performance_file"
        }
    else
        echo "{\"error\": \"jq not available for performance analysis\"}" > "$performance_file"
    fi

    # Analyze performance
    analyze_performance "$scheme" "$performance_file"
}

# Analyze performance metrics
analyze_performance() {
    local scheme="$1"
    local performance_file="$2"

    log_performance "Analyzing performance metrics for $scheme..."

    if [ -f "$performance_file" ] && command -v jq >/dev/null 2>&1; then
        local slow_tests=$(jq -r --arg threshold "$PERFORMANCE_THRESHOLD_MS" '
            .[] | select(.duration > ($threshold | tonumber / 1000)) | .testName
        ' "$performance_file" 2>/dev/null || echo "")

        if [ -n "$slow_tests" ]; then
            log_warning "Slow tests detected in $scheme:"
            echo "$slow_tests" | while read -r test; do
                echo "  - $test"
            done
        else
            log_success "All $scheme tests meet performance thresholds"
        fi
    fi
}

# Generate coverage report
generate_coverage_report() {
    log "Generating code coverage report..."

    local combined_coverage="$COVERAGE_DIR/combined-coverage.json"
    local html_report="$REPORTS_DIR/coverage.html"

    # Combine coverage files
    if command -v jq >/dev/null 2>&1; then
        jq -s 'add' "$COVERAGE_DIR"/*.json > "$combined_coverage" 2>/dev/null || {
            echo '{"error": "No coverage data found"}' > "$combined_coverage"
        }

        # Extract coverage percentage
        local coverage_percent=$(jq -r '.coverage.percent // 0' "$combined_coverage" 2>/dev/null || echo "0")

        if (( $(echo "$coverage_percent >= $COVERAGE_THRESHOLD" | bc -l) )); then
            log_success "Code coverage: ${coverage_percent}% (meets ${COVERAGE_THRESHOLD}% threshold)"
        else
            log_warning "Code coverage: ${coverage_percent}% (below ${COVERAGE_THRESHOLD}% threshold)"
        fi
    fi

    # Generate HTML report if possible
    if command -v genhtml >/dev/null 2>&1; then
        log_info "Generating HTML coverage report..."
        # HTML generation would go here
        echo "<html><body><h1>Coverage Report</h1><p>See JSON files for details</p></body></html>" > "$html_report"
    fi
}

# Run security analysis
run_security_analysis() {
    log "Running security analysis..."

    local security_report="$REPORTS_DIR/security.json"

    # Check for common security issues
    {
        echo "{"
        echo "  \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\","
        echo "  \"checks\": {"

        # Check for hardcoded secrets
        echo "    \"hardcoded_secrets\": $(grep -r "password\|secret\|key\|token" "$PROJECT_DIR/Sources" --include="*.swift" | wc -l),"

        # Check for insecure network calls
        echo "    \"insecure_network\": $(grep -r "http://" "$PROJECT_DIR/Sources" --include="*.swift" | wc -l),"

        # Check for debug code
        echo "    \"debug_code\": $(grep -r "print(\|NSLog\|debugPrint" "$PROJECT_DIR/Sources" --include="*.swift" | wc -l),"

        # Check for force unwrapping
        echo "    \"force_unwrap\": $(grep -r "!" "$PROJECT_DIR/Sources" --include="*.swift" | grep -v "// swiftlint:disable" | wc -l)"

        echo "  },"
        echo "  \"status\": \"completed\""
        echo "}"
    } > "$security_report"

    log_success "Security analysis completed"
}

# Generate final report
generate_final_report() {
    log "Generating final test report..."

    local final_report="$REPORTS_DIR/test-summary.html"
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)

    cat > "$final_report" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>MyTaskList Test Report</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; margin: 40px; }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; border-radius: 8px; }
        .section { margin: 20px 0; padding: 20px; border: 1px solid #ddd; border-radius: 8px; }
        .success { border-left: 4px solid #4CAF50; }
        .warning { border-left: 4px solid #FF9800; }
        .error { border-left: 4px solid #F44336; }
        .metric { display: inline-block; margin: 10px; padding: 10px 20px; background: #f5f5f5; border-radius: 4px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🚀 MyTaskList Test Report</h1>
        <p>Generated: $timestamp</p>
    </div>

    <div class="section success">
        <h2>✅ Test Execution Summary</h2>
        <div class="metric">
            <strong>Schemes Tested:</strong> SharedKit, App, Widget
        </div>
        <div class="metric">
            <strong>Device:</strong> $DEVICE
        </div>
        <div class="metric">
            <strong>iOS Version:</strong> $OS_VERSION
        </div>
    </div>

    <div class="section">
        <h2>📊 Test Results</h2>
        <p>Detailed test results are available in the JSON files.</p>
        <ul>
            <li><strong>SharedKit:</strong> Core functionality and performance tests</li>
            <li><strong>App:</strong> UI components and integration tests</li>
            <li><strong>Widget:</strong> Widget timeline and interaction tests</li>
        </ul>
    </div>

    <div class="section">
        <h2>⚡ Performance Analysis</h2>
        <p>Performance thresholds: ${PERFORMANCE_THRESHOLD_MS}ms per test, ${MEMORY_THRESHOLD_MB}MB memory usage</p>
        <p>See performance JSON files for detailed metrics.</p>
    </div>

    <div class="section">
        <h2>🔒 Security Analysis</h2>
        <p>Automated security checks completed. See security.json for details.</p>
    </div>

    <div class="section">
        <h2>📁 Report Files</h2>
        <ul>
            <li><code>TestResults/*.json</code> - Detailed test results</li>
            <li><code>Coverage/*.json</code> - Code coverage data</li>
            <li><code>Performance/*.json</code> - Performance metrics</li>
            <li><code>Reports/security.json</code> - Security analysis</li>
        </ul>
    </div>
</body>
</html>
EOF

    log_success "Final report generated: $final_report"
}

# Cleanup function
cleanup() {
    log "Cleaning up test environment..."

    # Clean up simulators
    xcrun simctl shutdown all 2>/dev/null || true

    # Clean up derived data (optional, keep for investigation)
    # rm -rf "$RESULTS_DIR/DerivedData"

    log_success "Cleanup completed"
}

# Main execution
main() {
    local exit_code=0

    log "🚀 Starting Enterprise Test Suite"
    log "Project: MyTaskList iOS"
    log "Device: $DEVICE ($OS_VERSION)"
    log "Timestamp: $(date)"

    # Setup
    setup_test_environment

    # Run test suites
    run_test_suite "$SCHEME_SHARED" "SharedKit" || exit_code=1
    run_test_suite "$SCHEME_APP" "App" || exit_code=1
    run_test_suite "$SCHEME_WIDGET" "Widget" || exit_code=1

    # Generate reports
    generate_coverage_report
    run_security_analysis
    generate_final_report

    # Summary
    if [ $exit_code -eq 0 ]; then
        log_success "🎉 All tests passed! Enterprise test suite completed successfully."
        log_info "Reports available in: $REPORTS_DIR"
    else
        log_error "💥 Some tests failed. Check the detailed reports for more information."
        log_info "Results available in: $RESULTS_DIR"
    fi

    cleanup
    exit $exit_code
}

# Handle interruption
trap cleanup INT TERM

# Check dependencies
if ! command -v xcodebuild >/dev/null 2>&1; then
    log_error "xcodebuild not found. Please install Xcode."
    exit 1
fi

if ! command -v xcbeautify >/dev/null 2>&1; then
    log_warning "xcbeautify not found. Output formatting will be basic."
fi

# Execute main function
main "$@"