//
//  MenuBarSignalIcon.swift
//  WiFiAnalyzer
//
//  Created by Jose Bovet Derpich on 2025.
//  jose.bovet@gmail.com
//  MIT License
//

import SwiftUI

/// Custom menu bar glyph: four ascending signal bars, with `activeBars` of them
/// filled to reflect the current signal strength.
///
/// Drawn as a monochrome shape so it can be rendered as a template image and tint
/// correctly in the menu bar (light/dark/active). The bar-meter shape is
/// deliberately distinct from the system Wi‑Fi arcs so the two icons aren't
/// confused. Rendered to a template `NSImage` by ``menuBarTemplateImage()``.
struct MenuBarSignalIcon: View {
    /// Number of filled bars, clamped to 0...4.
    let activeBars: Int

    static let barCount = 4

    var body: some View {
        Canvas { context, size in
            let gap = size.width * 0.12
            let barWidth = (size.width - gap * CGFloat(Self.barCount - 1)) / CGFloat(Self.barCount)
            let minHeight = size.height * 0.35

            for index in 0..<Self.barCount {
                let heightFraction = CGFloat(index) / CGFloat(Self.barCount - 1)
                let barHeight = minHeight + (size.height - minHeight) * heightFraction
                let x = CGFloat(index) * (barWidth + gap)
                let rect = CGRect(x: x, y: size.height - barHeight, width: barWidth, height: barHeight)
                let path = Path(roundedRect: rect, cornerRadius: barWidth * 0.35)

                // Opacity maps to alpha in the template image: filled bars render
                // solid, remaining bars stay faint to show the signal level.
                let isFilled = index < activeBars
                context.fill(path, with: .color(.black.opacity(isFilled ? 1.0 : 0.3)))
            }
        }
        .frame(width: 18, height: 14)
    }

    /// Renders the icon to a template `NSImage` suitable for a menu bar item.
    @MainActor
    static func menuBarTemplateImage(activeBars: Int) -> NSImage {
        let renderer = ImageRenderer(content: MenuBarSignalIcon(activeBars: activeBars))
        renderer.scale = 2
        let image = renderer.nsImage ?? NSImage()
        image.isTemplate = true
        return image
    }
}
