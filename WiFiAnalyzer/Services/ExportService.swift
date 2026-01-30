import Foundation
import AppKit

enum ExportFormat {
    case csv
    case json
}

enum ExportError: LocalizedError {
    case encodingFailed
    case fileCreationFailed
    case invalidData

    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode measurement data"
        case .fileCreationFailed:
            return "Failed to create export file"
        case .invalidData:
            return "Invalid measurement data"
        }
    }
}

class ExportService {

    // MARK: - Export Methods

    func exportToCSV(_ measurements: [MeasurementPoint]) throws -> URL {
        guard !measurements.isEmpty else {
            throw ExportError.invalidData
        }

        var csvString = "Location,SSID,BSSID,RSSI (dBm),Signal Quality,Date,Time\n"

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss"

        for measurement in measurements {
            let signalQuality = measurement.signalStrength.rawValue
            let date = dateFormatter.string(from: measurement.timestamp)
            let time = timeFormatter.string(from: measurement.timestamp)

            // Escape fields that might contain commas
            let location = escapeCSVField(measurement.locationName)
            let ssid = escapeCSVField(measurement.ssid)

            csvString += "\(location),\(ssid),\(measurement.bssid),\(measurement.rssi),\(signalQuality),\(date),\(time)\n"
        }

        return try saveToFile(csvString, filename: "WiFiMeasurements.csv")
    }

    func exportToJSON(_ measurements: [MeasurementPoint]) throws -> URL {
        guard !measurements.isEmpty else {
            throw ExportError.invalidData
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        guard let jsonData = try? encoder.encode(measurements) else {
            throw ExportError.encodingFailed
        }

        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw ExportError.encodingFailed
        }

        return try saveToFile(jsonString, filename: "WiFiMeasurements.json")
    }

    // MARK: - Import Methods

    func importFromCSV(_ url: URL) throws -> [MeasurementPoint] {
        guard let csvString = try? String(contentsOf: url, encoding: .utf8) else {
            throw ExportError.invalidData
        }

        let lines = csvString.components(separatedBy: .newlines).filter { !$0.isEmpty }

        guard lines.count > 1 else {
            throw ExportError.invalidData
        }

        var measurements: [MeasurementPoint] = []
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        // Skip header row
        for line in lines.dropFirst() {
            let fields = parseCSVLine(line)

            guard fields.count >= 7 else { continue }

            let location = fields[0]
            let ssid = fields[1]
            let bssid = fields[2]
            let rssi = Int(fields[3]) ?? -90
            let dateTimeString = "\(fields[5]) \(fields[6])"
            let timestamp = dateFormatter.date(from: dateTimeString) ?? Date()

            let measurement = MeasurementPoint(
                locationName: location,
                ssid: ssid,
                bssid: bssid,
                rssi: rssi,
                timestamp: timestamp
            )

            measurements.append(measurement)
        }

        return measurements
    }

    func importFromJSON(_ url: URL) throws -> [MeasurementPoint] {
        guard let jsonData = try? Data(contentsOf: url) else {
            throw ExportError.invalidData
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        guard let measurements = try? decoder.decode([MeasurementPoint].self, from: jsonData) else {
            throw ExportError.encodingFailed
        }

        return measurements
    }

    // MARK: - Helper Methods

    private func escapeCSVField(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return field
    }

    private func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var currentField = ""
        var insideQuotes = false
        var i = 0
        let characters = Array(line)

        while i < characters.count {
            let char = characters[i]

            if char == "\"" {
                if insideQuotes && i + 1 < characters.count && characters[i + 1] == "\"" {
                    // Escaped quote
                    currentField.append("\"")
                    i += 1
                } else {
                    // Toggle quote state
                    insideQuotes.toggle()
                }
            } else if char == "," && !insideQuotes {
                // Field separator
                fields.append(currentField)
                currentField = ""
            } else {
                currentField.append(char)
            }

            i += 1
        }

        // Add last field
        fields.append(currentField)

        return fields
    }

    private func saveToFile(_ content: String, filename: String) throws -> URL {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = filename
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false

        guard panel.runModal() == .OK, let url = panel.url else {
            throw ExportError.fileCreationFailed
        }

        try content.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
