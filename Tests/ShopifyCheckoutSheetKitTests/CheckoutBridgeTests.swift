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

@testable import ShopifyCheckoutSheetKit
import WebKit
import XCTest

// swiftlint:disable type_body_length
class CheckoutBridgeTests: XCTestCase {
    private var bridge: CheckoutBridge!
    private var mockConfiguration: Configuration!
    private var mockWebView: MockWKWebView!

    override func setUp() {
        super.setUp()
        mockConfiguration = Configuration()
        mockWebView = MockWKWebView()
        mockConfiguration.webView = mockWebView
        bridge = DefaultCheckoutBridge(configuration: mockConfiguration)
    }

    func testUserAgentFormat() {
        let userAgent = bridge.userAgent
        XCTAssertTrue(userAgent.contains("CheckoutKit/4.0.0"))
        XCTAssertTrue(userAgent.contains("(iOS)"))
        XCTAssertTrue(userAgent.contains("CheckoutSheetProtocol/2025-04"))
        XCTAssertTrue(userAgent.contains("auto") || userAgent.contains("light") || userAgent.contains("dark"))
    }

    func testColorSchemeNormalization() {
        // Test automatic -> auto
        mockConfiguration.colorScheme = .automatic
        bridge = DefaultCheckoutBridge(configuration: mockConfiguration)
        XCTAssertEqual(bridge.normalizedColorScheme(), "auto")

        // Test light -> light
        mockConfiguration.colorScheme = .light
        bridge = DefaultCheckoutBridge(configuration: mockConfiguration)
        XCTAssertEqual(bridge.normalizedColorScheme(), "light")

        // Test dark -> dark
        mockConfiguration.colorScheme = .dark
        bridge = DefaultCheckoutBridge(configuration: mockConfiguration)
        XCTAssertEqual(bridge.normalizedColorScheme(), "dark")
    }

    func testBridgePropertiesAndMethods() {
        XCTAssertEqual(bridge.libraryVersion(), "4.0.0")
        XCTAssertEqual(bridge.protocolVersion(), "2025-04")
        XCTAssertEqual(bridge.messageHandlerName(), "checkoutSheetProtocol")
        XCTAssertEqual(bridge.readyEventName(), "checkoutSheetProtocolReady")
        XCTAssertEqual(bridge.javascriptInterfaceName(), "window.Shopify.CheckoutSheetProtocol")
        XCTAssertEqual(bridge.dispatchMessage(), "window.Shopify.CheckoutSheetProtocol.postMessage")
    }

    func testEmbedParams() {
        let params = bridge.embedParams()
        XCTAssertEqual(params["embed"], "mobile_checkout_sdk")
        XCTAssertEqual(params["version"], "4.0.0")
        XCTAssertEqual(params["protocol"], "2025-04")
        XCTAssertEqual(params["theme"], "auto")
    }

    func testSendMessageShouldCallEvaluateJavaScriptPresented() {
        let evaluateJavaScriptExpectation = expectation(description: "evaluateJavaScript was called")
        mockWebView.evaluateJavaScriptExpectation = evaluateJavaScriptExpectation
        mockWebView.expectedScript = "window.Shopify.CheckoutSheetProtocol.postMessage(\"presented\")"

        bridge.sendMessage(message: "presented", completionHandler: nil)

        wait(for: [evaluateJavaScriptExpectation], timeout: 1)
    }

    func testSendMessageWithPayloadEvaulatesJavaScript() {
        let evaluateJavaScriptExpectation = expectation(description: "evaluateJavaScript was called")
        mockWebView.evaluateJavaScriptExpectation = evaluateJavaScriptExpectation
        mockWebView.expectedScript = "window.Shopify.CheckoutSheetProtocol.postMessage(\"payload\", {\"one\":true})"

        bridge.sendMessage(message: "payload", payload: ["one": true], completionHandler: nil)

        wait(for: [evaluateJavaScriptExpectation], timeout: 1)
    }

    func testDecodeEventFromValidJSON() {
        let json = """
        {
            "name": "completed",
            "body": {
                "orderDetails": {
                    "id": "gid://shopify/Order/123",
                    "cart": {
                        "token": "test-token"
                    }
                }
            }
        }
        """

        let result = bridge.decodeEvent(from: json)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?["name"] as? String, "completed")
        XCTAssertNotNil(result?["body"] as? [String: Any])
    }

    func testDecodeEventFromInvalidJSON() {
        let invalidJSON = "invalid json"
        let result = bridge.decodeEvent(from: invalidJSON)
        XCTAssertNil(result)
    }

    func testSendMessageWithDifferentPayloadTypes() {
        let evaluateJavaScriptExpectation = expectation(description: "evaluateJavaScript was called")
        mockWebView.evaluateJavaScriptExpectation = evaluateJavaScriptExpectation
        mockWebView.expectedScript = "window.Shopify.CheckoutSheetProtocol.postMessage(\"test\", [\"item1\",\"item2\"])"

        bridge.sendMessage(message: "test", payload: ["item1", "item2"], completionHandler: nil)

        wait(for: [evaluateJavaScriptExpectation], timeout: 1)
    }

    func testSendMessageHandlesJSONSerializationError() {
        let evaluateJavaScriptExpectation = expectation(description: "evaluateJavaScript was called")
        let completionExpectation = expectation(description: "Completion handler called with error")
        mockWebView.evaluateJavaScriptExpectation = evaluateJavaScriptExpectation
        mockWebView.expectedScript = "window.Shopify.CheckoutSheetProtocol.postMessage(\"test\", {})"

        // Create a payload that can't be serialized to JSON (Date objects aren't valid JSON)
        let invalidPayload: [String: Any] = ["date": Date()]

        bridge.sendMessage(message: "test", payload: invalidPayload) { result in
            switch result {
            case .success:
                XCTFail("Expected failure due to invalid JSON object")
            case .failure(let error):
                XCTAssertNotNil(error)
                completionExpectation.fulfill()
            }
        }

        wait(for: [evaluateJavaScriptExpectation, completionExpectation], timeout: 1)
    }

    func testSendMessageWithoutWebView() {
        // Test behavior when webView is nil
        var configWithoutWebView = Configuration()
        configWithoutWebView.webView = nil
        let bridgeWithoutWebView = DefaultCheckoutBridge(configuration: configWithoutWebView)

        let expectation = XCTestExpectation(description: "Completion handler called")
        bridgeWithoutWebView.sendMessage(message: "test") { result in
            switch result {
            case .success:
                XCTFail("Expected failure when webView is nil")
            case .failure(let error):
                XCTAssertEqual(error as? CheckoutError, .webViewNotAvailable)
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }
}

// Mock WebView for testing
class MockWKWebView: WKWebView {
    var expectedScript: String?
    var evaluateJavaScriptExpectation: XCTestExpectation?

    override func evaluateJavaScript(_ javaScriptString: String, completionHandler: (@MainActor @Sendable (Any?, (any Error)?) -> Void)? = nil) {
        if let expected = expectedScript {
            XCTAssertEqual(javaScriptString, expected)
        }
        evaluateJavaScriptExpectation?.fulfill()
        completionHandler?("success", nil)
    }
}

// swiftlint:enable type_body_length
