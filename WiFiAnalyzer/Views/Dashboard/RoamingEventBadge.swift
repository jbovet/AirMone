//
//  RoamingEventBadge.swift
//  WiFiAnalyzer
//
//  Created by Jose Bovet Derpich on 2025.
//  jose.bovet@gmail.com
//  MIT License
//

import SwiftUI

/// A badge notification displayed when a roaming event is detected.
///
/// Shows the target AP information, signal change, and auto-dismisses after a few seconds.
struct RoamingEventBadge: View {
    let event: RoamingEvent
    let onDismiss: () -> Void

    @State private var isVisible = true

    var body: some View {
        if isVisible {
            HStack(spacing: 10) {
                // Roaming icon with info tooltip
                Image(systemName: "arrow.triangle.swap")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.orange)
                    .help("Roaming detected: Your device switched to a different access point")

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("Roamed to \(event.toAPDescription)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.primary)

                        // Info icon with detailed tooltip
                        Image(systemName: "info.circle")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                            .help(detailedTooltip)
                    }

                    HStack(spacing: 8) {
                        // Signal change
                        HStack(spacing: 2) {
                            Image(systemName: event.signalImproved ? "arrow.up" : "arrow.down")
                                .font(.system(size: 9))
                            Text("\(event.signalAfter) dBm")
                                .font(.system(size: 10))
                        }
                        .foregroundColor(event.signalImproved ? .green : .red)
                        .help(event.signalImproved
                            ? "Signal improved after roaming"
                            : "Signal weakened after roaming - your device may have roamed due to network load balancing")

                        Text("(\(event.signalChangeDescription))")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)

                        Text("•")
                            .foregroundColor(.secondary)

                        Text(event.timeAgo)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Dismiss button
                Button(action: dismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Dismiss notification")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.orange.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color.orange.opacity(0.3), lineWidth: 1)
                    )
            )
            .transition(.asymmetric(
                insertion: .move(edge: .top).combined(with: .opacity),
                removal: .opacity
            ))
            .onAppear {
                // Auto-dismiss after 8 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                    dismiss()
                }
            }
        }
    }

    private var detailedTooltip: String {
        var lines = [
            "WiFi Roaming Event",
            "",
            "Your device switched access points while staying on the same network (\(event.ssid)).",
            "",
            "From: \(event.fromBSSID)"
        ]
        if let fromVendor = event.fromVendor {
            lines.append("       (\(fromVendor))")
        }
        lines.append("To:   \(event.toBSSID)")
        if let toVendor = event.toVendor {
            lines.append("       (\(toVendor))")
        }
        lines.append("")
        lines.append("Signal: \(event.signalBefore) dBm → \(event.signalAfter) dBm")

        return lines.joined(separator: "\n")
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.3)) {
            isVisible = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        RoamingEventBadge(
            event: RoamingEvent(
                fromBSSID: "aa:bb:cc:dd:ee:f0",
                toBSSID: "aa:bb:cc:dd:ee:f1",
                fromVendor: "Eero",
                toVendor: "Huawei",
                signalBefore: -65,
                signalAfter: -52,
                ssid: "BOVET"
            ),
            onDismiss: {}
        )

        RoamingEventBadge(
            event: RoamingEvent(
                fromBSSID: "aa:bb:cc:dd:ee:f1",
                toBSSID: "aa:bb:cc:dd:ee:f2",
                fromVendor: nil,
                toVendor: nil,
                signalBefore: -52,
                signalAfter: -68,
                ssid: "BOVET"
            ),
            onDismiss: {}
        )
    }
    .padding()
    .frame(width: 400)
}
