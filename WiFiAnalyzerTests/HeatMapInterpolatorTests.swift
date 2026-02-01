import XCTest
@testable import WiFiAnalyzer

final class HeatMapInterpolatorTests: XCTestCase {

    let interpolator = HeatMapInterpolator()

    // MARK: - Helper

    private func makeDataPoint(x: Double, y: Double, rssi: Int) -> HeatMapDataPoint {
        HeatMapDataPoint(
            locationName: "Test",
            coordinate: LocationCoordinate(x: x, y: y),
            rssi: rssi,
            timestamp: Date()
        )
    }

    // MARK: - Interpolation Tests

    func testSingleMeasurement() {
        let measurements = [makeDataPoint(x: 0.5, y: 0.5, rssi: -50)]
        let point = LocationCoordinate(x: 0.5, y: 0.5)
        let result = interpolator.interpolateRSSI(at: point, from: measurements)
        XCTAssertEqual(result, -50)
    }

    func testInterpolationAtExactPoint() {
        let measurements = [
            makeDataPoint(x: 0.0, y: 0.0, rssi: -30),
            makeDataPoint(x: 1.0, y: 1.0, rssi: -80)
        ]
        let point = LocationCoordinate(x: 0.0, y: 0.0)
        let result = interpolator.interpolateRSSI(at: point, from: measurements)
        // At exact point of first measurement, should be very close to -30
        XCTAssertEqual(result, -30, accuracy: 5)
    }

    func testInterpolationMidpoint() {
        let measurements = [
            makeDataPoint(x: 0.0, y: 0.5, rssi: -40),
            makeDataPoint(x: 1.0, y: 0.5, rssi: -80)
        ]
        let point = LocationCoordinate(x: 0.5, y: 0.5)
        let result = interpolator.interpolateRSSI(at: point, from: measurements)
        // Midpoint between two equal-distance measurements should be the average
        XCTAssertEqual(result, -60, accuracy: 1)
    }

    func testInterpolationCloserToStrongerSignal() {
        let measurements = [
            makeDataPoint(x: 0.0, y: 0.5, rssi: -30),
            makeDataPoint(x: 1.0, y: 0.5, rssi: -90)
        ]
        let point = LocationCoordinate(x: 0.2, y: 0.5)
        let result = interpolator.interpolateRSSI(at: point, from: measurements)
        // Closer to -30 point, should be stronger (higher) than average
        XCTAssertGreaterThan(result, -60)
    }

    func testEmptyMeasurementsReturnsDefault() {
        let point = LocationCoordinate(x: 0.5, y: 0.5)
        let result = interpolator.interpolateRSSI(at: point, from: [])
        XCTAssertEqual(result, -90)
    }

    // MARK: - Grid Generation Tests

    func testGridGenerationDimensions() {
        let measurements = [
            makeDataPoint(x: 0.25, y: 0.25, rssi: -50),
            makeDataPoint(x: 0.75, y: 0.75, rssi: -70)
        ]
        let grid = interpolator.generateHeatMapGrid(from: measurements, width: 10, height: 10)
        XCTAssertEqual(grid.count, 10)
        XCTAssertEqual(grid.first?.count, 10)
    }

    func testGridGenerationEmptyMeasurements() {
        let grid = interpolator.generateHeatMapGrid(from: [], width: 5, height: 5)
        // Empty measurements returns a default grid filled with -90
        XCTAssertEqual(grid.count, 5)
        XCTAssertEqual(grid.first?.count, 5)
        for row in grid {
            for value in row {
                XCTAssertEqual(value, -90)
            }
        }
    }

    func testGridValuesInRSSIRange() {
        let measurements = [
            makeDataPoint(x: 0.5, y: 0.5, rssi: -50)
        ]
        let grid = interpolator.generateHeatMapGrid(from: measurements, width: 5, height: 5)
        for row in grid {
            for value in row {
                XCTAssertLessThanOrEqual(value, 0)
                XCTAssertGreaterThanOrEqual(value, -100)
            }
        }
    }
}
