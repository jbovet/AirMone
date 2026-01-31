import Foundation
import Combine

enum SortOption: String, CaseIterable {
    case chronological = "Chronological"
    case signalStrength = "Signal Strength"

    var displayName: String {
        return self.rawValue
    }
}

@MainActor
class MeasurementsViewModel: ObservableObject {
    @Published var measurements: [MeasurementPoint] = []
    @Published var sortOption: SortOption = .chronological
    @Published var searchText: String = ""
    @Published var filterQuality: SignalStrength?

    private let persistenceService: PersistenceService
    private let exportService = ExportService()

    var filteredMeasurements: [MeasurementPoint] {
        var filtered = measurements

        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { measurement in
                measurement.locationName.localizedCaseInsensitiveContains(searchText) ||
                measurement.ssid.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Apply quality filter
        if let quality = filterQuality {
            filtered = filtered.filter { $0.signalStrength == quality }
        }

        return filtered
    }

    init(persistenceService: PersistenceService = PersistenceService()) {
        self.persistenceService = persistenceService
        loadMeasurements()
    }

    func loadMeasurements() {
        measurements = persistenceService.load()
        sortMeasurements()
    }

    func deleteMeasurement(id: UUID) {
        persistenceService.delete(id: id)
        loadMeasurements()
    }

    func deleteAllMeasurements() {
        persistenceService.deleteAll()
        loadMeasurements()
    }

    func changeSortOption(_ option: SortOption) {
        sortOption = option
        sortMeasurements()
    }

    private func sortMeasurements() {
        switch sortOption {
        case .chronological:
            measurements.sort { $0.timestamp > $1.timestamp }
        case .signalStrength:
            measurements.sort { $0.rssi > $1.rssi }
        }
    }

    // MARK: - Export Methods

    func exportToCSV() -> Result<URL, Error> {
        do {
            let url = try exportService.exportToCSV(measurements)
            return .success(url)
        } catch {
            return .failure(error)
        }
    }

    func exportToJSON() -> Result<URL, Error> {
        do {
            let url = try exportService.exportToJSON(measurements)
            return .success(url)
        } catch {
            return .failure(error)
        }
    }

}
