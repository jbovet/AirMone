//
//  NearbyNetworksViewModel.swift
//  WiFiAnalyzer
//
//  Created by Jose Bovet Derpich on 2025.
//  jose.bovet@gmail.com
//  MIT License
//

import Foundation
import Combine
import os

/// ViewModel for the Nearby Networks tab.
///
/// Performs periodic WiFi scans via ``WiFiScannerService/scanForNearbyNetworks()``,
/// groups results by SSID into ``NetworkGroup`` entries, tracks per-SSID signal history,
/// and supports band filtering and multiple sort orders.
@MainActor
class NearbyNetworksViewModel: ObservableObject {
    @Published var nearbyNetworks: [NearbyNetwork] = []
    @Published var signalHistory: [String: [SignalDataPoint]] = [:]  // Keyed by SSID
    @Published var errorMessage: String?
    @Published var isScanning: Bool = false
    @Published var selectedBandFilter: BandFilter = .all
    @Published var sortOrder: SortOrder = .signalStrength
    @Published var expandedSSIDs: Set<String> = []
    @Published var connectedBSSID: String?
    @Published var distanceTrends: [String: DistanceTrend] = [:]

    /// Previous distance readings per BSSID for trend calculation
    private var previousDistances: [String: Double] = [:]

    private let scannerService: WiFiScannerService
    private var scanTimer: Timer?
    private let maxHistoryPoints = 30
    private let scanInterval: TimeInterval = 4.0
    private var isScanInProgress = false

    enum BandFilter: String, CaseIterable {
        case all = "All Bands"
        case band2_4 = "2.4 GHz"
        case band5 = "5 GHz"
        case band6 = "6 GHz"
    }

    enum SortOrder: String, CaseIterable {
        case signalStrength = "Signal"
        case ssid = "Name"
        case channel = "Channel"
    }

    init(scannerService: WiFiScannerService = WiFiScannerService()) {
        self.scannerService = scannerService
    }

    // MARK: - Grouped Networks

    var networkGroups: [NetworkGroup] {
        let filtered: [NearbyNetwork]
        if selectedBandFilter == .all {
            filtered = nearbyNetworks
        } else {
            filtered = nearbyNetworks.filter { $0.band == selectedBandFilter.rawValue }
        }

        let grouped = Dictionary(grouping: filtered, by: { $0.ssid })
        var groups = grouped.map { NetworkGroup(ssid: $0.key, accessPoints: $0.value) }

        switch sortOrder {
        case .signalStrength:
            groups.sort { $0.bestRSSI > $1.bestRSSI }
        case .ssid:
            groups.sort { $0.ssid.localizedCaseInsensitiveCompare($1.ssid) == .orderedAscending }
        case .channel:
            groups.sort { $0.channels.first ?? 0 < $1.channels.first ?? 0 }
        }

        return groups
    }

    var totalNetworkCount: Int {
        networkGroups.reduce(0) { $0 + $1.apCount }
    }

    /// SSIDs from the current filtered groups, ordered by best signal (strongest first), capped to top 10
    var topSSIDsBySignal: [String] {
        networkGroups
            .sorted { $0.bestRSSI > $1.bestRSSI }
            .prefix(10)
            .map { $0.ssid }
    }

    /// Flattened signal history for chart display, filtered by current band selection
    var chartSignalHistory: [SignalDataPoint] {
        let allowedSSIDs = Set(topSSIDsBySignal)
        return signalHistory
            .filter { allowedSSIDs.contains($0.key) }
            .flatMap { $0.value }
    }

    var uniqueNetworkNames: [String] {
        networkGroups.map { $0.ssid }
    }

    // MARK: - Expand/Collapse

    func toggleExpanded(_ ssid: String) {
        if expandedSSIDs.contains(ssid) {
            expandedSSIDs.remove(ssid)
        } else {
            expandedSSIDs.insert(ssid)
        }
    }

    func isExpanded(_ ssid: String) -> Bool {
        expandedSSIDs.contains(ssid)
    }

    // MARK: - Scanning

    func startScanning() {
        guard !isScanning else { return }
        isScanning = true
        errorMessage = nil

        // Invalidate any leftover timer before creating a new one
        scanTimer?.invalidate()
        scanTimer = nil

        scanNow()
        scanTimer = Timer.scheduledTimer(withTimeInterval: scanInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.scanNow()
            }
        }
    }

    func stopScanning() {
        isScanning = false
        scanTimer?.invalidate()
        scanTimer = nil
    }

    func clearHistory() {
        signalHistory.removeAll()
    }

    private func scanNow() {
        guard !isScanInProgress else { return }
        isScanInProgress = true

        Task {
            do {
                let networks = try await Task.detached(priority: .userInitiated) { [scannerService] in
                    try scannerService.scanForNearbyNetworks()
                }.value

                // Also fetch connected network BSSID
                let currentBSSID = try? await Task.detached(priority: .userInitiated) { [scannerService] in
                    try? scannerService.getCurrentNetwork().bssid
                }.value

                await MainActor.run {
                    self.nearbyNetworks = networks
                    self.connectedBSSID = currentBSSID
                    self.errorMessage = nil

                    // Update distance trends for each AP
                    for network in networks {
                        let bssid = network.bssid
                        let currentDistance = network.estimatedDistanceMeters
                        let previousDistance = self.previousDistances[bssid]

                        let trend = DistanceTrend.compute(previous: previousDistance, current: currentDistance)
                        self.distanceTrends[bssid] = trend

                        // Store current distance for next comparison
                        if let dist = currentDistance {
                            self.previousDistances[bssid] = dist
                        }
                    }

                    // Track signal history per SSID using the best RSSI from all APs
                    let grouped = Dictionary(grouping: networks, by: { $0.ssid })
                    for (ssid, aps) in grouped {
                        guard let bestRSSI = aps.max(by: { $0.rssi < $1.rssi })?.rssi else { continue }
                        let dataPoint = SignalDataPoint(
                            timestamp: Date(),
                            rssi: bestRSSI,
                            ssid: ssid
                        )
                        var history = self.signalHistory[ssid, default: []]
                        history.append(dataPoint)
                        if history.count > self.maxHistoryPoints {
                            history.removeFirst(history.count - self.maxHistoryPoints)
                        }
                        self.signalHistory[ssid] = history
                    }

                    self.isScanInProgress = false
                }
            } catch {
                await MainActor.run {
                    AppLogger.network.error("Nearby network scan failed: \(error.localizedDescription, privacy: .public)")
                    self.errorMessage = error.localizedDescription
                    self.isScanInProgress = false
                }
            }
        }
    }

    nonisolated deinit {
        scanTimer?.invalidate()
    }
}
