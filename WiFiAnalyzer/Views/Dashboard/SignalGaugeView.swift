//
//  SignalGaugeView.swift
//  WiFiAnalyzer
//
//  Created by Jose Bovet Derpich on 2025.
//  jose.bovet@gmail.com
//  MIT License
//

import SwiftUI

/// A semi-circle gauge that visualizes WiFi signal strength with colored range segments.
///
/// Displays six color-coded arc segments (Unusable through Excellent), a needle indicator
/// pointing to the current RSSI position, dBm tick labels along the arc,
/// and a center readout showing the numeric RSSI value and strength category.
struct SignalGaugeView: View {
    let rssi: Int
    var size: CGFloat = 200
    var lineWidth: CGFloat = 20

    private let minRSSI: Double = -100
    private let maxRSSI: Double = -30

    private var signalStrength: SignalStrength {
        SignalStrength.from(rssi: rssi)
    }

    /// Needle angle in degrees: 0° = left (worst), 180° = right (best)
    private var needleAngle: Double {
        let clamped = max(minRSSI, min(maxRSSI, Double(rssi)))
        return ((clamped - minRSSI) / (maxRSSI - minRSSI)) * 180
    }

    /// Range segments from left to right (worst to best)
    private var segments: [(strength: SignalStrength, startDeg: Double, endDeg: Double)] {
        let totalRange = maxRSSI - minRSSI // 70
        let ranges: [(SignalStrength, Double, Double)] = [
            (.unusable, -100, -90),
            (.poor, -90, -80),
            (.weak, -80, -70),
            (.fair, -70, -60),
            (.good, -60, -50),
            (.excellent, -50, -30),
        ]
        return ranges.map { strength, low, high in
            let startFraction = (low - minRSSI) / totalRange
            let endFraction = (high - minRSSI) / totalRange
            return (strength, startFraction * 180, endFraction * 180)
        }
    }

    /// Tick marks at segment boundaries
    private var tickValues: [Int] {
        [-100, -90, -80, -70, -60, -50, -30]
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Colored range segments (semi-circle, opening at bottom)
                ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
                    arcSegment(
                        startAngle: segment.startDeg,
                        endAngle: segment.endDeg,
                        color: segment.strength.color
                    )
                }

                // Tick marks and labels
                ForEach(tickValues, id: \.self) { tick in
                    tickMark(for: tick)
                }

                // Needle
                needle

                // Center circle
                Circle()
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .frame(width: size * 0.38, height: size * 0.38)

                // Center text
                VStack(spacing: 1) {
                    Text("\(rssi)")
                        .font(.system(size: size * 0.16, weight: .bold, design: .rounded))
                        .foregroundColor(signalStrength.color)

                    Text("dBm")
                        .font(.system(size: size * 0.07, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: size, height: size * 0.58)

            Text(signalStrength.rawValue)
                .font(.system(size: size * 0.09, weight: .semibold))
                .foregroundColor(signalStrength.color)

            Text(signalStrength.rangeDescription + " dBm")
                .font(.system(size: size * 0.06, weight: .regular))
                .foregroundColor(.secondary)
        }
        .animation(.easeInOut(duration: 0.5), value: rssi)
    }

    // MARK: - Subviews

    /// Draw a single colored arc segment
    private func arcSegment(startAngle: Double, endAngle: Double, color: Color) -> some View {
        let radius = size / 2
        return Path { path in
            path.addArc(
                center: CGPoint(x: radius, y: radius * 0.85),
                radius: radius - lineWidth / 2,
                startAngle: .degrees(180 + startAngle),
                endAngle: .degrees(180 + endAngle),
                clockwise: false
            )
        }
        .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt))
        .frame(width: size, height: size * 0.58)
    }

    /// Draw a tick mark at a given dBm value
    private func tickMark(for dBm: Int) -> some View {
        let fraction = (Double(dBm) - minRSSI) / (maxRSSI - minRSSI)
        let angleDeg = 180 + fraction * 180
        let angleRad = CGFloat(angleDeg * .pi / 180)
        let radius = size / 2
        let center = CGPoint(x: radius, y: radius * 0.85)
        let outerR = radius - lineWidth / 2 + lineWidth / 2 + 2
        let innerR = radius - lineWidth / 2 - lineWidth / 2 - 2

        let outerPoint = CGPoint(
            x: center.x + outerR * cos(angleRad),
            y: center.y + outerR * sin(angleRad)
        )
        let labelR = outerR + size * 0.08
        let labelPoint = CGPoint(
            x: center.x + labelR * cos(angleRad),
            y: center.y + labelR * sin(angleRad)
        )

        return ZStack {
            Path { path in
                path.move(to: CGPoint(
                    x: center.x + innerR * cos(angleRad),
                    y: center.y + innerR * sin(angleRad)
                ))
                path.addLine(to: outerPoint)
            }
            .stroke(Color.primary.opacity(0.3), lineWidth: 1.5)

            Text("\(dBm)")
                .font(.system(size: size * 0.05))
                .foregroundColor(.secondary)
                .position(x: labelPoint.x, y: labelPoint.y)
        }
        .frame(width: size, height: size * 0.58)
    }

    /// Needle indicator
    private var needle: some View {
        let angleDeg = 180 + needleAngle
        let angleRad = CGFloat(angleDeg * .pi / 180)
        let radius = size / 2
        let center = CGPoint(x: radius, y: radius * 0.85)
        let needleLength = radius - lineWidth * 1.5
        let tipPoint = CGPoint(
            x: center.x + needleLength * cos(angleRad),
            y: center.y + needleLength * sin(angleRad)
        )

        return ZStack {
            // Needle line
            Path { path in
                path.move(to: center)
                path.addLine(to: tipPoint)
            }
            .stroke(Color.primary, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))

            // Center dot
            Circle()
                .fill(Color.primary)
                .frame(width: 8, height: 8)
                .position(x: center.x, y: center.y)
        }
        .frame(width: size, height: size * 0.58)
    }
}

#Preview {
    VStack(spacing: 30) {
        HStack(spacing: 40) {
            SignalGaugeView(rssi: -35, size: 200, lineWidth: 18)
            SignalGaugeView(rssi: -55, size: 200, lineWidth: 18)
        }
        HStack(spacing: 40) {
            SignalGaugeView(rssi: -72, size: 200, lineWidth: 18)
            SignalGaugeView(rssi: -88, size: 200, lineWidth: 18)
        }
    }
    .padding(40)
}
