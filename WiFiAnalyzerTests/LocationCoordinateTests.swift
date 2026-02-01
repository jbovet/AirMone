import XCTest
import CoreGraphics
@testable import WiFiAnalyzer

final class LocationCoordinateTests: XCTestCase {

    // MARK: - Distance Tests

    func testDistanceToSamePoint() {
        let a = LocationCoordinate(x: 0.5, y: 0.5)
        let b = LocationCoordinate(x: 0.5, y: 0.5)
        XCTAssertEqual(a.distance(to: b), 0.0, accuracy: 0.0001)
    }

    func testDistanceHorizontal() {
        let a = LocationCoordinate(x: 0.0, y: 0.0)
        let b = LocationCoordinate(x: 1.0, y: 0.0)
        XCTAssertEqual(a.distance(to: b), 1.0, accuracy: 0.0001)
    }

    func testDistanceVertical() {
        let a = LocationCoordinate(x: 0.0, y: 0.0)
        let b = LocationCoordinate(x: 0.0, y: 1.0)
        XCTAssertEqual(a.distance(to: b), 1.0, accuracy: 0.0001)
    }

    func testDistanceDiagonal() {
        let a = LocationCoordinate(x: 0.0, y: 0.0)
        let b = LocationCoordinate(x: 3.0, y: 4.0)
        XCTAssertEqual(a.distance(to: b), 5.0, accuracy: 0.0001)
    }

    func testDistanceIsSymmetric() {
        let a = LocationCoordinate(x: 0.2, y: 0.8)
        let b = LocationCoordinate(x: 0.7, y: 0.3)
        XCTAssertEqual(a.distance(to: b), b.distance(to: a), accuracy: 0.0001)
    }

    func testDistanceWithZCoordinate() {
        let a = LocationCoordinate(x: 0.0, y: 0.0, z: 0.0)
        let b = LocationCoordinate(x: 0.0, y: 0.0, z: 3.0)
        XCTAssertEqual(a.distance(to: b), 3.0, accuracy: 0.0001)
    }

    // MARK: - CGPoint Conversion Tests

    func testToCGPointOrigin() {
        let coord = LocationCoordinate(x: 0.0, y: 0.0)
        let point = coord.toCGPoint(in: CGSize(width: 100, height: 100))
        XCTAssertEqual(point.x, 0.0, accuracy: 0.0001)
        XCTAssertEqual(point.y, 0.0, accuracy: 0.0001)
    }

    func testToCGPointCenter() {
        let coord = LocationCoordinate(x: 0.5, y: 0.5)
        let point = coord.toCGPoint(in: CGSize(width: 200, height: 400))
        XCTAssertEqual(point.x, 100.0, accuracy: 0.0001)
        XCTAssertEqual(point.y, 200.0, accuracy: 0.0001)
    }

    func testToCGPointMax() {
        let coord = LocationCoordinate(x: 1.0, y: 1.0)
        let point = coord.toCGPoint(in: CGSize(width: 800, height: 600))
        XCTAssertEqual(point.x, 800.0, accuracy: 0.0001)
        XCTAssertEqual(point.y, 600.0, accuracy: 0.0001)
    }

    // MARK: - From CGPoint Tests

    func testFromCGPointCenter() {
        let point = CGPoint(x: 50, y: 50)
        let size = CGSize(width: 100, height: 100)
        let coord = LocationCoordinate.from(point: point, in: size)
        XCTAssertEqual(coord.x, 0.5, accuracy: 0.0001)
        XCTAssertEqual(coord.y, 0.5, accuracy: 0.0001)
    }

    func testFromCGPointRoundTrip() {
        let size = CGSize(width: 800, height: 600)
        let original = LocationCoordinate(x: 0.3, y: 0.7)
        let point = original.toCGPoint(in: size)
        let result = LocationCoordinate.from(point: point, in: size)
        XCTAssertEqual(result.x, original.x, accuracy: 0.0001)
        XCTAssertEqual(result.y, original.y, accuracy: 0.0001)
    }

    // MARK: - Equality Tests

    func testEquality() {
        let a = LocationCoordinate(x: 0.5, y: 0.5)
        let b = LocationCoordinate(x: 0.5, y: 0.5)
        XCTAssertEqual(a, b)
    }

    func testInequality() {
        let a = LocationCoordinate(x: 0.5, y: 0.5)
        let b = LocationCoordinate(x: 0.6, y: 0.5)
        XCTAssertNotEqual(a, b)
    }
}
