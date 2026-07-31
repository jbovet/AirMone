//
//  SecurityAuditViewModel.swift
//  WiFiAnalyzer
//
//  Created by Jose Bovet Derpich on 2025.
//  jose.bovet@gmail.com
//  MIT License
//

import Foundation
import Combine
import os

/// ViewModel for the Security Audit tab.
///
/// Periodically scans nearby access points and also reads the connected network,
/// classifying each by ``SecurityRating`` to flag weak encryption (Open / WEP /
/// WPA1) and to assess the user's own connection.
@MainActor
class SecurityAuditViewModel: ObservableObject {
    @Published var nearbyNetworks: [NearbyNetwork] = []
    @Published var connectedNetwork: WiFiNetwork?
    @Published var errorMessage: String?
    @Published var isScanning: Bool = false
    @Published var onlyIssues: Bool = false
    @Published var selectedBandFilter: NearbyNetworksViewModel.BandFilter = .all

    private let scannerService: WiFiScannerService
    private var scanTimer: Timer?
    private let scanInterval: TimeInterval = 4.0
    private var isScanInProgress = false

    init(scannerService: WiFiScannerService = .shared) {
        self.scannerService = scannerService
    }

    // MARK: - Derived state

    /// Rating of the connected network, if any.
    var connectedRating: SecurityRating? {
        guard let security = connectedNetwork?.security else { return nil }
        return SecurityRating.from(security: security)
    }

    /// BSSID of the connected access point, used to mark it in the nearby list.
    var connectedBSSID: String? {
        connectedNetwork?.bssid
    }

    /// Nearby networks restricted to the selected band (all bands when `.all`).
    var bandFilteredNetworks: [NearbyNetwork] {
        selectedBandFilter == .all
            ? nearbyNetworks
            : nearbyNetworks.filter { $0.band == selectedBandFilter.rawValue }
    }

    /// Band-filtered networks ordered worst-first (by risk, then strongest signal),
    /// further filtered to issues only when `onlyIssues` is set.
    var auditedNetworks: [NearbyNetwork] {
        let filtered = onlyIssues
            ? bandFilteredNetworks.filter { SecurityRating.from(security: $0.security).isIssue }
            : bandFilteredNetworks

        return filtered.sorted { lhs, rhs in
            let lRank = SecurityRating.from(security: lhs.security).riskOrder
            let rRank = SecurityRating.from(security: rhs.security).riskOrder
            return lRank != rRank ? lRank < rRank : lhs.rssi > rhs.rssi
        }
    }

    /// Count per rating over the band-filtered networks (ignores the issues filter).
    var summary: [SecurityRating: Int] {
        Dictionary(grouping: bandFilteredNetworks) { SecurityRating.from(security: $0.security) }
            .mapValues(\.count)
    }

    /// Number of band-filtered networks that are a security concern.
    var issueCount: Int {
        bandFilteredNetworks.filter { SecurityRating.from(security: $0.security).isIssue }.count
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

    private func scanNow() {
        guard !isScanInProgress else { return }
        isScanInProgress = true

        Task {
            do {
                let networks = try await Task.detached(priority: .userInitiated) { [scannerService] in
                    try scannerService.scanForNearbyNetworks()
                }.value

                // The connected network may fail (e.g. not associated); treat as optional.
                let connected = await Task.detached(priority: .userInitiated) { [scannerService] in
                    try? scannerService.getCurrentNetwork()
                }.value

                await MainActor.run {
                    self.nearbyNetworks = networks
                    self.connectedNetwork = connected
                    self.errorMessage = nil
                    self.isScanInProgress = false
                }
            } catch {
                await MainActor.run {
                    AppLogger.network.error("Security audit scan failed: \(error.localizedDescription, privacy: .public)")
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
