import SwiftUI
import SharedKit

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
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Setup") {
                        viewModel.setupDefaultTasks()
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadTodaysData()
        }
    }
}