//
//  HeatMapInterpolator.swift
//  WiFiAnalyzer
//
//  Created by Jose Bovet Derpich on 2025.
//  jose.bovet@gmail.com
//  MIT License
//

import Foundation

/// Performs spatial interpolation of RSSI values using Inverse Distance Weighting (IDW).
///
/// Used by ``HeatMapViewModel`` to generate a continuous signal-strength grid
/// from discrete ``HeatMapDataPoint`` measurements.
class HeatMapInterpolator {

    // MARK: - Inverse Distance Weighting (IDW) Interpolation

    /// Interpolate RSSI value at a given point using Inverse Distance Weighting
    /// - Parameters:
    ///   - point: The coordinate to interpolate
    ///   - measurements: Array of heat map data points
    ///   - power: Power parameter for IDW (typically 2.0)
    ///   - maxDistance: Maximum distance to consider (performance optimization)
    /// - Returns: Interpolated RSSI value
    func interpolateRSSI(
        at point: LocationCoordinate,
        from measurements: [HeatMapDataPoint],
        power: Double = 2.0,
        maxDistance: Double = 2.0
    ) -> Int {
        guard !measurements.isEmpty else { return -90 }

        var weightedSum = 0.0
        var totalWeight = 0.0

        for measurement in measurements {
            let distance = point.distance(to: measurement.coordinate)

            // If we're very close to a measurement, return its exact value
            if distance < 0.01 {
                return measurement.rssi
            }

            // Skip points beyond max distance for performance
            guard distance < maxDistance else { continue }

            let weight = 1.0 / pow(distance, power)
            weightedSum += Double(measurement.rssi) * weight
            totalWeight += weight
        }

        // If no measurements within range, find nearest
        if totalWeight == 0 {
            guard let nearest = measurements.min(by: {
                point.distance(to: $0.coordinate) < point.distance(to: $1.coordinate)
            }) else {
                return -90
            }
            return nearest.rssi
        }

        return Int(round(weightedSum / totalWeight))
    }

    // MARK: - Grid Generation

    /// Generate a complete heat map grid
    /// - Parameters:
    ///   - measurements: Array of heat map data points
    ///   - width: Grid width (number of cells)
    ///   - height: Grid height (number of cells)
    ///   - power: IDW power parameter
    /// - Returns: 2D array of RSSI values
    func generateHeatMapGrid(
        from measurements: [HeatMapDataPoint],
        width: Int,
        height: Int,
        power: Double = 2.0
    ) -> [[Int]] {
        guard !measurements.isEmpty else {
            return Array(repeating: Array(repeating: -90, count: width), count: height)
        }

        var grid: [[Int]] = []

        for row in 0..<height {
            var rowData: [Int] = []

            for col in 0..<width {
                let x = (Double(col) + 0.5) / Double(width)
                let y = (Double(row) + 0.5) / Double(height)
                let point = LocationCoordinate(x: x, y: y)

                let rssi = interpolateRSSI(at: point, from: measurements, power: power)
                rowData.append(rssi)
            }

            grid.append(rowData)
        }

        return grid
    }
}
