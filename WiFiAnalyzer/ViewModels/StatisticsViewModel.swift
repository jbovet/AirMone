import Foundation
import Combine

struct LocationStatistics: Identifiable {
    let id = UUID()
    let locationName: String
    let averageRSSI: Int
    let measurementCount: Int

    var signalStrength: SignalStrength {
        SignalStrength.from(rssi: averageRSSI)
    }
}

struct SignalQualityDistribution: Identifiable {
    let id = UUID()
    let quality: SignalStrength
    let count: Int
}

@MainActor
class StatisticsViewModel: ObservableObject {
    @Published var measurements: [MeasurementPoint] = []

    private let persistenceService: PersistenceService
    private var cancellables = Set<AnyCancellable>()

    init(persistenceService: PersistenceService = .shared) {
        self.persistenceService = persistenceService
        loadMeasurements()
        subscribeToDataChanges()
    }

    private func subscribeToDataChanges() {
        persistenceService.dataChanged
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.loadMeasurements()
            }
            .store(in: &cancellables)
    }

    func loadMeasurements() {
        measurements = persistenceService.load()
    }

    // MARK: - Overall Statistics

    var totalMeasurements: Int {
        measurements.count
    }

    var averageRSSI: Int {
        guard !measurements.isEmpty else { return -90 }
        let sum = measurements.reduce(0) { $0 + $1.rssi }
        return sum / measurements.count
    }

    var averageSignalStrength: SignalStrength {
        SignalStrength.from(rssi: averageRSSI)
    }

    var bestRSSI: Int {
        measurements.map(\.rssi).max() ?? -90
    }

    var worstRSSI: Int {
        measurements.map(\.rssi).min() ?? -90
    }

    var rssiStandardDeviation: Double {
        guard measurements.count > 1 else { return 0 }

        let mean = Double(averageRSSI)
        let variance = measurements.reduce(0.0) { result, measurement in
            let diff = Double(measurement.rssi) - mean
            return result + (diff * diff)
        } / Double(measurements.count - 1)

        return sqrt(variance)
    }

    // MARK: - Location Statistics

    var bestLocations: [LocationStatistics] {
        let grouped = groupByLocation()
        return grouped
            .sorted { $0.averageRSSI > $1.averageRSSI }
            .prefix(5)
            .map { $0 }
    }

    var worstLocations: [LocationStatistics] {
        let grouped = groupByLocation()
        return grouped
            .sorted { $0.averageRSSI < $1.averageRSSI }
            .prefix(5)
            .map { $0 }
    }

    private func groupByLocation() -> [LocationStatistics] {
        let grouped = Dictionary(grouping: measurements, by: { $0.locationName })

        return grouped.map { locationName, locationMeasurements in
            let averageRSSI = locationMeasurements.reduce(0) { $0 + $1.rssi } / locationMeasurements.count
            return LocationStatistics(
                locationName: locationName,
                averageRSSI: averageRSSI,
                measurementCount: locationMeasurements.count
            )
        }
    }

    // MARK: - Signal Quality Distribution

    var signalQualityDistribution: [SignalQualityDistribution] {
        let grouped = Dictionary(grouping: measurements, by: { $0.signalStrength })

        return SignalStrength.allCases.map { quality in
            SignalQualityDistribution(
                quality: quality,
                count: grouped[quality]?.count ?? 0
            )
        }
    }

    // MARK: - SSID Statistics

    var mostFrequentSSID: String? {
        guard !measurements.isEmpty else { return nil }

        let grouped = Dictionary(grouping: measurements, by: { $0.ssid })
        let sorted = grouped.sorted { $0.value.count > $1.value.count }

        return sorted.first?.key
    }

    var uniqueSSIDCount: Int {
        Set(measurements.map(\.ssid)).count
    }

    var ssidCounts: [(ssid: String, count: Int)] {
        let grouped = Dictionary(grouping: measurements, by: { $0.ssid })
        return grouped.map { (ssid: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
    }

    // MARK: - Time-based Statistics

    var oldestMeasurement: Date? {
        measurements.map(\.timestamp).min()
    }

    var newestMeasurement: Date? {
        measurements.map(\.timestamp).max()
    }

    var measurementDateRange: String {
        guard let oldest = oldestMeasurement,
              let newest = newestMeasurement else {
            return "No measurements"
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium

        if Calendar.current.isDate(oldest, inSameDayAs: newest) {
            return formatter.string(from: oldest)
        } else {
            return "\(formatter.string(from: oldest)) - \(formatter.string(from: newest))"
        }
    }
}
