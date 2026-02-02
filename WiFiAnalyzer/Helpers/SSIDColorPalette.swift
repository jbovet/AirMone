//
//  SSIDColorPalette.swift
//  WiFiAnalyzer
//
//  Created by Jose Bovet Derpich on 2025.
//  jose.bovet@gmail.com
//  MIT License
//

import SwiftUI

/// Provides a consistent color assignment for SSIDs across charts and legends.
///
/// Each SSID is mapped to a color by its index in the ordered SSID list,
/// cycling through the palette when there are more SSIDs than colors.
enum SSIDColorPalette {
    static let colors: [Color] = [
        .blue, .purple, .teal, .orange, .pink, .indigo, .mint, .cyan
    ]

    /// Returns a consistent color for an SSID based on its position in the ordered list.
    static func color(for ssid: String, in ssids: [String]) -> Color {
        guard let index = ssids.firstIndex(of: ssid) else { return .gray }
        return colors[index % colors.count]
    }
}
