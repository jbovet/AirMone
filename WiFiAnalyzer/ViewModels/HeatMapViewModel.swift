import Foundation
import Combine
import AppKit

@MainActor
class HeatMapViewModel: ObservableObject {
    @Published var measurements: [HeatMapDataPoint] = []
    @Published var heatMapGrid: [[Int]] = []
    @Published var isGenerating: Bool = false
    @Published var selectedSSID: String? = nil
    @Published var showCoordinateMappingSheet: Bool = false
    @Published var gridResolution: Int = 50
    @Published var errorMessage: String? = nil

    private let persistenceService: PersistenceService
    private let interpolator = HeatMapInterpolator()
    private let locationMappingService = LocationMappingService.shared

    var uniqueSSIDs: [String] {
        let allMeasurements = persistenceService.load()
        return Array(Set(allMeasurements.map(\.ssid))).sorted()
    }

    var hasCoordinates: Bool {
        locationMappingService.hasAnyCoordinates()
    }

    var unmappedLocations: [String] {
        let allMeasurements = persistenceService.load()
        let locationNames = Array(Set(allMeasurements.map(\.locationName)))
        return locationNames.filter { locationMappingService.coordinate(for: $0) == nil }
    }

    init(persistenceService: PersistenceService = PersistenceService()) {
        self.persistenceService = persistenceService
    }

    // MARK: - Data Loading

    func loadMeasurements() {
        let allMeasurements = persistenceService.load()

        // Filter by SSID if selected
        let filteredBySSID = if let ssid = selectedSSID {
            allMeasurements.filter { $0.ssid == ssid }
        } else {
            allMeasurements
        }

        // Convert to heat map data points (only those with coordinates)
        measurements = filteredBySSID.compactMap { measurement in
            guard let coordinate = measurement.coordinate else { return nil }
            return HeatMapDataPoint(from: measurement, coordinate: coordinate)
        }

        // Auto-generate grid layout for any locations missing coordinates
        if !allMeasurements.isEmpty && !unmappedLocations.isEmpty {
            autoGenerateCoordinates()
            // Reload after generating coordinates
            loadMeasurements()
            return
        }

        generateHeatMap()
    }

    private func autoGenerateCoordinates() {
        let allMeasurements = persistenceService.load()
        let locationNames = Array(Set(allMeasurements.map(\.locationName)))
        locationMappingService.applyGridLayout(for: locationNames)
    }

    // MARK: - Heat Map Generation

    func generateHeatMap() {
        guard !measurements.isEmpty else {
            heatMapGrid = []
            return
        }

        isGenerating = true
        errorMessage = nil

        Task {
            do {
                let grid = try await Task.detached(priority: .userInitiated) { [weak self] in
                    guard let self = self else { throw CancellationError() }
                    return await self.computeHeatMapGrid()
                }.value

                await MainActor.run {
                    self.heatMapGrid = grid
                    self.isGenerating = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to generate heat map: \(error.localizedDescription)"
                    self.isGenerating = false
                }
            }
        }
    }

    private func computeHeatMapGrid() async -> [[Int]] {
        interpolator.generateHeatMapGrid(
            from: measurements,
            width: gridResolution,
            height: gridResolution,
            power: 2.0
        )
    }

    // MARK: - Coordinate Management

    func updateMeasurementPosition(locationName: String, x: Double, y: Double) {
        let coordinate = LocationCoordinate(x: x, y: y)
        locationMappingService.setCoordinate(coordinate, for: locationName)
        loadMeasurements()
    }

    func saveCoordinateMapping() {
        // Mappings are automatically saved by LocationMappingService
        generateHeatMap()
    }

    func resetCoordinates() {
        locationMappingService.clearAllMappings()
        measurements.removeAll()
        heatMapGrid = []
    }
}
