import Foundation
import Combine

enum PersistenceError: LocalizedError {
    case encodingFailed
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to save measurement data. Please try again."
        case .decodingFailed:
            return "Failed to read saved measurements. Data may be corrupted."
        }
    }
}

class PersistenceService {
    static let shared = PersistenceService()

    private let userDefaults: UserDefaults
    private let measurementsKey = "savedMeasurements"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    /// Publishes whenever measurements data changes (save, delete, append)
    let dataChanged = PassthroughSubject<Void, Never>()

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    func save(_ measurements: [MeasurementPoint]) throws {
        guard let data = try? encoder.encode(measurements) else {
            throw PersistenceError.encodingFailed
        }
        userDefaults.set(data, forKey: measurementsKey)
        dataChanged.send()
    }

    func load() -> [MeasurementPoint] {
        guard let data = userDefaults.data(forKey: measurementsKey),
              let measurements = try? decoder.decode([MeasurementPoint].self, from: data) else {
            return []
        }
        return measurements
    }

    func append(_ measurement: MeasurementPoint) throws {
        var measurements = load()
        measurements.append(measurement)
        try save(measurements)
    }

    func delete(id: UUID) throws {
        var measurements = load()
        measurements.removeAll { $0.id == id }
        try save(measurements)
    }

    func deleteAll() throws {
        try save([])
    }
}
