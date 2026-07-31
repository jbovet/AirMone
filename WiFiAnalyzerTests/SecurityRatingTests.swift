import XCTest
@testable import WiFiAnalyzer

final class SecurityRatingTests: XCTestCase {

    // MARK: - Classification (nearby-network strings)

    func testOpen() {
        XCTAssertEqual(SecurityRating.from(security: "Open"), .open)
    }

    func testWEP() {
        XCTAssertEqual(SecurityRating.from(security: "WEP"), .insecure)
    }

    func testWPA1() {
        XCTAssertEqual(SecurityRating.from(security: "WPA Personal"), .weak)
        XCTAssertEqual(SecurityRating.from(security: "WPA Enterprise"), .weak)
    }

    func testWPA2() {
        XCTAssertEqual(SecurityRating.from(security: "WPA2 Personal"), .acceptable)
        XCTAssertEqual(SecurityRating.from(security: "WPA2 Enterprise"), .acceptable)
    }

    func testWPA3() {
        XCTAssertEqual(SecurityRating.from(security: "WPA3 Personal"), .strong)
        XCTAssertEqual(SecurityRating.from(security: "WPA3 Enterprise"), .strong)
    }

    func testUnknown() {
        XCTAssertEqual(SecurityRating.from(security: "Unknown"), .unknown)
        XCTAssertEqual(SecurityRating.from(security: ""), .unknown)
    }

    // MARK: - Classification (connected-network phrasings)

    func testConnectedOpenPhrasing() {
        XCTAssertEqual(SecurityRating.from(security: "Open (No Security)"), .open)
    }

    func testConnectedWEPPhrasing() {
        XCTAssertEqual(SecurityRating.from(security: "WEP (Weak)"), .insecure)
    }

    func testTransitionAndMixedPhrasings() {
        // "WPA2/WPA3 Personal" contains WPA3 -> strong (best of the two)
        XCTAssertEqual(SecurityRating.from(security: "WPA2/WPA3 Personal"), .strong)
        // "WPA/WPA2 Personal" contains WPA2 -> acceptable
        XCTAssertEqual(SecurityRating.from(security: "WPA/WPA2 Personal"), .acceptable)
    }

    // MARK: - Ordering & flags

    func testRiskOrderIsWorstToSafest() {
        let ratings: [SecurityRating] = [.strong, .open, .acceptable, .weak, .insecure, .unknown]
        let sorted = ratings.sorted { $0.riskOrder < $1.riskOrder }
        XCTAssertEqual(sorted, [.open, .insecure, .weak, .acceptable, .strong, .unknown])
    }

    func testIsIssueOnlyForWeakOrWorse() {
        XCTAssertTrue(SecurityRating.open.isIssue)
        XCTAssertTrue(SecurityRating.insecure.isIssue)
        XCTAssertTrue(SecurityRating.weak.isIssue)
        XCTAssertFalse(SecurityRating.acceptable.isIssue)
        XCTAssertFalse(SecurityRating.strong.isIssue)
        XCTAssertFalse(SecurityRating.unknown.isIssue)
    }
}
