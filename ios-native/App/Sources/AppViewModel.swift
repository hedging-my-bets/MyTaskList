import Foundation
import SwiftUI
import SharedKit

@MainActor
class AppViewModel: ObservableObject {
    @Published var petStage: Int = 0
    @Published var petPoints: Int = 0
    @Published var petImageName: String = "pet_baby"
    @Published var completedTasks: Int = 0
    @Published var totalTasks: Int = 0
    @Published var next3Tasks: [TaskFeedItem] = []

    private let store = SharedStore.shared
    private let engine = PetEvolutionEngine()
    private let planner = TaskPlanner.shared

    private var todaysKey: String {
        TimeSlot.dayKey(for: Date())
    }

    func loadTodaysData() {
        let dayKey = todaysKey
        var dayModel = store.loadDay(key: dayKey)

        // Create default schedule if no data exists
        if dayModel == nil {
            dayModel = planner.createDailySchedule()
            store.saveDay(dayModel!)
        }

        // Ensure minimum tasks
        if let day = dayModel {
            dayModel = planner.ensureMinimumTasks(dayModel: day, minimumCount: 3)
            store.saveDay(dayModel!)
        }

        updateUI(with: dayModel!)
    }

    func setupDefaultTasks() {
        let defaultDay = planner.createDailySchedule(
            startHour: 9,
            endHour: 17,
            taskCount: 3
        )
        store.saveDay(defaultDay)
        updateUI(with: defaultDay)
    }

    func completeTask(_ task: TaskFeedItem) {
        let dayKey = todaysKey
        if let updatedDay = store.markNextDone(for: dayKey, now: Date()) {
            updateUI(with: updatedDay)
        }
    }

    private func updateUI(with dayModel: DayModel) {
        petPoints = dayModel.points
        petStage = engine.stageIndex(for: dayModel.points)
        petImageName = engine.imageName(for: dayModel.points)

        completedTasks = dayModel.slots.filter { $0.isDone }.count
        totalTasks = dayModel.slots.count

        next3Tasks = planner.getNext3Tasks(from: dayModel)
    }
}
