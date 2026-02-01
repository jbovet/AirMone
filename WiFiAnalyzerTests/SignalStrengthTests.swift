import XCTest
@testable import WiFiAnalyzer

final class SignalStrengthTests: XCTestCase {

    // MARK: - Boundary Tests

    func testExcellentSignalUpperBound() {
        XCTAssertEqual(SignalStrength.from(rssi: 0), .excellent)
    }

    func testExcellentSignalLowerBound() {
        XCTAssertEqual(SignalStrength.from(rssi: -50), .excellent)
    }

    func testGoodSignalUpperBound() {
        XCTAssertEqual(SignalStrength.from(rssi: -51), .good)
    }

    func testGoodSignalLowerBound() {
        // -60 ..< -50 includes -60
        XCTAssertEqual(SignalStrength.from(rssi: -60), .good)
    }

    func testFairSignalUpperBound() {
        XCTAssertEqual(SignalStrength.from(rssi: -61), .fair)
    }

    func testFairSignalMidRange() {
        XCTAssertEqual(SignalStrength.from(rssi: -65), .fair)
    }

    func testFairSignalLowerBound() {
        // -70 ..< -60 includes -70
        XCTAssertEqual(SignalStrength.from(rssi: -70), .fair)
    }

    func testWeakSignalUpperBound() {
        XCTAssertEqual(SignalStrength.from(rssi: -71), .weak)
    }

    func testWeakSignalMidRange() {
        XCTAssertEqual(SignalStrength.from(rssi: -75), .weak)
    }

    func testWeakSignalLowerBound() {
        // -80 ..< -70 includes -80
        XCTAssertEqual(SignalStrength.from(rssi: -80), .weak)
    }

    func testPoorSignalUpperBound() {
        XCTAssertEqual(SignalStrength.from(rssi: -81), .poor)
    }

    func testPoorSignalMidRange() {
        XCTAssertEqual(SignalStrength.from(rssi: -85), .poor)
    }

    func testPoorSignalLowerBound() {
        // -90 ..< -80 includes -90
        XCTAssertEqual(SignalStrength.from(rssi: -90), .poor)
    }

    func testUnusableSignalUpperBound() {
        XCTAssertEqual(SignalStrength.from(rssi: -91), .unusable)
    }

    func testUnusableSignal() {
        XCTAssertEqual(SignalStrength.from(rssi: -100), .unusable)
    }

    // MARK: - Color Tests

    func testExcellentColor() {
        XCTAssertNotNil(SignalStrength.excellent.color)
    }

    // MARK: - Percentage Tests

    func testExcellentPercentage() {
        XCTAssertEqual(SignalStrength.excellent.percentage, 1.0)
    }

    func testUnusablePercentage() {
        XCTAssertEqual(SignalStrength.unusable.percentage, 0.16)
    }

    // MARK: - All Cases

    func testAllCasesCount() {
        XCTAssertEqual(SignalStrength.allCases.count, 6)
    }
}
