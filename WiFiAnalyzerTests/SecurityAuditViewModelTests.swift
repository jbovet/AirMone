import XCTest
@testable import WiFiAnalyzer

@MainActor
final class SecurityAuditViewModelTests: XCTestCase {

    var sut: SecurityAuditViewModel!

    override func setUp() {
        super.setUp()
        sut = SecurityAuditViewModel()
    }

    override func tearDown() {
        sut.stopScanning()
        sut = nil
        super.tearDown()
    }

    private func makeNetwork(
        ssid: String = "TestWiFi",
        bssid: String = "AA:BB:CC:DD:EE:FF",
        rssi: Int = -50,
        security: String = "WPA2 Personal",
        band: String = "2.4 GHz",
        channel: Int = 6
    ) -> NearbyNetwork {
        NearbyNetwork(
            id: "\(ssid)_\(bssid)",
            ssid: ssid,
            bssid: bssid,
            rssi: rssi,
            noise: -90,
            channel: channel,
            band: band,
            channelWidth: 20,
            security: security,
            countryCode: nil,
            isIBSS: false,
            beaconInterval: 100,
            timestamp: Date()
        )
    }

    // MARK: - auditedNetworks ordering

    func testAuditedNetworksSortedWorstFirst() {
        sut.nearbyNetworks = [
            makeNetwork(ssid: "Strong", bssid: "AA:AA:AA:AA:AA:01", security: "WPA3 Personal"),
            makeNetwork(ssid: "Open", bssid: "AA:AA:AA:AA:AA:02", security: "Open"),
            makeNetwork(ssid: "OK", bssid: "AA:AA:AA:AA:AA:03", security: "WPA2 Personal"),
            makeNetwork(ssid: "WEP", bssid: "AA:AA:AA:AA:AA:04", security: "WEP")
        ]

        let order = sut.auditedNetworks.map { $0.ssid }
        XCTAssertEqual(order, ["Open", "WEP", "OK", "Strong"])
    }

    func testAuditedNetworksTieBreaksByStrongestSignal() {
        sut.nearbyNetworks = [
            makeNetwork(ssid: "OpenWeak", bssid: "AA:AA:AA:AA:AA:01", rssi: -80, security: "Open"),
            makeNetwork(ssid: "OpenStrong", bssid: "AA:AA:AA:AA:AA:02", rssi: -40, security: "Open")
        ]

        // Same rating (open) -> strongest signal first
        XCTAssertEqual(sut.auditedNetworks.map { $0.ssid }, ["OpenStrong", "OpenWeak"])
    }

    // MARK: - onlyIssues filter

    func testOnlyIssuesFiltersToWeakOrWorse() {
        sut.nearbyNetworks = [
            makeNetwork(ssid: "Open", bssid: "AA:AA:AA:AA:AA:01", security: "Open"),
            makeNetwork(ssid: "WPA1", bssid: "AA:AA:AA:AA:AA:02", security: "WPA Personal"),
            makeNetwork(ssid: "WPA2", bssid: "AA:AA:AA:AA:AA:03", security: "WPA2 Personal"),
            makeNetwork(ssid: "WPA3", bssid: "AA:AA:AA:AA:AA:04", security: "WPA3 Personal")
        ]

        sut.onlyIssues = true
        let ssids = Set(sut.auditedNetworks.map { $0.ssid })
        XCTAssertEqual(ssids, ["Open", "WPA1"])   // WPA2/WPA3 excluded
    }

    func testAllNetworksShownWhenNotFiltering() {
        sut.nearbyNetworks = [
            makeNetwork(ssid: "Open", bssid: "AA:AA:AA:AA:AA:01", security: "Open"),
            makeNetwork(ssid: "WPA3", bssid: "AA:AA:AA:AA:AA:02", security: "WPA3 Personal")
        ]

        sut.onlyIssues = false
        XCTAssertEqual(sut.auditedNetworks.count, 2)
    }

    // MARK: - summary & issueCount

    func testSummaryCountsByRating() {
        sut.nearbyNetworks = [
            makeNetwork(bssid: "AA:AA:AA:AA:AA:01", security: "Open"),
            makeNetwork(bssid: "AA:AA:AA:AA:AA:02", security: "Open"),
            makeNetwork(bssid: "AA:AA:AA:AA:AA:03", security: "WEP"),
            makeNetwork(bssid: "AA:AA:AA:AA:AA:04", security: "WPA3 Personal")
        ]

        XCTAssertEqual(sut.summary[.open], 2)
        XCTAssertEqual(sut.summary[.insecure], 1)
        XCTAssertEqual(sut.summary[.strong], 1)
        XCTAssertNil(sut.summary[.acceptable])
    }

    func testIssueCountCountsWeakOrWorse() {
        sut.nearbyNetworks = [
            makeNetwork(bssid: "AA:AA:AA:AA:AA:01", security: "Open"),
            makeNetwork(bssid: "AA:AA:AA:AA:AA:02", security: "WEP"),
            makeNetwork(bssid: "AA:AA:AA:AA:AA:03", security: "WPA Personal"),
            makeNetwork(bssid: "AA:AA:AA:AA:AA:04", security: "WPA2 Personal"),
            makeNetwork(bssid: "AA:AA:AA:AA:AA:05", security: "WPA3 Personal")
        ]

        XCTAssertEqual(sut.issueCount, 3)   // Open + WEP + WPA1
    }

    // MARK: - Band filter

    func testBandFilterRestrictsAuditAndSummary() {
        sut.nearbyNetworks = [
            makeNetwork(ssid: "A", bssid: "AA:AA:AA:AA:AA:01", security: "Open", band: "2.4 GHz", channel: 6),
            makeNetwork(ssid: "B", bssid: "AA:AA:AA:AA:AA:02", security: "WEP", band: "5 GHz", channel: 36),
            makeNetwork(ssid: "C", bssid: "AA:AA:AA:AA:AA:03", security: "WPA3 Personal", band: "5 GHz", channel: 40)
        ]

        sut.selectedBandFilter = .band5

        XCTAssertEqual(Set(sut.auditedNetworks.map { $0.ssid }), ["B", "C"])
        XCTAssertEqual(sut.summary[.open], nil)        // 2.4 GHz network excluded
        XCTAssertEqual(sut.summary[.insecure], 1)      // WEP on 5 GHz
        XCTAssertEqual(sut.issueCount, 1)              // only the WEP network
    }

    func testEmptyWhenNoNetworks() {
        sut.nearbyNetworks = []
        XCTAssertTrue(sut.auditedNetworks.isEmpty)
        XCTAssertTrue(sut.summary.isEmpty)
        XCTAssertEqual(sut.issueCount, 0)
    }
}
