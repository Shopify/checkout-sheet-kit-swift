/*
MIT License

Copyright 2023 - Present, Shopify Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

import XCTest

final class SwiftUIExampleUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

	private func openCheckoutFromCartSheet(_ app: XCUIApplication) {
		app.buttons["addToCartButton"].tap()
		app.buttons["cartIcon"].tap()
		app.buttons["checkoutButton"].tap()
	}

	private func openCheckoutFromCartView(_ app: XCUIApplication) {
		app.buttons["addToCartButton"].tap()
		app.buttons["cartTabIcon"].tap()
		app.buttons["checkoutButton"].tap()
	}

	private func expectCheckoutToContain(_ element: XCUIElement) {
		let exists = NSPredicate(format: "exists == true")
		expectation(for: exists, evaluatedWith: element, handler: nil)
		waitForExpectations(timeout: 10, handler: nil)
		XCTAssertTrue(element.exists)
	}

	func testCheckoutSheetHasCustomTitle() {
		let app = XCUIApplication()

			app.launch()

		openCheckoutFromCartSheet(app)

		XCTAssertTrue(app.staticTexts["SwiftUI"].exists)

		expectCheckoutToContain(app.staticTexts["Contact"])
		expectCheckoutToContain(app.staticTexts["Delivery"])
	}

	func testCheckoutViewHasCustomTitle() {
		let app = XCUIApplication()

		app.launch()

		openCheckoutFromCartView(app)

		XCTAssertTrue(app.staticTexts["SwiftUI"].exists)
		expectCheckoutToContain(app.staticTexts["Contact"])
		expectCheckoutToContain(app.staticTexts["Delivery"])
	}
}
