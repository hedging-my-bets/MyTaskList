import SwiftUI
import SharedKit

struct ContentView: View {
    @EnvironmentObject var dataStore: DataStore

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Pet Display
                VStack {
                    Image(uiImage: dataStore.petImage())
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)

                    Text("Stage \(dataStore.pet.stageIndex)")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("XP: \(dataStore.pet.stageXP) / \(dataStore.currentThreshold)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    ProgressView(value: Double(dataStore.pet.stageXP), total: Double(dataStore.currentThreshold))
                        .progressViewStyle(LinearProgressViewStyle())
                        .frame(width: 200)
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)

                // Task Summary
                VStack {
                    Text("Today's Progress")
                        .font(.headline)

                    Text("\(dataStore.tasksDone) / \(dataStore.tasksTotal) tasks completed")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if dataStore.tasksTotal > 0 {
                        ProgressView(value: Double(dataStore.tasksDone), total: Double(dataStore.tasksTotal))
                            .progressViewStyle(LinearProgressViewStyle())
                    }
                }
                .padding()

                // Task List
                List {
                    if dataStore.todayTasksSorted.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 48))
                                .foregroundStyle(.secondary)
                            Text("No tasks today")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            Text("Tap the + button to add your first task")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color(.systemBackground))
                    } else {
                        ForEach(dataStore.todayTasksSorted, id: \.id) { task in
                            TaskRowView(task: task)
                        }
                    }
                }
                .scrollContentBackground(.hidden)

                Spacer()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("PetProgress")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dataStore.showPlanner = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Settings") {
                        dataStore.showSettings = true
                    }
                }
            }
            .sheet(isPresented: $dataStore.showSettings) {
                SettingsView()
                    .environmentObject(dataStore)
            }
            .sheet(isPresented: $dataStore.showPlanner) {
                AddTaskView()
                    .environmentObject(dataStore)
            }
        }
    }
}