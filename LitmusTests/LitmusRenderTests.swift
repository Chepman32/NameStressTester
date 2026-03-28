import SwiftUI
import XCTest
@testable import Litmus

@MainActor
final class LitmusRenderTests: XCTestCase {
    func testShareRendererProducesImage() {
        let name = NameComponents(first: "Ada", middle: "Mae", last: "Wren")
        let results = [
            TestResult(testType: .rhyme, verdict: .pass, summaryLine: "No rhymes", detailText: "Fine", detailData: .generic(message: "none"))
        ]
        let summary = NameRunSummary(results: results, strictMode: false)
        let image = ShareCardRenderer.renderReport(name: name, summary: summary, colorScheme: .light)
        XCTAssertNotNil(image)
        XCTAssertGreaterThan(image?.size.width ?? 0, 0)
    }
}
