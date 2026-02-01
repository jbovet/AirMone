import Foundation

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

    var networkKey: String { id }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: NearbyNetwork, rhs: NearbyNetwork) -> Bool {
        lhs.id == rhs.id
    }
}

struct NetworkGroup: Identifiable {
    let ssid: String
    let accessPoints: [NearbyNetwork]

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
}
