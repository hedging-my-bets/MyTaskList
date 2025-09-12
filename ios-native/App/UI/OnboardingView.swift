import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 40) {
            TabView(selection: $currentPage) {
                OnboardingPage(
                    title: "Welcome to PetProgress",
                    subtitle: "Evolve your pet by completing tasks on time",
                    image: "leaf.fill",
                    color: .green
                ).tag(0)
                
                OnboardingPage(
                    title: "Lock Screen Widget",
                    subtitle: "Add the widget to your Lock Screen for quick task completion",
                    image: "lock.iphone",
                    color: .blue
                ).tag(1)
                
                OnboardingPage(
                    title: "Plan Your Day",
                    subtitle: "Create recurring tasks and manage your schedule",
                    image: "calendar",
                    color: .orange
                ).tag(2)
            }
            .tabViewStyle(PageTabViewStyle())
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
            
            VStack(spacing: 16) {
                if currentPage < 2 {
                    Button("Next") {
                        withAnimation {
                            currentPage += 1
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                } else {
                    Button("Get Started") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                
                Button("Skip") {
                    dismiss()
                }
                .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

struct OnboardingPage: View {
    let title: String
    let subtitle: String
    let image: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: image)
                .font(.system(size: 80))
                .foregroundColor(color)
            
            VStack(spacing: 16) {
                Text(title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(subtitle)
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
    }
}

#Preview {
    OnboardingView()
}

