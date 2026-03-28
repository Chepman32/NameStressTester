import XCTest

final class LitmusUITests: XCTestCase {
    func testLaunchAndReachInput() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.staticTexts["Test a name"].waitForExistence(timeout: 5))
    }
}
