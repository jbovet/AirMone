import SwiftUI

// MARK: - Group Row (expandable)

struct NetworkGroupRowView: View {
    let group: NetworkGroup
    let color: Color
    let isExpanded: Bool
    let onToggle: () -> Void

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

                        Circle()
                            .fill(color)
                            .frame(width: 10, height: 10)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(group.ssid)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .lineLimit(1)

                            HStack(spacing: 4) {
                                Text("\(group.apCount) AP\(group.apCount == 1 ? "" : "s")")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)

                                Text("·")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)

                                Text(group.bands)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Channels
                    Text(group.channels.map(String.init).joined(separator: ", "))
                        .font(.caption)
                        .lineLimit(1)
                        .frame(width: 70, alignment: .center)

                    // Band
                    Text(group.bands)
                        .font(.caption)
                        .lineLimit(1)
                        .frame(width: 80, alignment: .center)

                    // Best signal
                    Text("\(group.bestRSSI) dBm")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(group.signalStrength.color)
                        .frame(width: 80, alignment: .trailing)

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
                    AccessPointRowView(network: ap, color: color)
                    if ap.id != group.accessPoints.sorted(by: { $0.rssi > $1.rssi }).last?.id {
                        Divider().padding(.leading, 40)
                    }
                }
            }
        }
    }
}

// MARK: - Individual AP Row (shown when expanded)

struct AccessPointRowView: View {
    let network: NearbyNetwork
    let color: Color

    var body: some View {
        HStack(spacing: 0) {
            // Indented BSSID
            HStack(spacing: 6) {
                Color.clear.frame(width: 12)  // Align with chevron space

                Circle()
                    .strokeBorder(color.opacity(0.5), lineWidth: 1.5)
                    .frame(width: 10, height: 10)

                Text(network.bssid)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Channel
            Text("\(network.channel)")
                .font(.caption)
                .frame(width: 70, alignment: .center)

            // Band
            Text(network.band)
                .font(.caption)
                .frame(width: 80, alignment: .center)

            // Signal
            Text("\(network.rssi) dBm")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(network.signalStrength.color)
                .frame(width: 80, alignment: .trailing)

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
        .padding(.vertical, 4)
        .padding(.horizontal, 4)
        .background(Color.primary.opacity(0.02))
    }
}
