import SwiftUI
import Charts

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
            // Overview Section
            overviewSection

            // Signal Quality Distribution
            signalQualitySection

            // Location Statistics
            locationStatisticsSection

            // SSID Statistics
            ssidStatisticsSection
        }
        .padding()
    }

    // MARK: - Overview Section

    private var overviewSection: some View {
        GroupBox {
            VStack(spacing: 16) {
                HStack {
                    Text("Overview")
                        .font(.headline)
                    Spacer()
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
                Text("Signal Quality Distribution")
                    .font(.headline)

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

    // MARK: - SSID Statistics Section

    private var ssidStatisticsSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 16) {
                Text("Network Statistics")
                    .font(.headline)

                HStack(spacing: 32) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Unique Networks")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("\(viewModel.uniqueSSIDCount)")
                            .font(.title)
                            .fontWeight(.bold)
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Most Frequent Network")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(viewModel.mostFrequentSSID ?? "N/A")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                if viewModel.ssidCounts.count > 1 {
                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Network Frequency")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        ForEach(viewModel.ssidCounts.prefix(5), id: \.ssid) { item in
                            HStack {
                                Text(item.ssid)
                                    .lineLimit(1)
                                Spacer()
                                Text("\(item.count) measurement\(item.count == 1 ? "" : "s")")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Supporting Views

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
