//
//  SignalStrengthGuideView.swift
//  WiFiAnalyzer
//
//  Created by Jose Bovet Derpich on 2025.
//  jose.bovet@gmail.com
//  MIT License
//

import SwiftUI

/// Reference guide card showing signal strength ranges, frequency band info, and optimization tips.
struct SignalStrengthGuideView: View {
    @State private var isExpanded: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: "Reference Guide")

            VStack(spacing: 16) {
                // Signal Strength Reference - Two Columns
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "chart.bar.fill")
                            .foregroundColor(.blue)
                            .frame(width: 16)

                        Text("Signal Strength Ranges")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }

                    // Two-column grid for signal ranges
                    HStack(alignment: .top, spacing: 20) {
                        // Left column - Excellent, Good, Fair
                        VStack(alignment: .leading, spacing: 6) {
                            SignalRangeCompactRow(strength: .excellent)
                            SignalRangeCompactRow(strength: .good)
                            SignalRangeCompactRow(strength: .fair)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        // Right column - Weak, Poor, Unusable
                        VStack(alignment: .leading, spacing: 6) {
                            SignalRangeCompactRow(strength: .weak)
                            SignalRangeCompactRow(strength: .poor)
                            SignalRangeCompactRow(strength: .unusable)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                Divider()

                // Frequency Bands
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .foregroundColor(.blue)
                            .frame(width: 16)

                        Text("Frequency Bands")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }

                    HStack(alignment: .top, spacing: 20) {
                        VStack(alignment: .leading, spacing: 6) {
                            BandInfoRow(band: "2.4 GHz", pros: "Long range", cons: "Slower, congested")
                            BandInfoRow(band: "5 GHz", pros: "Fast, less congested", cons: "Shorter range")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(alignment: .leading, spacing: 6) {
                            BandInfoRow(band: "6 GHz", pros: "Fastest, no congestion", cons: "Very short range")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                Divider()

                // Router Placement Tips
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.blue)
                            .frame(width: 16)

                        Text("Optimization Tips")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }

                    HStack(alignment: .top, spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            TipCompactRow(icon: "wifi.router", text: "Central location")
                            TipCompactRow(icon: "arrow.up.circle", text: "Elevate router")
                            TipCompactRow(icon: "cube.transparent", text: "Avoid obstacles")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(alignment: .leading, spacing: 6) {
                            TipCompactRow(icon: "antenna.radiowaves.left.and.right", text: "Reduce interference")
                            TipCompactRow(icon: "arrow.triangle.2.circlepath", text: "Update firmware")
                            TipCompactRow(icon: "gearshape", text: "Use 5 GHz for speed")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding()
        }
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }
}

/// A compact row displaying a signal strength category with its color indicator and dBm range.
struct SignalRangeCompactRow: View {
    let strength: SignalStrength

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(strength.color)
                .frame(width: 10, height: 10)

            Text(strength.rawValue)
                .font(.caption)
                .fontWeight(.medium)
                .frame(width: 70, alignment: .leading)

            Text(rssiRange(for: strength))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    private func rssiRange(for strength: SignalStrength) -> String {
        switch strength {
        case .excellent:
            return "-50 to 0 dBm"
        case .good:
            return "-60 to -50 dBm"
        case .fair:
            return "-70 to -60 dBm"
        case .weak:
            return "-80 to -70 dBm"
        case .poor:
            return "-90 to -80 dBm"
        case .unusable:
            return "< -90 dBm"
        }
    }
}

/// A row showing a frequency band with its pros and cons.
struct BandInfoRow: View {
    let band: String
    let pros: String
    let cons: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(band)
                .font(.caption)
                .fontWeight(.semibold)

            HStack(spacing: 4) {
                Text("✓")
                    .foregroundColor(.green)
                    .font(.caption2)
                Text(pros)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 4) {
                Text("✗")
                    .foregroundColor(.red)
                    .font(.caption2)
                Text(cons)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

/// A compact row with an icon and text for router optimization tips.
struct TipCompactRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 14)
                .font(.caption2)

            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    VStack {
        SignalStrengthGuideView()
            .padding()

        Spacer()
    }
    .frame(width: 800)
}
