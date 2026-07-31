import XCTest
@testable import WiFiAnalyzer

@MainActor
final class ChannelAnalyzerViewModelTests: XCTestCase {

    var sut: ChannelAnalyzerViewModel!

    override func setUp() {
        super.setUp()
        sut = ChannelAnalyzerViewModel()
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
        channel: Int = 6,
        band: String = "2.4 GHz"
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
            security: "WPA2 Personal",
            countryCode: nil,
            isIBSS: false,
            beaconInterval: 100,
            timestamp: Date()
        )
    }

    // MARK: - signalWeight

    func testSignalWeightStrongIsFull() {
        XCTAssertEqual(ChannelAnalyzerViewModel.signalWeight(rssi: -50), 1.0, accuracy: 0.0001)
    }

    func testSignalWeightMidRange() {
        XCTAssertEqual(ChannelAnalyzerViewModel.signalWeight(rssi: -70), 0.6, accuracy: 0.0001)
    }

    func testSignalWeightVeryWeakIsZero() {
        XCTAssertEqual(ChannelAnalyzerViewModel.signalWeight(rssi: -100), 0.0, accuracy: 0.0001)
    }

    // MARK: - overlapFactor

    func test24GHzCoChannelOverlapIsFull() {
        XCTAssertEqual(ChannelAnalyzerViewModel.overlapFactor(band: "2.4 GHz", separation: 0), 1.0, accuracy: 0.0001)
    }

    func test24GHzAdjacentChannelsPartiallyOverlap() {
        XCTAssertEqual(ChannelAnalyzerViewModel.overlapFactor(band: "2.4 GHz", separation: 1), 0.8, accuracy: 0.0001)
        XCTAssertEqual(ChannelAnalyzerViewModel.overlapFactor(band: "2.4 GHz", separation: 4), 0.2, accuracy: 0.0001)
    }

    func test24GHzFarChannelsDoNotOverlap() {
        XCTAssertEqual(ChannelAnalyzerViewModel.overlapFactor(band: "2.4 GHz", separation: 5), 0.0, accuracy: 0.0001)
        XCTAssertEqual(ChannelAnalyzerViewModel.overlapFactor(band: "2.4 GHz", separation: 8), 0.0, accuracy: 0.0001)
    }

    func test5GHzOnlyCoChannelOverlaps() {
        XCTAssertEqual(ChannelAnalyzerViewModel.overlapFactor(band: "5 GHz", separation: 0), 1.0, accuracy: 0.0001)
        XCTAssertEqual(ChannelAnalyzerViewModel.overlapFactor(band: "5 GHz", separation: 1), 0.0, accuracy: 0.0001)
    }

    // MARK: - congestionScore

    func testCongestionScoreSumsCoChannelWeights() {
        let networks = [
            makeNetwork(bssid: "AA:AA:AA:AA:AA:01", rssi: -50, channel: 6),
            makeNetwork(bssid: "AA:AA:AA:AA:AA:02", rssi: -70, channel: 6)
        ]
        // 1.0 (from -50) + 0.6 (from -70), both co-channel
        let score = ChannelAnalyzerViewModel.congestionScore(forChannel: 6, band: "2.4 GHz", among: networks)
        XCTAssertEqual(score, 1.6, accuracy: 0.0001)
    }

    func testCongestionScoreIncludesAdjacentChannelOverlapOn24GHz() {
        let networks = [
            makeNetwork(bssid: "AA:AA:AA:AA:AA:01", rssi: -50, channel: 6)  // sep 2 from ch 4
        ]
        // overlap factor at sep 2 = 0.6, weight = 1.0 -> 0.6
        let score = ChannelAnalyzerViewModel.congestionScore(forChannel: 4, band: "2.4 GHz", among: networks)
        XCTAssertEqual(score, 0.6, accuracy: 0.0001)
    }

    // MARK: - channelCongestion

    func testChannelCongestionGroupsByChannel() {
        sut.nearbyNetworks = [
            makeNetwork(bssid: "AA:AA:AA:AA:AA:01", channel: 1, band: "2.4 GHz"),
            makeNetwork(bssid: "AA:AA:AA:AA:AA:02", channel: 11, band: "2.4 GHz"),
            makeNetwork(bssid: "AA:AA:AA:AA:AA:03", channel: 36, band: "5 GHz")
        ]

        let levels = sut.channelCongestion
        XCTAssertEqual(levels.count, 3)
    }

    func testChannelCongestionCountsOverlappingAPsOn24GHz() {
        sut.nearbyNetworks = [
            makeNetwork(bssid: "AA:AA:AA:AA:AA:01", channel: 1, band: "2.4 GHz"),
            makeNetwork(bssid: "AA:AA:AA:AA:AA:02", channel: 3, band: "2.4 GHz")  // overlaps ch 1
        ]

        let channel1 = sut.channelCongestion.first { $0.channel == 1 }
        XCTAssertEqual(channel1?.apCount, 1)            // only the AP exactly on ch 1
        XCTAssertEqual(channel1?.overlappingAPCount, 2) // ch 1 and ch 3 both overlap
    }

    func testChannelCongestion5GHzHasNoAdjacentOverlap() {
        sut.nearbyNetworks = [
            makeNetwork(bssid: "AA:AA:AA:AA:AA:01", channel: 36, band: "5 GHz"),
            makeNetwork(bssid: "AA:AA:AA:AA:AA:02", channel: 40, band: "5 GHz")
        ]

        let channel36 = sut.channelCongestion.first { $0.channel == 36 }
        XCTAssertEqual(channel36?.apCount, 1)
        XCTAssertEqual(channel36?.overlappingAPCount, 1) // ch 40 does not overlap ch 36
    }

    func testChannelCongestionSortedByBandThenChannel() {
        sut.nearbyNetworks = [
            makeNetwork(bssid: "AA:AA:AA:AA:AA:01", channel: 11, band: "2.4 GHz"),
            makeNetwork(bssid: "AA:AA:AA:AA:AA:02", channel: 1, band: "2.4 GHz"),
            makeNetwork(bssid: "AA:AA:AA:AA:AA:03", channel: 36, band: "5 GHz")
        ]

        XCTAssertEqual(sut.channelCongestion.map { $0.channel }, [1, 11, 36])
    }

    func testChannelCongestionEmptyWhenNoNetworks() {
        sut.nearbyNetworks = []
        XCTAssertTrue(sut.channelCongestion.isEmpty)
    }

    func testChannelCongestionListsCoChannelSSIDsSortedAndDeduplicated() {
        sut.nearbyNetworks = [
            makeNetwork(ssid: "Zeta", bssid: "AA:AA:AA:AA:AA:01", channel: 6, band: "2.4 GHz"),
            makeNetwork(ssid: "alpha", bssid: "AA:AA:AA:AA:AA:02", channel: 6, band: "2.4 GHz"),
            // Same name as a second radio on the same channel -> collapses to one entry.
            makeNetwork(ssid: "alpha", bssid: "AA:AA:AA:AA:AA:03", channel: 6, band: "2.4 GHz"),
            // Different channel -> must not appear under channel 6.
            makeNetwork(ssid: "Other", bssid: "AA:AA:AA:AA:AA:04", channel: 11, band: "2.4 GHz")
        ]

        let channel6 = sut.channelCongestion.first { $0.channel == 6 }
        XCTAssertEqual(channel6?.apCount, 3)                 // three radios
        XCTAssertEqual(channel6?.ssids, ["alpha", "Zeta"])   // two unique names, case-insensitive sort
    }

    // MARK: - recommendationsByBand

    func testRecommendsLeastCongestedChannel() {
        // Strong APs occupy channels 1 and 6; channel 11 is left clear.
        sut.nearbyNetworks = [
            makeNetwork(bssid: "AA:AA:AA:AA:AA:01", rssi: -50, channel: 1, band: "2.4 GHz"),
            makeNetwork(bssid: "AA:AA:AA:AA:AA:02", rssi: -50, channel: 6, band: "2.4 GHz")
        ]

        let recommendation = sut.recommendationsByBand["2.4 GHz"]
        XCTAssertEqual(recommendation?.channel, 11)
        XCTAssertEqual(recommendation?.rating, .clear)
    }

    func testRecommendsAcrossBandsIndependently() {
        sut.nearbyNetworks = [
            makeNetwork(bssid: "AA:AA:AA:AA:AA:01", rssi: -50, channel: 1, band: "2.4 GHz"),
            makeNetwork(bssid: "AA:AA:AA:AA:AA:02", rssi: -50, channel: 36, band: "5 GHz")
        ]

        XCTAssertEqual(sut.recommendationsByBand["2.4 GHz"]?.channel, 6)   // 6/11 tie at 0, lower wins
        XCTAssertNotEqual(sut.recommendationsByBand["5 GHz"]?.channel, 36) // avoids the busy channel
    }

    // MARK: - Sort order

    func testSortDefaultsToMostCongested() {
        XCTAssertEqual(sut.channelSortOrder, .congestion)
    }

    func testSortByCongestionPutsBusiestFirst() {
        sut.nearbyNetworks = [
            // Channel 1: two strong APs -> higher score
            makeNetwork(bssid: "AA:AA:AA:AA:AA:01", rssi: -50, channel: 1, band: "2.4 GHz"),
            makeNetwork(bssid: "AA:AA:AA:AA:AA:02", rssi: -50, channel: 1, band: "2.4 GHz"),
            // Channel 11: one weak AP -> lower score
            makeNetwork(bssid: "AA:AA:AA:AA:AA:03", rssi: -85, channel: 11, band: "2.4 GHz")
        ]

        sut.channelSortOrder = .congestion
        let ordered = sut.sortedChannelCongestion
        XCTAssertEqual(ordered.first?.channel, 1)   // busiest first
        XCTAssertEqual(ordered.last?.channel, 11)
    }

    func testSortByChannelKeepsChannelOrder() {
        sut.nearbyNetworks = [
            makeNetwork(bssid: "AA:AA:AA:AA:AA:01", rssi: -85, channel: 1, band: "2.4 GHz"),
            makeNetwork(bssid: "AA:AA:AA:AA:AA:02", rssi: -50, channel: 11, band: "2.4 GHz")
        ]

        sut.channelSortOrder = .channel
        XCTAssertEqual(sut.sortedChannelCongestion.map { $0.channel }, [1, 11])
    }

    func testSortByAPCountPutsMostAPsFirst() {
        sut.nearbyNetworks = [
            makeNetwork(bssid: "AA:AA:AA:AA:AA:01", channel: 6, band: "2.4 GHz"),
            makeNetwork(bssid: "AA:AA:AA:AA:AA:02", channel: 6, band: "2.4 GHz"),
            makeNetwork(bssid: "AA:AA:AA:AA:AA:03", channel: 6, band: "2.4 GHz"),
            makeNetwork(bssid: "AA:AA:AA:AA:AA:04", channel: 1, band: "2.4 GHz")
        ]

        sut.channelSortOrder = .apCount
        XCTAssertEqual(sut.sortedChannelCongestion.first?.channel, 6) // 3 APs
        XCTAssertEqual(sut.sortedChannelCongestion.first?.apCount, 3)
    }

    // MARK: - Band Filter

    func testBandFilterRestrictsCongestion() {
        sut.nearbyNetworks = [
            makeNetwork(bssid: "AA:AA:AA:AA:AA:01", channel: 6, band: "2.4 GHz"),
            makeNetwork(bssid: "AA:AA:AA:AA:AA:02", channel: 36, band: "5 GHz")
        ]

        sut.selectedBandFilter = .band5

        let levels = sut.channelCongestion
        XCTAssertEqual(levels.count, 1)
        XCTAssertEqual(levels.first?.band, "5 GHz")
    }

    // MARK: - CongestionRating boundaries

    func testRatingClearBelowHalf() {
        XCTAssertEqual(CongestionRating.from(score: 0.3), .clear)
    }

    func testRatingModerate() {
        XCTAssertEqual(CongestionRating.from(score: 1.0), .moderate)
    }

    func testRatingBusy() {
        XCTAssertEqual(CongestionRating.from(score: 2.0), .busy)
    }

    func testRatingCrowded() {
        XCTAssertEqual(CongestionRating.from(score: 4.0), .crowded)
    }
}
