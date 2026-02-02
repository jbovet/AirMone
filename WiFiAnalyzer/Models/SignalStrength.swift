//
//  SignalStrength.swift
//  WiFiAnalyzer
//
//  Created by Jose Bovet Derpich on 2025.
//  jose.bovet@gmail.com
//  MIT License
//

import SwiftUI

/// Represents WiFi signal strength categories based on RSSI (Received Signal Strength Indicator) values.
///
/// Each case maps to an RSSI range in dBm and provides an associated color, percentage,
/// and human-readable range description for use in gauges, charts, and UI labels.
enum SignalStrength: String, CaseIterable {
    case excellent = "Excellent"
    case good = "Good"
    case fair = "Fair"
    case weak = "Weak"
    case poor = "Poor"
    case unusable = "Unusable"

    /// Maps an RSSI value (in dBm) to a ``SignalStrength`` category.
    /// - Parameter rssi: The RSSI value in dBm (typically between -100 and 0).
    /// - Returns: The corresponding signal strength category.
    static func from(rssi: Int) -> SignalStrength {
        switch rssi {
        case -50...0:
            return .excellent
        case -60 ..< -50:
            return .good
        case -70 ..< -60:
            return .fair
        case -80 ..< -70:
            return .weak
        case -90 ..< -80:
            return .poor
        default:
            return .unusable
        }
    }

    /// The color associated with this signal strength level, used for visual indicators.
    var color: Color {
        switch self {
        case .excellent:
            return .green
        case .good:
            return Color(red: 0.5, green: 0.8, blue: 0.0) // Lime
        case .fair:
            return .yellow
        case .weak:
            return .orange
        case .poor:
            return Color(red: 1.0, green: 0.4, blue: 0.0) // Red-orange
        case .unusable:
            return .red
        }
    }

    /// A normalized percentage (0.0–1.0) representing the signal quality for progress indicators.
    var percentage: Double {
        switch self {
        case .excellent: return 1.0
        case .good: return 0.83
        case .fair: return 0.66
        case .weak: return 0.5
        case .poor: return 0.33
        case .unusable: return 0.16
        }
    }

    /// A human-readable description of the RSSI range for this strength level (e.g., "-50 to -30").
    var rangeDescription: String {
        switch self {
        case .excellent:
            return "-50 to -30"
        case .good:
            return "-60 to -50"
        case .fair:
            return "-70 to -60"
        case .weak:
            return "-80 to -70"
        case .poor:
            return "-90 to -80"
        case .unusable:
            return "< -90"
        }
    }
}
