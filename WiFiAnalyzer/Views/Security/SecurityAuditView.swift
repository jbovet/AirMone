//
//  SecurityAuditView.swift
//  WiFiAnalyzer
//
//  Created by Jose Bovet Derpich on 2025.
//  jose.bovet@gmail.com
//  MIT License
//

import SwiftUI

/// Audits the security of the connected network and nearby access points,
/// flagging weak encryption (Open / WEP / WPA1) and recommending fixes.
struct SecurityAuditView: View {
    @StateObject private var viewModel = SecurityAuditViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                toolbarSection
                yourNetworkSection
                summarySection
                nearbyListSection
            }
            .padding()
        }
        .navigationTitle("Security Audit")
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
                .frame(maxWidth: 260)

                Toggle("Only issues", isOn: $viewModel.onlyIssues)
                    .toggleStyle(.switch)
                    .controlSize(.small)

                Spacer()

                if viewModel.isScanning {
                    ProgressView()
                        .controlSize(.small)
                        .padding(.trailing, 4)
                }

                Text("\(viewModel.issueCount) issue\(viewModel.issueCount == 1 ? "" : "s") · \(viewModel.bandFilteredNetworks.count) APs")
                    .font(.caption)
                    .foregroundColor(viewModel.issueCount > 0 ? .orange : .secondary)
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Your Network

    private var yourNetworkSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "person.fill.checkmark")
                        .foregroundColor(.blue)
                    Text("Your Network")
                        .font(.headline)
                    Spacer()
                }

                if let network = viewModel.connectedNetwork,
                   let security = network.security,
                   let rating = viewModel.connectedRating {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: rating.iconName)
                            .font(.system(size: 28))
                            .foregroundColor(rating.color)
                            .frame(width: 36)

                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 6) {
                                Text(network.ssid)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .lineLimit(1)
                                securityBadge(rating, rawSecurity: security)
                            }
                            Text(rating.advice)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                } else {
                    Text("Not connected to a WiFi network.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
    }

    // MARK: - Summary

    private var summarySection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "chart.pie.fill")
                        .foregroundColor(.blue)
                    Text("Nearby Summary")
                        .font(.headline)
                    Spacer()
                }

                if viewModel.summary.isEmpty {
                    Text(viewModel.nearbyNetworks.isEmpty
                         ? "Start scanning to audit nearby networks."
                         : "No networks on the selected band.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    HStack(spacing: 10) {
                        ForEach(SecurityRating.allCases, id: \.self) { rating in
                            let count = viewModel.summary[rating] ?? 0
                            if count > 0 {
                                summaryChip(rating, count: count)
                            }
                        }
                        Spacer(minLength: 0)
                    }
                }
            }
            .padding()
        }
    }

    private func summaryChip(_ rating: SecurityRating, count: Int) -> some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(rating.color)
            Text(rating.rawValue)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(rating.color.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Nearby list

    private var nearbyListSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Image(systemName: "list.bullet.rectangle")
                        .foregroundColor(.blue)
                    Text("Nearby Networks")
                        .font(.headline)
                    Spacer()
                }
                .padding(.bottom, 8)

                if let error = viewModel.errorMessage {
                    errorView(error)
                } else if viewModel.auditedNetworks.isEmpty {
                    emptyStateView
                } else {
                    ForEach(viewModel.auditedNetworks) { network in
                        auditRow(network)
                        Divider()
                    }
                }
            }
            .padding()
        }
    }

    private func auditRow(_ network: NearbyNetwork) -> some View {
        let rating = SecurityRating.from(security: network.security)
        let isConnected = network.bssid == viewModel.connectedBSSID

        return HStack(alignment: .top, spacing: 12) {
            Image(systemName: isConnected ? "wifi.circle.fill" : rating.iconName)
                .font(.system(size: 18))
                .foregroundColor(isConnected ? .green : rating.color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(network.ssid)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    if isConnected {
                        Text("Connected")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.15))
                            .foregroundColor(.green)
                            .clipShape(Capsule())
                    }
                    securityBadge(rating, rawSecurity: network.security)
                }

                HStack(spacing: 8) {
                    if let vendor = network.vendor {
                        Text(vendor)
                    }
                    Text("\(network.band) · Ch \(network.channel)")
                    Text("\(network.rssi) dBm")
                        .foregroundColor(network.signalStrength.color)
                }
                .font(.caption2)
                .foregroundColor(.secondary)

                if rating.isIssue {
                    Text(rating.advice)
                        .font(.caption2)
                        .foregroundColor(rating.color)
                }
            }
            Spacer()
        }
        .padding(.vertical, 8)
    }

    private func securityBadge(_ rating: SecurityRating, rawSecurity: String) -> some View {
        Text(rawSecurity)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(rating.color.opacity(0.15))
            .foregroundColor(rating.color)
            .clipShape(Capsule())
    }

    // MARK: - States

    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.shield")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text(viewModel.onlyIssues ? "No insecure networks nearby" : "No networks found")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(viewModel.onlyIssues ? "Nothing flagged with the current filter." : "Start scanning to audit nearby networks.")
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
}

#Preview {
    SecurityAuditView()
}
