import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject var store: DataStore

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                NavigationLink(destination: PlannerView().environmentObject(store), isActive: $store.showPlanner) { EmptyView() }
                NavigationLink(destination: WidgetInstructionsView(), isActive: $store.showWidgetInstructions) { EmptyView() }
                NavigationLink(destination: SettingsView().environmentObject(store), isActive: $store.showSettings) { EmptyView() }
                header
                List {
                    ForEach(store.todayTasksSorted) { task in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(task.title)
                                    .font(.body)
                                Text(String(format: "%02d:%02d", task.time.hour ?? 0, task.time.minute ?? 0))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if task.isCompleted {
                                Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                            } else {
                                HStack {
                                    Button("Done") { store.markDone(taskID: task.id) }
                                        .buttonStyle(.borderedProminent)
                                    Button("Snooze") { store.snooze(taskID: task.id, minutes: 15) }
                                        .buttonStyle(.bordered)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
            .navigationTitle("Today")
        }
    }

    private var header: some View {
        let threshold = store.currentThreshold
        let clampedProgress: Double = {
            if threshold == 0 { return 1 }
            return Double(max(0, min(store.pet.stageXP, threshold))) / Double(threshold)
        }()
        return VStack(spacing: 8) {
            Image(uiImage: store.petImage())
                .resizable()
                .scaledToFit()
                .frame(height: 120)
                .accessibilityLabel("Pet at stage \(store.pet.stageIndex + 1)")
            ProgressView(value: clampedProgress)
                .accessibilityLabel("\(Int(clampedProgress * 100))% to next stage")
            Text("\(store.tasksDone)/\(store.tasksTotal) done")
                .font(.subheadline)
                .accessibilityLabel("\(store.tasksDone) of \(store.tasksTotal) tasks completed")
            HStack {
                Button {
                    store.showWidgetInstructions = true
                } label: {
                    Label("Widget", systemImage: "lock.iphone")
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button {
                    store.routeToPlanner()
                } label: {
                    Label("Planner", systemImage: "calendar")
                }
                .buttonStyle(.bordered)
                
                Button {
                    store.showSettings = true
                } label: {
                    Label("Settings", systemImage: "gearshape")
                }
                .buttonStyle(.bordered)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(DataStore())
    }
}

