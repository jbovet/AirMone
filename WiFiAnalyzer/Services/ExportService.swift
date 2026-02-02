//
//  ExportService.swift
//  WiFiAnalyzer
//
//  Created by Jose Bovet Derpich on 2025.
//  jose.bovet@gmail.com
//  MIT License
//

import Foundation
import AppKit

/// Supported file formats for exporting measurement data.
enum ExportFormat {
    case csv
    case json
}

/// Errors that can occur during the export process.
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

/// Handles exporting ``MeasurementPoint`` data to CSV and JSON file formats.
///
/// Content generation methods are separated from file-saving logic
/// to enable unit testing without UI dependencies.
class ExportService {

    // MARK: - Content Generation (testable, no UI dependencies)

    func generateCSVContent(_ measurements: [MeasurementPoint]) throws -> String {
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

        return csvString
    }

    func generateJSONContent(_ measurements: [MeasurementPoint]) throws -> String {
        guard !measurements.isEmpty else {
            throw ExportError.invalidData
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        encoder.dateEncodingStrategy = .formatted(dateFormatter)

        guard let jsonData = try? encoder.encode(measurements) else {
            throw ExportError.encodingFailed
        }

        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw ExportError.encodingFailed
        }

        return jsonString
    }

    // MARK: - Export Methods (content generation + file saving)

    func exportToCSV(_ measurements: [MeasurementPoint]) throws -> URL {
        let content = try generateCSVContent(measurements)
        return try saveToFile(content, filename: "WiFiMeasurements.csv")
    }

    func exportToJSON(_ measurements: [MeasurementPoint]) throws -> URL {
        let content = try generateJSONContent(measurements)
        return try saveToFile(content, filename: "WiFiMeasurements.json")
    }

    // MARK: - Helper Methods

    func escapeCSVField(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return field
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
