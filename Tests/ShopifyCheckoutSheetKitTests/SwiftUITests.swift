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

class CheckoutViewControllerTests: XCTestCase {
	var checkoutURL: URL!
	var delegate: CheckoutDelegateWrapper!
	var checkoutViewController: CheckoutViewController!

	override func setUp() {
		super.setUp()
		checkoutURL = URL(string: "https://www.example.com")
		delegate = CheckoutDelegateWrapper()
		checkoutViewController = CheckoutViewController(checkout: checkoutURL, delegate: delegate)
	}

	func testInit() {
		XCTAssertNotNil(checkoutViewController)
	}
}

class CheckoutSheetTests: XCTestCase {
	var checkoutURL: URL!
	var checkoutSheet: CheckoutSheet!

	override func setUp() {
		super.setUp()
		checkoutURL = URL(string: "https://www.example.com")
		checkoutSheet = CheckoutSheet(checkout: checkoutURL)
	}

	/// Lifecycle events

	func testOnCancel() {
		var cancelActionCalled = false

		_ = checkoutSheet.onCancel {
			cancelActionCalled = true
		}
		checkoutSheet.delegate.checkoutDidCancel()
		XCTAssertTrue(cancelActionCalled)
	}

	func testOnComplete() {
		var completeActionCalled = false
		let event = CheckoutCompletedEvent()

		_ = checkoutSheet.onComplete { _ in
			completeActionCalled = true
		}
		checkoutSheet.delegate.checkoutDidComplete(event: event)
		XCTAssertTrue(completeActionCalled)
	}

	func testOnFail() {
		var failActionCalled = false
		let error: CheckoutError = .checkoutUnavailable(message: "error")

		_ = checkoutSheet.onFail { _ in
			failActionCalled = true
		}
		checkoutSheet.delegate.checkoutDidFail(error: error)
		XCTAssertTrue(failActionCalled)
	}

	func testOnPixelEvent() {
		var pixelEventActionCalled = false
		let standardEvent = StandardEvent(context: nil, id: "testId", name: "checkout_started", timestamp: "2022-01-01T00:00:00Z", data: nil)
		let pixelEvent = PixelEvent.standardEvent(standardEvent)

		_ = checkoutSheet.onPixelEvent { _ in
			pixelEventActionCalled = true
		}
		checkoutSheet.delegate.checkoutDidEmitWebPixelEvent(event: pixelEvent)
		XCTAssertTrue(pixelEventActionCalled)
	}
}
