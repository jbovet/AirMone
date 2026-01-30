import SwiftUI

struct NetworkInfoView: View {
    let network: WiFiNetwork

    var body: some View {
        VStack(spacing: 16) {
            // Network Identity & Addresses Section - Full Width
            VStack(alignment: .leading, spacing: 0) {
                SectionHeader(title: "Network")

                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 20) {
                        InfoRow(label: "Name", value: network.ssid, icon: "wifi")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        InfoRow(label: "BSSID", value: network.bssid, icon: "antenna.radiowaves.left.and.right")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if network.ipAddress != nil || network.routerAddress != nil {
                        HStack(spacing: 20) {
                            if let ipAddress = network.ipAddress {
                                InfoRow(label: "IP Address", value: ipAddress, icon: "network")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            } else {
                                Spacer()
                                    .frame(maxWidth: .infinity)
                            }

                            if let routerAddress = network.routerAddress {
                                InfoRow(label: "Gateway", value: routerAddress, icon: "wifi.router")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            } else {
                                Spacer()
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
                .padding()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)

            // Two Column Layout for Connection and Signal
            HStack(alignment: .top, spacing: 16) {
                // Connection Details - Left Column
                VStack(alignment: .leading, spacing: 0) {
                    SectionHeader(title: "Connection")

                    VStack(alignment: .leading, spacing: 12) {
                        if let band = network.band {
                            InfoRow(label: "Band", value: band, icon: "waveform.circle")
                        }

                        InfoRow(label: "Channel", value: channelInfo, icon: "dial.medium")

                        if let phyMode = network.phyMode {
                            InfoRow(label: "Protocol", value: phyMode, icon: "antenna.radiowaves.left.and.right.circle")
                        }

                        if let security = network.security {
                            InfoRow(
                                label: "Security",
                                value: security,
                                icon: "lock.shield",
                                valueColor: securityColor
                            )
                        }

                        if let transmitRate = network.transmitRate {
                            InfoRow(
                                label: "TX Rate",
                                value: String(format: "%.1f Mbps", transmitRate),
                                icon: "speedometer"
                            )
                        }
                    }
                    .padding()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(8)

                // Signal Quality - Right Column
                VStack(alignment: .leading, spacing: 0) {
                    SectionHeader(title: "Signal")

                    VStack(alignment: .leading, spacing: 12) {
                        InfoRow(label: "Strength", value: "\(network.rssi) dBm", icon: "chart.bar.fill")

                        if let noise = network.noise {
                            InfoRow(label: "Noise", value: "\(noise) dBm", icon: "waveform.path")
                            let snr = network.rssi - noise
                            InfoRow(
                                label: "SNR",
                                value: "\(snr) dB",
                                icon: "waveform.badge.magnifyingglass"
                            )
                            InfoRow(
                                label: "Quality",
                                value: network.signalQuality,
                                icon: "checkmark.seal"
                            )
                        }
                    }
                    .padding()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(8)
            }
        }
    }

    private var channelInfo: String {
        var info = "\(network.channel)"
        if let width = network.channelWidth {
            info += " (\(width) MHz)"
        }
        return info
    }

    private var securityColor: Color {
        guard let security = network.security else { return .secondary }

        if security.contains("WPA3") {
            return .green
        } else if security.contains("WPA2") || security.contains("Personal") {
            return .blue
        } else if security.contains("WEP") || security.contains("Open") {
            return .red
        }
        return .secondary
    }
}

struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.secondary)
            .textCase(.uppercase)
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 4)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    var icon: String? = nil
    var valueColor: Color = .primary

    var body: some View {
        HStack(spacing: 10) {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .frame(width: 18)
            }

            Text(label)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .frame(width: 85, alignment: .leading)

            Text(value)
                .fontWeight(.regular)
                .foregroundColor(valueColor)
                .textSelection(.enabled)
                .lineLimit(2)
        }
        .font(.system(size: 13))
    }
}

#Preview {
    NetworkInfoView(network: WiFiNetwork(
        ssid: "MyWiFiNetwork",
        bssid: "00:11:22:33:44:55",
        channel: 6,
        rssi: -55
    ))
    .padding()
    .frame(width: 400)
}
