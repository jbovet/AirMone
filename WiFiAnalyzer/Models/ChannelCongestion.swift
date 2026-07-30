//
//  ChannelCongestion.swift
//  WiFiAnalyzer
//
//  Created by Jose Bovet Derpich on 2025.
//  jose.bovet@gmail.com
//  MIT License
//

import SwiftUI

/// Congestion/interference assessment for a single (band, channel) pair,
/// derived from the access points observed during a scan.
///
/// Unlike a noise-floor reading — which CoreWLAN only reports for the interface's
/// active channel — congestion is computed entirely from data that a scan reliably
/// provides (each AP's channel, band, and RSSI), so every observed channel gets a
/// meaningful value.
struct ChannelCongestion: Identifiable, Hashable {
    let band: String              // "2.4 GHz", "5 GHz", or "6 GHz"
    let channel: Int

    /// Access points transmitting exactly on this channel (co-channel).
    let apCount: Int

    /// Unique network names (SSIDs) of the co-channel access points, sorted
    /// case-insensitively. May be fewer than ``apCount`` when several radios
    /// share one name (e.g. mesh or multi-band APs).
    let ssids: [String]

    /// Access points on this channel plus any that overlap it. On 2.4 GHz the
    /// 20–22 MHz channels overlap their neighbours; on 5/6 GHz channels don't
    /// overlap, so this equals ``apCount``.
    let overlappingAPCount: Int

    /// Weighted interference index (higher = more congested). Combines how many
    /// nearby APs share or overlap the channel with how strong each one is.
    let score: Double

    var id: String { "\(band)_\(channel)" }

    var rating: CongestionRating { CongestionRating.from(score: score) }
}

/// Qualitative classification of a channel's congestion level.
enum CongestionRating: String, CaseIterable {
    case clear = "Clear"
    case moderate = "Moderate"
    case busy = "Busy"
    case crowded = "Crowded"

    /// Maps a weighted interference index to a rating. Heuristic thresholds tuned
    /// so a single strong co-channel AP reads "Moderate" and several read "Crowded".
    /// (One AP at full signal contributes ~1.0 to the score.)
    static func from(score: Double) -> CongestionRating {
        switch score {
        case ..<0.5:
            return .clear
        case 0.5 ..< 1.5:
            return .moderate
        case 1.5 ..< 3.0:
            return .busy
        default:
            return .crowded
        }
    }

    var color: Color {
        switch self {
        case .clear:
            return .green
        case .moderate:
            return .yellow
        case .busy:
            return .orange
        case .crowded:
            return .red
        }
    }
}

/// The least-congested channel within a band, suggested to the user.
struct ChannelRecommendation: Identifiable, Hashable {
    let band: String
    let channel: Int
    let score: Double

    var id: String { band }
    var rating: CongestionRating { CongestionRating.from(score: score) }
}
