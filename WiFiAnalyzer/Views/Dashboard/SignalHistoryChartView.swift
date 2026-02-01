import SwiftUI
import Charts

struct SignalHistoryChartView: View {
    let history: [SignalDataPoint]
    var currentSSID: String? = nil
    var currentBand: String? = nil
    /// Optional pre-sorted SSID order (e.g. strongest signal first). If nil, uses insertion order.
    var ssidOrder: [String]? = nil

    // MARK: - SSID Color Palette

    private var uniqueSSIDs: [String] {
        if let order = ssidOrder {
            return order
        }
        var seen: [String] = []
        for point in history {
            if !seen.contains(point.ssid) {
                seen.append(point.ssid)
            }
        }
        return seen
    }

    private func colorForSSID(_ ssid: String) -> Color {
        SSIDColorPalette.color(for: ssid, in: uniqueSSIDs)
    }

    // MARK: - Chart Data

    private struct SSIDGroup: Identifiable {
        let ssid: String
        let points: [(time: Date, rssi: Int)]
        var id: String { ssid }
    }

    private var ssidGroups: [SSIDGroup] {
        let grouped = Dictionary(grouping: history, by: { $0.ssid })
        return uniqueSSIDs.compactMap { ssid in
            guard let points = grouped[ssid] else { return nil }
            return SSIDGroup(
                ssid: ssid,
                points: points.map { (time: $0.timestamp, rssi: $0.rssi) }
            )
        }
    }

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                headerView
                if history.isEmpty {
                    emptyStateView
                } else {
                    chartView
                }
            }
            .padding()
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Image(systemName: "waveform.path.ecg")
                .foregroundColor(.blue)
            Text("Signal History")
                .font(.headline)

            Spacer()

            if let ssid = currentSSID {
                HStack(spacing: 4) {
                    Circle()
                        .fill(colorForSSID(ssid))
                        .frame(width: 8, height: 8)
                    Text(ssid)
                        .font(.caption)
                        .fontWeight(.medium)
                    if let band = currentBand {
                        Text("· \(band)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(colorForSSID(ssid).opacity(0.12))
                .cornerRadius(10)
            }

            if !history.isEmpty {
                Text("\(history.count) readings")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Empty State

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

    // MARK: - Chart

    private var chartView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Chart {
                ForEach(ssidGroups) { group in
                    ForEach(group.points, id: \.time) { point in
                        LineMark(
                            x: .value("Time", point.time),
                            y: .value("Signal", point.rssi),
                            series: .value("Network", group.ssid)
                        )
                        .foregroundStyle(colorForSSID(group.ssid))
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .interpolationMethod(.catmullRom)
                    }
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
            .chartLegend(.hidden)
            .frame(height: 200)

            // SSID legend
            ssidLegendView
        }
    }

    // MARK: - SSID Legend

    private var ssidLegendView: some View {
        HStack(spacing: 16) {
            ForEach(uniqueSSIDs, id: \.self) { ssid in
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(colorForSSID(ssid))
                        .frame(width: 12, height: 3)
                    Text(ssid.isEmpty ? "Unknown" : ssid)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.top, 4)
    }

    // MARK: - Helpers

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
    let now = Date()
    let sampleHistory = [
        // BOVET (5 GHz) - stronger signal
        SignalDataPoint(timestamp: now.addingTimeInterval(-60), rssi: -42, ssid: "BOVET"),
        SignalDataPoint(timestamp: now.addingTimeInterval(-50), rssi: -45, ssid: "BOVET"),
        SignalDataPoint(timestamp: now.addingTimeInterval(-40), rssi: -48, ssid: "BOVET"),
        SignalDataPoint(timestamp: now.addingTimeInterval(-30), rssi: -44, ssid: "BOVET"),
        SignalDataPoint(timestamp: now.addingTimeInterval(-20), rssi: -46, ssid: "BOVET"),
        SignalDataPoint(timestamp: now.addingTimeInterval(-10), rssi: -43, ssid: "BOVET"),
        SignalDataPoint(timestamp: now, rssi: -41, ssid: "BOVET"),
        // TuxLabs (2.4 GHz) - weaker signal
        SignalDataPoint(timestamp: now.addingTimeInterval(-60), rssi: -62, ssid: "TuxLabs"),
        SignalDataPoint(timestamp: now.addingTimeInterval(-50), rssi: -65, ssid: "TuxLabs"),
        SignalDataPoint(timestamp: now.addingTimeInterval(-40), rssi: -68, ssid: "TuxLabs"),
        SignalDataPoint(timestamp: now.addingTimeInterval(-30), rssi: -64, ssid: "TuxLabs"),
        SignalDataPoint(timestamp: now.addingTimeInterval(-20), rssi: -66, ssid: "TuxLabs"),
        SignalDataPoint(timestamp: now.addingTimeInterval(-10), rssi: -70, ssid: "TuxLabs"),
        SignalDataPoint(timestamp: now, rssi: -63, ssid: "TuxLabs"),
    ]

    return SignalHistoryChartView(
        history: sampleHistory,
        currentSSID: "BOVET",
        currentBand: "5 GHz"
    )
    .padding()
}
