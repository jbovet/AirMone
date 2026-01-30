import SwiftUI
import Charts

struct SignalHistoryChartView: View {
    let history: [SignalDataPoint]

    private var chartData: [(time: Date, rssi: Int)] {
        history.map { (time: $0.timestamp, rssi: $0.rssi) }
    }

    private var timeRange: ClosedRange<Date> {
        guard let earliest = history.first?.timestamp,
              let latest = history.last?.timestamp else {
            let now = Date()
            return now...now
        }
        return earliest...latest
    }

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "waveform.path.ecg")
                        .foregroundColor(.blue)
                    Text("Signal History")
                        .font(.headline)

                    Spacer()

                    if !history.isEmpty {
                        Text("\(history.count) readings")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if history.isEmpty {
                    emptyStateView
                } else {
                    chartView
                }
            }
            .padding()
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 40))
                .foregroundColor(.secondary)

            Text("No signal history yet")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("Start live scanning to see signal changes over time")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }

    private var chartView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Chart {
                ForEach(chartData, id: \.time) { point in
                    LineMark(
                        x: .value("Time", point.time),
                        y: .value("Signal", point.rssi)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                SignalStrength.from(rssi: point.rssi).color,
                                SignalStrength.from(rssi: point.rssi).color.opacity(0.7)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .lineStyle(StrokeStyle(lineWidth: 2))

                    AreaMark(
                        x: .value("Time", point.time),
                        y: .value("Signal", point.rssi)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                SignalStrength.from(rssi: point.rssi).color.opacity(0.3),
                                SignalStrength.from(rssi: point.rssi).color.opacity(0.05)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .second, count: 15)) { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            Text(formatRelativeTime(date))
                                .font(.caption2)
                        }
                        AxisGridLine()
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    if let rssi = value.as(Int.self) {
                        AxisValueLabel {
                            Text("\(rssi)")
                                .font(.caption2)
                        }
                        AxisGridLine()
                    }
                }
            }
            .chartYScale(domain: -100...(-30))
            .frame(height: 200)

            // Signal quality zones legend
            HStack(spacing: 16) {
                ForEach([SignalStrength.excellent, .good, .fair, .weak, .poor, .unusable], id: \.self) { quality in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(quality.color)
                            .frame(width: 8, height: 8)
                        Text(quality.rawValue)
                            .font(.caption2)
                    }
                }
            }
            .padding(.top, 4)
        }
    }

    private func formatRelativeTime(_ date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))

        if seconds < 60 {
            return "\(seconds)s"
        } else {
            let minutes = seconds / 60
            return "\(minutes)m"
        }
    }
}

#Preview {
    let sampleHistory = [
        SignalDataPoint(timestamp: Date().addingTimeInterval(-60), rssi: -45),
        SignalDataPoint(timestamp: Date().addingTimeInterval(-50), rssi: -50),
        SignalDataPoint(timestamp: Date().addingTimeInterval(-40), rssi: -55),
        SignalDataPoint(timestamp: Date().addingTimeInterval(-30), rssi: -60),
        SignalDataPoint(timestamp: Date().addingTimeInterval(-20), rssi: -65),
        SignalDataPoint(timestamp: Date().addingTimeInterval(-10), rssi: -70),
        SignalDataPoint(timestamp: Date(), rssi: -75)
    ]

    return SignalHistoryChartView(history: sampleHistory)
        .padding()
}
