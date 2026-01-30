import Foundation

struct SignalDataPoint: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let rssi: Int

    init(id: UUID = UUID(), timestamp: Date = Date(), rssi: Int) {
        self.id = id
        self.timestamp = timestamp
        self.rssi = rssi
    }

    var signalStrength: SignalStrength {
        SignalStrength.from(rssi: rssi)
    }

    var relativeTime: TimeInterval {
        Date().timeIntervalSince(timestamp)
    }
}
