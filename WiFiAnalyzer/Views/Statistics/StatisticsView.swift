//
//  StatisticsView.swift
//  WiFiAnalyzer
//
//  Created by Jose Bovet Derpich on 2025.
//  jose.bovet@gmail.com
//  MIT License
//

import SwiftUI
import Charts

/// Statistics dashboard with overview cards, signal quality distribution chart,
/// location rankings, and per-SSID network comparison table.
struct StatisticsView: View {
    @StateObject private var viewModel = StatisticsViewModel()

    var body: some View {
        ScrollView {
            if viewModel.measurements.isEmpty {
                emptyStateView
            } else {
                statisticsContent
            }
        }
        .navigationTitle("Statistics")
        .onAppear {
            viewModel.loadMeasurements()
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No Statistics Available")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Take some measurements to see statistics about your WiFi signal strength.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }

    private var statisticsContent: some View {
        VStack(spacing: 24) {
            // SSID Filter
            ssidFilterSection

            // Overview Section
            overviewSection

            // Signal Quality Distribution
            signalQualitySection

            // Location Statistics
            locationStatisticsSection

            // Network Comparison (only when "All Networks" and 2+ SSIDs)
            if viewModel.selectedSSID == nil && viewModel.perSSIDStats.count > 1 {
                networkComparisonSection
            }
        }
        .padding()
    }

    // MARK: - SSID Filter

    private var ssidFilterSection: some View {
        GroupBox {
            HStack {
                Image(systemName: "wifi")
                    .foregroundColor(.blue)
                Text("Network Filter")
                    .font(.headline)

                Spacer()

                Picker("Network", selection: $viewModel.selectedSSID) {
                    Text("All Networks").tag(nil as String?)
                    Divider()
                    ForEach(viewModel.uniqueSSIDs, id: \.self) { ssid in
                        HStack {
                            Circle()
                                .fill(SSIDColorPalette.color(for: ssid, in: viewModel.uniqueSSIDs))
                                .frame(width: 8, height: 8)
                            Text(ssid)
                        }
                        .tag(ssid as String?)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: 200)
            }
            .padding(8)
        }
    }

    // MARK: - Overview Section

    private var overviewSection: some View {
        GroupBox {
            VStack(spacing: 16) {
                HStack {
                    Text("Overview")
                        .font(.headline)
                    Spacer()
                    if let ssid = viewModel.selectedSSID {
                        ssidBadge(ssid)
                    }
                }

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    StatisticCard(
                        title: "Total Measurements",
                        value: "\(viewModel.totalMeasurements)",
                        icon: "chart.bar.fill",
                        color: .blue
                    )

                    StatisticCard(
                        title: "Average Signal",
                        value: viewModel.averageSignalStrength.rawValue,
                        subtitle: "\(viewModel.averageRSSI) dBm",
                        icon: "wifi",
                        color: viewModel.averageSignalStrength.color
                    )

                    StatisticCard(
                        title: "Std. Deviation",
                        value: String(format: "±%.1f", viewModel.rssiStandardDeviation),
                        subtitle: "dBm",
                        icon: "waveform.path.ecg",
                        color: .purple
                    )

                    StatisticCard(
                        title: "Best Signal",
                        value: "\(viewModel.bestRSSI) dBm",
                        icon: "arrow.up.circle.fill",
                        color: .green
                    )

                    StatisticCard(
                        title: "Worst Signal",
                        value: "\(viewModel.worstRSSI) dBm",
                        icon: "arrow.down.circle.fill",
                        color: .red
                    )

                    StatisticCard(
                        title: "Date Range",
                        value: viewModel.measurementDateRange,
                        icon: "calendar",
                        color: .orange
                    )
                }
            }
            .padding()
        }
    }

    // MARK: - Signal Quality Section

    private var signalQualitySection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Signal Quality Distribution")
                        .font(.headline)
                    Spacer()
                    if let ssid = viewModel.selectedSSID {
                        ssidBadge(ssid)
                    }
                }

                Chart(viewModel.signalQualityDistribution) { item in
                    BarMark(
                        x: .value("Count", item.count),
                        y: .value("Quality", item.quality.rawValue)
                    )
                    .foregroundStyle(item.quality.color)
                    .annotation(position: .trailing) {
                        if item.count > 0 {
                            Text("\(item.count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(height: 250)
                .chartXAxis {
                    AxisMarks(position: .bottom)
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            }
            .padding()
        }
    }

    // MARK: - Location Statistics Section

    private var locationStatisticsSection: some View {
        HStack(alignment: .top, spacing: 16) {
            // Best Locations
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.green)
                        Text("Best Locations")
                            .font(.headline)
                        Spacer()
                        if let ssid = viewModel.selectedSSID {
                            ssidBadge(ssid)
                        }
                    }

                    if viewModel.bestLocations.isEmpty {
                        Text("No data")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        ForEach(viewModel.bestLocations) { location in
                            LocationStatRow(location: location)
                        }
                    }
                }
                .padding()
            }
            .frame(maxWidth: .infinity)

            // Worst Locations
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text("Worst Locations")
                            .font(.headline)
                        Spacer()
                        if let ssid = viewModel.selectedSSID {
                            ssidBadge(ssid)
                        }
                    }

                    if viewModel.worstLocations.isEmpty {
                        Text("No data")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        ForEach(viewModel.worstLocations) { location in
                            LocationStatRow(location: location)
                        }
                    }
                }
                .padding()
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Network Comparison Section

    private var networkComparisonSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "arrow.left.arrow.right")
                        .foregroundColor(.blue)
                    Text("Network Comparison")
                        .font(.headline)
                }

                // Table header
                HStack(spacing: 0) {
                    Text("Network")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Count")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 60, alignment: .trailing)
                    Text("Avg Signal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 90, alignment: .trailing)
                    Text("Best")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 70, alignment: .trailing)
                    Text("Worst")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 70, alignment: .trailing)
                    Text("Quality")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 80, alignment: .trailing)
                }
                .padding(.horizontal, 4)

                Divider()

                ForEach(viewModel.perSSIDStats) { stat in
                    networkComparisonRow(stat)
                }
            }
            .padding()
        }
    }

    private func networkComparisonRow(_ stat: SSIDStatistics) -> some View {
        HStack(spacing: 0) {
            // SSID name with color dot
            HStack(spacing: 6) {
                Circle()
                    .fill(SSIDColorPalette.color(for: stat.ssid, in: viewModel.uniqueSSIDs))
                    .frame(width: 10, height: 10)
                Text(stat.ssid)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Measurement count
            Text("\(stat.measurementCount)")
                .font(.subheadline)
                .frame(width: 60, alignment: .trailing)

            // Average RSSI
            Text("\(stat.averageRSSI) dBm")
                .font(.subheadline)
                .fontWeight(.semibold)
                .frame(width: 90, alignment: .trailing)

            // Best RSSI
            Text("\(stat.bestRSSI)")
                .font(.subheadline)
                .foregroundColor(.green)
                .frame(width: 70, alignment: .trailing)

            // Worst RSSI
            Text("\(stat.worstRSSI)")
                .font(.subheadline)
                .foregroundColor(.red)
                .frame(width: 70, alignment: .trailing)

            // Signal quality badge
            Text(stat.signalStrength.rawValue)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(stat.signalStrength.color)
                .cornerRadius(8)
                .frame(width: 80, alignment: .trailing)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
    }

    // MARK: - Helpers

    private func ssidBadge(_ ssid: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(SSIDColorPalette.color(for: ssid, in: viewModel.uniqueSSIDs))
                .frame(width: 8, height: 8)
            Text(ssid)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(SSIDColorPalette.color(for: ssid, in: viewModel.uniqueSSIDs).opacity(0.12))
        .cornerRadius(10)
    }
}

// MARK: - Supporting Views

/// A compact card displaying a single statistic with an icon, title, value, and optional subtitle.
struct StatisticCard: View {
    let title: String
    let value: String
    var subtitle: String?
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }
}

/// A row showing a location name with its measurement count and average signal strength.
struct LocationStatRow: View {
    let location: LocationStatistics

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(location.locationName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text("\(location.measurementCount) measurement\(location.measurementCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(location.averageRSSI) dBm")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(location.signalStrength.rawValue)
                    .font(.caption)
                    .foregroundColor(location.signalStrength.color)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        StatisticsView()
    }
}
