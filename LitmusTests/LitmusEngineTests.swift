import XCTest
@testable import Litmus

final class LitmusEngineTests: XCTestCase {
    func testOverallVerdictTreatsWarnAsPassOutsideStrictMode() {
        let results: [TestResult] = [
            .init(testType: .rhyme, verdict: .pass, summaryLine: "", detailText: "", detailData: .generic(message: "")),
            .init(testType: .initials, verdict: .warn, summaryLine: "", detailText: "", detailData: .generic(message: "")),
            .init(testType: .pronunciation, verdict: .warn, summaryLine: "", detailText: "", detailData: .generic(message: "")),
            .init(testType: .email, verdict: .pass, summaryLine: "", detailText: "", detailData: .generic(message: "")),
            .init(testType: .nameTag, verdict: .pass, summaryLine: "", detailText: "", detailData: .generic(message: "")),
            .init(testType: .namesake, verdict: .fail, summaryLine: "", detailText: "", detailData: .generic(message: "")),
            .init(testType: .monogram, verdict: .warn, summaryLine: "", detailText: "", detailData: .generic(message: ""))
        ]

        XCTAssertEqual(OverallVerdict.from(results: results, strictMode: false), .survived)
        XCTAssertEqual(OverallVerdict.from(results: results, strictMode: true), .mixed)
    }

    func testInitialsDetectorFlagsPrimaryMatch() async {
        let result = await InitialsDetector(store: .shared).analyze(name: NameComponents(first: "A", middle: "S", last: "S"))
        XCTAssertEqual(result.verdict, .fail)
    }

    func testMonogramAnalyzerRewardsBalancedInitials() async {
        let pass = await MonogramAnalyzer().analyze(name: NameComponents(first: "Ada", middle: "Mae", last: "Wren"))
        XCTAssertEqual(pass.verdict, .pass)
    }

    func testNameReportRoundTrip() {
        let name = NameComponents(first: "Ada", middle: "Mae", last: "Wren")
        let result = TestResult(testType: .rhyme, verdict: .pass, summaryLine: "OK", detailText: "Fine", detailData: .generic(message: "none"))
        let report = NameReport(
            name: name,
            testDate: .now,
            overallVerdict: .survived,
            passCount: 1,
            warnCount: 0,
            failCount: 0,
            testResults: [result]
        )
        XCTAssertEqual(report.testResults.first?.summaryLine, "OK")
        XCTAssertEqual(report.fullName, "Ada Mae Wren")
    }
}
