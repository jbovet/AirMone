//
//  NearbyNetworkRowView.swift
//  WiFiAnalyzer
//
//  Created by Jose Bovet Derpich on 2025.
//  jose.bovet@gmail.com
//  MIT License
//

import SwiftUI

// MARK: - Group Row (expandable)

/// An expandable row representing a group of access points sharing the same SSID.
struct NetworkGroupRowView: View {
    let group: NetworkGroup
    let color: Color
    let isExpanded: Bool
    let connectedBSSID: String?
    let distanceTrends: [String: DistanceTrend]
    let onToggle: () -> Void

    /// Check if any AP in this group is the connected AP
    private var hasConnectedAP: Bool {
        guard let connected = connectedBSSID else { return false }
        return group.accessPoints.contains { $0.bssid == connected }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Group header row
            Button(action: onToggle) {
                HStack(spacing: 0) {
                    // SSID with color indicator and expand chevron
                    HStack(spacing: 6) {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .frame(width: 12)

                        // Connected indicator or color dot
                        if hasConnectedAP {
                            Image(systemName: "wifi.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.green)
                        } else {
                            Circle()
                                .fill(color)
                                .frame(width: 10, height: 10)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 4) {
                                Text(group.ssid)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .lineLimit(1)

                                if hasConnectedAP {
                                    Text("Connected")
                                        .font(.system(size: 9, weight: .semibold))
                                        .foregroundColor(.green)
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 1)
                                        .background(Color.green.opacity(0.15))
                                        .cornerRadius(3)
                                        .help("Your device is currently connected to an AP in this network. Expand to see which one.")
                                }
                            }

                            HStack(spacing: 4) {
                                Text("\(group.apCount) AP\(group.apCount == 1 ? "" : "s")")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)

                                if group.physicalAPCount < group.apCount {
                                    Text("·")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text("\(group.physicalAPCount) device\(group.physicalAPCount == 1 ? "" : "s")")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }

                                Text("·")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)

                                Text(group.bands)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)

                                if !group.vendors.isEmpty {
                                    Text("·")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text(group.vendors.joined(separator: ", "))
                                        .font(.caption2)
                                        .foregroundColor(.blue)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Channels with width
                    VStack(spacing: 1) {
                        Text(group.channels.map(String.init).joined(separator: ", "))
                            .font(.caption)
                            .lineLimit(1)
                        if !group.channelWidths.isEmpty {
                            Text(group.channelWidths)
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(width: 100, alignment: .center)

                    // Band
                    Text(group.bands)
                        .font(.caption)
                        .lineLimit(1)
                        .frame(width: 80, alignment: .center)

                    // Best signal with quality bar
                    HStack(spacing: 4) {
                        SignalQualityBar(
                            percent: group.bestSignal.signalQualityPercent,
                            color: group.signalStrength.color
                        )
                        .frame(width: 30)

                        Text("\(group.bestRSSI) dBm")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(group.signalStrength.color)
                    }
                    .frame(width: 100, alignment: .trailing)

                    // SNR
                    Text("\(group.bestSNR) dB")
                        .font(.caption)
                        .frame(width: 60, alignment: .trailing)

                    // Security
                    Text(group.security)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .frame(width: 120, alignment: .trailing)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 4)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Expanded AP rows
            if isExpanded {
                ForEach(group.accessPoints.sorted(by: { $0.rssi > $1.rssi })) { ap in
                    AccessPointRowView(
                        network: ap,
                        color: color,
                        isConnected: ap.bssid == connectedBSSID,
                        distanceTrend: distanceTrends[ap.bssid] ?? .unknown
                    )
                    if ap.id != group.accessPoints.sorted(by: { $0.rssi > $1.rssi }).last?.id {
                        Divider().padding(.leading, 40)
                    }
                }
            }
        }
    }
}

// MARK: - Individual AP Row (shown when expanded)

/// A detail row for an individual access point, shown when a ``NetworkGroupRowView`` is expanded.
struct AccessPointRowView: View {
    let network: NearbyNetwork
    let color: Color
    let isConnected: Bool
    let distanceTrend: DistanceTrend

    var body: some View {
        VStack(spacing: 0) {
            // Main row with core metrics
            HStack(spacing: 0) {
                // Indented BSSID + Vendor
                HStack(spacing: 6) {
                    Color.clear.frame(width: 12)  // Align with chevron space

                    // Connected indicator or color circle
                    if isConnected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.green)
                    } else {
                        Circle()
                            .strokeBorder(color.opacity(0.5), lineWidth: 1.5)
                            .frame(width: 10, height: 10)
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        HStack(spacing: 4) {
                            Text(network.bssid)
                                .font(.caption)
                                .foregroundColor(isConnected ? .primary : .secondary)
                                .lineLimit(1)

                            if isConnected {
                                Text("Connected")
                                    .font(.system(size: 8, weight: .semibold))
                                    .foregroundColor(.green)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(Color.green.opacity(0.15))
                                    .cornerRadius(2)
                                    .help("This is the access point your device is currently connected to")
                            }
                        }

                        if let vendor = network.vendor {
                            Text(vendor)
                                .font(.caption2)
                                .foregroundColor(.blue)
                                .lineLimit(1)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Channel with width
                Text(network.channelDisplayString)
                    .font(.caption)
                    .frame(width: 100, alignment: .center)

                // Band
                Text(network.band)
                    .font(.caption)
                    .frame(width: 80, alignment: .center)

                // Signal with quality bar
                HStack(spacing: 4) {
                    SignalQualityBar(percent: network.signalQualityPercent, color: network.signalStrength.color)
                        .frame(width: 30)

                    Text("\(network.rssi) dBm")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(network.signalStrength.color)
                }
                .frame(width: 100, alignment: .trailing)

                // SNR
                Text("\(network.snr) dB")
                    .font(.caption2)
                    .frame(width: 60, alignment: .trailing)

                // Security
                Text(network.security)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .frame(width: 120, alignment: .trailing)
            }

            // Detail chips row
            HStack(spacing: 6) {
                Color.clear.frame(width: 28)  // Align with BSSID indent

                // Distance with trend indicator
                if let distance = network.estimatedDistanceFormatted {
                    DistanceChipWithTrend(distance: distance, trend: distanceTrend)
                }

                if let countryCode = network.countryCode, !countryCode.isEmpty {
                    APDetailChip(icon: "globe", text: countryCode)
                }

                APDetailChip(icon: "chart.bar.fill", text: "\(network.signalQualityPercent)%")

                if network.beaconInterval > 0 {
                    APDetailChip(icon: "timer", text: "\(network.beaconInterval) ms")
                }

                if network.isIBSS {
                    APDetailChip(icon: "point.3.connected.trianglepath.dotted", text: "Ad-Hoc")
                }

                Spacer()
            }
            .padding(.top, 2)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 4)
        .background(isConnected ? Color.green.opacity(0.05) : Color.primary.opacity(0.02))
    }
}

/// A small pill-shaped chip for displaying AP detail metadata.
struct APDetailChip: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 8))
            Text(text)
                .font(.system(size: 10))
        }
        .foregroundColor(.secondary)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.primary.opacity(0.05))
        .cornerRadius(4)
    }
}

/// Distance chip with trend arrow indicator showing if AP is getting closer or farther.
struct DistanceChipWithTrend: View {
    let distance: String
    let trend: DistanceTrend

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "location.fill")
                .font(.system(size: 8))
            Text(distance)
                .font(.system(size: 10))

            // Trend arrow (only show if not unknown)
            if trend != .unknown {
                Image(systemName: trend.iconName)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(trend.color)
            }
        }
        .foregroundColor(.secondary)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(trendBackground)
        .cornerRadius(4)
        .help(tooltipText)
        .accessibilityLabel("\(distance), \(trend.accessibilityLabel)")
    }

    private var trendBackground: Color {
        switch trend {
        case .gettingCloser:
            return Color.green.opacity(0.1)
        case .gettingFarther:
            return Color.red.opacity(0.1)
        default:
            return Color.primary.opacity(0.05)
        }
    }

    private var tooltipText: String {
        let base = "Estimated distance: \(distance)"
        switch trend {
        case .gettingCloser:
            return "\(base)\n↘ Getting closer - signal improving"
        case .gettingFarther:
            return "\(base)\n↗ Getting farther - signal degrading"
        case .stable:
            return "\(base)\n→ Distance stable"
        case .unknown:
            return "\(base)\nWaiting for trend data..."
        }
    }
}

/// A mini horizontal bar indicating signal quality percentage.
struct SignalQualityBar: View {
    let percent: Int
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.primary.opacity(0.08))
                    .frame(height: 4)

                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: geometry.size.width * CGFloat(percent) / 100.0, height: 4)
            }
        }
        .frame(height: 4)
    }
}
