import SwiftUI

struct WidgetInstructionsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Image(systemName: "lock.iphone")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                VStack(spacing: 24) {
                    Text("Add Lock Screen Widget")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        InstructionStep(
                            number: 1,
                            text: "Long press on your Lock Screen"
                        )
                        
                        InstructionStep(
                            number: 2,
                            text: "Tap the \"+\" button to add widgets"
                        )
                        
                        InstructionStep(
                            number: 3,
                            text: "Search for \"PetProgress\" and add the widget"
                        )
                        
                        InstructionStep(
                            number: 4,
                            text: "Tap \"Done\" to save your Lock Screen"
                        )
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                Button("Got It") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding()
            .navigationTitle("Widget Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Skip") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct InstructionStep: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Text("\(number)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(Circle().fill(.blue))
            
            Text(text)
                .font(.body)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
    }
}

#Preview {
    WidgetInstructionsView()
}

