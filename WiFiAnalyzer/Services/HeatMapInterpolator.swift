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
/// from discrete ``HeatMapDataPoint`` measurements. Also provides optional
/// Gaussian smoothing for visual refinement of the heat map.
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

    /// Interpolate RSSI with confidence level
    func interpolateWithConfidence(
        at point: LocationCoordinate,
        from measurements: [HeatMapDataPoint],
        power: Double = 2.0
    ) -> (rssi: Int, confidence: Double) {
        guard !measurements.isEmpty else { return (-90, 0.0) }

        // Find nearest measurements
        let sorted = measurements.sorted {
            point.distance(to: $0.coordinate) < point.distance(to: $1.coordinate)
        }

        let nearest = sorted.prefix(5)
        let maxDist = nearest.map { point.distance(to: $0.coordinate) }.max() ?? 1.0

        // Confidence decreases with distance
        let confidence = 1.0 / (1.0 + maxDist)

        let rssi = interpolateRSSI(at: point, from: Array(nearest), power: power, maxDistance: maxDist * 2)

        return (rssi, confidence)
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

    // MARK: - Smoothing

    /// Apply Gaussian smoothing to heat map grid
    func applyGaussianSmoothing(to grid: [[Int]], kernelSize: Int = 3) -> [[Int]] {
        guard !grid.isEmpty, kernelSize > 0 else { return grid }

        let height = grid.count
        let width = grid[0].count
        var smoothed = grid

        let sigma = Double(kernelSize) / 3.0
        let kernel = generateGaussianKernel(size: kernelSize, sigma: sigma)

        for row in 0..<height {
            for col in 0..<width {
                var sum = 0.0
                var weightSum = 0.0

                for kr in 0..<kernelSize {
                    for kc in 0..<kernelSize {
                        let r = row + kr - kernelSize / 2
                        let c = col + kc - kernelSize / 2

                        if r >= 0 && r < height && c >= 0 && c < width {
                            sum += Double(grid[r][c]) * kernel[kr][kc]
                            weightSum += kernel[kr][kc]
                        }
                    }
                }

                smoothed[row][col] = Int(round(sum / weightSum))
            }
        }

        return smoothed
    }

    private func generateGaussianKernel(size: Int, sigma: Double) -> [[Double]] {
        var kernel: [[Double]] = Array(repeating: Array(repeating: 0.0, count: size), count: size)
        let center = size / 2

        for i in 0..<size {
            for j in 0..<size {
                let x = Double(i - center)
                let y = Double(j - center)
                kernel[i][j] = exp(-(x * x + y * y) / (2.0 * sigma * sigma))
            }
        }

        return kernel
    }
}
