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

// MARK: - InlineCheckout SwiftUI Tests

class InlineCheckoutTests: XCTestCase {
	private var checkoutURL: URL!
	private var inlineCheckout: InlineCheckout!

	override func setUp() {
		super.setUp()
		checkoutURL = URL(string: "https://www.example.com/checkout")!
		inlineCheckout = InlineCheckout(checkout: checkoutURL)
	}

	override func tearDown() {
		inlineCheckout = nil
		checkoutURL = nil
		super.tearDown()
	}

	func testInitialization() {
		XCTAssertEqual(inlineCheckout.checkoutURL, checkoutURL)
		XCTAssertTrue(inlineCheckout.autoResizeHeight)
	}

	func testInitializationWithCustomSettings() {
		let customInlineCheckout = InlineCheckout(
			checkout: checkoutURL,
			autoResizeHeight: false
		)

		XCTAssertEqual(customInlineCheckout.checkoutURL, checkoutURL)
		XCTAssertFalse(customInlineCheckout.autoResizeHeight)
	}

	func testOnCheckoutComplete() {
		var completeCalled = false
		var receivedEvent: CheckoutCompletedEvent?
		let event = createEmptyCheckoutCompletedEvent()

		let inlineCheckoutWithHandlers = InlineCheckout(
			checkout: checkoutURL,
			onCheckoutComplete: { event in
				completeCalled = true
				receivedEvent = event
			}
		)

		inlineCheckoutWithHandlers.onCheckoutComplete?(event)

		XCTAssertTrue(completeCalled)
		XCTAssertNotNil(receivedEvent)
	}

	func testOnCheckoutCancel() {
		var cancelCalled = false

		let inlineCheckoutWithHandlers = InlineCheckout(
			checkout: checkoutURL,
			onCheckoutCancel: {
				cancelCalled = true
			}
		)

		inlineCheckoutWithHandlers.onCheckoutCancel?()

		XCTAssertTrue(cancelCalled)
	}

	func testOnCheckoutFail() {
		var failCalled = false
		var receivedError: CheckoutError?
		let error: CheckoutError = .checkoutUnavailable(message: "Test error", code: CheckoutUnavailable.httpError(statusCode: 500), recoverable: false)

		let inlineCheckoutWithHandlers = InlineCheckout(
			checkout: checkoutURL,
			onCheckoutFail: { error in
				failCalled = true
				receivedError = error
			}
		)

		inlineCheckoutWithHandlers.onCheckoutFail?(error)

		XCTAssertTrue(failCalled)
		XCTAssertNotNil(receivedError)
	}

	func testOnHeightChange() {
		var heightChangeCalled = false
		var receivedHeight: CGFloat = 0
		let testHeight: CGFloat = 650

		let inlineCheckoutWithHandlers = InlineCheckout(
			checkout: checkoutURL,
			onHeightChange: { height in
				heightChangeCalled = true
				receivedHeight = height
			}
		)

		inlineCheckoutWithHandlers.onHeightChange?(testHeight)

		XCTAssertTrue(heightChangeCalled)
		XCTAssertEqual(receivedHeight, testHeight)
	}

	func testOnPixelEvent() {
		var pixelEventCalled = false
		var receivedEvent: PixelEvent?
		let standardEvent = StandardEvent(context: nil, id: "testId", name: "checkout_started", timestamp: "2022-01-01T00:00:00Z", data: nil)
		let pixelEvent = PixelEvent.standardEvent(standardEvent)

		let inlineCheckoutWithHandlers = InlineCheckout(
			checkout: checkoutURL,
			onPixelEvent: { event in
				pixelEventCalled = true
				receivedEvent = event
			}
		)

		inlineCheckoutWithHandlers.onPixelEvent?(pixelEvent)

		XCTAssertTrue(pixelEventCalled)
		XCTAssertNotNil(receivedEvent)
	}

	func testOnLinkClick() {
		var linkClickCalled = false
		var receivedURL: URL?
		let testURL = URL(string: "https://shopify.com")!

		let inlineCheckoutWithHandlers = InlineCheckout(
			checkout: checkoutURL,
			onLinkClick: { url in
				linkClickCalled = true
				receivedURL = url
			}
		)

		inlineCheckoutWithHandlers.onLinkClick?(testURL)

		XCTAssertTrue(linkClickCalled)
		XCTAssertEqual(receivedURL, testURL)
	}
}

// MARK: - InlineCheckoutWebViewWrapper Tests

class InlineCheckoutWebViewWrapperTests: XCTestCase {
	private var wrapper: InlineCheckoutWebViewWrapper!
	private var mockDelegate: MockInlineCheckoutDelegate!
	private var checkoutURL: URL!

	override func setUp() {
		super.setUp()
		checkoutURL = URL(string: "https://www.example.com/checkout")!
		mockDelegate = MockInlineCheckoutDelegate()
		wrapper = InlineCheckoutWebViewWrapper()
	}

	override func tearDown() {
		wrapper = nil
		mockDelegate = nil
		checkoutURL = nil
		super.tearDown()
	}

	func testWrapperInitialization() {
		XCTAssertNotNil(wrapper)
		XCTAssertEqual(wrapper.intrinsicContentSize.height, 400)
	}

	func testHeightUpdating() {
		wrapper.configure(with: checkoutURL, delegate: mockDelegate, autoResizeHeight: true)

		var heightChangeCallbackReceived = false
		var receivedHeight: CGFloat = 0

		wrapper.onHeightChangeWrapper = { height in
			heightChangeCallbackReceived = true
			receivedHeight = height
		}

		let newHeight: CGFloat = 600
		wrapper.updateHeight(newHeight)

		XCTAssertTrue(heightChangeCallbackReceived)
		XCTAssertEqual(receivedHeight, newHeight)
		XCTAssertEqual(wrapper.intrinsicContentSize.height, newHeight)
	}

	func testHeightUpdatingWithSameValue() {
		wrapper.configure(with: checkoutURL, delegate: mockDelegate, autoResizeHeight: true)

		var heightChangeCallbackCount = 0
		wrapper.onHeightChangeWrapper = { _ in
			heightChangeCallbackCount += 1
		}

		wrapper.updateHeight(400)
		XCTAssertEqual(heightChangeCallbackCount, 0)

		wrapper.updateHeight(500)
		XCTAssertEqual(heightChangeCallbackCount, 1)
	}
}

// MARK: - InlineCheckoutDelegateWrapper Tests

class InlineCheckoutDelegateWrapperTests: XCTestCase {
	private var delegateWrapper: InlineCheckoutDelegateWrapper!

	override func setUp() {
		super.setUp()
		delegateWrapper = InlineCheckoutDelegateWrapper()
	}

	override func tearDown() {
		delegateWrapper = nil
		super.tearDown()
	}

	func testCheckoutDidComplete() {
		var completeCalled = false
		var receivedEvent: CheckoutCompletedEvent?
		let event = createEmptyCheckoutCompletedEvent()

		delegateWrapper.onComplete = { event in
			completeCalled = true
			receivedEvent = event
		}

		delegateWrapper.checkoutDidComplete(event: event)

		XCTAssertTrue(completeCalled)
		XCTAssertNotNil(receivedEvent)
	}

	func testCheckoutDidCancel() {
		var cancelCalled = false

		delegateWrapper.onCancel = {
			cancelCalled = true
		}

		delegateWrapper.checkoutDidCancel()

		XCTAssertTrue(cancelCalled)
	}

	func testCheckoutDidFail() {
		var failCalled = false
		var receivedError: CheckoutError?
		let error: CheckoutError = .checkoutUnavailable(message: "Test error", code: CheckoutUnavailable.httpError(statusCode: 500), recoverable: false)

		delegateWrapper.onFail = { error in
			failCalled = true
			receivedError = error
		}

		delegateWrapper.checkoutDidFail(error: error)

		XCTAssertTrue(failCalled)
		XCTAssertNotNil(receivedError)
	}
}

// MARK: - Mock Classes

class MockInlineCheckoutDelegate: CheckoutDelegate {
	var completedEventReceived: CheckoutCompletedEvent?
	var errorReceived: CheckoutError?
	var linkURLReceived: URL?
	var pixelEventReceived: PixelEvent?

	func checkoutDidComplete(event: CheckoutCompletedEvent) {
		completedEventReceived = event
	}

	func checkoutDidCancel() {
		// Mock implementation
	}

	func checkoutDidFail(error: CheckoutError) {
		errorReceived = error
	}

	func checkoutDidClickContactLink(url: URL) {
		linkURLReceived = url
	}

	func checkoutDidEmitWebPixelEvent(event: PixelEvent) {
		pixelEventReceived = event
	}
}
