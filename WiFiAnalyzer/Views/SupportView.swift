import SwiftUI

struct SupportView: View {
    let donationURL = URL(string: "https://www.buymeacoffee.com/jpbd")!
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                VStack(spacing: 15) {
                    Image(systemName: "heart.circle.fill")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .foregroundStyle(.red.gradient)
                    
                    Text("Support the Developer")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Brewing coffee, parsing logs, and building nerd stuff. 🐧☕️⚙️")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Text("If you find this tool helpful, consider supporting its development. Your donations help keep the project alive and free for everyone!")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 40)
                }
                
                Link(destination: donationURL) {
                    HStack {
                        Image(systemName: "cup.and.saucer.fill")
                        Text("Buy me a coffee")
                            .fontWeight(.semibold)
                    }
                    .padding()
                    .frame(width: 250)
                    .background(Color.yellow)
                    .foregroundColor(.black)
                    .cornerRadius(12)
                    .shadow(radius: 5)
                }
                .buttonStyle(.plain)
                
                Spacer()
            }
            .padding(.vertical, 50)
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

#Preview {
    SupportView()
}
