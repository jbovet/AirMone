//
//  ChannelOverlapChartView.swift
//  WiFiAnalyzer
//
//  Created by Jose Bovet Derpich on 2025.
//  jose.bovet@gmail.com
//  MIT License
//

import SwiftUI
import Charts

/// Spectrum-style overlap chart: each access point is drawn as a bell curve on a
/// frequency axis — centered on its channel, as wide as its channel width, and as
/// tall as its signal (RSSI) — coloured by SSID. Overlapping curves make co- and
/// adjacent-channel interference visible at a glance.
///
/// The bell is a visual approximation of channel occupancy (a raised cosine), not a
/// true spectral mask. A separate chart is drawn per band, since 2.4/5/6 GHz occupy
/// different frequency ranges.
struct ChannelOverlapChartView: View {
    let networks: [NearbyNetwork]

    /// Signal floor used as the baseline of every curve (dBm).
    private let floor: Double = -100

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "waveform.path")
                        .foregroundColor(.blue)
                    Text("Channel Overlap")
                        .font(.headline)
                    Spacer()
                }

                if bands.isEmpty {
                    emptyStateView
                } else {
                    ForEach(bands, id: \.self) { band in
                        bandChart(band)
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Per-band data

    /// Bands present in the current scan, ordered 2.4 → 5 → 6 GHz.
    private var bands: [String] {
        Array(Set(networks.map(\.band))).sorted()
    }

    private func networks(in band: String) -> [NearbyNetwork] {
        networks.filter { $0.band == band }
    }

    /// SSIDs in a band, strongest first, for stable colour assignment.
    private func orderedSSIDs(in band: String) -> [String] {
        var seen: [String] = []
        for ap in networks(in: band).sorted(by: { $0.rssi > $1.rssi }) where !seen.contains(ap.ssid) {
            seen.append(ap.ssid)
        }
        return seen
    }

    private struct CurvePoint: Identifiable {
        let apID: String
        let ssid: String
        let freq: Double
        let level: Double
        var id: String { "\(apID)_\(freq)" }
    }

    /// Sampled raised-cosine bell for each AP in the band.
    private func curvePoints(in band: String) -> [CurvePoint] {
        let sampleCount = 9
        var points: [CurvePoint] = []

        for ap in networks(in: band) {
            guard let center = WiFiFrequency.centerFrequencyMHz(channel: ap.channel, band: band) else { continue }
            let halfWidth = Double(ap.channelWidth ?? 20) / 2
            let peak = Double(ap.rssi)

            for i in 0..<sampleCount {
                let fraction = Double(i) / Double(sampleCount - 1)      // 0...1
                let offset = (fraction * 2 - 1) * halfWidth             // -halfWidth...halfWidth
                // Raised cosine: 1 at center, 0 at the channel edges.
                let bell = 0.5 * (1 + cos(.pi * offset / halfWidth))
                let level = floor + (peak - floor) * bell
                points.append(CurvePoint(apID: ap.id, ssid: ap.ssid, freq: center + offset, level: level))
            }
        }
        return points
    }

    /// Channel-number ticks positioned at each occupied channel's center frequency.
    private func channelTicks(in band: String) -> [(freq: Double, channel: Int)] {
        let channels = Set(networks(in: band).map(\.channel)).sorted()
        return channels.compactMap { channel in
            WiFiFrequency.centerFrequencyMHz(channel: channel, band: band).map { (freq: $0, channel: channel) }
        }
    }

    // MARK: - Per-band chart

    private func bandChart(_ band: String) -> some View {
        let points = curvePoints(in: band)
        let ssids = orderedSSIDs(in: band)
        let ticks = channelTicks(in: band)
        let domain = frequencyDomain(in: band)

        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(band)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                Spacer()
                Text("Channel")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Chart(points) { point in
                AreaMark(
                    x: .value("Frequency", point.freq),
                    yStart: .value("Floor", floor),
                    yEnd: .value("Signal", point.level),
                    series: .value("AP", point.apID)
                )
                .foregroundStyle(SSIDColorPalette.color(for: point.ssid, in: ssids).opacity(0.18))
                .interpolationMethod(.catmullRom)

                LineMark(
                    x: .value("Frequency", point.freq),
                    y: .value("Signal", point.level),
                    series: .value("AP", point.apID)
                )
                .foregroundStyle(SSIDColorPalette.color(for: point.ssid, in: ssids))
                .lineStyle(StrokeStyle(lineWidth: 2))
                .interpolationMethod(.catmullRom)
            }
            .chartXScale(domain: domain)
            .chartXAxis {
                AxisMarks(values: ticks.map(\.freq)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel {
                        if let freq = value.as(Double.self),
                           let tick = ticks.first(where: { $0.freq == freq }) {
                            Text("\(tick.channel)")
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartYScale(domain: floor...(-30))
            .chartYAxis {
                AxisMarks(position: .leading, values: [-100, -80, -60, -40]) { value in
                    if let rssi = value.as(Int.self) {
                        AxisValueLabel { Text("\(rssi)").font(.caption2) }
                        AxisGridLine()
                    }
                }
            }
            .chartLegend(.hidden)
            .frame(height: 170)

            legend(ssids)
        }
        .padding(.bottom, 4)
    }

    /// X-axis frequency range (MHz) for a band. 2.4 GHz uses the full fixed band so
    /// channels sit in familiar positions; 5/6 GHz fit the observed channels with
    /// padding and a minimum span so a lone channel isn't a single thin spike.
    private func frequencyDomain(in band: String) -> ClosedRange<Double> {
        if band == "2.4 GHz" {
            return 2400...2500
        }

        let freqs = networks(in: band).compactMap {
            WiFiFrequency.centerFrequencyMHz(channel: $0.channel, band: band)
        }
        guard let minFreq = freqs.min(), let maxFreq = freqs.max() else {
            return band == "6 GHz" ? 5950...7130 : 5150...5900
        }

        let padding = 40.0
        var lower = minFreq - padding
        var upper = maxFreq + padding

        let minimumSpan = 160.0
        if upper - lower < minimumSpan {
            let mid = (lower + upper) / 2
            lower = mid - minimumSpan / 2
            upper = mid + minimumSpan / 2
        }
        return lower...upper
    }

    private func legend(_ ssids: [String]) -> some View {
        FlowLayout(spacing: 10) {
            ForEach(ssids, id: \.self) { ssid in
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(SSIDColorPalette.color(for: ssid, in: ssids))
                        .frame(width: 12, height: 3)
                    Text(ssid.isEmpty ? "Unknown" : ssid)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "waveform.path")
                .font(.system(size: 36))
                .foregroundColor(.secondary)
            Text("No spectrum data")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("Start scanning to see channel overlap")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 150)
        .frame(maxWidth: .infinity)
    }
}

/// Minimal wrapping layout for the legend chips.
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rows: [[CGSize]] = [[]]
        var rowWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth, !rows[rows.count - 1].isEmpty {
                rows.append([])
                rowWidth = 0
            }
            rows[rows.count - 1].append(size)
            rowWidth += size.width + spacing
        }

        let height = rows.reduce(CGFloat(0)) { acc, row in
            acc + (row.map(\.height).max() ?? 0) + spacing
        }
        return CGSize(width: maxWidth == .infinity ? rowWidth : maxWidth, height: max(0, height - spacing))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
