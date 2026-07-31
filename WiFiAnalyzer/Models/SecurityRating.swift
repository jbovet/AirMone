//
//  SecurityRating.swift
//  WiFiAnalyzer
//
//  Created by Jose Bovet Derpich on 2025.
//  jose.bovet@gmail.com
//  MIT License
//

import SwiftUI

/// Risk classification for a WiFi network's encryption, derived from the security
/// string produced by `WiFiScannerService` (e.g. "Open", "WEP", "WPA2 Personal",
/// "WPA3 Enterprise", "Open (No Security)", "WEP (Weak)").
///
/// Used by the Security Audit tab to flag weak networks and to assess the user's
/// own connection. Classification is by keyword so it tolerates the different
/// phrasings the scanner emits for nearby vs. connected networks.
enum SecurityRating: String, CaseIterable {
    case open = "Open"
    case insecure = "Insecure"   // WEP
    case weak = "Weak"           // WPA (v1)
    case acceptable = "Acceptable" // WPA2
    case strong = "Strong"       // WPA3
    case unknown = "Unknown"

    /// Classifies a raw security string. Order matters: "WPA2"/"WPA3" contain
    /// "WPA", so the more specific generations are checked first.
    static func from(security: String) -> SecurityRating {
        if security.contains("WPA3") {
            return .strong
        }
        if security.contains("WPA2") {
            return .acceptable
        }
        if security.contains("WPA") {
            return .weak
        }
        if security.contains("WEP") {
            return .insecure
        }
        if security.contains("Open") {
            return .open
        }
        return .unknown
    }

    /// Sort key, most-severe (0) to safest. Unknown sorts after real ratings.
    var riskOrder: Int {
        switch self {
        case .open: return 0
        case .insecure: return 1
        case .weak: return 2
        case .acceptable: return 3
        case .strong: return 4
        case .unknown: return 5
        }
    }

    /// True for ratings that represent an actual security concern (used by the
    /// "Only issues" filter and the summary).
    var isIssue: Bool {
        switch self {
        case .open, .insecure, .weak:
            return true
        case .acceptable, .strong, .unknown:
            return false
        }
    }

    /// One-line, user-facing recommendation.
    var advice: String {
        switch self {
        case .open:
            return "No encryption — anyone nearby can intercept traffic."
        case .insecure:
            return "WEP is broken and trivially cracked. Avoid."
        case .weak:
            return "WPA (v1) is outdated — upgrade the router to WPA2/WPA3."
        case .acceptable:
            return "WPA2 is acceptable; WPA3 is stronger where available."
        case .strong:
            return "WPA3 — current best practice."
        case .unknown:
            return "Security type could not be determined."
        }
    }

    var color: Color {
        switch self {
        case .open, .insecure:
            return .red
        case .weak:
            return .orange
        case .acceptable:
            return .blue
        case .strong:
            return .green
        case .unknown:
            return .secondary
        }
    }

    /// SF Symbol for the badge.
    var iconName: String {
        switch self {
        case .open:
            return "lock.open"
        case .insecure, .weak:
            return "exclamationmark.shield"
        case .acceptable:
            return "lock.shield"
        case .strong:
            return "checkmark.shield.fill"
        case .unknown:
            return "questionmark.shield"
        }
    }
}
