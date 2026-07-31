//
//  WiFiFrequency.swift
//  WiFiAnalyzer
//
//  Created by Jose Bovet Derpich on 2025.
//  jose.bovet@gmail.com
//  MIT License
//

import Foundation

/// Maps WiFi channel numbers to their center frequency, per band.
///
/// Used by the spectrum overlap chart to place each access point on a frequency
/// axis. Formulas follow the IEEE channel-numbering conventions for each band.
enum WiFiFrequency {

    /// Center frequency (MHz) for a channel on the given band, or `nil` if the
    /// channel/band combination isn't recognized.
    ///
    /// - 2.4 GHz: channels 1–13 → `2412 + (channel - 1) * 5`; channel 14 → `2484`.
    /// - 5 GHz:   `5000 + channel * 5`.
    /// - 6 GHz:   `5950 + channel * 5` (Wi‑Fi 6E numbering).
    static func centerFrequencyMHz(channel: Int, band: String) -> Double? {
        switch band {
        case "2.4 GHz":
            if channel == 14 {
                return 2484
            }
            guard (1...13).contains(channel) else { return nil }
            return Double(2412 + (channel - 1) * 5)
        case "5 GHz":
            guard channel > 0 else { return nil }
            return Double(5000 + channel * 5)
        case "6 GHz":
            guard channel > 0 else { return nil }
            return Double(5950 + channel * 5)
        default:
            return nil
        }
    }
}
