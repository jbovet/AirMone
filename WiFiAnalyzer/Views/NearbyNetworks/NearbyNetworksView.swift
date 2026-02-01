import SwiftUI

struct NearbyNetworksView: View {
    @StateObject private var viewModel = NearbyNetworksViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                toolbarSection
                chartSection
                networkListSection
            }
            .padding()
        }
        .navigationTitle("Nearby Networks")
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

                Picker("Sort", selection: $viewModel.sortOrder) {
                    ForEach(NearbyNetworksViewModel.SortOrder.allCases, id: \.self) { order in
                        Text(order.rawValue).tag(order)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 100)

                Spacer()

                if viewModel.isScanning {
                    ProgressView()
                        .controlSize(.small)
                        .padding(.trailing, 4)
                }

                Text("\(viewModel.networkGroups.count) networks (\(viewModel.totalNetworkCount) APs)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Chart

    private var chartSection: some View {
        SignalHistoryChartView(
            history: viewModel.chartSignalHistory,
            currentSSID: nil,
            currentBand: nil,
            ssidOrder: viewModel.topSSIDsBySignal
        )
    }

    // MARK: - Network List

    private var networkListSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Image(systemName: "list.bullet")
                        .foregroundColor(.blue)
                    Text("Discovered Networks")
                        .font(.headline)
                    Spacer()
                }
                .padding(.bottom, 8)

                if let error = viewModel.errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                } else if viewModel.networkGroups.isEmpty && !viewModel.isScanning {
                    emptyStateView
                } else {
                    networkTable
                }
            }
            .padding()
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("No networks found")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("Start scanning to discover nearby WiFi networks")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 150)
        .frame(maxWidth: .infinity)
    }

    private var networkTable: some View {
        VStack(spacing: 0) {
            // Table header
            HStack(spacing: 0) {
                Text("Network")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Ch")
                    .frame(width: 70, alignment: .center)
                Text("Band")
                    .frame(width: 80, alignment: .center)
                Text("Signal")
                    .frame(width: 80, alignment: .trailing)
                Text("SNR")
                    .frame(width: 60, alignment: .trailing)
                Text("Security")
                    .frame(width: 120, alignment: .trailing)
            }
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.secondary)
            .padding(.vertical, 6)
            .padding(.horizontal, 4)

            Divider()

            ForEach(viewModel.networkGroups) { group in
                NetworkGroupRowView(
                    group: group,
                    color: SSIDColorPalette.color(
                        for: group.ssid,
                        in: viewModel.uniqueNetworkNames
                    ),
                    isExpanded: viewModel.isExpanded(group.ssid),
                    onToggle: { viewModel.toggleExpanded(group.ssid) }
                )
                Divider()
            }
        }
    }
}

#Preview {
    NearbyNetworksView()
}
