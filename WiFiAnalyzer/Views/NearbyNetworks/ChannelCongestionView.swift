import SwiftUI
import Charts

struct ChannelCongestionView: View {
    let congestion: [ChannelCongestion]
    let recommendations: [ChannelRecommendation]

    var body: some View {
        VStack(spacing: 16) {
            recommendationsSection
            chartSection
        }
    }

    // MARK: - Recommendations

    private var recommendationsSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("Recommended Channels")
                        .font(.headline)
                    Spacer()
                }

                if recommendations.isEmpty {
                    Text("Start scanning to get channel recommendations")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    HStack(spacing: 12) {
                        ForEach(recommendations) { rec in
                            recommendationCard(rec)
                        }
                    }
                }
            }
            .padding()
        }
    }

    private func recommendationCard(_ rec: ChannelRecommendation) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(rec.band)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                Spacer()
                congestionBadge(rec.congestionLevel)
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("Ch \(rec.channel)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(colorForCongestion(rec.congestionLevel))
            }

            Text(rec.reason)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(colorForCongestion(rec.congestionLevel).opacity(0.08))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(colorForCongestion(rec.congestionLevel).opacity(0.2), lineWidth: 1)
        )
    }

    private func congestionBadge(_ level: CongestionLevel) -> some View {
        Text(level.rawValue)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundColor(colorForCongestion(level))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(colorForCongestion(level).opacity(0.15))
            .cornerRadius(4)
    }

    // MARK: - Chart

    private var chartSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(.blue)
                    Text("Channel Congestion")
                        .font(.headline)
                    Spacer()
                }

                if congestion.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("No channel data yet")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                } else {
                    bandCharts
                }
            }
            .padding()
        }
    }

    private var bandCharts: some View {
        let bands = Dictionary(grouping: congestion, by: { $0.band })
        return VStack(spacing: 16) {
            ForEach(["2.4 GHz", "5 GHz", "6 GHz"], id: \.self) { band in
                if let channels = bands[band], !channels.isEmpty {
                    bandChart(band: band, channels: channels)
                }
            }
        }
    }

    private func bandChart(band: String, channels: [ChannelCongestion]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(band)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            Chart(channels) { channel in
                BarMark(
                    x: .value("Channel", "Ch \(channel.channel)"),
                    y: .value("Networks", channel.totalCount)
                )
                .foregroundStyle(colorForCongestion(channel.congestionLevel).gradient)
                .annotation(position: .top, alignment: .center) {
                    if channel.totalCount > 0 {
                        Text("\(channel.totalCount)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                if channel.overlappingCount > 0 {
                    BarMark(
                        x: .value("Channel", "Ch \(channel.channel)"),
                        y: .value("Overlap", channel.overlappingCount)
                    )
                    .foregroundStyle(Color.orange.opacity(0.4).gradient)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    if let count = value.as(Int.self) {
                        AxisValueLabel {
                            Text("\(count)")
                                .font(.caption2)
                        }
                        AxisGridLine()
                    }
                }
            }
            .chartYAxisLabel("Networks", position: .leading)
            .chartLegend(.hidden)
            .frame(height: 160)
        }
    }

    // MARK: - Helpers

    private func colorForCongestion(_ level: CongestionLevel) -> Color {
        switch level {
        case .free: return .green
        case .low: return .mint
        case .moderate: return .yellow
        case .high: return .orange
        case .veryHigh: return .red
        }
    }
}
