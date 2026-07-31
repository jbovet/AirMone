import XCTest
@testable import WiFiAnalyzer

final class WiFiFrequencyTests: XCTestCase {

    // MARK: - 2.4 GHz

    func test24GHzChannel1() {
        XCTAssertEqual(WiFiFrequency.centerFrequencyMHz(channel: 1, band: "2.4 GHz"), 2412)
    }

    func test24GHzChannel6() {
        XCTAssertEqual(WiFiFrequency.centerFrequencyMHz(channel: 6, band: "2.4 GHz"), 2437)
    }

    func test24GHzChannel11() {
        XCTAssertEqual(WiFiFrequency.centerFrequencyMHz(channel: 11, band: "2.4 GHz"), 2462)
    }

    func test24GHzChannel14IsSpecialCased() {
        XCTAssertEqual(WiFiFrequency.centerFrequencyMHz(channel: 14, band: "2.4 GHz"), 2484)
    }

    func test24GHzOutOfRangeChannelIsNil() {
        XCTAssertNil(WiFiFrequency.centerFrequencyMHz(channel: 15, band: "2.4 GHz"))
        XCTAssertNil(WiFiFrequency.centerFrequencyMHz(channel: 0, band: "2.4 GHz"))
    }

    // MARK: - 5 GHz

    func test5GHzChannel36() {
        XCTAssertEqual(WiFiFrequency.centerFrequencyMHz(channel: 36, band: "5 GHz"), 5180)
    }

    func test5GHzChannel149() {
        XCTAssertEqual(WiFiFrequency.centerFrequencyMHz(channel: 149, band: "5 GHz"), 5745)
    }

    // MARK: - 6 GHz

    func test6GHzChannel1() {
        XCTAssertEqual(WiFiFrequency.centerFrequencyMHz(channel: 1, band: "6 GHz"), 5955)
    }

    // MARK: - Unknown band

    func testUnknownBandIsNil() {
        XCTAssertNil(WiFiFrequency.centerFrequencyMHz(channel: 6, band: "Unknown"))
    }
}
