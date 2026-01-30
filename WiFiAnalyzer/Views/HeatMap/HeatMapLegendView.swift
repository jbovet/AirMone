import SwiftUI

struct HeatMapLegendView: View {
    var body: some View {
        HStack(spacing: 20) {
            Text("Signal Strength:")
                .font(.subheadline)
                .fontWeight(.medium)

            HStack(spacing: 12) {
                ForEach(SignalStrength.allCases, id: \.self) { strength in
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(strength.color.opacity(0.6))
                            .frame(width: 20, height: 12)

                        Text(strength.rawValue)
                            .font(.caption)
                    }
                }
            }

            Spacer()

            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .foregroundColor(.secondary)
                Text("Zoom: Pinch • Pan: Drag")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    HeatMapLegendView()
        .padding()
}
