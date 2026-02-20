//
//  AppLogger.swift
//  WiFiAnalyzer
//
//  Created by Jose Bovet Derpich on 2025.
//  jose.bovet@gmail.com
//  MIT License
//

import Foundation
import os

/// Centralized logging namespace using Apple's unified `os.Logger` API.
///
/// Usage:
/// ```swift
/// AppLogger.network.info("Scan completed successfully")
/// AppLogger.persistence.error("Failed to save: \(error.localizedDescription, privacy: .public)")
/// ```
///
/// Logs are viewable in Console.app filtered by subsystem `com.jbovet.AirMone`.
enum AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.jbovet.AirMone"

    /// WiFi scanning, nearby networks, and network state changes.
    static let network = Logger(subsystem: subsystem, category: "network")

    /// Location authorization and location-related events.
    static let location = Logger(subsystem: subsystem, category: "location")

    /// Data persistence, coordinate mappings, measurements, and export operations.
    static let persistence = Logger(subsystem: subsystem, category: "persistence")

    /// Heat map generation and interpolation.
    static let heatMap = Logger(subsystem: subsystem, category: "heatMap")

    /// General-purpose logging (resource loading, initialization, etc.).
    static let general = Logger(subsystem: subsystem, category: "general")
}
