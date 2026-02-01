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

struct SSIDStatistics: Identifiable {
    let ssid: String
    let measurementCount: Int
    let averageRSSI: Int
    let bestRSSI: Int
    let worstRSSI: Int

    var id: String { ssid }

    var signalStrength: SignalStrength {
        SignalStrength.from(rssi: averageRSSI)
    }
}

@MainActor
class StatisticsViewModel: ObservableObject {
    @Published var measurements: [MeasurementPoint] = []
    @Published var selectedSSID: String? = nil

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

    // MARK: - Filtered Measurements

    var filteredMeasurements: [MeasurementPoint] {
        if let ssid = selectedSSID {
            return measurements.filter { $0.ssid == ssid }
        }
        return measurements
    }

    var uniqueSSIDs: [String] {
        let grouped = Dictionary(grouping: measurements, by: { $0.ssid })
        return grouped.sorted { $0.value.count > $1.value.count }.map(\.key)
    }

    // MARK: - Overall Statistics (operate on filteredMeasurements)

    var totalMeasurements: Int {
        filteredMeasurements.count
    }

    var averageRSSI: Int {
        guard !filteredMeasurements.isEmpty else { return -90 }
        let sum = filteredMeasurements.reduce(0) { $0 + $1.rssi }
        return sum / filteredMeasurements.count
    }

    var averageSignalStrength: SignalStrength {
        SignalStrength.from(rssi: averageRSSI)
    }

    var bestRSSI: Int {
        filteredMeasurements.map(\.rssi).max() ?? -90
    }

    var worstRSSI: Int {
        filteredMeasurements.map(\.rssi).min() ?? -90
    }

    var rssiStandardDeviation: Double {
        guard filteredMeasurements.count > 1 else { return 0 }

        let mean = Double(averageRSSI)
        let variance = filteredMeasurements.reduce(0.0) { result, measurement in
            let diff = Double(measurement.rssi) - mean
            return result + (diff * diff)
        } / Double(filteredMeasurements.count - 1)

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
        let grouped = Dictionary(grouping: filteredMeasurements, by: { $0.locationName })

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
        let grouped = Dictionary(grouping: filteredMeasurements, by: { $0.signalStrength })

        return SignalStrength.allCases.map { quality in
            SignalQualityDistribution(
                quality: quality,
                count: grouped[quality]?.count ?? 0
            )
        }
    }

    // MARK: - SSID Statistics

    var mostFrequentSSID: String? {
        guard !filteredMeasurements.isEmpty else { return nil }

        let grouped = Dictionary(grouping: filteredMeasurements, by: { $0.ssid })
        let sorted = grouped.sorted { $0.value.count > $1.value.count }

        return sorted.first?.key
    }

    var uniqueSSIDCount: Int {
        Set(filteredMeasurements.map(\.ssid)).count
    }

    var ssidCounts: [(ssid: String, count: Int)] {
        let grouped = Dictionary(grouping: filteredMeasurements, by: { $0.ssid })
        return grouped.map { (ssid: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
    }

    // MARK: - Per-SSID Comparison Statistics

    var perSSIDStats: [SSIDStatistics] {
        let grouped = Dictionary(grouping: measurements, by: { $0.ssid })

        return grouped.map { ssid, ssidMeasurements in
            let avg = ssidMeasurements.reduce(0) { $0 + $1.rssi } / ssidMeasurements.count
            return SSIDStatistics(
                ssid: ssid,
                measurementCount: ssidMeasurements.count,
                averageRSSI: avg,
                bestRSSI: ssidMeasurements.map(\.rssi).max() ?? -90,
                worstRSSI: ssidMeasurements.map(\.rssi).min() ?? -90
            )
        }
        .sorted { $0.measurementCount > $1.measurementCount }
    }

    // MARK: - Time-based Statistics

    var oldestMeasurement: Date? {
        filteredMeasurements.map(\.timestamp).min()
    }

    var newestMeasurement: Date? {
        filteredMeasurements.map(\.timestamp).max()
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
