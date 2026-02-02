//
//  MeasurementRowView.swift
//  WiFiAnalyzer
//
//  Created by Jose Bovet Derpich on 2025.
//  jose.bovet@gmail.com
//  MIT License
//

import SwiftUI

/// A single row in the measurements list showing location, SSID, timestamp, and signal strength.
struct MeasurementRowView: View {
    let measurement: MeasurementPoint

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: measurement.timestamp)
    }

    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(measurement.signalStrength.color)
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 4) {
                Text(measurement.locationName)
                    .font(.headline)

                HStack(spacing: 8) {
                    Text(measurement.ssid)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("•")
                        .foregroundColor(.secondary)

                    Text(formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(measurement.rssi) dBm")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(measurement.signalStrength.color)

                Text(measurement.signalStrength.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    List {
        MeasurementRowView(measurement: MeasurementPoint(
            locationName: "Kitchen",
            ssid: "MyWiFi",
            bssid: "00:11:22:33:44:55",
            rssi: -55
        ))

        MeasurementRowView(measurement: MeasurementPoint(
            locationName: "Living Room",
            ssid: "MyWiFi",
            bssid: "00:11:22:33:44:55",
            rssi: -72
        ))
    }
}
