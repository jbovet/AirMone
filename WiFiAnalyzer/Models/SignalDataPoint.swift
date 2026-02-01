import Foundation

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
