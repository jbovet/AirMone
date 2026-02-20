//
//  DistanceTrend.swift
//  WiFiAnalyzer
//
//  Created by Jose Bovet Derpich on 2025.
//  jose.bovet@gmail.com
//  MIT License
//

import SwiftUI

/// Represents the trend of distance change for an access point.
enum DistanceTrend {
    case gettingCloser    // Distance decreased significantly
    case gettingFarther   // Distance increased significantly
    case stable           // Distance relatively unchanged
    case unknown          // No previous data to compare

    /// Threshold in meters for considering a change significant
    static let threshold: Double = 0.5

    /// Compute trend from previous and current distance values.
    static func compute(previous: Double?, current: Double?) -> DistanceTrend {
        guard let prev = previous, let curr = current else {
            return .unknown
        }
        let delta = curr - prev
        if delta > threshold {
            return .gettingFarther
        } else if delta < -threshold {
            return .gettingCloser
        }
        return .stable
    }

    /// SF Symbol name for the trend arrow
    var iconName: String {
        switch self {
        case .gettingCloser:
            return "arrow.down.right"
        case .gettingFarther:
            return "arrow.up.right"
        case .stable:
            return "arrow.right"
        case .unknown:
            return "minus"
        }
    }

    /// Color for the trend indicator
    var color: Color {
        switch self {
        case .gettingCloser:
            return .green
        case .gettingFarther:
            return .red
        case .stable:
            return .secondary
        case .unknown:
            return .secondary.opacity(0.5)
        }
    }

    /// Accessibility label for the trend
    var accessibilityLabel: String {
        switch self {
        case .gettingCloser:
            return "Getting closer"
        case .gettingFarther:
            return "Getting farther"
        case .stable:
            return "Distance stable"
        case .unknown:
            return "Distance trend unknown"
        }
    }
}
