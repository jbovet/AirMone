import Foundation

class LocationMappingService {
    static let shared = LocationMappingService()

    private let userDefaults = UserDefaults.standard
    private let coordinateMappingKey = "locationCoordinateMapping"

    private var coordinateMapping: [String: LocationCoordinate] = [:]

    private init() {
        loadMapping()
    }

    // MARK: - Public Methods

    func coordinate(for locationName: String) -> LocationCoordinate? {
        coordinateMapping[locationName]
    }

    func setCoordinate(_ coordinate: LocationCoordinate, for locationName: String) {
        coordinateMapping[locationName] = coordinate
        saveMapping()
    }

    func removeCoordinate(for locationName: String) {
        coordinateMapping.removeValue(forKey: locationName)
        saveMapping()
    }

    func hasCoordinates(for locationNames: [String]) -> Bool {
        !locationNames.filter { coordinate(for: $0) == nil }.isEmpty == false
    }

    func hasAnyCoordinates() -> Bool {
        !coordinateMapping.isEmpty
    }

    func allMappings() -> [String: LocationCoordinate] {
        coordinateMapping
    }

    func clearAllMappings() {
        coordinateMapping.removeAll()
        saveMapping()
    }

    // MARK: - Automatic Grid Layout Generation

    func generateGridLayout(for locationNames: [String], gridSpacing: Double = 5.0) -> [String: LocationCoordinate] {
        let count = locationNames.count
        let cols = Int(ceil(sqrt(Double(count))))
        let rows = Int(ceil(Double(count) / Double(cols)))

        var mapping: [String: LocationCoordinate] = [:]

        for (index, locationName) in locationNames.enumerated() {
            let row = index / cols
            let col = index % cols

            // Normalize to 0-1 range
            let x = (Double(col) + 0.5) / Double(cols)
            let y = (Double(row) + 0.5) / Double(rows)

            mapping[locationName] = LocationCoordinate(x: x, y: y)
        }

        return mapping
    }

    func applyGridLayout(for locationNames: [String]) {
        let gridMapping = generateGridLayout(for: locationNames)
        for (locationName, coordinate) in gridMapping {
            coordinateMapping[locationName] = coordinate
        }
        saveMapping()
    }

    // MARK: - Persistence

    private func loadMapping() {
        guard let data = userDefaults.data(forKey: coordinateMappingKey) else {
            return
        }

        do {
            let decoder = JSONDecoder()
            coordinateMapping = try decoder.decode([String: LocationCoordinate].self, from: data)
        } catch {
            print("Failed to load coordinate mapping: \(error)")
            coordinateMapping = [:]
        }
    }

    private func saveMapping() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(coordinateMapping)
            userDefaults.set(data, forKey: coordinateMappingKey)
        } catch {
            print("Failed to save coordinate mapping: \(error)")
        }
    }

    // MARK: - Import/Export

    func exportMapping() -> Data? {
        try? JSONEncoder().encode(coordinateMapping)
    }

    func importMapping(from data: Data) throws {
        let mapping = try JSONDecoder().decode([String: LocationCoordinate].self, from: data)
        coordinateMapping = mapping
        saveMapping()
    }
}
