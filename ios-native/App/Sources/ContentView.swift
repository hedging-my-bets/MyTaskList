import SwiftUI
import SharedKit

extension Notification.Name {
    static let openPlanner = Notification.Name("openPlanner")
    static let openTask = Notification.Name("openTask")
}

struct ContentView: View {
    @StateObject private var viewModel = AppViewModel()

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Pet Display
                PetDisplayView(
                    stage: viewModel.petStage,
                    points: viewModel.petPoints,
                    imageName: viewModel.petImageName
                )

                // Task Summary
                TaskSummaryView(
                    completed: viewModel.completedTasks,
                    total: viewModel.totalTasks
                )

                // Next 3 Tasks Feed
                TaskFeedView(tasks: viewModel.next3Tasks) { task in
                    viewModel.completeTask(task)
                }

                Spacer()
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Pet Progress")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink("Templates") {
                        TemplateListView()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Setup") {
                        viewModel.setupDefaultTasks()
                    }
                }
            }
        }
        .withCelebrations()
        .onAppear {
            viewModel.loadTodaysData()
        }
        .onReceive(NotificationCenter.default.publisher(for: .openPlanner)) { _ in
            // Handle deep link to planner - this would typically navigate to a planner view
            // For now, just trigger the setup action as a placeholder
            viewModel.setupDefaultTasks()
        }
        .onReceive(NotificationCenter.default.publisher(for: .openTask)) { notification in
            // Handle deep link to specific task
            if let userInfo = notification.userInfo as? [String: String],
               let dayKey = userInfo["dayKey"],
               let hourString = userInfo["hour"],
               let hour = Int(hourString),
               let title = userInfo["title"] {

                // For now, just load today's data to refresh the view
                // In a full implementation, this would navigate to the specific task
                viewModel.loadTodaysData()

                // Optional: Could add logic here to highlight the specific task
                // or scroll to it in the task feed
            }
        }
    }
}
