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

import Common
@testable import ShopifyCheckoutSheetKit
import WebKit
import XCTest

// swiftlint:disable type_body_length
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

    func testReturnsStandardUserAgent() {
        let version = ShopifyCheckoutSheetKit.version
        let schemaVersion = MetaData.schemaVersion
        XCTAssertEqual(CheckoutBridge.applicationName, "ShopifyCheckoutSDK/\(version) (\(schemaVersion);automatic;standard)")
    }

    func testReturnsRecoveryUserAgent() {
        let version = ShopifyCheckoutSheetKit.version
        XCTAssertEqual(CheckoutBridge.recoveryAgent, "ShopifyCheckoutSDK/\(version) (noconnect;automatic;standard_recovery)")
    }

    func testReturnsUserAgentWithCustomPlatformSuffix() {
        let version = ShopifyCheckoutSheetKit.version
        let schemaVersion = MetaData.schemaVersion
        ShopifyCheckoutSheetKit.configuration.platform = Platform.reactNative
        XCTAssertEqual(CheckoutBridge.applicationName, "ShopifyCheckoutSDK/\(version) (\(schemaVersion);automatic;standard) ReactNative")
        XCTAssertEqual(CheckoutBridge.recoveryAgent, "ShopifyCheckoutSDK/\(version) (noconnect;automatic;standard_recovery) ReactNative")
        ShopifyCheckoutSheetKit.configuration.platform = nil
    }

    func testReturnsUserAgentWithEntryPoint() {
        let version = ShopifyCheckoutSheetKit.version
        let schemaVersion = MetaData.schemaVersion
        let applicationNameWithEntryPoint = CheckoutBridge.applicationName(entryPoint: .acceleratedCheckouts)
        let recoveryAgentWithEntryPoint = CheckoutBridge.recoveryAgent(entryPoint: .acceleratedCheckouts)

        XCTAssertEqual(applicationNameWithEntryPoint, "ShopifyCheckoutSDK/\(version) (\(schemaVersion);automatic;standard) AcceleratedCheckouts")
        XCTAssertEqual(recoveryAgentWithEntryPoint, "ShopifyCheckoutSDK/\(version) (noconnect;automatic;standard_recovery) AcceleratedCheckouts")
    }

    func testReturnsUserAgentWithEntryPointAndPlatform() {
        let version = ShopifyCheckoutSheetKit.version
        let schemaVersion = MetaData.schemaVersion
        ShopifyCheckoutSheetKit.configuration.platform = Platform.reactNative

        let applicationNameWithEntryPoint = CheckoutBridge.applicationName(entryPoint: .acceleratedCheckouts)
        let recoveryAgentWithEntryPoint = CheckoutBridge.recoveryAgent(entryPoint: .acceleratedCheckouts)

        XCTAssertEqual(applicationNameWithEntryPoint, "ShopifyCheckoutSDK/\(version) (\(schemaVersion);automatic;standard) ReactNative AcceleratedCheckouts")
        XCTAssertEqual(recoveryAgentWithEntryPoint, "ShopifyCheckoutSDK/\(version) (noconnect;automatic;standard_recovery) ReactNative AcceleratedCheckouts")

        ShopifyCheckoutSheetKit.configuration.platform = nil
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
        let mock = createEventPayload(name: "unknown", "{}")

        let result = try CheckoutBridge.decode(mock)

        guard case CheckoutBridge.WebEvent.unsupported = result else {
            return XCTFail("expected CheckoutScriptMessage.unsupportedEvent, got \(result)")
        }
    }

    func testDecodeSupportsCheckoutCompletedEvent() throws {
        let payload = "{\"orderDetails\":{\"id\":\"gid://shopify/OrderIdentity/8\",\"cart\":{\"lines\":[{\"quantity\":1,\"title\":\"Awesome Plastic Shoes\",\"price\":{\"amount\":87.99,\"currencyCode\":\"CAD\"},\"merchandiseId\":\"gid://shopify/ProductVariant/1\",\"productId\":\"gid://shopify/Product/1\"}],\"price\":{\"total\":{\"amount\":109.89,\"currencyCode\":\"CAD\"},\"subtotal\":{\"amount\":87.99,\"currencyCode\":\"CAD\"},\"taxes\":{\"amount\":0,\"currencyCode\":\"CAD\"},\"shipping\":{\"amount\":21.9,\"currencyCode\":\"CAD\"}},\"token\": \"fake-token\"},\"billingAddress\":{\"city\":\"Calgary\",\"countryCode\":\"CA\",\"postalCode\":\"T1X 0L3\",\"address1\":\"The Cloak & Dagger\",\"address2\":\"1st Street Southeast\",\"firstName\":\"Test\",\"lastName\":\"McTest\",\"name\":\"Test\",\"zoneCode\":\"AB\",\"coordinates\":{\"latitude\":45.416311,\"longitude\":-75.68683}},\"paymentMethods\":[{\"type\":\"direct\",\"details\":{\"amount\":\"109.89\",\"currency\":\"CAD\",\"brand\":\"BOGUS\",\"lastFourDigits\":\"1\"}}],\"deliveries\":[{\"method\":\"SHIPPING\",\"details\":{\"location\":{\"city\":\"Calgary\",\"countryCode\":\"CA\",\"postalCode\":\"T1X 0L3\",\"address1\":\"The Cloak & Dagger\",\"address2\":\"1st Street Southeast\",\"firstName\":\"Test\",\"lastName\":\"McTest\",\"name\":\"Test\",\"zoneCode\":\"AB\",\"coordinates\":{\"latitude\":45.416311,\"longitude\":-75.68683}}}}]},\"orderId\":\"gid://shopify/OrderIdentity/19\"}"

        let event = createEventPayload(name: "completed", payload)
        let result = try CheckoutBridge.decode(event)

        guard case let .checkoutComplete(event) = result else {
            XCTFail("Expected .checkoutComplete, got \(result)")
            return
        }

        XCTAssertEqual("gid://shopify/OrderIdentity/8", event.orderDetails.id)
        XCTAssertEqual(1, event.orderDetails.cart.lines.count)
        XCTAssertEqual("gid://shopify/Product/1", event.orderDetails.cart.lines[0].productId)
        XCTAssertEqual(1, event.orderDetails.paymentMethods?.count)
        XCTAssertEqual("direct", event.orderDetails.paymentMethods?[0].type)
    }

    func testFailedDecodeReturnsEmptyEvent() throws {
        /// Missing orderId, taxes, billingAddress
        let payload = "{\"orderDetails\":{\"cart\":{\"lines\":[{\"quantity\":1,\"title\":\"Awesome Plastic Shoes\",\"price\":{\"amount\":87.99,\"currencyCode\":\"CAD\"},\"merchandiseId\":\"gid://shopify/ProductVariant/1\",\"productId\":\"gid://shopify/Product/1\"}],\"price\":{\"total\":{\"amount\":109.89,\"currencyCode\":\"CAD\"},\"subtotal\":{\"amount\":87.99,\"currencyCode\":\"CAD\"},\"shipping\":{\"amount\":21.9,\"currencyCode\":\"CAD\"}},\"token\":\"fake-token\"},\"paymentMethods\":[{\"type\":\"direct\",\"details\":{\"amount\":\"109.89\",\"currency\":\"CAD\",\"brand\":\"BOGUS\",\"lastFourDigits\":\"1\"}}],\"deliveries\":[{\"method\":\"SHIPPING\",\"details\":{\"location\":{\"city\":\"Calgary\",\"countryCode\":\"CA\",\"postalCode\":\"T1X 0L3\",\"address1\":\"The Cloak & Dagger\",\"address2\":\"1st Street Southeast\",\"firstName\":\"Test\",\"lastName\":\"McTest\",\"name\":\"Test\",\"zoneCode\":\"AB\",\"coordinates\":{\"latitude\":45.416311,\"longitude\":-75.68683}}}}]},\"orderId\":\"gid://shopify/OrderIdentity/19\",\"cart\":{\"lines\":[{\"quantity\":1,\"title\":\"Awesome Plastic Shoes\",\"price\":{\"amount\":87.99,\"currencyCode\":\"CAD\"},\"merchandiseId\":\"gid://shopify/ProductVariant/1\",\"productId\":\"gid://shopify/Product/1\"}],\"price\":{\"total\":{\"amount\":109.89,\"currencyCode\":\"CAD\"},\"subtotal\":{\"amount\":87.99,\"currencyCode\":\"CAD\"},\"taxes\":{\"amount\":0,\"currencyCode\":\"CAD\"},\"shipping\":{\"amount\":21.9,\"currencyCode\":\"CAD\"}}}}"

        let event = createEventPayload(name: "completed", payload)
        let result = try CheckoutBridge.decode(event)

        guard case let .checkoutComplete(event) = result else {
            XCTFail("Expected .checkoutComplete, got \(result)")
            return
        }

        XCTAssertEqual(event.orderDetails.id, "")
    }

    func testDecodeSupportsCheckoutExpiredEvent() throws {
        let event = createErrorEventPayload("[{\"group\":\"expired\",\"type\": \"invalidCart\",\"reason\": \"Cart is invalid\", \"flowType\": \"regular\", \"code\": \"null\"}]")
        let result = try CheckoutBridge.decode(event)

        guard case CheckoutBridge.WebEvent.checkoutExpired = result else {
            return XCTFail("expected .checkoutExpired error, got \(result)")
        }
    }

    func testDecodesBarebonesErrorEvent() throws {
        let event = createErrorEventPayload("[{\"group\":\"expired\"}]")
        let result = try CheckoutBridge.decode(event)

        guard case CheckoutBridge.WebEvent.checkoutExpired = result else {
            return XCTFail("expected .checkoutExpired error, got \(result)")
        }
    }

    func testDecodeSupportsUnrecoverableErrorEvent() throws {
        let event = createErrorEventPayload("[{\"group\":\"unrecoverable\",\"reason\": \"Checkout crashed\", \"code\": \"sdk_not_enabled\"}]")

        let result = try CheckoutBridge.decode(event)

        guard case CheckoutBridge.WebEvent.checkoutUnavailable = result else {
            return XCTFail("expected .checkoutUnavailable error, got \(result)")
        }
    }

    func testDecodeSupportsConfigurationErrorEvent() throws {
        let event = createErrorEventPayload("[{\"group\":\"configuration\",\"code\":\"storefront_password_required\",\"reason\": \"Storefront password required\"}]")

        let result = try CheckoutBridge.decode(event)

        guard case CheckoutBridge.WebEvent.configurationError = result else {
            return XCTFail("expected .configurationError error, got \(result)")
        }
    }

    func testDecodeSupportsUnsupportedConfigurationErrorEvent() throws {
        let event = createErrorEventPayload("[{\"group\":\"configuration\",\"code\":\"unsupported\",\"reason\": \"Unsupported\"}]")

        let result = try CheckoutBridge.decode(event)

        guard case CheckoutBridge.WebEvent.configurationError = result else {
            return XCTFail("expected .configurationError error, got \(result)")
        }
    }

    func testDecodeFailsSilentlyWhenErrorIsUnsupported() throws {
        let event = createErrorEventPayload("[{\"group\":\"checkout\",\"reason\": \"violation\"}]")
        let result = try CheckoutBridge.decode(event)

        guard case CheckoutBridge.WebEvent.unsupported = result else {
            return XCTFail("expected .unsupported event, got \(result)")
        }
    }

    func testDecodeSupportsCheckoutBlockingEvent() throws {
        let event = createEventPayload(name: "checkoutBlockingEvent", "true")

        let result = try CheckoutBridge.decode(event)

        guard case CheckoutBridge.WebEvent.checkoutModalToggled = result else {
            return XCTFail("expected CheckoutScriptMessage.checkoutModalToggled, got \(result)")
        }
    }

    func testDecodeSupportsStandardWebPixelsEvent() throws {
        let event = createEventPayload(name: "webPixels", "{\"name\": \"page_viewed\",\"event\": {\"id\": \"123\",\"name\": \"page_viewed\",\"type\":\"standard\",\"timestamp\": \"2024-01-04T09:48:53.358Z\",\"data\": {}, \"context\": {}}}")

        let result = try CheckoutBridge.decode(event)

        guard case let .webPixels(pixelEvent) = result, case let .standardEvent(pageViewedEvent) = pixelEvent else {
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

        guard case let .webPixels(pixelEvent) = result, case let .customEvent(customEvent) = pixelEvent else {
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
        let body = "{\"name\": \"checkout_completed\",\"event\": {\"id\": \"123\",\"name\": \"checkout_completed\",\"type\":\"standard\",\"timestamp\": \"2024-01-04T09:48:53.358Z\",\"data\": { \"checkout\": {\"currencyCode\": \"USD\", \"order\": {\"customer\": { \"id\":\"456\",\"isFirstOrder\":true }}}}, \"context\": {}}}"
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "")

        let mock = WKScriptMessageMock(body: """
        {
        	"name": "webPixels",
        	"body": "\(body)"
        }
        """)

        let result = try CheckoutBridge.decode(mock)

        guard case let .webPixels(pixelEvent) = result, case let .standardEvent(pageViewedEvent) = pixelEvent else {
            XCTFail("Expected .webPixels(.pageViewed), got \(result)")
            return
        }

        XCTAssertEqual("checkout_completed", pageViewedEvent.name)
        XCTAssertEqual("123", pageViewedEvent.id)
        XCTAssertEqual("USD", pageViewedEvent.data?.checkout?.currencyCode)
        XCTAssertEqual("456", pageViewedEvent.data?.checkout?.order?.customer?.id)
        XCTAssertEqual(true, pageViewedEvent.data?.checkout?.order?.customer?.isFirstOrder)
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

    private func createPayload(_ jsonString: String) -> String {
        return jsonString
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "")
    }

    private func createErrorEventPayload(_ jsonString: String) -> CheckoutBridgeTests.WKScriptMessageMock {
        return WKScriptMessageMock(body: "{\"name\": \"error\",\"body\": \"\(createPayload(jsonString))\"}")
    }

    private func createEventPayload(name: String, _ jsonString: String) -> CheckoutBridgeTests.WKScriptMessageMock {
        return WKScriptMessageMock(body: "{\"name\": \"\(name)\",\"body\": \"\(createPayload(jsonString))\"}")
    }
}

struct MyCustomData: Codable {
    let wrapper: MyCustomDataWrapper
}

struct MyCustomDataWrapper: Codable {
    let attr: String
    let attr2: [Int]
}

// swiftlint:enable type_body_length
