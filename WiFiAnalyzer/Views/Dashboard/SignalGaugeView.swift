import SwiftUI

struct SignalGaugeView: View {
    let rssi: Int
    var size: CGFloat = 200
    var lineWidth: CGFloat = 20

    private var signalStrength: SignalStrength {
        SignalStrength.from(rssi: rssi)
    }

    private var normalizedPercentage: Double {
        let minRSSI: Double = -90
        let maxRSSI: Double = -30
        let clampedRSSI = max(minRSSI, min(maxRSSI, Double(rssi)))
        return (clampedRSSI - minRSSI) / (maxRSSI - minRSSI)
    }

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: lineWidth)
                    .frame(width: size, height: size)

                Circle()
                    .trim(from: 0, to: normalizedPercentage)
                    .stroke(signalStrength.color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: normalizedPercentage)

                VStack(spacing: 2) {
                    Text("\(rssi)")
                        .font(.system(size: size * 0.24, weight: .bold, design: .rounded))
                        .foregroundColor(signalStrength.color)

                    Text("dBm")
                        .font(.system(size: size * 0.08, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }

            Text(signalStrength.rawValue)
                .font(.system(size: size * 0.09, weight: .semibold))
                .foregroundColor(signalStrength.color)
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        SignalGaugeView(rssi: -45)
        SignalGaugeView(rssi: -75)
    }
    .padding()
}
