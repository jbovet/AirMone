//
//  WiFiScannerViewModel.swift
//  WiFiAnalyzer
//
//  Created by Jose Bovet Derpich on 2025.
//  jose.bovet@gmail.com
//  MIT License
//

import Foundation
import Combine
import os

/// ViewModel that drives the Signal Monitor (Dashboard) tab.
///
/// Manages a 2-second polling timer to continuously fetch the current WiFi network
/// via ``WiFiScannerService``, maintains a rolling signal history for charting,
/// and supports marking locations as ``MeasurementPoint`` via ``PersistenceService``.
@MainActor
class WiFiScannerViewModel: ObservableObject {
    @Published var currentNetwork: WiFiNetwork?
    @Published var errorMessage: String?
    @Published var isScanning: Bool = false
    @Published var signalHistory: [SignalDataPoint] = []
    @Published var lastRoamingEvent: RoamingEvent?
    @Published var roamingEvents: [RoamingEvent] = []

    private let scannerService: WiFiScannerService
    private let persistenceService: PersistenceService
    private var scanTimer: Timer?
    private let maxHistoryPoints = 30 // Last 60 seconds of data (at 2-second intervals)
    private var previousBSSID: String?
    private var previousRSSI: Int?
    private let maxRoamingEvents = 10
    
    var recentLocations: [String] {
        let measurements = persistenceService.load()
        let names = measurements.map { $0.locationName }
        var uniqueNames: [String] = []
        for name in names {
            if !uniqueNames.contains(name) {
                uniqueNames.append(name)
            }
        }
        return Array(uniqueNames.reversed().prefix(5))
    }

    init(scannerService: WiFiScannerService = WiFiScannerService(),
         persistenceService: PersistenceService = .shared) {
        self.scannerService = scannerService
        self.persistenceService = persistenceService
    }

    func startLiveScanning() {
        guard !isScanning else { return }
        isScanning = true
        errorMessage = nil

        scanNow()

        scanTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.scanNow()
            }
        }
    }

    func stopLiveScanning() {
        isScanning = false
        scanTimer?.invalidate()
        scanTimer = nil
    }

    func clearHistory() {
        signalHistory.removeAll()
    }

    private func scanNow() {
        Task {
            do {
                let network = try await Task.detached(priority: .userInitiated) { [scannerService] in
                    try scannerService.getCurrentNetwork()
                }.value

                await MainActor.run {
                    // Detect roaming event (BSSID changed but same SSID)
                    if let prevBSSID = self.previousBSSID,
                       prevBSSID != network.bssid,
                       self.currentNetwork?.ssid == network.ssid {
                        let roamEvent = RoamingEvent(
                            fromBSSID: prevBSSID,
                            toBSSID: network.bssid,
                            fromVendor: self.currentNetwork?.vendor,
                            toVendor: network.vendor,
                            signalBefore: self.previousRSSI ?? 0,
                            signalAfter: network.rssi,
                            ssid: network.ssid
                        )
                        self.lastRoamingEvent = roamEvent
                        self.roamingEvents.insert(roamEvent, at: 0)

                        // Keep only recent roaming events
                        if self.roamingEvents.count > self.maxRoamingEvents {
                            self.roamingEvents = Array(self.roamingEvents.prefix(self.maxRoamingEvents))
                        }
                    }

                    // Update tracking state
                    self.previousBSSID = network.bssid
                    self.previousRSSI = network.rssi

                    self.currentNetwork = network
                    self.errorMessage = nil

                    // Add to signal history
                    let dataPoint = SignalDataPoint(timestamp: network.timestamp, rssi: network.rssi, ssid: network.ssid)
                    self.signalHistory.append(dataPoint)

                    // Trim history to keep only last maxHistoryPoints
                    if self.signalHistory.count > self.maxHistoryPoints {
                        self.signalHistory.removeFirst(self.signalHistory.count - self.maxHistoryPoints)
                    }
                }
            } catch {
                await MainActor.run {
                    AppLogger.network.error("Failed to fetch current network: \(error.localizedDescription, privacy: .public)")
                    self.currentNetwork = nil
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    /// Dismiss the current roaming event notification
    func dismissRoamingEvent() {
        lastRoamingEvent = nil
    }

    func markLocation(at locationName: String) {
        guard let network = currentNetwork else { return }
        
        let trimmedName = locationName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        let measurement = MeasurementPoint(locationName: trimmedName, network: network)
        do {
            try persistenceService.append(measurement)
        } catch {
            AppLogger.persistence.error("Failed to save measurement: \(error.localizedDescription, privacy: .public)")
            errorMessage = error.localizedDescription
        }
    }

    func existingMeasurementCount(for locationName: String) -> Int {
        let trimmedName = locationName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return 0 }
        return persistenceService.load().filter { $0.locationName == trimmedName }.count
    }

    deinit {
        scanTimer?.invalidate()
    }
}
