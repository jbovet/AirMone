//
//  MenuBarContentView.swift
//  WiFiAnalyzer
//
//  Created by Jose Bovet Derpich on 2025.
//  jose.bovet@gmail.com
//  MIT License
//

import SwiftUI
import AppKit

/// Content of the menu bar dropdown (`.window` style).
///
/// Shows a compact live view of the current WiFi connection — the reused
/// ``SignalGaugeView`` plus key connection details — and actions to open the
/// main window or quit. Driven by a dedicated ``WiFiScannerViewModel`` owned by
/// the app so it keeps updating regardless of which window/tab is visible.
struct MenuBarContentView: View {
    @ObservedObject var viewModel: WiFiScannerViewModel

    /// Window identifier used to bring the main window forward.
    static let mainWindowID = "main"

    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let network = viewModel.currentNetwork {
                connectedContent(network)
            } else {
                disconnectedContent
            }

            Divider()

            HStack {
                Button {
                    openMainWindow()
                } label: {
                    Label("Open WiFi Analyzer", systemImage: "macwindow")
                }

                Spacer()

                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Label("Quit", systemImage: "power")
                }
            }
        }
        .padding(14)
        .frame(width: 280)
    }

    // MARK: - Connected

    private func connectedContent(_ network: WiFiNetwork) -> some View {
        VStack(spacing: 10) {
            HStack {
                Circle()
                    .fill(network.signalStrength.color)
                    .frame(width: 8, height: 8)
                Text(network.ssid)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
            }

            SignalGaugeView(rssi: network.rssi, size: 150, lineWidth: 14)

            VStack(spacing: 4) {
                detailRow("Signal", "\(network.rssi) dBm · \(network.signalStrength.rawValue)")
                if let band = network.band {
                    detailRow("Band", "\(band) · Ch \(network.channel)")
                }
                if let phyMode = network.phyMode {
                    detailRow("Standard", phyMode)
                }
                if let ip = network.ipAddress {
                    detailRow("IP", ip)
                }
            }
        }
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
        }
    }

    // MARK: - Disconnected

    private var disconnectedContent: some View {
        VStack(spacing: 8) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 32))
                .foregroundColor(.secondary)
            Text("No WiFi Connection")
                .font(.subheadline)
                .fontWeight(.medium)
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - Actions

    private func openMainWindow() {
        openWindow(id: Self.mainWindowID)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
}
