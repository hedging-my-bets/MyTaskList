import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Task Timing") {
                    HStack {
                        Text("Grace Period")
                        Spacer()
                        Stepper("\(store.state.graceMinutes ?? 60) min", value: Binding(
                            get: { store.state.graceMinutes ?? 60 },
                            set: { store.updateGraceMinutes($0) }
                        ), in: 5...120, step: 5)
                    }
                    
                    HStack {
                        Text("Reset Time")
                        Spacer()
                        DatePicker("", selection: Binding(
                            get: { 
                                let comps = store.state.resetTime ?? DateComponents(hour: 0, minute: 0)
                                return Calendar.current.date(from: comps) ?? Date()
                            },
                            set: { 
                                let comps = Calendar.current.dateComponents([.hour, .minute], from: $0)
                                store.updateResetTime(comps)
                            }
                        ), displayedComponents: .hourAndMinute)
                    }
                }
                
                Section("Data Management") {
                    Toggle("Rollover Incomplete Tasks", isOn: Binding(
                        get: { store.state.rolloverEnabled },
                        set: { store.updateRolloverEnabled($0) }
                    ))
                    
                    Button("Reset All Data") {
                        store.showResetConfirmation = true
                    }
                    .foregroundColor(.red)
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Pet Stage")
                        Spacer()
                        Text("\(store.pet.stageIndex + 1) of 20")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .alert("Reset All Data", isPresented: $store.showResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                store.resetAllData()
            }
        } message: {
            Text("This will delete all tasks, series, and reset your pet to stage 1. This action cannot be undone.")
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(DataStore())
}


