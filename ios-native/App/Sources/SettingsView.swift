import SwiftUI
import SharedKit

struct SettingsView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                Section("Pet Settings") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Grace Period")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text("Tasks completed within this window count as on-time")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Picker("Grace Minutes", selection: Binding(
                            get: { dataStore.state.graceMinutes },
                            set: { dataStore.updateGraceMinutes($0) }
                        )) {
                            Text("30 minutes").tag(30)
                            Text("60 minutes").tag(60)
                            Text("90 minutes").tag(90)
                            Text("120 minutes").tag(120)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    .padding(.vertical, 8)

                    Toggle("Rollover Incomplete Tasks", isOn: Binding(
                        get: { dataStore.state.rolloverEnabled },
                        set: { dataStore.updateRolloverEnabled($0) }
                    ))
                }

                Section("Debug") {
                    Button("Reset All Data") {
                        dataStore.showResetConfirmation = true
                    }
                    .foregroundStyle(.red)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Reset All Data", isPresented: $dataStore.showResetConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    dataStore.resetAllData()
                    dismiss()
                }
            } message: {
                Text("This will permanently delete all your tasks and reset your pet. This cannot be undone.")
            }
        }
    }
}
