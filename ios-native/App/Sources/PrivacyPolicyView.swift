import SwiftUI
import SafariServices

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingFallback = false

    var body: some View {
        NavigationView {
            Group {
                if showingFallback {
                    FallbackPrivacyView()
                } else {
                    SafariView(url: privacyPolicyURL) { success in
                        if !success {
                            showingFallback = true
                        }
                    }
                }
            }
            .navigationTitle("Privacy Policy")
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

    private var privacyPolicyURL: URL {
        // Use actual hosted privacy policy URL
        URL(string: "https://hedging-my-bets.github.io/MyTaskList/privacy-policy.html") ??
        URL(string: "https://www.iubenda.com/privacy-policy/placeholder")!
    }
}

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

struct FallbackPrivacyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Privacy Policy")
                    .font(.largeTitle)
                    .bold()

                Text("Last updated: \(formattedDate)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

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
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: Date())
    }
}