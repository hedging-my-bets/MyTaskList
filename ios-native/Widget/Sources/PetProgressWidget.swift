import WidgetKit
import SwiftUI
import SharedKit
import AppIntents
import os.log
import Combine

/// Enterprise-grade timeline provider with comprehensive error handling and performance optimization
@available(iOS 17.0, *)
struct Provider: TimelineProvider {

    // MARK: - Performance & Logging

    private let logger = Logger(subsystem: "com.petprogress.Widget", category: "Timeline")
    private let performanceLogger = Logger(subsystem: "com.petprogress.Widget", category: "Performance")

    // MARK: - Timeline Provider Implementation

    func placeholder(in context: Context) -> SimpleEntry {
        let startTime = CFAbsoluteTimeGetCurrent()

        defer {
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            performanceLogger.debug("Placeholder generation: \(duration * 1000, specifier: "%.2f")ms")
        }

        logger.debug("Generating placeholder entry")

        // Create rich placeholder data for preview
        let placeholderSlots = [
            DayModel.Slot(hour: 9, title: "Morning focus session", isDone: true),
            DayModel.Slot(hour: 14, title: "Midday productivity", isDone: false),
            DayModel.Slot(hour: 18, title: "Evening reflection", isDone: false)
        ]

        let placeholderModel = DayModel(
            key: TimeSlot.dayKey(for: Date()),
            slots: placeholderSlots,
            points: 125
        )

        return SimpleEntry(
            date: Date(),
            dayModel: placeholderModel,
            isPlaceholder: true,
            errorState: nil
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let startTime = CFAbsoluteTimeGetCurrent()

        defer {
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            performanceLogger.debug("Snapshot generation: \(duration * 1000, specifier: "%.2f")ms")
        }

        let now = Date()
        let dayKey = TimeSlot.dayKey(for: now)

        logger.debug("Generating snapshot for day: \(dayKey)")

        do {
            // Attempt to load or create day model
            let dayModel = loadOrCreateDayModel(for: dayKey, at: now)

            let entry = SimpleEntry(
                date: now,
                dayModel: dayModel,
                isPlaceholder: false,
                errorState: nil
            )

            completion(entry)
            logger.debug("Snapshot generated successfully")

        } catch {
            logger.error("Snapshot generation failed: \(error.localizedDescription)")

            // Provide fallback entry with error state
            let fallbackEntry = SimpleEntry(
                date: now,
                dayModel: DayModel(key: dayKey, points: 0),
                isPlaceholder: false,
                errorState: .dataLoadingFailed(error.localizedDescription)
            )

            completion(fallbackEntry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let startTime = CFAbsoluteTimeGetCurrent()

        defer {
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            performanceLogger.debug("Timeline generation: \(duration * 1000, specifier: "%.2f")ms")
        }

        let now = Date()
        let dayKey = TimeSlot.dayKey(for: now)

        logger.info("Generating timeline for day: \(dayKey)")

        do {
            // Load or create day model with error handling
            let dayModel = loadOrCreateDayModel(for: dayKey, at: now)

            // Generate optimized timeline entries
            let entries = generateTimelineEntries(from: dayModel, startingAt: now)

            // Calculate next refresh with advanced logic
            let nextRefresh = calculateOptimalRefreshTime(from: now, dayModel: dayModel)

            // Create timeline with appropriate policy
            let timeline = Timeline(
                entries: entries,
                policy: .after(nextRefresh)
            )

            completion(timeline)
            logger.info("Timeline generated with \(entries.count) entries, next refresh: \(nextRefresh)")

        } catch {
            logger.error("Timeline generation failed: \(error.localizedDescription)")

            // Provide minimal fallback timeline
            let fallbackEntry = SimpleEntry(
                date: now,
                dayModel: DayModel(key: dayKey, points: 0),
                isPlaceholder: false,
                errorState: .dataLoadingFailed(error.localizedDescription)
            )

            let fallbackTimeline = Timeline(
                entries: [fallbackEntry],
                policy: .after(Calendar.current.date(byAdding: .minute, value: 15, to: now) ?? now)
            )

            completion(fallbackTimeline)
        }
    }

    // MARK: - Private Implementation

    private func loadOrCreateDayModel(for dayKey: String, at date: Date) throws -> DayModel {
        // Attempt to load from AppState first (authoritative source)
        if let currentModel = SharedStore.shared.getCurrentDayModel() {
            logger.debug("Loaded day model from AppState bridge with \(currentModel.slots.count) tasks")
            return currentModel
        }

        // Fallback: attempt to load legacy DayModel
        if let existingModel = SharedStore.shared.loadDay(key: dayKey) {
            logger.debug("Loaded legacy day model with \(existingModel.slots.count) tasks")
            return existingModel
        }

        // Create fallback day model for widget display
        logger.info("Creating fallback day model for \(dayKey)")
        let fallbackSlots = [
            DayModel.Slot(hour: 9, title: "Morning task", isDone: false),
            DayModel.Slot(hour: 14, title: "Afternoon task", isDone: false),
            DayModel.Slot(hour: 18, title: "Evening task", isDone: false)
        ]

        let fallbackModel = DayModel(key: dayKey, slots: fallbackSlots, points: 0)

        // Save the fallback model
        SharedStore.shared.saveDay(fallbackModel)

        return fallbackModel
    }

    private func generateTimelineEntries(from dayModel: DayModel, startingAt date: Date) -> [SimpleEntry] {
        var entries: [SimpleEntry] = []
        let calendar = Calendar.current

        // Generate entries for key moments throughout the day
        let keyHours = [date] + generateKeyUpdateTimes(from: date, dayModel: dayModel)

        for entryDate in keyHours.prefix(10) { // Limit to 10 entries for performance
            let entry = SimpleEntry(
                date: entryDate,
                dayModel: dayModel,
                isPlaceholder: false,
                errorState: nil
            )
            entries.append(entry)
        }

        // Ensure we have at least one entry
        if entries.isEmpty {
            entries.append(SimpleEntry(
                date: date,
                dayModel: dayModel,
                isPlaceholder: false,
                errorState: nil
            ))
        }

        return entries.sorted { $0.date < $1.date }
    }

    private func generateKeyUpdateTimes(from startDate: Date, dayModel: DayModel) -> [Date] {
        let calendar = Calendar.current
        var updateTimes: [Date] = []

        // Add hourly updates for the next 8 hours
        for hour in 1...8 {
            if let futureTime = calendar.date(byAdding: .hour, value: hour, to: startDate) {
                updateTimes.append(futureTime)
            }
        }

        // Add specific times for incomplete tasks
        let currentHour = TimeSlot.hourIndex(for: startDate)
        for slot in dayModel.slots where !slot.isDone && slot.hour > currentHour {
            if let taskTime = calendar.date(bySettingHour: slot.hour, minute: 0, second: 0, of: startDate) {
                updateTimes.append(taskTime)
            }
        }

        return updateTimes
    }

    private func calculateOptimalRefreshTime(from currentDate: Date, dayModel: DayModel) -> Date {
        let calendar = Calendar.current

        // Default to next hour
        let defaultNext = TimeSlot.nextHour(after: currentDate)

        // Check if we have upcoming tasks that warrant earlier refresh
        let currentHour = TimeSlot.hourIndex(for: currentDate)
        let nextIncompleteTask = dayModel.slots.first { slot in
            !slot.isDone && slot.hour > currentHour
        }

        if let nextTask = nextIncompleteTask,
           let taskTime = calendar.date(bySettingHour: nextTask.hour, minute: 0, second: 0, of: currentDate),
           taskTime < defaultNext {
            logger.debug("Next refresh optimized for upcoming task at \(nextTask.hour):00")
            return taskTime
        }

        // Check for day boundary
        let startOfNextDay = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate)
        if defaultNext > startOfNextDay {
            logger.debug("Next refresh set to start of next day")
            return startOfNextDay
        }

        return defaultNext
    }
}

/// Enhanced timeline entry with error handling and state management
struct SimpleEntry: TimelineEntry {
    let date: Date
    let dayModel: DayModel
    let isPlaceholder: Bool
    let errorState: WidgetErrorState?

    init(date: Date, dayModel: DayModel, isPlaceholder: Bool = false, errorState: WidgetErrorState? = nil) {
        self.date = date
        self.dayModel = dayModel
        self.isPlaceholder = isPlaceholder
        self.errorState = errorState
    }
}

/// Widget error states for comprehensive error handling
enum WidgetErrorState: Equatable {
    case dataLoadingFailed(String)
    case appGroupAccessDenied
    case timelineGenerationFailed
    case networkUnavailable

    var displayMessage: String {
        switch self {
        case .dataLoadingFailed(let details):
            return "Unable to load data: \(details)"
        case .appGroupAccessDenied:
            return "App Group access denied"
        case .timelineGenerationFailed:
            return "Timeline generation failed"
        case .networkUnavailable:
            return "Network unavailable"
        }
    }

    var iconName: String {
        switch self {
        case .dataLoadingFailed:
            return "exclamationmark.triangle.fill"
        case .appGroupAccessDenied:
            return "lock.fill"
        case .timelineGenerationFailed:
            return "clock.badge.exclamationmark"
        case .networkUnavailable:
            return "wifi.slash"
        }
    }
}


struct PetProgressWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        switch widgetFamily {
        case .accessoryCircular:
            CircularLockScreenView(entry: entry)
        case .accessoryRectangular:
            RectangularLockScreenView(entry: entry)
        case .systemSmall, .systemMedium:
            StandardWidgetView(entry: entry)
        default:
            StandardWidgetView(entry: entry)
        }
    }
}

struct CircularLockScreenView: View {
    let entry: Provider.Entry
    private let engine = PetEvolutionEngine()

    var body: some View {
        ZStack {
            // Pet image in center
            Image(engine.imageName(for: entry.dayModel.points))
                .resizable()
                .scaledToFit()
                .clipShape(Circle())

            // Stage indicator
            VStack {
                Spacer()
                Text("S\(engine.stageIndex(for: entry.dayModel.points))")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(.regularMaterial, in: Capsule())
            }
        }
        .accessibilityLabel("Pet at stage \(engine.stageIndex(for: entry.dayModel.points))")
    }
}

/// Award-winning lock screen widget with pixel-perfect design and comprehensive accessibility
@available(iOS 17.0, *)
struct RectangularLockScreenView: View {
    let entry: Provider.Entry
    private let engine = PetEvolutionEngine()
    private let logger = Logger(subsystem: "com.petprogress.Widget", category: "UI")

    // MARK: - Adaptive Sizing for Dynamic Type

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityEnabled) private var accessibilityEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if let errorState = entry.errorState {
            ErrorStateView(errorState: errorState)
        } else {
            MainContentView()
        }
    }

    // MARK: - Main Content

    @ViewBuilder
    private func MainContentView() -> some View {
        VStack(spacing: adaptiveSpacing) {
            // Row 1: Pet Status with Advanced Animations
            PetStatusRow()

            // Row 2: Next Task Information
            NextTaskRow()

            // Row 3: Interactive Action Buttons
            InteractiveButtonRow()
        }
        .padding(.horizontal, adaptivePadding.horizontal)
        .padding(.vertical, adaptivePadding.vertical)
        .background(adaptiveBackground)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(comprehensiveAccessibilityLabel)
        .accessibilityHint("Double-tap to open the app for more details")
    }

    // MARK: - Pet Status Row

    @ViewBuilder
    private func PetStatusRow() -> some View {
        HStack(spacing: adaptiveSpacing) {
            // Pet Avatar with Emotional State
            PetAvatarView()

            // Stage Information
            StageInfoView()

            Spacer()

            // Task Progress Indicator
            TaskProgressView()
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func PetAvatarView() -> some View {
        let petImageName = engine.imageName(for: entry.dayModel.points, includeEmotionalVariant: true)

        ZStack {
            // Background glow for emotional states
            if engine.currentEmotionalState != .neutral {
                Circle()
                    .fill(emotionalGlowColor.opacity(0.3))
                    .frame(width: petAvatarSize.width + 4, height: petAvatarSize.height + 4)
                    .blur(radius: 2)
            }

            // Pet image with advanced rendering
            Group {
                if AssetPipeline.shared.hasAsset(named: petImageName) {
                    Image(petImageName)
                        .resizable()
                        .interpolation(.high)
                        .antialiased(true)
                } else {
                    // SF Symbol fallback with styling
                    AssetPipeline.shared.placeholderImage(for: currentStage)
                        .foregroundStyle(adaptivePetColor)
                }
            }
            .aspectRatio(contentMode: .fit)
            .frame(width: petAvatarSize.width, height: petAvatarSize.height)
            .clipShape(RoundedRectangle(cornerRadius: adaptiveCornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 0.5)

            // Stage indicator overlay
            if !accessibilityEnabled {
                StageIndicatorOverlay()
            }
        }
        .accessibilityLabel("Pet at stage \(currentStage)")
        .accessibilityValue(engine.currentEmotionalState.rawValue.capitalized)
    }

    @ViewBuilder
    private func StageIndicatorOverlay() -> some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Text("S\(currentStage)")
                    .font(.system(size: adaptiveStageTextSize, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(.regularMaterial.opacity(0.9), in: Capsule())
                    .shadow(radius: 1)
            }
        }
    }

    @ViewBuilder
    private func StageInfoView() -> some View {
        if accessibilityEnabled {
            VStack(alignment: .leading, spacing: 1) {
                Text("Stage \(currentStage)")
                    .font(.system(size: adaptiveTextSize.primary, weight: .semibold))
                    .foregroundStyle(.primary)

                Text("\(entry.dayModel.points) points")
                    .font(.system(size: adaptiveTextSize.secondary))
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
        }
    }

    @ViewBuilder
    private func TaskProgressView() -> some View {
        VStack(alignment: .trailing, spacing: 1) {
            Text("\(completedTasks)/\(totalTasks)")
                .font(.system(size: adaptiveTextSize.primary, weight: .medium))
                .foregroundStyle(progressColor)

            if totalTasks > 0 {
                ProgressBar(value: Double(completedTasks), total: Double(totalTasks))
                    .frame(width: progressBarWidth, height: progressBarHeight)
            }
        }
        .accessibilityLabel("\(completedTasks) of \(totalTasks) tasks completed")
        .accessibilityValue(progressPercentage)
    }

    // MARK: - Next Task Row

    @ViewBuilder
    private func NextTaskRow() -> some View {
        HStack(spacing: adaptiveSpacing) {
            if let nextSlot = nextIncompleteSlot {
                NextTaskInfoView(slot: nextSlot)
            } else {
                AllTasksCompleteView()
            }

            Spacer()

            // Time indicator
            TimeIndicatorView()
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func NextTaskInfoView(slot: DayModel.Slot) -> some View {
        HStack(spacing: 4) {
            // Task status indicator
            Circle()
                .fill(taskStatusColor(for: slot))
                .frame(width: statusIndicatorSize, height: statusIndicatorSize)

            // Task details
            VStack(alignment: .leading, spacing: 0) {
                Text(slot.title.prefix(maxTaskTitleLength))
                    .font(.system(size: adaptiveTextSize.primary, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text("at \(slot.hour):00")
                    .font(.system(size: adaptiveTextSize.secondary))
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityLabel("Next task: \(slot.title) at \(slot.hour):00")
    }

    @ViewBuilder
    private func AllTasksCompleteView() -> some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: adaptiveTextSize.primary))
                .foregroundStyle(.green)

            Text("All done!")
                .font(.system(size: adaptiveTextSize.primary, weight: .medium))
                .foregroundStyle(.green)
        }
        .accessibilityLabel("All tasks completed")
    }

    @ViewBuilder
    private func TimeIndicatorView() -> some View {
        Text(timeDisplayString)
            .font(.system(size: adaptiveTextSize.secondary, weight: .medium, design: .monospaced))
            .foregroundStyle(.secondary)
            .accessibilityLabel("Current time: \(timeDisplayString)")
    }

    // MARK: - Interactive Button Row

    @ViewBuilder
    private func InteractiveButtonRow() -> some View {
        if nextIncompleteSlot != nil {
            HStack(spacing: buttonSpacing) {
                // Complete Task Button
                InteractiveButton(
                    intent: CompleteTaskIntent(),
                    icon: "checkmark.circle.fill",
                    color: .green,
                    label: "Complete",
                    accessibilityLabel: "Complete current task"
                )

                // Snooze Task Button
                InteractiveButton(
                    intent: SnoozeTaskIntent(),
                    icon: "clock.fill",
                    color: .orange,
                    label: "Snooze",
                    accessibilityLabel: "Snooze current task by 1 hour"
                )

                // Mark Next Button
                InteractiveButton(
                    intent: MarkNextIntent(),
                    icon: "arrow.right.circle.fill",
                    color: .blue,
                    label: "Next",
                    accessibilityLabel: "Mark task as done and move to next"
                )

                Spacer()
            }
        } else {
            // Show celebratory message when all tasks are done
            HStack {
                Image(systemName: "party.popper.fill")
                    .font(.system(size: adaptiveTextSize.primary))
                    .foregroundStyle(.yellow)

                Text("Great job today!")
                    .font(.system(size: adaptiveTextSize.primary, weight: .medium))
                    .foregroundStyle(.primary)

                Spacer()
            }
            .accessibilityLabel("Congratulations! All tasks completed for today")
        }
    }

    // MARK: - Interactive Button Component

    @ViewBuilder
    private func InteractiveButton(
        intent: some AppIntent,
        icon: String,
        color: Color,
        label: String,
        accessibilityLabel: String
    ) -> some View {
        Button(intent: intent) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: buttonIconSize, weight: .medium))
                    .foregroundStyle(color)

                if dynamicTypeSize.isAccessibilitySize {
                    Text(label)
                        .font(.system(size: adaptiveTextSize.secondary, weight: .medium))
                        .foregroundStyle(color)
                }
            }
            .frame(minWidth: buttonMinWidth)
        }
        .buttonStyle(WidgetInteractionButtonStyle())
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Double-tap to perform action")
    }

    // MARK: - Error State View

    @ViewBuilder
    private func ErrorStateView(errorState: WidgetErrorState) -> some View {
        VStack(spacing: 4) {
            Image(systemName: errorState.iconName)
                .font(.system(size: adaptiveTextSize.primary))
                .foregroundStyle(.red)

            Text(errorState.displayMessage)
                .font(.system(size: adaptiveTextSize.secondary))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(adaptivePadding.uniform)
        .accessibilityLabel("Error: \(errorState.displayMessage)")
    }

    // MARK: - Supporting Components

    @ViewBuilder
    private func ProgressBar(value: Double, total: Double) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: progressBarHeight / 2, style: .continuous)
                    .fill(.tertiary)

                // Progress fill
                RoundedRectangle(cornerRadius: progressBarHeight / 2, style: .continuous)
                    .fill(progressColor.gradient)
                    .frame(width: geometry.size.width * (value / total))
                    .animation(.easeInOut(duration: reduceMotion ? 0 : 0.3), value: value)
            }
        }
    }

    // MARK: - Computed Properties

    private var currentStage: Int {
        engine.stageIndex(for: entry.dayModel.points)
    }

    private var completedTasks: Int {
        entry.dayModel.slots.filter { $0.isDone }.count
    }

    private var totalTasks: Int {
        entry.dayModel.slots.count
    }

    private var nextIncompleteSlot: DayModel.Slot? {
        let currentHour = TimeSlot.hourIndex(for: entry.date)
        return entry.dayModel.slots.first { slot in
            slot.hour >= currentHour && !slot.isDone
        }
    }

    private var progressPercentage: String {
        guard totalTasks > 0 else { return "0%" }
        let percentage = Int((Double(completedTasks) / Double(totalTasks)) * 100)
        return "\(percentage)%"
    }

    private var timeDisplayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = dynamicTypeSize.isAccessibilitySize ? "h:mm a" : "h:mm"
        return formatter.string(from: entry.date)
    }

    private var comprehensiveAccessibilityLabel: String {
        var components: [String] = []

        components.append("Pet Progress Widget")
        components.append("Pet at stage \(currentStage)")
        components.append("\(completedTasks) of \(totalTasks) tasks completed")

        if let nextTask = nextIncompleteSlot {
            components.append("Next task: \(nextTask.title) at \(nextTask.hour):00")
        } else {
            components.append("All tasks completed")
        }

        return components.joined(separator: ". ")
    }

    // MARK: - Adaptive Styling

    private var adaptiveSpacing: CGFloat {
        switch dynamicTypeSize {
        case .xLarge, .xxLarge, .xxxLarge:
            return 6
        case .accessibility1, .accessibility2, .accessibility3, .accessibility4, .accessibility5:
            return 8
        default:
            return 4
        }
    }

    private var adaptivePadding: (horizontal: CGFloat, vertical: CGFloat, uniform: CGFloat) {
        let base: CGFloat = dynamicTypeSize.isAccessibilitySize ? 8 : 6
        return (horizontal: base, vertical: base * 0.75, uniform: base)
    }

    private var adaptiveCornerRadius: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 4 : 3
    }

    private var petAvatarSize: (width: CGFloat, height: CGFloat) {
        let base: CGFloat = dynamicTypeSize.isAccessibilitySize ? 24 : 18
        return (width: base, height: base)
    }

    private var adaptiveTextSize: (primary: CGFloat, secondary: CGFloat) {
        switch dynamicTypeSize {
        case .accessibility1, .accessibility2, .accessibility3, .accessibility4, .accessibility5:
            return (primary: 16, secondary: 14)
        case .xLarge, .xxLarge, .xxxLarge:
            return (primary: 13, secondary: 11)
        default:
            return (primary: 11, secondary: 9)
        }
    }

    private var adaptiveStageTextSize: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 10 : 8
    }

    private var buttonIconSize: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 16 : 12
    }

    private var buttonMinWidth: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 44 : 32
    }

    private var buttonSpacing: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 12 : 8
    }

    private var statusIndicatorSize: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 8 : 6
    }

    private var maxTaskTitleLength: Int {
        dynamicTypeSize.isAccessibilitySize ? 20 : 15
    }

    private var progressBarWidth: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 40 : 30
    }

    private var progressBarHeight: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 4 : 3
    }

    // MARK: - Color Adaptations

    private var adaptiveBackground: some ShapeStyle {
        colorScheme == .dark ?
            .regularMaterial.blendMode(.normal) :
            .thickMaterial.blendMode(.normal)
    }

    private var adaptivePetColor: some ShapeStyle {
        LinearGradient(
            colors: [.blue.opacity(0.8), .purple.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var emotionalGlowColor: Color {
        switch engine.currentEmotionalState {
        case .ecstatic, .happy: return .yellow
        case .content: return .green
        case .neutral: return .blue
        case .worried: return .orange
        case .sad, .frustrated: return .red
        }
    }

    private var progressColor: Color {
        let progress = Double(completedTasks) / Double(max(totalTasks, 1))
        if progress >= 0.8 { return .green }
        if progress >= 0.5 { return .blue }
        if progress >= 0.2 { return .orange }
        return .red
    }

    private func taskStatusColor(for slot: DayModel.Slot) -> Color {
        let currentHour = TimeSlot.hourIndex(for: entry.date)

        if slot.isDone {
            return .green
        } else if slot.hour < currentHour {
            return .red // Overdue
        } else if slot.hour == currentHour {
            return .blue // Current
        } else {
            return .secondary // Future
        }
    }
}

/// Custom button style for widget interactions with accessibility support
struct WidgetInteractionButtonStyle: ButtonStyle {
    @Environment(\.accessibilityEnabled) private var accessibilityEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .background(
                accessibilityEnabled ?
                    RoundedRectangle(cornerRadius: 8).fill(.quaternary) :
                    RoundedRectangle(cornerRadius: 8).fill(.clear)
            )
    }
}

struct StandardWidgetView: View {
    let entry: Provider.Entry
    private let engine = PetEvolutionEngine()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Pet status
            HStack {
                Image(engine.imageName(for: entry.dayModel.points))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Stage \(engine.stageIndex(for: entry.dayModel.points))")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text("\(entry.dayModel.points) points")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            // Progress summary
            if !entry.dayModel.slots.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(completedTasks)/\(totalTasks) tasks")
                        .font(.caption)
                        .fontWeight(.medium)

                    if totalTasks > 0 {
                        ProgressView(value: Double(completedTasks), total: Double(totalTasks))
                            .progressViewStyle(LinearProgressViewStyle())
                    }
                }
            } else {
                Text("No tasks scheduled")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
    }

    private var completedTasks: Int {
        entry.dayModel.slots.filter { $0.isDone }.count
    }

    private var totalTasks: Int {
        entry.dayModel.slots.count
    }
}

struct PetProgressWidget: Widget {
    let kind: String = "PetProgressWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                PetProgressWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                PetProgressWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("Pet Progress")
        .description("Track your daily tasks and watch your pet evolve!")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryCircular,
            .accessoryRectangular
        ])
    }
}

#Preview(as: .systemSmall) {
    PetProgressWidget()
} timeline: {
    SimpleEntry(
        date: .now,
        dayModel: DayModel(
            key: TimeSlot.dayKey(for: .now),
            slots: [
                DayModel.Slot(hour: 9, title: "Morning task", isDone: true),
                DayModel.Slot(hour: 14, title: "Afternoon task", isDone: false)
            ],
            points: 125
        )
    )
}
