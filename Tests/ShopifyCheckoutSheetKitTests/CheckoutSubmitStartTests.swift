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
        let params = CheckoutSubmitStartParams(
            cart: createTestCart(),
            checkout: Checkout(id: "test-checkout-123")
        )
        let request = CheckoutSubmitStart(id: "test-id-456", params: params)
        request.webview = mockWebView

        let payload = CheckoutSubmitStartResponsePayload(payment: nil, cart: nil, errors: nil)

        let expectation = expectation(description: "JavaScript executed")
        mockWebView.evaluateJavaScriptExpectation = expectation

        try request.respondWith(payload: payload)

        waitForExpectations(timeout: 2.0)

        // Verify the JavaScript was executed and contains the expected JSON-RPC response
        XCTAssertNotNil(mockWebView.capturedJavaScript, "JavaScript should have been executed")

        let capturedJS = mockWebView.capturedJavaScript ?? ""

        // Verify the response contains expected JSON-RPC fields
        XCTAssertTrue(capturedJS.contains("window.postMessage"), "Should call window.postMessage")
        XCTAssertTrue(capturedJS.contains("\"jsonrpc\":\"2.0\""), "Should include JSON-RPC version")
        XCTAssertTrue(capturedJS.contains("\"id\":\"test-id-456\""), "Should include request ID")
        XCTAssertTrue(capturedJS.contains("\"result\""), "Should include result field")
    }

    // MARK: - Decoding Tests

    func testDecodesCheckoutSessionId() throws {
        let json = """
        {
            "cart": {
                "id": "gid://shopify/Cart/test-cart-789",
                "lines": [],
                "cost": {
                    "subtotalAmount": {"amount": "75.00", "currencyCode": "CAD"},
                    "totalAmount": {"amount": "75.00", "currencyCode": "CAD"}
                },
                "buyerIdentity": {},
                "deliveryGroups": [],
                "discountCodes": [],
                "appliedGiftCards": [],
                "discountAllocations": [],
                "delivery": {"addresses": []},
                "payment": {"instruments": []}
            },
            "checkout": {
                "id": "checkout-session-123"
            }
        }
        """

        let data = json.data(using: .utf8)!
        let params = try JSONDecoder().decode(CheckoutSubmitStartParams.self, from: data)

        XCTAssertEqual(params.checkout.id, "checkout-session-123")
    }
}
