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
    @Published var errorMessage: String?

    private let persistenceService: PersistenceService
    private let exportService = ExportService()
    private var cancellables = Set<AnyCancellable>()

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
        sortMeasurements()
    }

    func deleteMeasurement(id: UUID) {
        do {
            try persistenceService.delete(id: id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteAllMeasurements() {
        do {
            try persistenceService.deleteAll()
        } catch {
            errorMessage = error.localizedDescription
        }
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
