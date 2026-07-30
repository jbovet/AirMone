//
//  ChannelAnalyzerView.swift
//  WiFiAnalyzer
//
//  Created by Jose Bovet Derpich on 2025.
//  jose.bovet@gmail.com
//  MIT License
//

import SwiftUI
import Charts

/// Shows how congested each WiFi channel is, based on the number and strength of
/// nearby access points (plus adjacent-channel overlap on 2.4 GHz), and recommends
/// the least-congested channel per band.
struct ChannelAnalyzerView: View {
    @StateObject private var viewModel = ChannelAnalyzerViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                toolbarSection
                recommendationSection
                chartSection
                channelListSection
            }
            .padding()
        }
        .navigationTitle("Channel Analyzer")
        .onAppear { viewModel.startScanning() }
        .onDisappear { viewModel.stopScanning() }
    }

    // MARK: - Toolbar

    private var toolbarSection: some View {
        GroupBox {
            HStack(spacing: 16) {
                Button {
                    if viewModel.isScanning {
                        viewModel.stopScanning()
                    } else {
                        viewModel.startScanning()
                    }
                } label: {
                    Label(
                        viewModel.isScanning ? "Stop" : "Scan",
                        systemImage: viewModel.isScanning ? "stop.fill" : "antenna.radiowaves.left.and.right"
                    )
                }
                .controlSize(.regular)

                Picker("Band", selection: $viewModel.selectedBandFilter) {
                    ForEach(NearbyNetworksViewModel.BandFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .frame(maxWidth: 300)

                Spacer()

                if viewModel.isScanning {
                    ProgressView()
                        .controlSize(.small)
                        .padding(.trailing, 4)
                }

                Text("\(viewModel.channelCongestion.count) channels (\(viewModel.nearbyNetworks.count) APs)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Recommendation

    private var recommendationSection: some View {
        let recommendations = viewModel.recommendationsByBand
            .values
            .sorted { $0.band < $1.band }

        return GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                    Text("Recommended Channels")
                        .font(.headline)
                    Spacer()
                }

                if recommendations.isEmpty {
                    Text("Start scanning to get a channel recommendation for each band.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    HStack(spacing: 12) {
                        ForEach(recommendations) { rec in
                            recommendationCard(rec)
                        }
                        Spacer(minLength: 0)
                    }
                }
            }
            .padding()
        }
    }

    private func recommendationCard(_ rec: ChannelRecommendation) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(rec.band)
                .font(.caption)
                .foregroundColor(.secondary)
            Text("Ch \(rec.channel)")
                .font(.title2)
                .fontWeight(.bold)
            Text(rec.rating.rawValue)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(rec.rating.color)
        }
        .padding(12)
        .frame(minWidth: 100, alignment: .leading)
        .background(rec.rating.color.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Chart

    private var chartSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "chart.bar.xaxis")
                        .foregroundColor(.blue)
                    Text("Congestion by Channel")
                        .font(.headline)
                    Spacer()
                }

                if let error = viewModel.errorMessage {
                    errorView(error)
                } else if viewModel.channelCongestion.isEmpty {
                    emptyStateView
                } else {
                    congestionChart
                }
            }
            .padding()
        }
    }

    private var congestionChart: some View {
        Chart(viewModel.channelCongestion) { level in
            BarMark(
                x: .value("Channel", "\(level.band) Ch \(level.channel)"),
                y: .value("Congestion", level.score)
            )
            .foregroundStyle(level.rating.color)
            .annotation(position: .top) {
                Text("\(level.apCount) AP\(level.apCount == 1 ? "" : "s")")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(height: 250)
        .chartXAxis {
            AxisMarks(position: .bottom) { _ in
                AxisValueLabel()
                    .font(.caption2)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .chartYScale(domain: yAxisRange)
    }

    /// Y-axis from 0 to the busiest channel, with a little headroom.
    private var yAxisRange: ClosedRange<Double> {
        let maxScore = viewModel.channelCongestion.map(\.score).max() ?? 1.0
        return 0...(max(maxScore, 1.0) + 0.5)
    }

    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("No channel data")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("Start scanning to see how busy each channel is")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 150)
        .frame(maxWidth: .infinity)
    }

    private func errorView(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Channel List

    private var channelListSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Image(systemName: "list.bullet")
                        .foregroundColor(.blue)
                    Text("Channel Details")
                        .font(.headline)
                    Spacer()
                }
                .padding(.bottom, 8)

                if viewModel.channelCongestion.isEmpty {
                    emptyStateView
                } else {
                    channelTable
                }
            }
            .padding()
        }
    }

    private var channelTable: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text("Band")
                    .frame(width: 70, alignment: .leading)
                Text("Ch")
                    .frame(width: 50, alignment: .center)
                Text("APs")
                    .frame(width: 50, alignment: .trailing)
                Text("Overlap")
                    .frame(width: 70, alignment: .trailing)
                Text("Level")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 12)
            }
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.secondary)
            .padding(.vertical, 6)
            .padding(.horizontal, 4)

            Divider()

            ForEach(viewModel.channelCongestion) { level in
                channelRow(level)
                Divider()
            }
        }
    }

    private func channelRow(_ level: ChannelCongestion) -> some View {
        let isRecommended = viewModel.recommendationsByBand[level.band]?.channel == level.channel

        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 0) {
                Text(level.band)
                    .frame(width: 70, alignment: .leading)
                Text("\(level.channel)")
                    .frame(width: 50, alignment: .center)
                Text("\(level.apCount)")
                    .frame(width: 50, alignment: .trailing)
                Text("\(level.overlappingAPCount)")
                    .frame(width: 70, alignment: .trailing)
                    .foregroundColor(level.overlappingAPCount > level.apCount ? .orange : .primary)

                HStack(spacing: 8) {
                    SignalQualityBar(percent: congestionPercent(level.score), color: level.rating.color)
                        .frame(width: 60)
                    Text(level.rating.rawValue)
                        .font(.caption)
                        .foregroundColor(level.rating.color)
                    if isRecommended {
                        Text("Best")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.15))
                            .foregroundColor(.green)
                            .clipShape(Capsule())
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 12)
            }
            .font(.system(.body, design: .monospaced))

            if !level.ssids.isEmpty {
                Text(level.ssids.joined(separator: " · "))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    // Align under the metric columns (Band+Ch+APs+Overlap = 240) + list padding.
                    .padding(.leading, 240 + 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
    }

    /// Maps a congestion score to a 0–100 fill for the level bar. A score of 4+
    /// (several strong co-channel APs) fills the bar.
    private func congestionPercent(_ score: Double) -> Int {
        Int(min(max(score / 4.0, 0), 1) * 100)
    }
}

#Preview {
    ChannelAnalyzerView()
}
