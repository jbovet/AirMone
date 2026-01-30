import SwiftUI

struct SignalStrengthGuideView: View {
    @State private var isExpanded: Bool = false

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                // Header with toggle
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                }) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)

                        Text("Signal Strength Guide")
                            .font(.headline)

                        Spacer()

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                .buttonStyle(.plain)

                if isExpanded {
                    Divider()

                    // Signal strength ranges
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Understanding Your WiFi Signal")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)

                        ForEach(SignalStrength.allCases, id: \.self) { strength in
                            SignalRangeRow(strength: strength)
                        }
                    }

                    Divider()

                    // Additional tips
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tips for Better Signal")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)

                        TipRow(
                            icon: "wifi.router",
                            text: "Place router in a central location"
                        )

                        TipRow(
                            icon: "arrow.up.circle",
                            text: "Elevate router off the ground"
                        )

                        TipRow(
                            icon: "cube.transparent",
                            text: "Avoid obstacles like walls and furniture"
                        )

                        TipRow(
                            icon: "antenna.radiowaves.left.and.right",
                            text: "Keep away from electronic interference"
                        )
                    }
                }
            }
            .padding()
        }
    }
}

struct SignalRangeRow: View {
    let strength: SignalStrength

    var body: some View {
        HStack(spacing: 12) {
            // Color indicator
            RoundedRectangle(cornerRadius: 4)
                .fill(strength.color)
                .frame(width: 40, height: 24)

            // Strength name
            Text(strength.rawValue)
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 80, alignment: .leading)

            // dBm range
            Text(rssiRange(for: strength))
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 90, alignment: .leading)

            // Description
            Text(description(for: strength))
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 2)
    }

    private func rssiRange(for strength: SignalStrength) -> String {
        switch strength {
        case .excellent:
            return "-50 to 0 dBm"
        case .good:
            return "-60 to -50 dBm"
        case .fair:
            return "-70 to -60 dBm"
        case .weak:
            return "-80 to -70 dBm"
        case .poor:
            return "-90 to -80 dBm"
        case .unusable:
            return "< -90 dBm"
        }
    }

    private func description(for strength: SignalStrength) -> String {
        switch strength {
        case .excellent:
            return "Perfect for all activities including 4K streaming and gaming"
        case .good:
            return "Great for HD streaming, video calls, and browsing"
        case .fair:
            return "Suitable for web browsing and standard video"
        case .weak:
            return "May experience slow speeds and buffering"
        case .poor:
            return "Difficult to maintain connections, frequent drops"
        case .unusable:
            return "Cannot establish or maintain reliable connection"
        }
    }
}

struct TipRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)

            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    VStack {
        SignalStrengthGuideView()
            .padding()

        Spacer()
    }
}
