import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = WiFiScannerViewModel()
    @State private var showingDropPin = false
    @State private var locationName = ""
    @State private var showingError = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let network = viewModel.currentNetwork {
                    // Signal Monitor Panel - Combines Gauge and History
                    VStack(alignment: .leading, spacing: 0) {
                        SectionHeader(title: "Signal Monitor")

                        HStack(alignment: .center, spacing: 20) {
                            // Signal Gauge - Left Side
                            SignalGaugeView(rssi: network.rssi, size: 180, lineWidth: 18)
                                .frame(width: 220)

                            // Signal History Chart - Right Side
                            SignalHistoryChartView(history: viewModel.signalHistory)
                                .frame(maxWidth: .infinity)
                        }
                        .padding()
                    }
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(8)
                    .padding(.horizontal)

                    // Network Information
                    NetworkInfoView(network: network)
                        .padding(.horizontal)

                    // Signal Strength Guide
                    SignalStrengthGuideView()
                        .padding(.horizontal)

                } else if let error = viewModel.errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "wifi.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)

                        Text("No WiFi Connection")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text(error)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        if error.contains("permission") {
                            Button("Open System Settings") {
                                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices") {
                                    NSWorkspace.shared.open(url)
                                }
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding()
                } else {
                    ProgressView("Scanning for WiFi...")
                        .padding()
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("WiFi Signal")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    showingDropPin = true
                }) {
                    Label("Drop Pin", systemImage: "mappin.circle.fill")
                }
                .help("Save current signal measurement")
                .disabled(viewModel.currentNetwork == nil)
            }
        }
        .onAppear {
            viewModel.startLiveScanning()
        }
        .onDisappear {
            viewModel.stopLiveScanning()
        }
        .sheet(isPresented: $showingDropPin) {
            locationName = ""
        } content: {
            if let network = viewModel.currentNetwork {
                DropPinView(
                    locationName: $locationName,
                    network: network,
                    onSave: {
                        viewModel.dropPin(locationName: locationName)
                    }
                )
            }
        }
    }
}

#Preview {
    NavigationStack {
        DashboardView()
    }
}
