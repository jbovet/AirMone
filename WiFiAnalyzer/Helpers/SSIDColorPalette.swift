import SwiftUI

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
