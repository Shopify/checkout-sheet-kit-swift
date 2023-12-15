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
import WebKit
@testable import ShopifyCheckoutSheetKit

class CheckoutBridgeTests: XCTestCase {
	class WKScriptMessageMock: WKScriptMessage {
		private let _mockBody: Any

		override var body: Any {
			_mockBody
		}

		init(body: Any = "") {
			_mockBody = body
		}
	}

	func testDecodeThrowsInvalidBridgeEventWhenNonStringBody() throws {
		let mock = WKScriptMessageMock(body: 1234)

		XCTAssertThrowsError(try CheckoutBridge.decode(mock)) { error in
			guard case BridgeError.invalidBridgeEvent = error else {
				return XCTFail("unexpected error thrown: \(error)")
			}
		}
	}

	func testDecodeThrowsInvalidBridgeEventWhenEmptyBody() throws {
		let mock = WKScriptMessageMock(body: "")

		XCTAssertThrowsError(try CheckoutBridge.decode(mock)) { error in
			guard case BridgeError.invalidBridgeEvent = error else {
				return XCTFail("unexpected error thrown: \(error)")
			}
		}
	}

	func testDecodeHandlesUnsupportedEventsGracefully() throws {
		let mock = WKScriptMessageMock(body: """
	{ "name": "unknown_event", "body": "" }
	""")

		let result = try CheckoutBridge.decode(mock)

		guard case CheckoutBridge.WebEvent.unsupported = result else {
			return XCTFail("expected CheckoutScriptMessage.unsupportedEvent, got \(result)")
		}
	}

	func testDecodeSupportsCheckoutCompleteEvent() throws {
		let mock = WKScriptMessageMock(body: """
	{
		"name": "completed"
	}
	""")

		let result = try CheckoutBridge.decode(mock)

		guard case CheckoutBridge.WebEvent.checkoutComplete = result else {
			return XCTFail("expected CheckoutScriptMessage.checkoutComplete, got \(result)")
		}
	}

	func testDecodeSupportsCheckoutUnavailableEvent() throws {
		let mock = WKScriptMessageMock(body: """
	{
		"name": "error"
	}
	""")

		let result = try CheckoutBridge.decode(mock)

		guard case CheckoutBridge.WebEvent.checkoutExpired = result else {
			return XCTFail("expected CheckoutScriptMessage.checkoutExpired, got \(result)")
		}
	}

	func testDecodeSupportsCheckoutBlockingEvent() throws {
		let mock = WKScriptMessageMock(body: """
	{
		"name": "checkoutBlockingEvent",
		"body": "true"
	}
	""")

		let result = try CheckoutBridge.decode(mock)

		guard case CheckoutBridge.WebEvent.checkoutModalToggled = result else {
			return XCTFail("expected CheckoutScriptMessage.checkoutModalToggled, got \(result)")
		}
	}

	func testInstrumentationPayloadToBridgeEvent() {
		let payload = InstrumentationPayload(name: "test", value: 1, type: .histogram)
		let jsonString = payload.toBridgeEvent()
		XCTAssertNotNil(jsonString)

		if let jsonData = jsonString?.data(using: .utf8) {
			let decodedPayload = try? JSONDecoder().decode(SdkToWebEvent<InstrumentationPayload>.self, from: jsonData)
			XCTAssertNotNil(decodedPayload)
			XCTAssertEqual(decodedPayload?.detail.name, "test")
			XCTAssertEqual(decodedPayload?.detail.value, 1)
			XCTAssertEqual(decodedPayload?.detail.type, .histogram)
		}
	}

	func testSdkToWebEventToJson() {
		let payload = InstrumentationPayload(name: "test", value: 1, type: .incrementCounter)
		let event = SdkToWebEvent(detail: payload)
		let jsonString = event.toJson()
		XCTAssertNotNil(jsonString)

		if let jsonData = jsonString?.data(using: .utf8) {
			let decodedEvent = try? JSONDecoder().decode(SdkToWebEvent<InstrumentationPayload>.self, from: jsonData)
			XCTAssertNotNil(decodedEvent)
			XCTAssertEqual(decodedEvent?.detail.name, "test")
			XCTAssertEqual(decodedEvent?.detail.value, 1)
			XCTAssertEqual(decodedEvent?.detail.type, .incrementCounter)
		}
	}
}
