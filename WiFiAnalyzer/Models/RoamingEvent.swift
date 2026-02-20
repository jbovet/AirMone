//
//  RoamingEvent.swift
//  WiFiAnalyzer
//
//  Created by Jose Bovet Derpich on 2025.
//  jose.bovet@gmail.com
//  MIT License
//

import Foundation

/// Represents a roaming event when the device switches between access points.
struct RoamingEvent: Identifiable {
    let id: UUID
    let timestamp: Date
    let fromBSSID: String
    let toBSSID: String
    let fromVendor: String?
    let toVendor: String?
    let signalBefore: Int
    let signalAfter: Int
    let ssid: String

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        fromBSSID: String,
        toBSSID: String,
        fromVendor: String? = nil,
        toVendor: String? = nil,
        signalBefore: Int,
        signalAfter: Int,
        ssid: String
    ) {
        self.id = id
        self.timestamp = timestamp
        self.fromBSSID = fromBSSID
        self.toBSSID = toBSSID
        self.fromVendor = fromVendor
        self.toVendor = toVendor
        self.signalBefore = signalBefore
        self.signalAfter = signalAfter
        self.ssid = ssid
    }

    /// Short description of the target AP (vendor or last 8 chars of BSSID)
    var toAPDescription: String {
        if let vendor = toVendor {
            return vendor
        }
        // Return last 8 characters of BSSID (e.g., "38:4b:b0")
        let components = toBSSID.split(separator: ":")
        if components.count >= 3 {
            return components.suffix(3).joined(separator: ":")
        }
        return toBSSID
    }

    /// Whether signal improved after roaming
    var signalImproved: Bool {
        signalAfter > signalBefore
    }

    /// Signal change description
    var signalChangeDescription: String {
        let delta = signalAfter - signalBefore
        if delta > 0 {
            return "+\(delta) dBm"
        } else {
            return "\(delta) dBm"
        }
    }

    /// Time since roaming event occurred
    var timeAgo: String {
        let interval = Date().timeIntervalSince(timestamp)
        if interval < 60 {
            return "just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        }
        return "long ago"
    }
}
