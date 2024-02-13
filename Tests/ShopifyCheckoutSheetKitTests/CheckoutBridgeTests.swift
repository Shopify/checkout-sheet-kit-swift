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

	func testDecodeSupportsCheckoutCompletedEvent() throws {
		let body = "{\"orderDetails\":{\"id\":\"gid://shopify/OrderIdentity/8\",\"cart\":{\"lines\":[{\"quantity\":1,\"title\":\"Awesome Plastic Shoes\",\"price\":{\"amount\":87.99,\"currencyCode\":\"CAD\"},\"merchandiseId\":\"gid://shopify/ProductVariant/1\",\"productId\":\"gid://shopify/Product/1\"}],\"price\":{\"total\":{\"amount\":109.89,\"currencyCode\":\"CAD\"},\"subtotal\":{\"amount\":87.99,\"currencyCode\":\"CAD\"},\"taxes\":{\"amount\":0,\"currencyCode\":\"CAD\"},\"shipping\":{\"amount\":21.9,\"currencyCode\":\"CAD\"}}},\"billingAddress\":{\"city\":\"Cagalry\",\"countryCode\":\"CA\",\"postalCode\":\"T1X 0L3\",\"address1\":\"The Cloak & Dagger\",\"address2\":\"1st Street Southeast\",\"firstName\":\"Test\",\"lastName\":\"McTest\",\"name\":\"Test\",\"zoneCode\":\"AB\",\"coordinates\":{\"latitude\":45.416311,\"longitude\":-75.68683}},\"paymentMethods\":[{\"type\":\"direct\",\"details\":{\"amount\":\"109.89\",\"currency\":\"CAD\",\"brand\":\"BOGUS\",\"lastFourDigits\":\"1\"}}],\"deliveries\":[{\"method\":\"SHIPPING\",\"details\":{\"location\":{\"city\":\"Cagalry\",\"countryCode\":\"CA\",\"postalCode\":\"T1X 0L3\",\"address1\":\"The Cloak & Dagger\",\"address2\":\"1st Street Southeast\",\"firstName\":\"Test\",\"lastName\":\"McTest\",\"name\":\"Test\",\"zoneCode\":\"AB\",\"coordinates\":{\"latitude\":45.416311,\"longitude\":-75.68683}}}}]},\"orderId\":\"gid://shopify/OrderIdentity/19\",\"cart\":{\"lines\":[{\"quantity\":1,\"title\":\"Awesome Plastic Shoes\",\"price\":{\"amount\":87.99,\"currencyCode\":\"CAD\"},\"merchandiseId\":\"gid://shopify/ProductVariant/1\",\"productId\":\"gid://shopify/Product/1\"}],\"price\":{\"total\":{\"amount\":109.89,\"currencyCode\":\"CAD\"},\"subtotal\":{\"amount\":87.99,\"currencyCode\":\"CAD\"},\"taxes\":{\"amount\":0,\"currencyCode\":\"CAD\"},\"shipping\":{\"amount\":21.9,\"currencyCode\":\"CAD\"}}}}"
			.replacingOccurrences(of: "\"", with: "\\\"")
			.replacingOccurrences(of: "\n", with: "")

		let mock = WKScriptMessageMock(body: """
			{
				"name": "completed",
				"body": "\(body)"
			}
			""")

		let result = try CheckoutBridge.decode(mock)

		guard case .checkoutComplete(let event) = result else {
			XCTFail("Expected .checkoutComplete, got \(result)")
			return
		}

		XCTAssertEqual("gid://shopify/OrderIdentity/8", event.orderDetails?.id)
		XCTAssertEqual(1, event.orderDetails?.cart?.lines?.count)
		XCTAssertEqual("gid://shopify/Product/1", event.orderDetails?.cart?.lines?[0].productId)
		XCTAssertEqual(1, event.orderDetails?.paymentMethods?.count)
		XCTAssertEqual("direct", event.orderDetails?.paymentMethods?[0].type)
	}

	func testDecodeSupportsPartialCheckoutCompletedEvent() throws {
		/// Missing orderId, taxes, billingAddress
		let body = "{\"orderDetails\":{\"cart\":{\"lines\":[{\"quantity\":1,\"title\":\"Awesome Plastic Shoes\",\"price\":{\"amount\":87.99,\"currencyCode\":\"CAD\"},\"merchandiseId\":\"gid://shopify/ProductVariant/1\",\"productId\":\"gid://shopify/Product/1\"}],\"price\":{\"total\":{\"amount\":109.89,\"currencyCode\":\"CAD\"},\"subtotal\":{\"amount\":87.99,\"currencyCode\":\"CAD\"},\"shipping\":{\"amount\":21.9,\"currencyCode\":\"CAD\"}}},\"paymentMethods\":[{\"type\":\"direct\",\"details\":{\"amount\":\"109.89\",\"currency\":\"CAD\",\"brand\":\"BOGUS\",\"lastFourDigits\":\"1\"}}],\"deliveries\":[{\"method\":\"SHIPPING\",\"details\":{\"location\":{\"city\":\"Cagalry\",\"countryCode\":\"CA\",\"postalCode\":\"T1X 0L3\",\"address1\":\"The Cloak & Dagger\",\"address2\":\"1st Street Southeast\",\"firstName\":\"Test\",\"lastName\":\"McTest\",\"name\":\"Test\",\"zoneCode\":\"AB\",\"coordinates\":{\"latitude\":45.416311,\"longitude\":-75.68683}}}}]},\"orderId\":\"gid://shopify/OrderIdentity/19\",\"cart\":{\"lines\":[{\"quantity\":1,\"title\":\"Awesome Plastic Shoes\",\"price\":{\"amount\":87.99,\"currencyCode\":\"CAD\"},\"merchandiseId\":\"gid://shopify/ProductVariant/1\",\"productId\":\"gid://shopify/Product/1\"}],\"price\":{\"total\":{\"amount\":109.89,\"currencyCode\":\"CAD\"},\"subtotal\":{\"amount\":87.99,\"currencyCode\":\"CAD\"},\"taxes\":{\"amount\":0,\"currencyCode\":\"CAD\"},\"shipping\":{\"amount\":21.9,\"currencyCode\":\"CAD\"}}}}"
			.replacingOccurrences(of: "\"", with: "\\\"")
			.replacingOccurrences(of: "\n", with: "")

		let mock = WKScriptMessageMock(body: "{\"name\":\"completed\",\"body\": \"\(body)\"}")

		let result = try CheckoutBridge.decode(mock)

		guard case .checkoutComplete(let event) = result else {
			XCTFail("Expected .checkoutComplete, got \(result)")
			return
		}

		XCTAssertEqual(1, event.orderDetails?.cart?.lines?.count)
		XCTAssertEqual("gid://shopify/Product/1", event.orderDetails?.cart?.lines?[0].productId)
		XCTAssertEqual(1, event.orderDetails?.paymentMethods?.count)
		XCTAssertEqual("direct", event.orderDetails?.paymentMethods?[0].type)
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

	func testDecodeSupportsStandardWebPixelsEvent() throws {
		let body = "{\"name\": \"page_viewed\",\"event\": {\"id\": \"123\",\"name\": \"page_viewed\",\"type\":\"standard\",\"timestamp\": \"2024-01-04T09:48:53.358Z\",\"data\": {}, \"context\": {}}}"
			.replacingOccurrences(of: "\"", with: "\\\"")
			.replacingOccurrences(of: "\n", with: "")

		let mock = WKScriptMessageMock(body: """
			{
				"name": "webPixels",
				"body": "\(body)"
			}
			""")

		let result = try CheckoutBridge.decode(mock)

		guard case .webPixels(let pixelEvent) = result, case .standardEvent(let pageViewedEvent) = pixelEvent else {
			XCTFail("Expected .webPixels(.pageViewed), got \(result)")
			return
		}

		XCTAssertEqual("page_viewed", pageViewedEvent.name)
		XCTAssertEqual("123", pageViewedEvent.id)
		XCTAssertEqual("2024-01-04T09:48:53.358Z", pageViewedEvent.timestamp)
	}

	func testDecodeSupportsCustomWebPixelsEvent() throws {
		let body = "{\"name\": \"my_custom_event\",\"event\": {\"id\": \"123\",\"name\": \"my_custom_event\",\"type\":\"custom\",\"timestamp\": \"2024-01-04T09:48:53.358Z\",\"customData\": {\"wrapper\": {\"attr\": \"attrVal\", \"attr2\": [1,2,3]}}, \"context\": {}}}"
			.replacingOccurrences(of: "\"", with: "\\\"")
			.replacingOccurrences(of: "\n", with: "")

		let mock = WKScriptMessageMock(body: """
			{
				"name": "webPixels",
				"body": "\(body)"
			}
			""")

		let result = try CheckoutBridge.decode(mock)

		guard case .webPixels(let pixelEvent) = result, case .customEvent(let customEvent) = pixelEvent else {
			XCTFail("Expected .webPixels(.pageViewed), got \(result)")
			return
		}

		XCTAssertEqual("my_custom_event", customEvent.name)

		let decoder = JSONDecoder()
		let customData = try decoder.decode(MyCustomData.self, from: customEvent.customData!.data(using: .utf8)!)

		XCTAssertEqual("attrVal", customData.wrapper.attr)
		XCTAssertEqual([1, 2, 3], customData.wrapper.attr2)
	}

	func testDecodeSupportsWebPixelsEventWithAdditionalDataAttributes() throws {
		let body = "{\"name\": \"page_viewed\",\"event\": {\"id\": \"123\",\"name\": \"page_viewed\",\"type\":\"standard\",\"timestamp\": \"2024-01-04T09:48:53.358Z\",\"data\": { \"checkout\": {\"currencyCode\": \"USD\"}, \"cart\": {\"cartId\": \"123\"} }, \"context\": {}}}"
			.replacingOccurrences(of: "\"", with: "\\\"")
			.replacingOccurrences(of: "\n", with: "")

		let mock = WKScriptMessageMock(body: """
			{
				"name": "webPixels",
				"body": "\(body)"
			}
			""")

		let result = try CheckoutBridge.decode(mock)

		guard case .webPixels(let pixelEvent) = result, case .standardEvent(let pageViewedEvent) = pixelEvent else {
			XCTFail("Expected .webPixels(.pageViewed), got \(result)")
			return
		}

		XCTAssertEqual("page_viewed", pageViewedEvent.name)
		XCTAssertEqual("123", pageViewedEvent.id)
		XCTAssertEqual("USD", pageViewedEvent.data?.checkout?.currencyCode)
		XCTAssertEqual("2024-01-04T09:48:53.358Z", pageViewedEvent.timestamp)
	}

	func testDecoderThrowsBridgeErrorWhenMandatoryAttributesAreMissing() throws {
		let body = "{\"name\": \"page_viewed\",\"event\": {\"name\": \"page_viewed\",\"type\":\"standard\",\"timestamp\": \"2024-01-04T09:48:53.358Z\", \"context\": {}}}"
			.replacingOccurrences(of: "\"", with: "\\\"")
			.replacingOccurrences(of: "\n", with: "")

		let mock = WKScriptMessageMock(body: """
			{
				"name": "webPixels",
				"body": "\(body)"
			}
			""")

		XCTAssertThrowsError(try CheckoutBridge.decode(mock)) { error in
			guard case BridgeError.invalidBridgeEvent = error else {
				return XCTFail("unexpected error thrown: \(error)")
			}
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

	func testSendMessageShouldCallEvaluateJavaScriptPresented() {
		let webView = MockWebView()
		webView.expectedScript = expectedPresentedScript()
		let evaluateJavaScriptExpectation = expectation(
			description: "evaluateJavaScript was called"
		)
		webView.evaluateJavaScriptExpectation = evaluateJavaScriptExpectation

		CheckoutBridge.sendMessage(webView, messageName: "presented", messageBody: nil)

		wait(for: [evaluateJavaScriptExpectation], timeout: 1)
	}

	func testSendMessageWithPayloadEvaulatesJavaScript() {
		let webView = MockWebView()
		webView.expectedScript = expectedPayloadScript()
		let evaluateJavaScriptExpectation = expectation(
			description: "evaluateJavaScript was called"
		)
		webView.evaluateJavaScriptExpectation = evaluateJavaScriptExpectation

		CheckoutBridge.sendMessage(webView, messageName: "payload", messageBody: "{\"one\": true}")

		wait(for: [evaluateJavaScriptExpectation], timeout: 1)
	}

	private func expectedPresentedScript() -> String {
		return """
		if (window.MobileCheckoutSdk && window.MobileCheckoutSdk.dispatchMessage) {
			window.MobileCheckoutSdk.dispatchMessage('presented');
		} else {
			window.addEventListener('mobileCheckoutBridgeReady', function () {
				window.MobileCheckoutSdk.dispatchMessage('presented');
			}, {passive: true, once: true});
		}
		"""
	}

	private func expectedPayloadScript() -> String {
		return """
		if (window.MobileCheckoutSdk && window.MobileCheckoutSdk.dispatchMessage) {
			window.MobileCheckoutSdk.dispatchMessage('payload', {"one": true});
		} else {
			window.addEventListener('mobileCheckoutBridgeReady', function () {
				window.MobileCheckoutSdk.dispatchMessage('payload', {"one": true});
			}, {passive: true, once: true});
		}
		"""
	}
}

struct MyCustomData: Codable {
	let wrapper: MyCustomDataWrapper
}

struct MyCustomDataWrapper: Codable {
	let attr: String
	let attr2: [Int]
}
