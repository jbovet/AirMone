//
//  MeasurementPoint.swift
//  WiFiAnalyzer
//
//  Created by Jose Bovet Derpich on 2025.
//  jose.bovet@gmail.com
//  MIT License
//

import Foundation

/// A saved WiFi signal measurement at a named location.
///
/// Created when the user marks a location via the "Drop Pin" action.
/// Persisted through ``PersistenceService`` and used in statistics, exports, and heat maps.
struct MeasurementPoint: Identifiable, Codable {
    let id: UUID
    let locationName: String
    let ssid: String
    let bssid: String
    let rssi: Int
    let timestamp: Date

    init(id: UUID = UUID(), locationName: String, network: WiFiNetwork) {
        self.id = id
        self.locationName = locationName
        self.ssid = network.ssid
        self.bssid = network.bssid
        self.rssi = network.rssi
        self.timestamp = network.timestamp
    }

    init(id: UUID = UUID(), locationName: String, ssid: String, bssid: String, rssi: Int, timestamp: Date = Date()) {
        self.id = id
        self.locationName = locationName
        self.ssid = ssid
        self.bssid = bssid
        self.rssi = rssi
        self.timestamp = timestamp
    }

    var signalStrength: SignalStrength {
        SignalStrength.from(rssi: rssi)
    }
}
