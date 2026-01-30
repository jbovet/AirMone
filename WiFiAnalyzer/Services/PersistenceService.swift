import Foundation

class PersistenceService {
    private let userDefaults = UserDefaults.standard
    private let measurementsKey = "savedMeasurements"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    func save(_ measurements: [MeasurementPoint]) {
        guard let data = try? encoder.encode(measurements) else {
            print("Failed to encode measurements")
            return
        }
        userDefaults.set(data, forKey: measurementsKey)
    }

    func load() -> [MeasurementPoint] {
        guard let data = userDefaults.data(forKey: measurementsKey),
              let measurements = try? decoder.decode([MeasurementPoint].self, from: data) else {
            return []
        }
        return measurements
    }

    func append(_ measurement: MeasurementPoint) {
        var measurements = load()
        measurements.append(measurement)
        save(measurements)
    }

    func delete(id: UUID) {
        var measurements = load()
        measurements.removeAll { $0.id == id }
        save(measurements)
    }

    func deleteAll() {
        save([])
    }
}
