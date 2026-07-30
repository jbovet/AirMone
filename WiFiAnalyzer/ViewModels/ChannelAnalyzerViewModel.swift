//
//  ChannelAnalyzerViewModel.swift
//  WiFiAnalyzer
//
//  Created by Jose Bovet Derpich on 2025.
//  jose.bovet@gmail.com
//  MIT License
//

import Foundation
import Combine
import os

/// ViewModel for the Channel Analyzer tab.
///
/// Periodically scans nearby access points and computes a per-channel congestion
/// index from data a scan reliably provides — each AP's channel, band, and RSSI —
/// plus adjacent-channel overlap on 2.4 GHz. It also recommends the least-congested
/// channel per band.
///
/// This intentionally does not use CoreWLAN's per-AP noise floor: that value is only
/// valid for the interface's active channel, so it can't describe every channel.
@MainActor
class ChannelAnalyzerViewModel: ObservableObject {
    @Published var nearbyNetworks: [NearbyNetwork] = []
    @Published var errorMessage: String?
    @Published var isScanning: Bool = false
    @Published var selectedBandFilter: NearbyNetworksViewModel.BandFilter = .all

    private let scannerService: WiFiScannerService
    private var scanTimer: Timer?
    private let scanInterval: TimeInterval = 4.0
    private var isScanInProgress = false

    init(scannerService: WiFiScannerService = .shared) {
        self.scannerService = scannerService
    }

    // MARK: - Interference Model (pure, testable)

    /// Standard non-overlapping channels evaluated when recommending a channel.
    /// Bands without an entry fall back to the channels actually observed.
    static let candidateChannels: [String: [Int]] = [
        "2.4 GHz": [1, 6, 11],
        "5 GHz": [36, 40, 44, 48, 149, 153, 157, 161]
    ]

    /// How strongly one AP contributes to interference, from its RSSI (0...1).
    /// Reuses the app's RSSI→quality mapping: a strong AP counts fully, a distant
    /// one only a little.
    static func signalWeight(rssi: Int) -> Double {
        let percent = min(max(2 * (rssi + 100), 0), 100)
        return Double(percent) / 100.0
    }

    /// Fraction of an AP's energy that lands on a target channel, given the channel
    /// separation. On 2.4 GHz the 20–22 MHz channels (5 MHz apart) overlap within ±4;
    /// on 5/6 GHz a 20 MHz channel only interferes with itself.
    static func overlapFactor(band: String, separation: Int) -> Double {
        if band == "2.4 GHz" {
            return max(0.0, Double(5 - separation) / 5.0)
        }
        return separation == 0 ? 1.0 : 0.0
    }

    /// Weighted interference index for a channel: every AP on the same band adds
    /// its signal weight scaled by how much it overlaps the target channel.
    static func congestionScore(forChannel channel: Int, band: String, among networks: [NearbyNetwork]) -> Double {
        networks.reduce(0.0) { total, ap in
            let factor = overlapFactor(band: band, separation: abs(ap.channel - channel))
            guard factor > 0 else { return total }
            return total + factor * signalWeight(rssi: ap.rssi)
        }
    }

    // MARK: - Derived State

    private var filteredNetworks: [NearbyNetwork] {
        selectedBandFilter == .all
            ? nearbyNetworks
            : nearbyNetworks.filter { $0.band == selectedBandFilter.rawValue }
    }

    private struct ChannelKey: Hashable {
        let band: String
        let channel: Int
    }

    /// Congestion for every channel currently occupied by at least one AP,
    /// sorted by band then channel.
    var channelCongestion: [ChannelCongestion] {
        let networks = filteredNetworks
        let grouped = Dictionary(grouping: networks) { ChannelKey(band: $0.band, channel: $0.channel) }

        return grouped.map { key, coChannelAPs in
            let sameBand = networks.filter { $0.band == key.band }
            let overlappingCount = sameBand.filter {
                Self.overlapFactor(band: key.band, separation: abs($0.channel - key.channel)) > 0
            }.count
            let score = Self.congestionScore(forChannel: key.channel, band: key.band, among: sameBand)
            let ssids = Set(coChannelAPs.map { $0.ssid })
                .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }

            return ChannelCongestion(
                band: key.band,
                channel: key.channel,
                apCount: coChannelAPs.count,
                ssids: ssids,
                overlappingAPCount: overlappingCount,
                score: score
            )
        }
        .sorted {
            $0.band == $1.band ? $0.channel < $1.channel : $0.band < $1.band
        }
    }

    /// The least-congested channel per band. For a band with standard candidates
    /// (2.4/5 GHz) an empty non-overlapping channel can win even if no AP uses it.
    var recommendationsByBand: [String: ChannelRecommendation] {
        let networks = filteredNetworks
        let bands = Set(networks.map { $0.band })

        var result: [String: ChannelRecommendation] = [:]
        for band in bands {
            let sameBand = networks.filter { $0.band == band }
            let candidates = Self.candidateChannels[band]
                ?? Array(Set(sameBand.map { $0.channel })).sorted()
            guard !candidates.isEmpty else { continue }

            let scored = candidates.map { channel in
                (channel: channel, score: Self.congestionScore(forChannel: channel, band: band, among: sameBand))
            }
            if let best = scored.min(by: {
                $0.score != $1.score ? $0.score < $1.score : $0.channel < $1.channel
            }) {
                result[band] = ChannelRecommendation(band: band, channel: best.channel, score: best.score)
            }
        }
        return result
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

                await MainActor.run {
                    self.nearbyNetworks = networks
                    self.errorMessage = nil
                    self.isScanInProgress = false
                }
            } catch {
                await MainActor.run {
                    AppLogger.network.error("Channel analyzer scan failed: \(error.localizedDescription, privacy: .public)")
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
