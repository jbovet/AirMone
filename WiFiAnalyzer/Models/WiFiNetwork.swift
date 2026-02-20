//
//  WiFiNetwork.swift
//  WiFiAnalyzer
//
//  Created by Jose Bovet Derpich on 2025.
//  jose.bovet@gmail.com
//  MIT License
//

import Foundation

/// Represents a connected WiFi network with detailed connection metadata.
///
/// Contains identification (SSID, BSSID), signal metrics (RSSI, noise, SNR),
/// connection details (channel, band, PHY mode, security), and network addresses.
struct WiFiNetwork: Identifiable, Codable {
    let id: UUID
    let ssid: String
    let bssid: String
    let channel: Int
    let rssi: Int
    let ipAddress: String?
    let routerAddress: String?
    let band: String?            // "2.4 GHz" or "5 GHz"
    let phyMode: String?          // "802.11ac", "802.11n", etc.
    let security: String?         // Security type
    let channelWidth: Int?        // Channel bandwidth (20, 40, 80, 160 MHz)
    let transmitRate: Double?     // Current TX rate in Mbps
    let noise: Int?               // Noise level in dBm
    let timestamp: Date

    init(
        id: UUID = UUID(),
        ssid: String,
        bssid: String,
        channel: Int,
        rssi: Int,
        ipAddress: String? = nil,
        routerAddress: String? = nil,
        band: String? = nil,
        phyMode: String? = nil,
        security: String? = nil,
        channelWidth: Int? = nil,
        transmitRate: Double? = nil,
        noise: Int? = nil,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.ssid = ssid
        self.bssid = bssid
        self.channel = channel
        self.rssi = rssi
        self.ipAddress = ipAddress
        self.routerAddress = routerAddress
        self.band = band
        self.phyMode = phyMode
        self.security = security
        self.channelWidth = channelWidth
        self.transmitRate = transmitRate
        self.noise = noise
        self.timestamp = timestamp
    }

    var signalStrength: SignalStrength {
        SignalStrength.from(rssi: rssi)
    }

    /// Vendor/manufacturer name resolved from the BSSID OUI prefix.
    var vendor: String? {
        OUILookup.vendor(for: bssid)
    }

    var signalQuality: String {
        if let noise = noise, rssi != 0 {
            let snr = rssi - noise
            if snr > 40 { return "Excellent" }
            if snr > 25 { return "Good" }
            if snr > 15 { return "Fair" }
            if snr > 10 { return "Poor" }
            return "Bad"
        }
        return "Unknown"
    }
}
