//
//  LocationCoordinate.swift
//  WiFiAnalyzer
//
//  Created by Jose Bovet Derpich on 2025.
//  jose.bovet@gmail.com
//  MIT License
//

import Foundation
import CoreGraphics

/// A 2D (or optional 3D) coordinate used to position measurement points on the heat map.
///
/// Coordinates are normalized to the 0.0–1.0 range for resolution-independent layout.
/// Provides distance calculations and conversion to/from `CGPoint`.
struct LocationCoordinate: Codable, Equatable, Hashable {
    let x: Double  // Normalized 0.0 to 1.0 or meters
    let y: Double  // Normalized 0.0 to 1.0 or meters
    let z: Double? // Optional for multi-floor support

    init(x: Double, y: Double, z: Double? = nil) {
        self.x = x
        self.y = y
        self.z = z
    }

    // Distance calculation (Euclidean distance)
    func distance(to other: LocationCoordinate) -> Double {
        let dx = x - other.x
        let dy = y - other.y
        let dz = (z ?? 0) - (other.z ?? 0)
        return sqrt(dx * dx + dy * dy + dz * dz)
    }

    // Convert to CGPoint (for 2D visualization)
    func toCGPoint(in size: CGSize) -> CGPoint {
        CGPoint(x: x * size.width, y: y * size.height)
    }

    // Create from CGPoint (normalized to 0-1)
    static func from(point: CGPoint, in size: CGSize) -> LocationCoordinate {
        LocationCoordinate(
            x: point.x / size.width,
            y: point.y / size.height
        )
    }
}

// Extension for MeasurementPoint coordinate lookup
extension MeasurementPoint {
    var coordinate: LocationCoordinate? {
        LocationMappingService.shared.coordinate(for: locationName)
    }
}
