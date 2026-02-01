import XCTest
@testable import WiFiAnalyzer

final class LocationMappingServiceTests: XCTestCase {

    // MARK: - generateGridLayout Tests

    func testGridLayoutSingleLocation() {
        let service = LocationMappingService.shared
        let mapping = service.generateGridLayout(for: ["Kitchen"])

        XCTAssertEqual(mapping.count, 1)
        XCTAssertNotNil(mapping["Kitchen"])
        XCTAssertEqual(mapping["Kitchen"]!.x, 0.5, accuracy: 0.0001)
        XCTAssertEqual(mapping["Kitchen"]!.y, 0.5, accuracy: 0.0001)
    }

    func testGridLayoutFourLocations() {
        let service = LocationMappingService.shared
        let locations = ["A", "B", "C", "D"]
        let mapping = service.generateGridLayout(for: locations)

        XCTAssertEqual(mapping.count, 4)

        // 4 locations should form a 2x2 grid
        for location in locations {
            let coord = mapping[location]
            XCTAssertNotNil(coord)
            XCTAssertGreaterThan(coord!.x, 0.0)
            XCTAssertLessThan(coord!.x, 1.0)
            XCTAssertGreaterThan(coord!.y, 0.0)
            XCTAssertLessThan(coord!.y, 1.0)
        }
    }

    func testGridLayoutAllCoordinatesUnique() {
        let service = LocationMappingService.shared
        let locations = ["A", "B", "C", "D", "E", "F"]
        let mapping = service.generateGridLayout(for: locations)

        let coordinates = Array(mapping.values)
        for i in 0..<coordinates.count {
            for j in (i + 1)..<coordinates.count {
                let notEqual = coordinates[i].x != coordinates[j].x || coordinates[i].y != coordinates[j].y
                XCTAssertTrue(notEqual, "Coordinates at index \(i) and \(j) should be unique")
            }
        }
    }

    func testGridLayoutEmptyInput() {
        let service = LocationMappingService.shared
        let mapping = service.generateGridLayout(for: [])
        XCTAssertTrue(mapping.isEmpty)
    }

    func testGridLayoutCoordinatesInNormalizedRange() {
        let service = LocationMappingService.shared
        let locations = (1...9).map { "Location\($0)" }
        let mapping = service.generateGridLayout(for: locations)

        for (_, coord) in mapping {
            XCTAssertGreaterThanOrEqual(coord.x, 0.0)
            XCTAssertLessThanOrEqual(coord.x, 1.0)
            XCTAssertGreaterThanOrEqual(coord.y, 0.0)
            XCTAssertLessThanOrEqual(coord.y, 1.0)
        }
    }

    // MARK: - hasCoordinates Tests

    func testHasCoordinatesAllMapped() {
        let service = LocationMappingService.shared

        // Set coordinates
        service.setCoordinate(LocationCoordinate(x: 0.5, y: 0.5), for: "TestHasCoord_A")
        service.setCoordinate(LocationCoordinate(x: 0.3, y: 0.3), for: "TestHasCoord_B")

        XCTAssertTrue(service.hasCoordinates(for: ["TestHasCoord_A", "TestHasCoord_B"]))

        // Cleanup
        service.removeCoordinate(for: "TestHasCoord_A")
        service.removeCoordinate(for: "TestHasCoord_B")
    }

    func testHasCoordinatesPartiallyMapped() {
        let service = LocationMappingService.shared

        service.setCoordinate(LocationCoordinate(x: 0.5, y: 0.5), for: "TestPartial_A")

        XCTAssertFalse(service.hasCoordinates(for: ["TestPartial_A", "TestPartial_Unmapped"]))

        // Cleanup
        service.removeCoordinate(for: "TestPartial_A")
    }

    func testHasCoordinatesEmptyInput() {
        let service = LocationMappingService.shared
        XCTAssertTrue(service.hasCoordinates(for: []))
    }
}
