import XCTest

final class NamifyUITests: XCTestCase {
    func testLaunchAndReachInput() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.staticTexts["Test a name"].waitForExistence(timeout: 5))
    }
}
