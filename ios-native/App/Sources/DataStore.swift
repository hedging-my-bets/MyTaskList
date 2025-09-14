import Foundation
import SwiftUI
import UIKit
import SharedKit

@MainActor
final class DataStore: ObservableObject {
    @Published private(set) var state: AppState
    @Published var showPlanner: Bool = false
    @Published var showWidgetInstructions: Bool = false
    @Published var showSettings: Bool = false
    @Published var showResetConfirmation: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    @Published var showSuccess: Bool = false
    @Published var successMessage: String = ""

    private let sharedStore = SharedStore()
    private let stageLoader = StageConfigLoader()

    init() {
        // Load or initialize
        if let loaded = try? sharedStore.loadState() {
            self.state = loaded
        } else {
            let today = dayKey(for: Date())
            self.state = AppState(
                dayKey: today,
                pet: PetState(stageIndex: 0, stageXP: 0, lastCloseoutDayKey: today)
            )
            try? sharedStore.saveState(state)
        }
    }

    var pet: PetState { state.pet }
    var tasksTotal: Int {
        let mats = materializeTasks(for: state.dayKey, in: state)
        return mats.count
    }
    var tasksDone: Int {
        let mats = materializeTasks(for: state.dayKey, in: state)
        return mats.filter { $0.isCompleted }.count
    }
    var todayTasksSorted: [MaterializedTask] {
        materializeTasks(for: state.dayKey, in: state)
    }
    var currentThreshold: Int {
        let cfg = (try? stageLoader.load()) ?? StageCfg.defaultConfig()
        return PetEngine.threshold(for: state.pet.stageIndex, cfg: cfg)
    }

    func petImage() -> UIImage {
        let cfg = (try? stageLoader.load()) ?? StageCfg.defaultConfig()
        let asset = cfg.stages[safe: state.pet.stageIndex]?.asset ?? "pet_frog"
        if let ui = UIImage(named: asset) {
            return ui
        }
        return UIImage(systemName: "leaf") ?? UIImage()
    }

    func markDone(taskID: UUID) {
        let now = Date()
        let dayKey = state.dayKey
        var completed = state.completions[dayKey] ?? Set<UUID>()
        guard !completed.contains(taskID) else { return }

        // Find the materialized task to determine on-time status
        let mats = materializeTasks(for: dayKey, in: state)
        guard let mt = mats.first(where: { $0.id == taskID }) else { return }

        let onTime = isOnTimeForMaterializedTask(task: mt, now: now)

        completed.insert(taskID)
        state.completions[dayKey] = completed

        var petCopy = state.pet
        let cfg = (try? stageLoader.load()) ?? StageCfg.defaultConfig()
        let oldXP = petCopy.stageXP
        let oldStage = petCopy.stageIndex

        PetEngine.onCheck(onTime: onTime, pet: &petCopy, cfg: cfg)
        state.pet = petCopy

        // Haptic feedback and success messages
        if onTime {
            triggerHapticFeedback(.success)
            showSuccessMessage("Task completed on time! +XP earned")
        } else {
            triggerHapticFeedback(.warning)
            showSuccessMessage("Task completed")
        }

        // Level up celebration
        if petCopy.stageIndex > oldStage {
            triggerHapticFeedback(.success)
            showSuccessMessage("🎉 Your pet leveled up to Stage \(petCopy.stageIndex)!")
        }

        persist()
    }

    private func isOnTimeForMaterializedTask(task: MaterializedTask, now: Date) -> Bool {
        let cal = Calendar.current
        let due = cal.date(bySettingHour: task.time.hour ?? 0, minute: task.time.minute ?? 0, second: 0, of: now) ?? now
        let graceMinutes = state.graceMinutes
        let windowStart = due.addingTimeInterval(TimeInterval(-graceMinutes * 60))
        let windowEnd = due.addingTimeInterval(TimeInterval(graceMinutes * 60))
        return now >= windowStart && now <= windowEnd
    }

    func snooze(taskID: UUID, minutes: Int) {
        let dayKey = state.dayKey
        let mats = materializeTasks(for: dayKey, in: state)
        guard let mt = mats.first(where: { $0.id == taskID }) else { return }
        guard !mt.isCompleted else { return }

        // For series tasks, create an override with new time
        if case .series(let seriesId) = mt.origin {
            let calendar = Calendar.current
            let now = Date()
            let scheduled = calendar.date(bySettingHour: mt.time.hour ?? 0, minute: mt.time.minute ?? 0, second: 0, of: now) ?? now
            let snoozed = min(scheduled.addingTimeInterval(TimeInterval(minutes * 60)), calendar.date(bySettingHour: 23, minute: 59, second: 0, of: now) ?? scheduled)
            let comps = calendar.dateComponents([.hour, .minute], from: snoozed)

            if let idx = state.overrides.firstIndex(where: { $0.seriesId == seriesId && $0.dayKey == dayKey }) {
                state.overrides[idx] = TaskInstanceOverride(
                    id: state.overrides[idx].id,
                    seriesId: seriesId,
                    dayKey: dayKey,
                    time: comps
                )
            } else {
                state.overrides.append(TaskInstanceOverride(
                    seriesId: seriesId,
                    dayKey: dayKey,
                    time: comps
                ))
            }
        } else {
            // For one-off tasks, update the task's scheduled time directly
            guard let idx = state.tasks.firstIndex(where: { $0.id == taskID }) else { return }
            var task = state.tasks[idx]
            let calendar = Calendar.current
            let now = Date()
            let scheduled = calendar.date(bySettingHour: task.scheduledAt.hour ?? 0, minute: task.scheduledAt.minute ?? 0, second: 0, of: now) ?? now
            let snoozed = min(scheduled.addingTimeInterval(TimeInterval(minutes * 60)), calendar.date(bySettingHour: 23, minute: 59, second: 0, of: now) ?? scheduled)
            task.snoozedUntil = snoozed
            let comps = calendar.dateComponents([.hour, .minute], from: snoozed)
            task.scheduledAt = comps
            state.tasks[idx] = task
        }
        persist()
    }

    func launchApplyCloseoutIfNeeded() async {
        await applyCloseoutIfNeeded(now: Date())
    }

    func applyCloseoutIfNeeded(now: Date) async {
        let today = dayKey(for: now)
        guard state.pet.lastCloseoutDayKey != today else { return }

        // Compute yesterday completion rate
        let yesterdayKey = state.pet.lastCloseoutDayKey
        let yesterdayTasks = state.tasks.filter { $0.dayKey == yesterdayKey }
        let total = yesterdayTasks.count
        let done = yesterdayTasks.filter { $0.isCompleted }.count
        let rate = total == 0 ? 1.0 : Double(done) / Double(total)

        var petCopy = state.pet
        let cfg = (try? stageLoader.load()) ?? StageCfg.defaultConfig()
        PetEngine.onDailyCloseout(rate: rate, pet: &petCopy, cfg: cfg, dayKey: today)
        state.pet = petCopy

        // Archive yesterday (no-op here) and seed today (no rollover by default)
        state.pet.lastCloseoutDayKey = today
        state.dayKey = today
        if state.rolloverEnabled {
            let carry = yesterdayTasks.filter { !$0.isCompleted }
            let seed = carry.map { old -> TaskItem in
                let comps = DateComponents(hour: old.scheduledAt.hour, minute: old.scheduledAt.minute)
                return TaskItem(id: UUID(), title: old.title, scheduledAt: comps, dayKey: today, isCompleted: false, completedAt: nil, snoozedUntil: nil)
            }
            state.tasks.append(contentsOf: seed)
        }

        persist()
    }

    private func persist() {
        objectWillChange.send()
        do {
            try sharedStore.saveState(state)
        } catch {
            showErrorMessage("Failed to save data: \(error.localizedDescription)")
        }
    }

    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true

        // Auto-dismiss after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.showError = false
        }
    }

    private func showSuccessMessage(_ message: String) {
        successMessage = message
        showSuccess = true

        // Auto-dismiss after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.showSuccess = false
        }
    }

    private func triggerHapticFeedback(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }

    public func replaceState(_ newState: AppState) {
        state = newState
        persist()
    }

    func routeToPlanner() { showPlanner = true }

    func addTask(_ task: TaskItem) {
        // Validate task before adding
        guard task.isValid else {
            showErrorMessage("Unable to add task: Invalid task details")
            return
        }

        // Check for duplicate tasks at the same time
        let existingTask = state.tasks.first { existing in
            existing.dayKey == task.dayKey &&
            existing.scheduledAt.hour == task.scheduledAt.hour &&
            existing.scheduledAt.minute == task.scheduledAt.minute
        }

        if let existing = existingTask {
            showErrorMessage("A task is already scheduled at \(timeString(from: task.scheduledAt))")
            return
        }

        state.tasks.append(task)
        persist()
        showSuccessMessage("Task '\(task.title)' added successfully!")
    }

    private func timeString(from dateComponents: DateComponents) -> String {
        let hour = dateComponents.hour ?? 0
        let minute = dateComponents.minute ?? 0
        return String(format: "%02d:%02d", hour, minute)
    }

    func deleteTask(_ taskID: UUID) {
        guard let taskToDelete = state.tasks.first(where: { $0.id == taskID }) else {
            showErrorMessage("Task not found")
            return
        }

        state.tasks.removeAll { $0.id == taskID }
        // Also remove from completions if it was completed
        for dayKey in state.completions.keys {
            state.completions[dayKey]?.remove(taskID)
        }

        triggerHapticFeedback(.warning)
        showSuccessMessage("Task '\(taskToDelete.title)' deleted")
        persist()
    }

    func updateTask(_ updatedTask: TaskItem) {
        guard updatedTask.isValid else {
            showErrorMessage("Unable to update task: Invalid task details")
            return
        }

        guard let index = state.tasks.firstIndex(where: { $0.id == updatedTask.id }) else {
            showErrorMessage("Task not found")
            return
        }

        // Check for time conflicts with other tasks (excluding this one)
        let conflictingTask = state.tasks.first { existing in
            existing.id != updatedTask.id &&
            existing.dayKey == updatedTask.dayKey &&
            existing.scheduledAt.hour == updatedTask.scheduledAt.hour &&
            existing.scheduledAt.minute == updatedTask.scheduledAt.minute
        }

        if let existing = conflictingTask {
            showErrorMessage("Another task is already scheduled at \(timeString(from: updatedTask.scheduledAt))")
            return
        }

        state.tasks[index] = updatedTask
        triggerHapticFeedback(.success)
        showSuccessMessage("Task updated successfully")
        persist()
    }

    func updateGraceMinutes(_ minutes: Int) {
        state.graceMinutes = minutes
        persist()
    }

    func updateResetTime(_ time: DateComponents) {
        state.resetTime = time
        persist()
    }

    func updateRolloverEnabled(_ enabled: Bool) {
        state.rolloverEnabled = enabled
        persist()
    }

    func resetAllData() {
        let today = dayKey(for: Date())
        state = AppState(
            dayKey: today,
            pet: PetState(stageIndex: 0, stageXP: 0, lastCloseoutDayKey: today)
        )
        persist()
    }
}