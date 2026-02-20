//
//  SignalHistoryChartView.swift
//  WiFiAnalyzer
//
//  Created by Jose Bovet Derpich on 2025.
//  jose.bovet@gmail.com
//  MIT License
//

import SwiftUI
import Charts

/// A live-updating line chart showing RSSI signal history over time, grouped by SSID.
///
/// Supports both single-network mode (dashboard) and multi-network mode (nearby networks).
/// Each SSID is rendered as a separate colored line using ``SSIDColorPalette``.
struct SignalHistoryChartView: View {
    let history: [SignalDataPoint]
    var currentSSID: String? = nil
    var currentBand: String? = nil
    /// Optional pre-sorted SSID order (e.g. strongest signal first). If nil, uses insertion order.
    var ssidOrder: [String]? = nil

    /// SSIDs hidden by the user via the interactive legend.
    @State private var hiddenSSIDs: Set<String> = []

    /// Currently selected data point for tooltip display.
    @State private var selectedPoint: SignalDataPoint?

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

    /// Groups filtered to only include SSIDs the user hasn't hidden.
    private var visibleSSIDGroups: [SSIDGroup] {
        ssidGroups.filter { !hiddenSSIDs.contains($0.ssid) }
    }

    /// Dynamic Y-axis range based on visible data with padding.
    private var yAxisRange: ClosedRange<Int> {
        let visiblePoints = history.filter { !hiddenSSIDs.contains($0.ssid) }
        guard !visiblePoints.isEmpty else {
            return -100...(-20) // Default range when no data
        }

        let rssiValues = visiblePoints.map { $0.rssi }
        let minRSSI = rssiValues.min() ?? -100
        let maxRSSI = rssiValues.max() ?? -20

        // Add 10 dB padding above and below, clamped to reasonable bounds
        let lowerBound = max(-100, minRSSI - 10)
        let upperBound = min(0, maxRSSI + 10)

        return lowerBound...upperBound
    }

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                headerView
                    .zIndex(1)
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
                ForEach(visibleSSIDGroups) { group in
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
            .chartYScale(domain: yAxisRange)
            .chartLegend(.hidden)
            .chartPlotStyle { plotArea in
                plotArea.clipped()
            }
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .onContinuousHover { phase in
                            switch phase {
                            case .active(let location):
                                selectedPoint = findNearestPoint(at: location, proxy: proxy, geometry: geometry)
                            case .ended:
                                selectedPoint = nil
                            }
                        }
                }
            }
            .overlay(alignment: .topLeading) {
                if let point = selectedPoint {
                    tooltipView(for: point)
                        .transition(.opacity)
                }
            }
            .frame(height: 200)

            // SSID legend
            ssidLegendView
        }
    }

    // MARK: - SSID Legend

    private var ssidLegendView: some View {
        HStack(spacing: 12) {
            ForEach(uniqueSSIDs, id: \.self) { ssid in
                let isHidden = hiddenSSIDs.contains(ssid)
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if isHidden {
                            hiddenSSIDs.remove(ssid)
                        } else {
                            hiddenSSIDs.insert(ssid)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(isHidden ? Color.gray.opacity(0.3) : colorForSSID(ssid))
                            .frame(width: 12, height: 3)
                        Text(ssid.isEmpty ? "Unknown" : ssid)
                            .font(.caption2)
                            .foregroundColor(isHidden ? .secondary.opacity(0.4) : .secondary)
                            .strikethrough(isHidden, color: .secondary.opacity(0.4))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(isHidden ? Color.clear : colorForSSID(ssid).opacity(0.08))
                    .cornerRadius(4)
                }
                .buttonStyle(.plain)
                .help(isHidden ? "Click to show \(ssid) on chart" : "Click to hide \(ssid) from chart")
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

    // MARK: - Tooltip

    private func findNearestPoint(at location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) -> SignalDataPoint? {
        guard let plotFrame = proxy.plotFrame else { return nil }
        let plotArea = geometry[plotFrame]
        let relativeX = location.x - plotArea.origin.x
        let relativeY = location.y - plotArea.origin.y

        guard relativeX >= 0, relativeX <= plotArea.width,
              relativeY >= 0, relativeY <= plotArea.height else { return nil }

        guard let timestamp: Date = proxy.value(atX: relativeX),
              let rssiAtCursor: Int = proxy.value(atY: relativeY) else { return nil }

        // Find the closest point considering both time (X) and signal strength (Y)
        let visiblePoints = history.filter { !hiddenSSIDs.contains($0.ssid) }

        // First, filter to points near the cursor's X position (within 5 seconds)
        let nearbyInTime = visiblePoints.filter {
            abs($0.timestamp.timeIntervalSince(timestamp)) < 5.0
        }

        guard !nearbyInTime.isEmpty else {
            // Fallback to closest by time if nothing within 5 seconds
            return visiblePoints.min(by: {
                abs($0.timestamp.timeIntervalSince(timestamp)) < abs($1.timestamp.timeIntervalSince(timestamp))
            })
        }

        // Among points near in time, find the one closest to cursor's Y position (RSSI)
        return nearbyInTime.min(by: {
            abs($0.rssi - rssiAtCursor) < abs($1.rssi - rssiAtCursor)
        })
    }

    private func tooltipView(for point: SignalDataPoint) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Circle()
                    .fill(colorForSSID(point.ssid))
                    .frame(width: 8, height: 8)
                Text(point.ssid.isEmpty ? "Unknown" : point.ssid)
                    .font(.caption)
                    .fontWeight(.medium)
            }

            Text("\(point.rssi) dBm")
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.semibold)

            Text(signalQuality(for: point.rssi))
                .font(.caption2)
                .foregroundColor(signalQualityColor(for: point.rssi))

            Text(formatTooltipTime(point.timestamp))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(8)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
        }
        .padding(8)
    }

    private func signalQuality(for rssi: Int) -> String {
        switch rssi {
        case -30...0:
            return "Excellent"
        case -50 ..< -30:
            return "Very Good"
        case -60 ..< -50:
            return "Good"
        case -70 ..< -60:
            return "Fair"
        case -80 ..< -70:
            return "Weak"
        default:
            return "Poor"
        }
    }

    private func signalQualityColor(for rssi: Int) -> Color {
        switch rssi {
        case -30...0:
            return .green
        case -50 ..< -30:
            return .green
        case -60 ..< -50:
            return .blue
        case -70 ..< -60:
            return .orange
        case -80 ..< -70:
            return .orange
        default:
            return .red
        }
    }

    private func formatTooltipTime(_ date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 60 {
            return "\(seconds)s ago"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm:ss a"
            return formatter.string(from: date)
        }
    }
}

