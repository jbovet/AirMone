import Foundation

struct HeatMapDataPoint: Identifiable, Equatable {
    let id: UUID
    let locationName: String
    let coordinate: LocationCoordinate
    let rssi: Int
    let timestamp: Date

    init(id: UUID = UUID(), locationName: String, coordinate: LocationCoordinate, rssi: Int, timestamp: Date = Date()) {
        self.id = id
        self.locationName = locationName
        self.coordinate = coordinate
        self.rssi = rssi
        self.timestamp = timestamp
    }

    init(from measurement: MeasurementPoint, coordinate: LocationCoordinate) {
        self.id = measurement.id
        self.locationName = measurement.locationName
        self.coordinate = coordinate
        self.rssi = measurement.rssi
        self.timestamp = measurement.timestamp
    }

    var signalStrength: SignalStrength {
        SignalStrength.from(rssi: rssi)
    }

    var x: Double { coordinate.x }
    var y: Double { coordinate.y }
}
