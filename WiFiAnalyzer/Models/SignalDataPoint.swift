//
//  SignalDataPoint.swift
//  WiFiAnalyzer
//
//  Created by Jose Bovet Derpich on 2025.
//  jose.bovet@gmail.com
//  MIT License
//

import Foundation

/// A timestamped RSSI sample used for tracking signal history over time.
///
/// Stored as part of the live scanning signal history and displayed
/// in the ``SignalHistoryChartView``.
struct SignalDataPoint: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let rssi: Int
    let ssid: String

    init(id: UUID = UUID(), timestamp: Date = Date(), rssi: Int, ssid: String = "") {
        self.id = id
        self.timestamp = timestamp
        self.rssi = rssi
        self.ssid = ssid
    }

    var signalStrength: SignalStrength {
        SignalStrength.from(rssi: rssi)
    }

    var relativeTime: TimeInterval {
        Date().timeIntervalSince(timestamp)
    }
}
