import XCTest
@testable import WiFiAnalyzer

@MainActor
final class StatisticsViewModelTests: XCTestCase {

    var sut: StatisticsViewModel!
    var testDefaults: UserDefaults!
    var persistenceService: PersistenceService!

    override func setUp() {
        super.setUp()
        testDefaults = UserDefaults(suiteName: "com.wifianalyzer.stats.tests.\(UUID().uuidString)")!
        persistenceService = PersistenceService(userDefaults: testDefaults)
        sut = StatisticsViewModel(persistenceService: persistenceService)
    }

    override func tearDown() {
        testDefaults = nil
        persistenceService = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func makeMeasurement(location: String = "Kitchen", ssid: String = "WiFi", rssi: Int = -50) -> MeasurementPoint {
        MeasurementPoint(
            locationName: location,
            ssid: ssid,
            bssid: "00:11:22:33:44:55",
            rssi: rssi,
            timestamp: Date()
        )
    }

    private func loadWithMeasurements(_ measurements: [MeasurementPoint]) throws {
        try persistenceService.save(measurements)
        sut.loadMeasurements()
    }

    // MARK: - Empty State Tests

    func testEmptyTotalMeasurements() {
        XCTAssertEqual(sut.totalMeasurements, 0)
    }

    func testEmptyAverageRSSI() {
        XCTAssertEqual(sut.averageRSSI, -90)
    }

    func testEmptyBestRSSI() {
        XCTAssertEqual(sut.bestRSSI, -90)
    }

    func testEmptyWorstRSSI() {
        XCTAssertEqual(sut.worstRSSI, -90)
    }

    func testEmptyStandardDeviation() {
        XCTAssertEqual(sut.rssiStandardDeviation, 0.0)
    }

    func testEmptyMostFrequentSSID() {
        XCTAssertNil(sut.mostFrequentSSID)
    }

    // MARK: - Computed Statistics Tests

    func testTotalMeasurements() throws {
        try loadWithMeasurements([
            makeMeasurement(rssi: -50),
            makeMeasurement(rssi: -70),
            makeMeasurement(rssi: -60)
        ])
        XCTAssertEqual(sut.totalMeasurements, 3)
    }

    func testAverageRSSI() throws {
        try loadWithMeasurements([
            makeMeasurement(rssi: -40),
            makeMeasurement(rssi: -60)
        ])
        XCTAssertEqual(sut.averageRSSI, -50)
    }

    func testBestRSSI() throws {
        try loadWithMeasurements([
            makeMeasurement(rssi: -30),
            makeMeasurement(rssi: -70),
            makeMeasurement(rssi: -50)
        ])
        XCTAssertEqual(sut.bestRSSI, -30)
    }

    func testWorstRSSI() throws {
        try loadWithMeasurements([
            makeMeasurement(rssi: -30),
            makeMeasurement(rssi: -70),
            makeMeasurement(rssi: -50)
        ])
        XCTAssertEqual(sut.worstRSSI, -70)
    }

    func testStandardDeviation() throws {
        // Values: -40, -60. Mean = -50. Variance = (100+100)/1 = 200. SD = ~14.14
        try loadWithMeasurements([
            makeMeasurement(rssi: -40),
            makeMeasurement(rssi: -60)
        ])
        XCTAssertEqual(sut.rssiStandardDeviation, 14.14, accuracy: 0.1)
    }

    // MARK: - Location Statistics Tests

    func testBestLocations() throws {
        try loadWithMeasurements([
            makeMeasurement(location: "Kitchen", rssi: -30),
            makeMeasurement(location: "Bedroom", rssi: -70),
            makeMeasurement(location: "Garage", rssi: -90)
        ])
        let best = sut.bestLocations
        XCTAssertEqual(best.first?.locationName, "Kitchen")
    }

    func testWorstLocations() throws {
        try loadWithMeasurements([
            makeMeasurement(location: "Kitchen", rssi: -30),
            makeMeasurement(location: "Bedroom", rssi: -70),
            makeMeasurement(location: "Garage", rssi: -90)
        ])
        let worst = sut.worstLocations
        XCTAssertEqual(worst.first?.locationName, "Garage")
    }

    // MARK: - SSID Statistics Tests

    func testUniqueSSIDCount() throws {
        try loadWithMeasurements([
            makeMeasurement(ssid: "WiFi_A"),
            makeMeasurement(ssid: "WiFi_B"),
            makeMeasurement(ssid: "WiFi_A")
        ])
        XCTAssertEqual(sut.uniqueSSIDCount, 2)
    }

    func testMostFrequentSSID() throws {
        try loadWithMeasurements([
            makeMeasurement(ssid: "WiFi_A"),
            makeMeasurement(ssid: "WiFi_B"),
            makeMeasurement(ssid: "WiFi_A")
        ])
        XCTAssertEqual(sut.mostFrequentSSID, "WiFi_A")
    }

    // MARK: - Signal Quality Distribution Tests

    func testSignalQualityDistribution() throws {
        try loadWithMeasurements([
            makeMeasurement(rssi: -45), // Excellent
            makeMeasurement(rssi: -55), // Good
            makeMeasurement(rssi: -55)  // Good
        ])
        let distribution = sut.signalQualityDistribution
        let excellentCount = distribution.first { $0.quality == .excellent }?.count ?? 0
        let goodCount = distribution.first { $0.quality == .good }?.count ?? 0
        XCTAssertEqual(excellentCount, 1)
        XCTAssertEqual(goodCount, 2)
    }
}
