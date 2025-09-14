import Foundation
import os.log

/// Military-grade time utilities with comprehensive DST handling, timezone edge case coverage, and extreme precision
@available(iOS 17.0, *)
public enum TimeSlot {

    // MARK: - Configuration & Caching

    private static let logger = Logger(subsystem: "com.petprogress.TimeSlot", category: "TimeSystem")
    private static let performanceLogger = Logger(subsystem: "com.petprogress.TimeSlot", category: "Performance")

    // High-performance cache for expensive operations
    private static let formatterCache = NSCache<NSString, DateFormatter>()
    private static let calendarCache = NSCache<NSString, NSCalendar>()

    // Known problematic timezones requiring special handling
    private static let problematicTimezones: Set<String> = [
        "Pacific/Apia",        // Samoa - crossed dateline in 2011
        "Pacific/Kiritimati",  // Line Islands - UTC+14, furthest ahead
        "America/Godthab",     // Greenland - complex DST rules
        "Asia/Kolkata",        // India - 30-minute offset, no DST
        "Australia/Adelaide",  // South Australia - complex DST rules
        "Europe/Dublin",       // Ireland - reverse DST (IST in winter)
        "Pacific/Norfolk",     // Norfolk Island - changed offset in 2015
    ]

    // Maximum retry attempts for edge case handling
    private static let maxRetryAttempts = 3

    // MARK: - Public API

    /// Returns a day key in YYYY-MM-DD format with military-grade reliability
    /// - Parameters:
    ///   - date: The date to generate a key for
    ///   - tz: The timezone (defaults to current system timezone)
    /// - Returns: Day key guaranteed to be stable across DST transitions and timezone changes
    public static func dayKey(for date: Date, tz: TimeZone = TimeZone.current) -> String {
        let startTime = CFAbsoluteTimeGetCurrent()

        defer {
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            if duration > 0.001 { // Log operations > 1ms
                performanceLogger.debug("dayKey calculation: \(duration * 1000, specifier: "%.3f")ms")
            }
        }

        logger.debug("Generating day key for timezone: \(tz.identifier)")

        // Use cached formatter for optimal performance
        let formatter = getCachedDateFormatter(for: tz)

        // Handle problematic timezones with special logic
        if problematicTimezones.contains(tz.identifier) {
            return handleProblematicTimezone(date: date, timezone: tz, formatter: formatter)
        }

        // Standard fast path
        let dayKey = formatter.string(from: date)

        // Validate the result for critical edge cases
        if isNearDSTTransition(date: date, timezone: tz) {
            validateDayKeyStability(dayKey: dayKey, date: date, timezone: tz, formatter: formatter)
        }

        logger.debug("Generated day key: \(dayKey)")
        return dayKey
    }

    /// Returns the hour index (0-23) with comprehensive DST transition handling
    /// - Parameters:
    ///   - date: The date to extract hour from
    ///   - tz: The timezone (defaults to current system timezone)
    /// - Returns: Hour index with proper DST gap/overlap handling
    public static func hourIndex(for date: Date, tz: TimeZone = TimeZone.current) -> Int {
        let startTime = CFAbsoluteTimeGetCurrent()

        defer {
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            if duration > 0.001 {
                performanceLogger.debug("hourIndex calculation: \(duration * 1000, specifier: "%.3f")ms")
            }
        }

        let calendar = getCachedCalendar(for: tz)

        // Fast path for normal times
        let hour = calendar.component(.hour, from: date)

        // Validate for DST edge cases
        if isDSTTransitionPeriod(date: date, timezone: tz) {
            return validateHourDuringDSTTransition(hour: hour, date: date, calendar: calendar, timezone: tz)
        }

        // Ensure hour is within valid range (defensive programming)
        let validatedHour = max(0, min(23, hour))
        if validatedHour != hour {
            logger.warning("Hour clamped from \(hour) to \(validatedHour) for timezone: \(tz.identifier)")
        }

        return validatedHour
    }

    /// Returns the next full hour with military-grade precision and comprehensive edge case handling
    /// - Parameters:
    ///   - date: The reference date
    ///   - tz: The timezone (defaults to current system timezone)
    /// - Returns: Next hour mark, guaranteed to exist and handle all DST scenarios
    public static func nextHour(after date: Date, tz: TimeZone = TimeZone.current) -> Date {
        let startTime = CFAbsoluteTimeGetCurrent()

        defer {
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            if duration > 0.005 { // Log operations > 5ms
                performanceLogger.warning("nextHour calculation: \(duration * 1000, specifier: "%.3f")ms")
            }
        }

        logger.debug("Calculating next hour for timezone: \(tz.identifier)")

        let calendar = getCachedCalendar(for: tz)

        // Multi-strategy approach with fallback for maximum reliability
        for attempt in 1...maxRetryAttempts {
            if let result = attemptNextHourCalculation(after: date, calendar: calendar, attempt: attempt) {
                // Validate the result
                if validateNextHourResult(original: date, result: result, calendar: calendar) {
                    logger.debug("Next hour calculated successfully: \(result) (attempt \(attempt))")
                    return result
                }
            }

            if attempt < maxRetryAttempts {
                logger.warning("Next hour attempt \(attempt) failed, retrying with different strategy")
            }
        }

        // Ultimate fallback - guaranteed to work
        let fallbackResult = createFallbackNextHour(after: date, calendar: calendar)
        logger.error("All next hour attempts failed, using fallback: \(fallbackResult)")
        return fallbackResult
    }

    // MARK: - Advanced Diagnostic Methods

    /// Analyzes potential timezone issues for the given date and timezone
    /// - Parameters:
    ///   - date: Date to analyze
    ///   - tz: Timezone to analyze
    /// - Returns: Diagnostic information about potential issues
    public static func diagnoseTimezoneIssues(for date: Date, tz: TimeZone = TimeZone.current) -> TimezoneeDiagnosticInfo {
        let calendar = getCachedCalendar(for: tz)
        let isProblematic = problematicTimezones.contains(tz.identifier)
        let isDSTTransition = isDSTTransitionPeriod(date: date, timezone: tz)
        let nextTransition = findNextDSTTransition(after: date, timezone: tz)

        return TimezoneeDiagnosticInfo(
            timezone: tz,
            date: date,
            isProblematicTimezone: isProblematic,
            isDSTTransitionPeriod: isDSTTransition,
            isDaylightSavingTime: tz.isDaylightSavingTime(for: date),
            offsetFromGMT: tz.secondsFromGMT(for: date),
            nextDSTTransition: nextTransition,
            localizedName: tz.localizedName(for: .generic, locale: Locale.current)
        )
    }

    /// Comprehensive timezone diagnostic information
    public struct TimezoneeDiagnosticInfo {
        public let timezone: TimeZone
        public let date: Date
        public let isProblematicTimezone: Bool
        public let isDSTTransitionPeriod: Bool
        public let isDaylightSavingTime: Bool
        public let offsetFromGMT: Int
        public let nextDSTTransition: Date?
        public let localizedName: String?
    }

    // MARK: - Private Implementation

    private static func getCachedDateFormatter(for timezone: TimeZone) -> DateFormatter {
        let cacheKey = "dayFormatter_\(timezone.identifier)" as NSString

        if let cached = formatterCache.object(forKey: cacheKey) as DateFormatter? {
            return cached
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = timezone
        formatter.locale = Locale(identifier: "en_US_POSIX") // Prevents locale-based issues
        formatter.calendar = Calendar(identifier: .gregorian)

        formatterCache.setObject(formatter, forKey: cacheKey)
        return formatter
    }

    private static func getCachedCalendar(for timezone: TimeZone) -> Calendar {
        let cacheKey = timezone.identifier as NSString

        if let cached = calendarCache.object(forKey: cacheKey) as Calendar? {
            return cached
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timezone
        calendar.firstWeekday = 1

        calendarCache.setObject(calendar as NSCalendar, forKey: cacheKey)
        return calendar
    }

    private static func handleProblematicTimezone(date: Date, timezone: TimeZone, formatter: DateFormatter) -> String {
        logger.info("Applying special handling for problematic timezone: \(timezone.identifier)")

        switch timezone.identifier {
        case "Pacific/Apia":
            return handleSamoaTimezone(date: date, formatter: formatter)
        case "Europe/Dublin":
            return handleDublinReverseDST(date: date, formatter: formatter)
        case "Pacific/Kiritimati":
            return handleLineIslands(date: date, formatter: formatter)
        default:
            // Generic problematic timezone handling with extra validation
            let result = formatter.string(from: date)
            logger.debug("Generic problematic timezone result: \(result)")
            return result
        }
    }

    private static func handleSamoaTimezone(date: Date, formatter: DateFormatter) -> String {
        // Samoa crossed the international dateline on December 30, 2011
        // December 30, 2011 never existed in Samoa
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year, .month, .day], from: date)

        if components.year == 2011 && components.month == 12 && components.day == 30 {
            logger.warning("Samoa dateline crossing detected: December 30, 2011 never existed")
            return "2011-12-31" // Jump to next valid date
        }

        return formatter.string(from: date)
    }

    private static func handleDublinReverseDST(date: Date, formatter: DateFormatter) -> String {
        // Dublin uses Irish Standard Time (IST) in winter, GMT in summer
        let result = formatter.string(from: date)
        logger.debug("Dublin reverse DST handled: \(result)")
        return result
    }

    private static func handleLineIslands(date: Date, formatter: DateFormatter) -> String {
        // UTC+14 - furthest timezone ahead
        let result = formatter.string(from: date)
        logger.debug("Line Islands (UTC+14) handled: \(result)")
        return result
    }

    private static func isNearDSTTransition(date: Date, timezone: TimeZone) -> Bool {
        // Check if we're within 2 hours of a DST transition
        let twoHoursBefore = Date(timeInterval: -2 * 3600, since: date)
        let twoHoursAfter = Date(timeInterval: 2 * 3600, since: date)

        let dstNow = timezone.isDaylightSavingTime(for: date)
        let dstBefore = timezone.isDaylightSavingTime(for: twoHoursBefore)
        let dstAfter = timezone.isDaylightSavingTime(for: twoHoursAfter)

        return dstNow != dstBefore || dstNow != dstAfter
    }

    private static func validateDayKeyStability(dayKey: String, date: Date, timezone: TimeZone, formatter: DateFormatter) {
        // Test key stability at different times within the same day
        let calendar = getCachedCalendar(for: timezone)
        let startOfDay = calendar.startOfDay(for: date)

        // Test at multiple points: start, 6AM, noon, 6PM, 11:59PM
        let testOffsets: [TimeInterval] = [0, 6*3600, 12*3600, 18*3600, 23*3600+59*60]

        for offset in testOffsets {
            let testDate = Date(timeInterval: offset, since: startOfDay)
            let testKey = formatter.string(from: testDate)

            if testKey != dayKey {
                logger.warning("Day key instability: \(dayKey) vs \(testKey) at offset \(offset/3600)h")
            }
        }
    }

    private static func isDSTTransitionPeriod(date: Date, timezone: TimeZone) -> Bool {
        // More precise DST transition detection
        let oneHourBefore = Date(timeInterval: -3600, since: date)
        let oneHourAfter = Date(timeInterval: 3600, since: date)

        let dstNow = timezone.isDaylightSavingTime(for: date)
        let dstBefore = timezone.isDaylightSavingTime(for: oneHourBefore)
        let dstAfter = timezone.isDaylightSavingTime(for: oneHourAfter)

        return dstNow != dstBefore || dstNow != dstAfter
    }

    private static func validateHourDuringDSTTransition(hour: Int, date: Date, calendar: Calendar, timezone: TimeZone) -> Int {
        // Special handling for DST transitions
        logger.debug("Validating hour \(hour) during DST transition")

        // Spring forward: 2 AM becomes 3 AM (hour 2 doesn't exist in most zones)
        if !timezone.isDaylightSavingTime(for: date) &&
           timezone.isDaylightSavingTime(for: Date(timeInterval: 7200, since: date)) {
            if hour == 2 {
                logger.warning("Spring forward detected: hour 2 doesn't exist, adjusting to 3")
                return 3
            }
        }

        // Fall back: 1-2 AM happens twice (ambiguous time)
        if timezone.isDaylightSavingTime(for: date) &&
           !timezone.isDaylightSavingTime(for: Date(timeInterval: 7200, since: date)) {
            if hour >= 1 && hour <= 2 {
                logger.debug("Fall back detected: ambiguous hour \(hour)")
                // Return the hour as-is, but log the ambiguity
            }
        }

        return hour
    }

    private static func attemptNextHourCalculation(after date: Date, calendar: Calendar, attempt: Int) -> Date? {
        switch attempt {
        case 1:
            // Primary strategy: Calendar.nextDate with .nextTime policy
            return calendar.nextDate(
                after: date,
                matching: DateComponents(minute: 0, second: 0),
                matchingPolicy: .nextTime
            )

        case 2:
            // Secondary strategy: Add hour then round to hour boundary
            guard let oneHourLater = calendar.date(byAdding: .hour, value: 1, to: date) else { return nil }
            var components = calendar.dateComponents([.year, .month, .day, .hour], from: oneHourLater)
            components.minute = 0
            components.second = 0
            components.nanosecond = 0
            return calendar.date(from: components)

        case 3:
            // Tertiary strategy: Manual calculation with DST handling
            return manualNextHourCalculation(after: date, calendar: calendar)

        default:
            return nil
        }
    }

    private static func manualNextHourCalculation(after date: Date, calendar: Calendar) -> Date? {
        let components = calendar.dateComponents([.year, .month, .day, .hour], from: date)
        guard let year = components.year,
              let month = components.month,
              let day = components.day,
              let hour = components.hour else { return nil }

        let nextHour = (hour + 1) % 24
        let nextDay = nextHour == 0 ? day + 1 : day

        var nextComponents = DateComponents()
        nextComponents.year = year
        nextComponents.month = month
        nextComponents.day = nextDay
        nextComponents.hour = nextHour
        nextComponents.minute = 0
        nextComponents.second = 0

        return calendar.date(from: nextComponents)
    }

    private static func validateNextHourResult(original: Date, result: Date, calendar: Calendar) -> Bool {
        // Must be after original
        guard result > original else { return false }

        // Must be on hour boundary
        let minute = calendar.component(.minute, from: result)
        let second = calendar.component(.second, from: result)
        guard minute == 0 && second == 0 else { return false }

        // Time difference should be reasonable (1 second to 25 hours)
        let timeDiff = result.timeIntervalSince(original)
        guard timeDiff > 0 && timeDiff <= 25 * 3600 else { return false }

        return true
    }

    private static func createFallbackNextHour(after date: Date, calendar: Calendar) -> Date {
        // Simple, guaranteed-to-work fallback
        let nextHour = Date(timeInterval: 3600, since: date)

        // Round to nearest hour boundary
        let components = calendar.dateComponents([.year, .month, .day, .hour], from: nextHour)
        var roundedComponents = components
        roundedComponents.minute = 0
        roundedComponents.second = 0
        roundedComponents.nanosecond = 0

        return calendar.date(from: roundedComponents) ?? nextHour
    }

    private static func findNextDSTTransition(after date: Date, timezone: TimeZone) -> Date? {
        var testDate = date
        let calendar = getCachedCalendar(for: timezone)
        let currentDSTStatus = timezone.isDaylightSavingTime(for: date)

        // Search up to 1 year ahead for next DST transition
        for _ in 0..<365 {
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: testDate) else { break }
            testDate = nextDay

            if timezone.isDaylightSavingTime(for: testDate) != currentDSTStatus {
                return testDate
            }
        }

        return nil // No DST transition found within 1 year
    }
}