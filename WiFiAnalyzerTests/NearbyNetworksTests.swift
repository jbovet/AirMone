import XCTest
@testable import WiFiAnalyzer

// MARK: - NearbyNetwork Model Tests

final class NearbyNetworkTests: XCTestCase {

    private func makeNetwork(
        ssid: String = "TestWiFi",
        bssid: String = "AA:BB:CC:DD:EE:FF",
        rssi: Int = -50,
        noise: Int = -90,
        channel: Int = 6,
        band: String = "2.4 GHz",
        security: String = "WPA2 Personal"
    ) -> NearbyNetwork {
        NearbyNetwork(
            id: "\(ssid)_\(bssid)",
            ssid: ssid,
            bssid: bssid,
            rssi: rssi,
            noise: noise,
            channel: channel,
            band: band,
            channelWidth: 20,
            security: security,
            countryCode: "US",
            isIBSS: false,
            beaconInterval: 100,
            timestamp: Date()
        )
    }

    func testNetworkId() {
        let network = makeNetwork(ssid: "MyWiFi", bssid: "11:22:33:44:55:66")
        XCTAssertEqual(network.id, "MyWiFi_11:22:33:44:55:66")
    }

    func testNetworkKey() {
        let network = makeNetwork()
        XCTAssertEqual(network.networkKey, network.id)
    }

    func testSignalStrengthExcellent() {
        let network = makeNetwork(rssi: -40)
        XCTAssertEqual(network.signalStrength, .excellent)
    }

    func testSignalStrengthPoor() {
        let network = makeNetwork(rssi: -85)
        XCTAssertEqual(network.signalStrength, .poor)
    }

    func testSNRCalculation() {
        let network = makeNetwork(rssi: -50, noise: -90)
        XCTAssertEqual(network.snr, 40)
    }

    func testSNRWithHighNoise() {
        let network = makeNetwork(rssi: -60, noise: -65)
        XCTAssertEqual(network.snr, 5)
    }

    func testEqualityByID() {
        let a = makeNetwork(ssid: "WiFi", bssid: "AA:BB:CC:DD:EE:FF")
        let b = NearbyNetwork(
            id: "WiFi_AA:BB:CC:DD:EE:FF",
            ssid: "WiFi", bssid: "AA:BB:CC:DD:EE:FF",
            rssi: -70, noise: -95, channel: 11, band: "2.4 GHz",
            channelWidth: 40, security: "WPA3 Personal",
            countryCode: nil, isIBSS: false, beaconInterval: 100,
            timestamp: Date()
        )
        XCTAssertEqual(a, b)
    }

    func testInequalityByID() {
        let a = makeNetwork(ssid: "WiFi", bssid: "AA:BB:CC:DD:EE:01")
        let b = makeNetwork(ssid: "WiFi", bssid: "AA:BB:CC:DD:EE:02")
        XCTAssertNotEqual(a, b)
    }
}

// MARK: - NetworkGroup Model Tests

final class NetworkGroupTests: XCTestCase {

    private func makeNetwork(
        ssid: String = "TestWiFi",
        bssid: String = "AA:BB:CC:DD:EE:FF",
        rssi: Int = -50,
        noise: Int = -90,
        channel: Int = 6,
        band: String = "2.4 GHz"
    ) -> NearbyNetwork {
        NearbyNetwork(
            id: "\(ssid)_\(bssid)",
            ssid: ssid, bssid: bssid,
            rssi: rssi, noise: noise,
            channel: channel, band: band,
            channelWidth: 20, security: "WPA2 Personal",
            countryCode: nil, isIBSS: false, beaconInterval: 100,
            timestamp: Date()
        )
    }

    func testGroupId() {
        let group = NetworkGroup(ssid: "MyWiFi", accessPoints: [
            makeNetwork(ssid: "MyWiFi")
        ])
        XCTAssertEqual(group.id, "MyWiFi")
    }

    func testBestSignalPicksStrongest() {
        let group = NetworkGroup(ssid: "WiFi", accessPoints: [
            makeNetwork(ssid: "WiFi", bssid: "01", rssi: -70),
            makeNetwork(ssid: "WiFi", bssid: "02", rssi: -40),
            makeNetwork(ssid: "WiFi", bssid: "03", rssi: -60)
        ])
        XCTAssertEqual(group.bestRSSI, -40)
    }

    func testSignalStrengthFromBestRSSI() {
        let group = NetworkGroup(ssid: "WiFi", accessPoints: [
            makeNetwork(ssid: "WiFi", bssid: "01", rssi: -45)
        ])
        XCTAssertEqual(group.signalStrength, .excellent)
    }

    func testAPCount() {
        let group = NetworkGroup(ssid: "WiFi", accessPoints: [
            makeNetwork(ssid: "WiFi", bssid: "01"),
            makeNetwork(ssid: "WiFi", bssid: "02"),
            makeNetwork(ssid: "WiFi", bssid: "03")
        ])
        XCTAssertEqual(group.apCount, 3)
    }

    func testBandsSingleBand() {
        let group = NetworkGroup(ssid: "WiFi", accessPoints: [
            makeNetwork(ssid: "WiFi", bssid: "01", band: "5 GHz"),
            makeNetwork(ssid: "WiFi", bssid: "02", band: "5 GHz")
        ])
        XCTAssertEqual(group.bands, "5 GHz")
    }

    func testBandsMultipleBands() {
        let group = NetworkGroup(ssid: "WiFi", accessPoints: [
            makeNetwork(ssid: "WiFi", bssid: "01", band: "2.4 GHz"),
            makeNetwork(ssid: "WiFi", bssid: "02", band: "5 GHz")
        ])
        XCTAssertEqual(group.bands, "2.4 GHz + 5 GHz")
    }

    func testChannelsSorted() {
        let group = NetworkGroup(ssid: "WiFi", accessPoints: [
            makeNetwork(ssid: "WiFi", bssid: "01", channel: 44),
            makeNetwork(ssid: "WiFi", bssid: "02", channel: 6),
            makeNetwork(ssid: "WiFi", bssid: "03", channel: 36)
        ])
        XCTAssertEqual(group.channels, [6, 36, 44])
    }

    func testChannelsDeduplication() {
        let group = NetworkGroup(ssid: "WiFi", accessPoints: [
            makeNetwork(ssid: "WiFi", bssid: "01", channel: 6),
            makeNetwork(ssid: "WiFi", bssid: "02", channel: 6)
        ])
        XCTAssertEqual(group.channels, [6])
    }

    func testSecurityFromBestSignal() {
        let ap1 = NearbyNetwork(
            id: "WiFi_01", ssid: "WiFi", bssid: "01",
            rssi: -70, noise: -90, channel: 6, band: "2.4 GHz",
            channelWidth: 20, security: "WPA2 Personal",
            countryCode: nil, isIBSS: false, beaconInterval: 100, timestamp: Date()
        )
        let ap2 = NearbyNetwork(
            id: "WiFi_02", ssid: "WiFi", bssid: "02",
            rssi: -40, noise: -90, channel: 36, band: "5 GHz",
            channelWidth: 80, security: "WPA3 Personal",
            countryCode: nil, isIBSS: false, beaconInterval: 100, timestamp: Date()
        )
        let group = NetworkGroup(ssid: "WiFi", accessPoints: [ap1, ap2])
        XCTAssertEqual(group.security, "WPA3 Personal")
    }

    func testBestSNR() {
        let group = NetworkGroup(ssid: "WiFi", accessPoints: [
            makeNetwork(ssid: "WiFi", bssid: "01", rssi: -40, noise: -90)
        ])
        XCTAssertEqual(group.bestSNR, 50)
    }
}

// MARK: - NearbyNetworksViewModel Tests

@MainActor
final class NearbyNetworksViewModelTests: XCTestCase {

    var sut: NearbyNetworksViewModel!

    override func setUp() {
        super.setUp()
        sut = NearbyNetworksViewModel()
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
        noise: Int = -90,
        channel: Int = 6,
        band: String = "2.4 GHz"
    ) -> NearbyNetwork {
        NearbyNetwork(
            id: "\(ssid)_\(bssid)",
            ssid: ssid, bssid: bssid,
            rssi: rssi, noise: noise,
            channel: channel, band: band,
            channelWidth: 20, security: "WPA2 Personal",
            countryCode: nil, isIBSS: false, beaconInterval: 100,
            timestamp: Date()
        )
    }

    // MARK: - Initial State

    func testInitialStateEmpty() {
        XCTAssertTrue(sut.nearbyNetworks.isEmpty)
        XCTAssertTrue(sut.networkGroups.isEmpty)
        XCTAssertFalse(sut.isScanning)
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(sut.selectedBandFilter, .all)
        XCTAssertEqual(sut.sortOrder, .signalStrength)
    }

    func testInitialTotalNetworkCount() {
        XCTAssertEqual(sut.totalNetworkCount, 0)
    }

    func testInitialChartHistoryEmpty() {
        XCTAssertTrue(sut.chartSignalHistory.isEmpty)
    }

    func testInitialTopSSIDsEmpty() {
        XCTAssertTrue(sut.topSSIDsBySignal.isEmpty)
    }

    // MARK: - Grouping

    func testGroupsBySsid() {
        sut.nearbyNetworks = [
            makeNetwork(ssid: "WiFi_A", bssid: "01", rssi: -40),
            makeNetwork(ssid: "WiFi_A", bssid: "02", rssi: -60),
            makeNetwork(ssid: "WiFi_B", bssid: "03", rssi: -50)
        ]
        XCTAssertEqual(sut.networkGroups.count, 2)
    }

    func testGroupAPCount() {
        sut.nearbyNetworks = [
            makeNetwork(ssid: "WiFi_A", bssid: "01"),
            makeNetwork(ssid: "WiFi_A", bssid: "02"),
            makeNetwork(ssid: "WiFi_A", bssid: "03")
        ]
        XCTAssertEqual(sut.networkGroups.first?.apCount, 3)
        XCTAssertEqual(sut.totalNetworkCount, 3)
    }

    func testGroupCountVsTotalAPCount() {
        sut.nearbyNetworks = [
            makeNetwork(ssid: "WiFi_A", bssid: "01"),
            makeNetwork(ssid: "WiFi_A", bssid: "02"),
            makeNetwork(ssid: "WiFi_B", bssid: "03")
        ]
        XCTAssertEqual(sut.networkGroups.count, 2)
        XCTAssertEqual(sut.totalNetworkCount, 3)
    }

    // MARK: - Band Filtering

    func testBandFilterAll() {
        sut.nearbyNetworks = [
            makeNetwork(ssid: "WiFi_A", bssid: "01", band: "2.4 GHz"),
            makeNetwork(ssid: "WiFi_B", bssid: "02", band: "5 GHz")
        ]
        sut.selectedBandFilter = .all
        XCTAssertEqual(sut.networkGroups.count, 2)
    }

    func testBandFilter2_4GHz() {
        sut.nearbyNetworks = [
            makeNetwork(ssid: "WiFi_A", bssid: "01", band: "2.4 GHz"),
            makeNetwork(ssid: "WiFi_B", bssid: "02", band: "5 GHz"),
            makeNetwork(ssid: "WiFi_C", bssid: "03", band: "2.4 GHz")
        ]
        sut.selectedBandFilter = .band2_4
        XCTAssertEqual(sut.networkGroups.count, 2)
        XCTAssertTrue(sut.networkGroups.allSatisfy { group in
            group.accessPoints.allSatisfy { $0.band == "2.4 GHz" }
        })
    }

    func testBandFilter5GHz() {
        sut.nearbyNetworks = [
            makeNetwork(ssid: "WiFi_A", bssid: "01", band: "2.4 GHz"),
            makeNetwork(ssid: "WiFi_B", bssid: "02", band: "5 GHz")
        ]
        sut.selectedBandFilter = .band5
        XCTAssertEqual(sut.networkGroups.count, 1)
        XCTAssertEqual(sut.networkGroups.first?.ssid, "WiFi_B")
    }

    func testBandFilterEmptyResult() {
        sut.nearbyNetworks = [
            makeNetwork(ssid: "WiFi_A", bssid: "01", band: "2.4 GHz")
        ]
        sut.selectedBandFilter = .band6
        XCTAssertTrue(sut.networkGroups.isEmpty)
    }

    func testBandFilterAffectsMultiAPGroup() {
        // Same SSID with APs on different bands
        sut.nearbyNetworks = [
            makeNetwork(ssid: "WiFi", bssid: "01", band: "2.4 GHz"),
            makeNetwork(ssid: "WiFi", bssid: "02", band: "5 GHz")
        ]
        sut.selectedBandFilter = .band5
        XCTAssertEqual(sut.networkGroups.count, 1)
        XCTAssertEqual(sut.networkGroups.first?.apCount, 1)
    }

    // MARK: - Sorting

    func testSortBySignalStrength() {
        sut.nearbyNetworks = [
            makeNetwork(ssid: "Weak", bssid: "01", rssi: -80),
            makeNetwork(ssid: "Strong", bssid: "02", rssi: -30),
            makeNetwork(ssid: "Medium", bssid: "03", rssi: -55)
        ]
        sut.sortOrder = .signalStrength
        let ssids = sut.networkGroups.map { $0.ssid }
        XCTAssertEqual(ssids, ["Strong", "Medium", "Weak"])
    }

    func testSortByName() {
        sut.nearbyNetworks = [
            makeNetwork(ssid: "Charlie", bssid: "01"),
            makeNetwork(ssid: "Alpha", bssid: "02"),
            makeNetwork(ssid: "Bravo", bssid: "03")
        ]
        sut.sortOrder = .ssid
        let ssids = sut.networkGroups.map { $0.ssid }
        XCTAssertEqual(ssids, ["Alpha", "Bravo", "Charlie"])
    }

    func testSortByChannel() {
        sut.nearbyNetworks = [
            makeNetwork(ssid: "WiFi_C", bssid: "01", channel: 44),
            makeNetwork(ssid: "WiFi_A", bssid: "02", channel: 1),
            makeNetwork(ssid: "WiFi_B", bssid: "03", channel: 11)
        ]
        sut.sortOrder = .channel
        let ssids = sut.networkGroups.map { $0.ssid }
        XCTAssertEqual(ssids, ["WiFi_A", "WiFi_B", "WiFi_C"])
    }

    // MARK: - Top SSIDs By Signal (Chart)

    func testTopSSIDsBySignalOrder() {
        sut.nearbyNetworks = [
            makeNetwork(ssid: "Weak", bssid: "01", rssi: -80),
            makeNetwork(ssid: "Strong", bssid: "02", rssi: -30),
            makeNetwork(ssid: "Medium", bssid: "03", rssi: -55)
        ]
        let top = sut.topSSIDsBySignal
        XCTAssertEqual(top, ["Strong", "Medium", "Weak"])
    }

    func testTopSSIDsCappedAt10() {
        var networks: [NearbyNetwork] = []
        for i in 0..<15 {
            networks.append(makeNetwork(
                ssid: "WiFi_\(String(format: "%02d", i))",
                bssid: String(format: "%02d", i),
                rssi: -40 - i
            ))
        }
        sut.nearbyNetworks = networks
        XCTAssertEqual(sut.topSSIDsBySignal.count, 10)
    }

    func testTopSSIDsRespectsBandFilter() {
        sut.nearbyNetworks = [
            makeNetwork(ssid: "WiFi_2G", bssid: "01", rssi: -30, band: "2.4 GHz"),
            makeNetwork(ssid: "WiFi_5G", bssid: "02", rssi: -40, band: "5 GHz")
        ]
        sut.selectedBandFilter = .band5
        XCTAssertEqual(sut.topSSIDsBySignal, ["WiFi_5G"])
    }

    func testTopSSIDsUsesGroupBestRSSI() {
        // WiFi_A has two APs, best is -35
        sut.nearbyNetworks = [
            makeNetwork(ssid: "WiFi_A", bssid: "01", rssi: -35),
            makeNetwork(ssid: "WiFi_A", bssid: "02", rssi: -70),
            makeNetwork(ssid: "WiFi_B", bssid: "03", rssi: -40)
        ]
        let top = sut.topSSIDsBySignal
        XCTAssertEqual(top.first, "WiFi_A")
    }

    // MARK: - Chart Signal History

    func testChartHistoryEmptyWhenNoHistory() {
        sut.nearbyNetworks = [makeNetwork()]
        XCTAssertTrue(sut.chartSignalHistory.isEmpty)
    }

    func testChartHistoryRespectsFilter() {
        sut.nearbyNetworks = [
            makeNetwork(ssid: "WiFi_2G", bssid: "01", band: "2.4 GHz"),
            makeNetwork(ssid: "WiFi_5G", bssid: "02", band: "5 GHz")
        ]
        sut.signalHistory = [
            "WiFi_2G": [SignalDataPoint(rssi: -50, ssid: "WiFi_2G")],
            "WiFi_5G": [SignalDataPoint(rssi: -40, ssid: "WiFi_5G")]
        ]

        sut.selectedBandFilter = .band2_4
        XCTAssertEqual(sut.chartSignalHistory.count, 1)
        XCTAssertEqual(sut.chartSignalHistory.first?.ssid, "WiFi_2G")
    }

    func testChartHistoryAllBands() {
        sut.nearbyNetworks = [
            makeNetwork(ssid: "WiFi_2G", bssid: "01", band: "2.4 GHz"),
            makeNetwork(ssid: "WiFi_5G", bssid: "02", band: "5 GHz")
        ]
        sut.signalHistory = [
            "WiFi_2G": [SignalDataPoint(rssi: -50, ssid: "WiFi_2G")],
            "WiFi_5G": [SignalDataPoint(rssi: -40, ssid: "WiFi_5G")]
        ]

        sut.selectedBandFilter = .all
        XCTAssertEqual(sut.chartSignalHistory.count, 2)
    }

    // MARK: - Expand/Collapse

    func testInitiallyCollapsed() {
        XCTAssertFalse(sut.isExpanded("WiFi"))
    }

    func testToggleExpand() {
        sut.toggleExpanded("WiFi")
        XCTAssertTrue(sut.isExpanded("WiFi"))
    }

    func testToggleCollapse() {
        sut.toggleExpanded("WiFi")
        sut.toggleExpanded("WiFi")
        XCTAssertFalse(sut.isExpanded("WiFi"))
    }

    func testMultipleExpandedSSIDs() {
        sut.toggleExpanded("WiFi_A")
        sut.toggleExpanded("WiFi_B")
        XCTAssertTrue(sut.isExpanded("WiFi_A"))
        XCTAssertTrue(sut.isExpanded("WiFi_B"))
    }

    // MARK: - Unique Network Names

    func testUniqueNetworkNames() {
        sut.nearbyNetworks = [
            makeNetwork(ssid: "WiFi_A", bssid: "01"),
            makeNetwork(ssid: "WiFi_B", bssid: "02"),
            makeNetwork(ssid: "WiFi_A", bssid: "03")
        ]
        let names = sut.uniqueNetworkNames
        XCTAssertEqual(names.count, 2)
        XCTAssertTrue(names.contains("WiFi_A"))
        XCTAssertTrue(names.contains("WiFi_B"))
    }

    // MARK: - Clear History

    func testClearHistory() {
        sut.signalHistory = [
            "WiFi": [SignalDataPoint(rssi: -50, ssid: "WiFi")]
        ]
        sut.clearHistory()
        XCTAssertTrue(sut.signalHistory.isEmpty)
    }

    // MARK: - Start/Stop Scanning

    func testStartScanning() {
        sut.startScanning()
        XCTAssertTrue(sut.isScanning)
    }

    func testStopScanning() {
        sut.startScanning()
        sut.stopScanning()
        XCTAssertFalse(sut.isScanning)
    }

    func testStartScanningClearsError() {
        sut.errorMessage = "Previous error"
        sut.startScanning()
        XCTAssertNil(sut.errorMessage)
    }

    func testDoubleStartDoesNotCrash() {
        sut.startScanning()
        sut.startScanning()
        XCTAssertTrue(sut.isScanning)
    }
}
