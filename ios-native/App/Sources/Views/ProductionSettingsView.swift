import SwiftUI
import SharedKit
import SafariServices

/// Production-grade Settings view with Grace Minutes and Privacy Policy
/// Built by world-class engineers for App Store compliance
@available(iOS 17.0, *)
struct ProductionSettingsView: View {
    @StateObject private var store = AppGroupStore.shared
    @State private var showingPrivacyPolicy = false
    @State private var showingAbout = false

    var body: some View {
        NavigationView {
            List {
                // MARK: - Task Configuration
                Section {
                    GraceMinutesControl()
                    TaskWindowSettings()
                } header: {
                    Label("Task Settings", systemImage: "clock")
                }

                // MARK: - Pet Settings
                Section {
                    PetProgressSummary()
                    CelebrationSettings()
                } header: {
                    Label("Pet Progress", systemImage: "heart.fill")
                }

                // MARK: - Legal & Privacy
                Section {
                    Button(action: { showingPrivacyPolicy = true }) {
                        HStack {
                            Label("Privacy Policy", systemImage: "hand.raised.fill")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }

                    Button(action: { showingAbout = true }) {
                        HStack {
                            Label("About PetProgress", systemImage: "info.circle")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                } header: {
                    Label("Privacy & Legal", systemImage: "lock.shield")
                }

                // MARK: - Advanced
                Section {
                    PerformanceInsights()
                    StorageMetricsDisplay()
                } header: {
                    Label("Advanced", systemImage: "gear")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingPrivacyPolicy) {
                PrivacyPolicyView()
            }
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
        }
    }
}

// Duplicate GraceMinutesControl removed - using SettingsView.swift version

// MARK: - Task Window Settings

@available(iOS 17.0, *)
struct TaskWindowSettings: View {
    @StateObject private var store = AppGroupStore.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Active Tasks", systemImage: "list.bullet.rectangle")
                Spacer()
                Text("\(store.getCurrentTasks().count)")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }

            Text("Tasks currently visible in your Lock Screen widget based on the grace period.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Pet Progress Summary

@available(iOS 17.0, *)
struct PetProgressSummary: View {
    @StateObject private var store = AppGroupStore.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Current Stage", systemImage: "star.fill")
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Stage \(store.state.pet.stageIndex + 1)")
                        .font(.headline)
                    Text("\(store.state.pet.stageXP) XP")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Progress bar to next stage
            let stageCfg = StageConfigLoader.shared.loadStageConfig()
            if store.state.pet.stageIndex < stageCfg.stages.count {
                let currentThreshold = stageCfg.stages[store.state.pet.stageIndex].threshold
                let progress = currentThreshold > 0 ? Double(store.state.pet.stageXP) / Double(currentThreshold) : 0

                ProgressView(value: progress) {
                    Text("Progress to next stage")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .tint(.blue)
            }

            Text("Complete tasks to gain XP and evolve your pet. Higher stages unlock better animations!")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Celebration Settings

@available(iOS 17.0, *)
struct CelebrationSettings: View {
    @StateObject private var store = AppGroupStore.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Celebrations", systemImage: "party.popper")
                Spacer()
                Button("Test") {
                    // Test celebration
                    let haptic = UINotificationFeedbackGenerator()
                    haptic.notificationOccurred(.success)

                    // Show confetti effect (would be implemented)
                    // Test celebration triggered
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.mini)
            }

            Text("Haptic feedback and animations when your pet evolves to the next stage.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Performance Insights

@available(iOS 17.0, *)
struct PerformanceInsights: View {
    @State private var performanceReport: PerformanceReport?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Performance", systemImage: "speedometer")
                Spacer()
                Button("Refresh") {
                    performanceReport = PerformanceProfiler.shared.generatePerformanceReport()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.mini)
            }

            if let report = performanceReport {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Battery Impact:")
                        Spacer()
                        Text("\(report.batteryImpactScore)/100")
                            .foregroundColor(report.batteryImpactScore > 80 ? .green : report.batteryImpactScore > 60 ? .orange : .red)
                    }

                    HStack {
                        Text("Memory Efficiency:")
                        Spacer()
                        Text("\(report.memoryEfficiencyScore)/100")
                            .foregroundColor(report.memoryEfficiencyScore > 80 ? .green : report.memoryEfficiencyScore > 60 ? .orange : .red)
                    }

                    HStack {
                        Text("Memory Usage:")
                        Spacer()
                        Text("\(String(format: "%.1f", report.currentMemoryUsage)) MB")
                            .foregroundColor(report.currentMemoryUsage < 50 ? .green : report.currentMemoryUsage < 100 ? .orange : .red)
                    }
                }
                .font(.caption)
                .padding(.top, 4)
            }

            Text("Performance metrics for Lock Screen widget optimization.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .onAppear {
            performanceReport = PerformanceProfiler.shared.generatePerformanceReport()
        }
    }
}

// MARK: - Storage Metrics

@available(iOS 17.0, *)
struct StorageMetricsDisplay: View {
    @StateObject private var store = AppGroupStore.shared
    @State private var storageMetrics: SharedKit.StorageMetrics?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Storage", systemImage: "internaldrive")
                Spacer()
                if let metrics = storageMetrics {
                    Text("\(ByteCountFormatter().string(fromByteCount: Int64(metrics.stateSize)))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if let metrics = storageMetrics {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Tasks:")
                        Spacer()
                        Text("\(metrics.taskCount)")
                    }

                    HStack {
                        Text("Completions:")
                        Spacer()
                        Text("\(metrics.completionCount)")
                    }

                    HStack {
                        Text("Last sync:")
                        Spacer()
                        Text(metrics.lastSaveDate, style: .relative)
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Text("App Group shared storage between main app and Lock Screen widget.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .onAppear {
            storageMetrics = store.getStorageMetrics()
        }
    }
}

// MARK: - Privacy Policy View

// Duplicate PrivacyPolicyView removed - using dedicated PrivacyPolicyView.swift file

// MARK: - Local Privacy Policy Fallback

@available(iOS 17.0, *)
struct LocalPrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Privacy Policy")
                    .font(.largeTitle)
                    .bold()

                Text("Last updated: \(formattedDate)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                privacyContent
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    @ViewBuilder
    private var privacyContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Data Collection")
                .font(.headline)

            Text("PetProgress stores your task data locally on your device and in iCloud (if enabled). We do not collect, transmit, or store any personal information on external servers.")

            Text("Widget Data")
                .font(.headline)

            Text("The Lock Screen widget accesses your task data through iOS App Groups to display current progress. This data remains on your device.")

            Text("Third-Party Services")
                .font(.headline)

            Text("PetProgress does not use any third-party analytics, advertising, or tracking services.")

            Text("Contact")
                .font(.headline)

            Text("For privacy questions, contact: privacy@petprogress.app")

            Text("Data Storage")
                .font(.headline)

            Text("All data is stored using iOS App Groups and iCloud sync (if enabled by user). No data is transmitted to third-party servers or used for advertising purposes.")

            Text("Your Rights")
                .font(.headline)

            Text("You can delete all app data by uninstalling the app. iCloud data can be managed through iOS Settings > Apple ID > iCloud.")
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: Date())
    }
}

// MARK: - About View

@available(iOS 17.0, *)
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // App icon and name
                    VStack(spacing: 8) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.pink)

                        Text("PetProgress")
                            .font(.title)
                            .bold()

                        Text("Version 1.0")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Description
                    VStack(alignment: .leading, spacing: 12) {
                        Text("About")
                            .font(.headline)

                        Text("Transform your Lock Screen into a productivity companion. Complete tasks to evolve your pet—all without opening the app.")

                        Text("Features")
                            .font(.headline)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("• Interactive Lock Screen widgets")
                            Text("• Pet evolution system with 16 stages")
                            Text("• Smart time-based task management")
                            Text("• Privacy-first design (all data stays local)")
                            Text("• Configurable grace periods")
                            Text("• Haptic feedback and celebrations")
                        }
                        .font(.callout)

                        Text("Perfect for students, professionals, and anyone who wants to stay productive without constant app switching.")
                            .font(.callout)
                            .italic()
                    }

                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Safari View (reused from previous implementation)

@available(iOS 17.0, *)
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    let onLoadFailure: ((Bool) -> Void)?

    init(url: URL, onLoadFailure: ((Bool) -> Void)? = nil) {
        self.url = url
        self.onLoadFailure = onLoadFailure
    }

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let safari = SFSafariViewController(url: url)
        safari.delegate = context.coordinator
        return safari
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // No updates needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onLoadFailure: onLoadFailure)
    }

    class Coordinator: NSObject, SFSafariViewControllerDelegate {
        let onLoadFailure: ((Bool) -> Void)?

        init(onLoadFailure: ((Bool) -> Void)?) {
            self.onLoadFailure = onLoadFailure
        }

        func safariViewController(_ controller: SFSafariViewController, didCompleteInitialLoad didLoadSuccessfully: Bool) {
            if !didLoadSuccessfully {
                onLoadFailure?(false)
            }
        }
    }
}

// MARK: - Preview

@available(iOS 17.0, *)
struct ProductionSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        ProductionSettingsView()
    }
}