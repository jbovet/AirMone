//
//  NearbyNetwork.swift
//  WiFiAnalyzer
//
//  Created by Jose Bovet Derpich on 2025.
//  jose.bovet@gmail.com
//  MIT License
//

import Foundation

/// Represents a discovered WiFi access point from a nearby network scan.
///
/// Identified by a composite key of SSID + BSSID. Contains radio metrics (RSSI, noise, SNR),
/// channel information, and security details.
struct NearbyNetwork: Identifiable, Hashable {
    let id: String               // Composite key: "\(ssid)_\(bssid)"
    let ssid: String
    let bssid: String
    let rssi: Int
    let noise: Int
    let channel: Int
    let band: String             // "2.4 GHz", "5 GHz", or "6 GHz"
    let channelWidth: Int?       // 20, 40, 80, 160 MHz
    let security: String
    let countryCode: String?
    let isIBSS: Bool
    let beaconInterval: Int
    let timestamp: Date

    var signalStrength: SignalStrength {
        SignalStrength.from(rssi: rssi)
    }

    var snr: Int {
        rssi - noise
    }

    /// Signal quality as a 0–100 percentage derived from RSSI.
    var signalQualityPercent: Int {
        min(max(2 * (rssi + 100), 0), 100)
    }

    /// Vendor/manufacturer name resolved from the BSSID OUI prefix.
    var vendor: String? {
        OUILookup.vendor(for: bssid)
    }

    /// Estimated distance in meters using the free-space path loss model.
    /// Uses a reference frequency derived from the band (2.4 GHz → 2437 MHz, 5 GHz → 5180 MHz).
    var estimatedDistanceMeters: Double? {
        guard rssi < 0 else { return nil }
        let frequencyMHz: Double
        if band == "2.4 GHz" {
            frequencyMHz = 2437 // Center of channel 6
        } else if band == "5 GHz" {
            frequencyMHz = 5180 // Channel 36
        } else if band == "6 GHz" {
            frequencyMHz = 5975 // Low 6 GHz
        } else {
            return nil
        }
        // FSPL: d = 10^((27.55 - 20*log10(f) + |RSSI|) / 20)
        let exponent = (27.55 - (20 * log10(frequencyMHz)) + abs(Double(rssi))) / 20.0
        let distance = pow(10, exponent)
        return max(distance, 0.1)
    }

    /// Formatted distance string (e.g. "~3.2 m" or "~12 m").
    var estimatedDistanceFormatted: String? {
        guard let distance = estimatedDistanceMeters else { return nil }
        if distance < 10 {
            return String(format: "~%.1f m", distance)
        } else {
            return String(format: "~%.0f m", distance)
        }
    }

    /// Channel display string including width (e.g. "6 (40 MHz)").
    var channelDisplayString: String {
        if let width = channelWidth, width > 0 {
            return "\(channel) (\(width) MHz)"
        }
        return "\(channel)"
    }

    var networkKey: String { id }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: NearbyNetwork, rhs: NearbyNetwork) -> Bool {
        lhs.id == rhs.id
    }
}

/// Groups multiple ``NearbyNetwork`` access points that share the same SSID.
///
/// Provides aggregated metrics (best signal, bands, channels) and is used
/// to display expandable rows in ``NearbyNetworksView``.
struct NetworkGroup: Identifiable {
    let ssid: String
    let accessPoints: [NearbyNetwork]
    /// Number of distinct physical devices, computed once at init from BSSID clustering.
    let physicalAPCount: Int

    init(ssid: String, accessPoints: [NearbyNetwork]) {
        self.ssid = ssid
        self.accessPoints = accessPoints
        self.physicalAPCount = Self.computePhysicalAPCount(from: accessPoints)
    }

    var id: String { ssid }

    var bestSignal: NearbyNetwork {
        accessPoints.max(by: { $0.rssi < $1.rssi }) ?? accessPoints[0]
    }

    var bestRSSI: Int { bestSignal.rssi }

    var signalStrength: SignalStrength {
        SignalStrength.from(rssi: bestRSSI)
    }

    var apCount: Int { accessPoints.count }

    var bands: String {
        let unique = Set(accessPoints.map { $0.band })
        return unique.sorted().joined(separator: " + ")
    }

    var channels: [Int] {
        Array(Set(accessPoints.map { $0.channel })).sorted()
    }

    var security: String {
        bestSignal.security
    }

    var bestSNR: Int {
        bestSignal.snr
    }

    /// Unique vendor names from all access points in this group.
    var vendors: [String] {
        let unique = Set(accessPoints.compactMap { $0.vendor })
        return unique.sorted()
    }

    /// Channel width summary (e.g. "20/80 MHz").
    var channelWidths: String {
        let unique = Set(accessPoints.compactMap { $0.channelWidth }).sorted()
        guard !unique.isEmpty else { return "" }
        return unique.map { "\($0)" }.joined(separator: "/") + " MHz"
    }

    /// Detects groups of APs that share the same physical device (sequential BSSIDs).
    private static func computePhysicalAPCount(from accessPoints: [NearbyNetwork]) -> Int {
        let bssids = accessPoints.compactMap { ap -> UInt64? in
            let hex = ap.bssid.replacingOccurrences(of: ":", with: "")
            return UInt64(hex, radix: 16)
        }.sorted()

        guard bssids.count > 1 else { return bssids.count }

        var groups = 1
        for i in 1..<bssids.count {
            // If MACs differ by more than 4, they're likely different physical devices
            if bssids[i] - bssids[i - 1] > 4 {
                groups += 1
            }
        }
        return groups
    }
}
