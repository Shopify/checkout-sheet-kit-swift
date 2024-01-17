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
@testable import ShopifyCheckoutSheetKit

class MockCheckoutWebViewDelegate: CheckoutWebViewDelegate {
	var didStartNavigationExpectation: XCTestExpectation?

	var didFinishNavigationExpectation: XCTestExpectation?

	var didCompleteCheckoutExpectation: XCTestExpectation?

	var didClickContactLinkExpectation: XCTestExpectation?

	var didClickLinkExpectation: XCTestExpectation?

	var didFailWithErrorExpectation: XCTestExpectation?

	var didToggleModalExpectation: XCTestExpectation?

	var didEmitWebPixelsEventExpectation: XCTestExpectation?

	func checkoutViewDidStartNavigation() {
		didStartNavigationExpectation?.fulfill()
	}

	func checkoutViewDidCompleteCheckout() {
		didCompleteCheckoutExpectation?.fulfill()
	}

	func checkoutViewDidFinishNavigation() {
		didFinishNavigationExpectation?.fulfill()
	}

	func checkoutViewDidClickContactLink(url: URL) {
		didClickContactLinkExpectation?.fulfill()
	}

	func checkoutViewDidClickLink(url: URL) {
		didClickLinkExpectation?.fulfill()
	}

    func checkoutViewDidFailWithError(error: CheckoutError) {
		didFailWithErrorExpectation?.fulfill()
	}

	func checkoutViewDidToggleModal(modalVisible: Bool) {
		didToggleModalExpectation?.fulfill()
	}

	func checkoutViewDidEmitWebPixelEvent(event: PixelEvent) {
		didEmitWebPixelsEventExpectation?.fulfill()
	}
}
