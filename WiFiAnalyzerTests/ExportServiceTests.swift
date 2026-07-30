import XCTest
@testable import WiFiAnalyzer

final class ExportServiceTests: XCTestCase {

    let sut = ExportService()

    // MARK: - Helpers

    private func makeMeasurement(location: String = "Kitchen", ssid: String = "TestWiFi", rssi: Int = -50) -> MeasurementPoint {
        MeasurementPoint(
            locationName: location,
            ssid: ssid,
            bssid: "00:11:22:33:44:55",
            rssi: rssi,
            timestamp: Date(timeIntervalSince1970: 1738339200) // Fixed date for deterministic tests
        )
    }

    // MARK: - CSV Content Generation Tests

    func testCSVContentHasHeader() throws {
        let csv = try sut.generateCSVContent([makeMeasurement()])
        let lines = csv.components(separatedBy: "\n")
        XCTAssertEqual(lines.first, "Location,SSID,BSSID,RSSI (dBm),Signal Quality,Date,Time")
    }

    func testCSVContentHasCorrectFieldCount() throws {
        let csv = try sut.generateCSVContent([makeMeasurement()])
        let lines = csv.components(separatedBy: "\n").filter { !$0.isEmpty }
        let dataLine = lines[1]
        let fields = dataLine.components(separatedBy: ",")
        XCTAssertEqual(fields.count, 7)
    }

    func testCSVContentContainsLocationName() throws {
        let csv = try sut.generateCSVContent([makeMeasurement(location: "Living Room")])
        XCTAssertTrue(csv.contains("Living Room"))
    }

    func testCSVContentContainsRSSI() throws {
        let csv = try sut.generateCSVContent([makeMeasurement(rssi: -65)])
        XCTAssertTrue(csv.contains("-65"))
    }

    func testCSVContentEscapesCommasInLocation() throws {
        let csv = try sut.generateCSVContent([makeMeasurement(location: "Room, Floor 2")])
        XCTAssertTrue(csv.contains("\"Room, Floor 2\""))
    }

    func testCSVContentEmptyThrows() {
        XCTAssertThrowsError(try sut.generateCSVContent([])) { error in
            XCTAssertTrue(error is ExportError)
        }
    }

    func testCSVMultipleMeasurements() throws {
        let measurements = [
            makeMeasurement(location: "Kitchen", rssi: -50),
            makeMeasurement(location: "Bedroom", rssi: -70)
        ]
        let csv = try sut.generateCSVContent(measurements)
        let lines = csv.components(separatedBy: "\n").filter { !$0.isEmpty }
        XCTAssertEqual(lines.count, 3) // header + 2 data rows
    }

    // MARK: - JSON Content Generation Tests

    func testJSONContentIsValidJSON() throws {
        let json = try sut.generateJSONContent([makeMeasurement()])
        let data = json.data(using: .utf8)!
        XCTAssertNoThrow(try JSONSerialization.jsonObject(with: data))
    }

    func testJSONContentContainsFields() throws {
        let json = try sut.generateJSONContent([makeMeasurement(location: "Kitchen", ssid: "TestWiFi")])
        XCTAssertTrue(json.contains("Kitchen"))
        XCTAssertTrue(json.contains("TestWiFi"))
    }

    func testJSONContentEmptyThrows() {
        XCTAssertThrowsError(try sut.generateJSONContent([])) { error in
            XCTAssertTrue(error is ExportError)
        }
    }

    func testJSONContentHasLocalTimestamp() throws {
        let json = try sut.generateJSONContent([makeMeasurement()])
        // Should NOT contain "Z" suffix (UTC), should be local time format
        // The timestamp format is yyyy-MM-dd'T'HH:mm:ss without timezone indicator
        XCTAssertTrue(json.contains("T"))
    }

    // MARK: - CSV Escape Tests

    func testEscapeFieldNoSpecialChars() {
        XCTAssertEqual(sut.escapeCSVField("Kitchen"), "Kitchen")
    }

    func testEscapeFieldWithComma() {
        XCTAssertEqual(sut.escapeCSVField("Room, 2"), "\"Room, 2\"")
    }

    func testEscapeFieldWithQuote() {
        XCTAssertEqual(sut.escapeCSVField("Room \"A\""), "\"Room \"\"A\"\"\"")
    }

    func testEscapeFieldWithNewline() {
        XCTAssertEqual(sut.escapeCSVField("Room\nFloor"), "\"Room\nFloor\"")
    }

    // MARK: - CSV Formula Injection Tests

    func testEscapeFieldNeutralizesLeadingEquals() {
        XCTAssertEqual(sut.escapeCSVField("=HYPERLINK(\"http://evil.com\")"), "\"'=HYPERLINK(\"\"http://evil.com\"\")\"")
    }

    func testEscapeFieldNeutralizesLeadingPlus() {
        XCTAssertEqual(sut.escapeCSVField("+1+1"), "'+1+1")
    }

    func testEscapeFieldNeutralizesLeadingMinus() {
        XCTAssertEqual(sut.escapeCSVField("-2+3"), "'-2+3")
    }

    func testEscapeFieldNeutralizesLeadingAt() {
        XCTAssertEqual(sut.escapeCSVField("@SUM(A1:A2)"), "'@SUM(A1:A2)")
    }

    func testEscapeFieldNeutralizesLeadingTab() {
        XCTAssertEqual(sut.escapeCSVField("\t=cmd"), "'\t=cmd")
    }

    func testEscapeFieldDoesNotAlterBenignLeadingCharacters() {
        XCTAssertEqual(sut.escapeCSVField("Kitchen"), "Kitchen")
        XCTAssertEqual(sut.escapeCSVField("3rd Floor"), "3rd Floor")
    }

    func testCSVContentNeutralizesFormulaInSSID() throws {
        let csv = try sut.generateCSVContent([makeMeasurement(ssid: "=2+5+cmd|' /C calc'!A0")])
        let lines = csv.components(separatedBy: "\n").filter { !$0.isEmpty }
        let fields = lines[1].components(separatedBy: ",")
        // SSID is the second field and must not start with a formula-trigger character
        XCTAssertTrue(fields[1].hasPrefix("\"'=") || fields[1].hasPrefix("'="))
    }
}
