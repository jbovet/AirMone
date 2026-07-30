//
//  PersistenceService.swift
//  WiFiAnalyzer
//
//  Created by Jose Bovet Derpich on 2025.
//  jose.bovet@gmail.com
//  MIT License
//

import Foundation
import Combine

/// Errors that can occur during measurement data persistence.
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

/// Manages CRUD operations for ``MeasurementPoint`` data using `UserDefaults`.
///
/// Uses JSON encoding/decoding with ISO 8601 date formatting.
/// Publishes a ``dataChanged`` event via Combine so ViewModels can react to data mutations.
class PersistenceService {
    static let shared = PersistenceService()

    private let userDefaults: UserDefaults
    private let measurementsKey = "savedMeasurements"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    /// Serializes access to ``cache`` so `load()`/`save()` are safe across threads.
    private let lock = NSLock()

    /// In-memory copy of the persisted measurements, lazily populated on first
    /// `load()` and kept in sync on every mutation. `load()` is reachable from
    /// SwiftUI `body` (e.g. via computed ViewModel properties), so this avoids
    /// decoding the full UserDefaults blob on every view update. All writes go
    /// through this service, so the cache never goes stale.
    private var cache: [MeasurementPoint]?

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
        lock.lock()
        cache = measurements
        lock.unlock()
        dataChanged.send()
    }

    func load() -> [MeasurementPoint] {
        lock.lock()
        defer { lock.unlock() }

        if let cache {
            return cache
        }

        let measurements: [MeasurementPoint]
        if let data = userDefaults.data(forKey: measurementsKey),
           let decoded = try? decoder.decode([MeasurementPoint].self, from: data) {
            measurements = decoded
        } else {
            measurements = []
        }
        cache = measurements
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
