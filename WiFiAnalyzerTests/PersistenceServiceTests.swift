import XCTest
@testable import WiFiAnalyzer

final class PersistenceServiceTests: XCTestCase {

    var sut: PersistenceService!
    var testDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        testDefaults = UserDefaults(suiteName: "com.wifianalyzer.tests.\(UUID().uuidString)")!
        sut = PersistenceService(userDefaults: testDefaults)
    }

    override func tearDown() {
        testDefaults.removePersistentDomain(forName: testDefaults.volatileDomainNames.first ?? "")
        testDefaults = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func makeMeasurement(location: String = "Kitchen", rssi: Int = -50) -> MeasurementPoint {
        MeasurementPoint(
            locationName: location,
            ssid: "TestWiFi",
            bssid: "00:11:22:33:44:55",
            rssi: rssi,
            timestamp: Date()
        )
    }

    // MARK: - Load / Save Tests

    func testLoadEmptyReturnsEmptyArray() {
        let measurements = sut.load()
        XCTAssertTrue(measurements.isEmpty)
    }

    func testSaveAndLoad() throws {
        let measurement = makeMeasurement()
        try sut.save([measurement])

        let loaded = sut.load()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.locationName, "Kitchen")
        XCTAssertEqual(loaded.first?.rssi, -50)
    }

    func testSaveMultipleAndLoad() throws {
        let measurements = [
            makeMeasurement(location: "Kitchen", rssi: -50),
            makeMeasurement(location: "Bedroom", rssi: -70)
        ]
        try sut.save(measurements)

        let loaded = sut.load()
        XCTAssertEqual(loaded.count, 2)
    }

    // MARK: - Append Tests

    func testAppendToEmpty() throws {
        let measurement = makeMeasurement()
        try sut.append(measurement)

        let loaded = sut.load()
        XCTAssertEqual(loaded.count, 1)
    }

    func testAppendToExisting() throws {
        try sut.append(makeMeasurement(location: "Kitchen"))
        try sut.append(makeMeasurement(location: "Bedroom"))

        let loaded = sut.load()
        XCTAssertEqual(loaded.count, 2)
    }

    // MARK: - Delete Tests

    func testDeleteById() throws {
        let m1 = makeMeasurement(location: "Kitchen")
        let m2 = makeMeasurement(location: "Bedroom")
        try sut.save([m1, m2])

        try sut.delete(id: m1.id)

        let loaded = sut.load()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.locationName, "Bedroom")
    }

    func testDeleteNonExistentIdDoesNothing() throws {
        let measurement = makeMeasurement()
        try sut.save([measurement])

        try sut.delete(id: UUID())

        let loaded = sut.load()
        XCTAssertEqual(loaded.count, 1)
    }

    func testDeleteAll() throws {
        try sut.save([makeMeasurement(), makeMeasurement()])
        try sut.deleteAll()

        let loaded = sut.load()
        XCTAssertTrue(loaded.isEmpty)
    }

    // MARK: - Data Changed Notification Tests

    func testSavePublishesDataChanged() throws {
        let expectation = XCTestExpectation(description: "dataChanged published")
        let cancellable = sut.dataChanged.sink { expectation.fulfill() }

        try sut.save([makeMeasurement()])

        wait(for: [expectation], timeout: 1.0)
        cancellable.cancel()
    }

    func testAppendPublishesDataChanged() throws {
        let expectation = XCTestExpectation(description: "dataChanged published")
        let cancellable = sut.dataChanged.sink { expectation.fulfill() }

        try sut.append(makeMeasurement())

        wait(for: [expectation], timeout: 1.0)
        cancellable.cancel()
    }

    func testDeletePublishesDataChanged() throws {
        let measurement = makeMeasurement()
        try sut.save([measurement])

        let expectation = XCTestExpectation(description: "dataChanged published")
        let cancellable = sut.dataChanged.sink { expectation.fulfill() }

        try sut.delete(id: measurement.id)

        wait(for: [expectation], timeout: 1.0)
        cancellable.cancel()
    }
}
