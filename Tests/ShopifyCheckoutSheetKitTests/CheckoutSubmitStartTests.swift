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
import XCTest

class CheckoutSubmitStartTests: XCTestCase {
    // MARK: - Response Tests

    func testRespondWithSendsJavaScriptToWebView() throws {
        let mockWebView = MockWebView()
        let request = try createRequest(webview: mockWebView)

        let payload = CheckoutSubmitStartResponsePayload(cart: nil, errors: nil)

        let expectation = expectation(description: "JavaScript executed")
        mockWebView.evaluateJavaScriptExpectation = expectation

        try request.respondWith(payload: payload)

        waitForExpectations(timeout: 4.0)

        // Verify the JavaScript was executed and contains the expected JSON-RPC response
        XCTAssertNotNil(mockWebView.capturedJavaScript, "JavaScript should have been executed")

        let capturedJS = mockWebView.capturedJavaScript ?? ""

        // Verify the response contains expected JSON-RPC fields
        XCTAssertTrue(capturedJS.contains("window.postMessage"), "Should call window.postMessage")
        XCTAssertTrue(capturedJS.contains("\"jsonrpc\":\"2.0\""), "Should include JSON-RPC version")
        XCTAssertTrue(capturedJS.contains("\"id\":\"test-id-456\""), "Should include request ID")
        XCTAssertTrue(capturedJS.contains("\"result\""), "Should include result field")
    }

    func testCartIsFlattened() throws {
        let request = try createRequest()
        XCTAssertNotNil(request.cart, "cart should be accessible directly")
    }

    func testSessionIdIsFlattened() throws {
        let request = try createRequest()
        XCTAssertNotNil(request.sessionId, "sessionId should be accessible directly")
    }

    // MARK: - Decoding Tests

    func testDecodesCheckoutSessionId() throws {
        let request = try createRequest(checkoutId: "checkout-session-123")
        XCTAssertEqual(request.sessionId, "checkout-session-123")
    }

    // MARK: - Helper Methods

    private func createRequest(webview: MockWebView? = nil, checkoutId: String = "test-checkout-123") throws -> CheckoutSubmitStartEvent {
        let jsonString = """
        {
            "jsonrpc": "2.0",
            "id": "test-id-456",
            "method": "checkout.submitStart",
            "params": {
                "cart": \(createTestCartJSON()),
                "sessionId": "\(checkoutId)"
            }
        }
        """
        let data = jsonString.data(using: .utf8)!
        let request = try CheckoutSubmitStartEvent.decode(from: data, webview: webview ?? MockWebView())
        return request
    }
}
