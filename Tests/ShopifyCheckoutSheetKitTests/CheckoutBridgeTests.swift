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

class CheckoutBridgeTests: XCTestCase {
    private lazy var mockWebView = MockWebView()

    class WKScriptMessageMock: WKScriptMessage {
        private let _mockBody: Any
        private let _mockWebView: WKWebView?

        override var body: Any {
            _mockBody
        }

        override var webView: WKWebView? {
            _mockWebView
        }

        init(body: Any = "", webView: WKWebView? = nil) {
            _mockBody = body
            _mockWebView = webView
        }
    }

    func testMessageHandlerName() {
        XCTAssertEqual(CheckoutBridge.messageHandler, "EmbeddedCheckoutProtocolConsumer")
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

    func testDecodeThrowsInvalidBridgeEventWhenNotJSONRPC() throws {
        let mock = WKScriptMessageMock(body: """
        {
            "name": "test",
            "body": "test"
        }
        """)

        XCTAssertThrowsError(try CheckoutBridge.decode(mock)) { error in
            guard case BridgeError.invalidBridgeEvent = error else {
                return XCTFail("unexpected error thrown: \(error)")
            }
        }
    }

    func testDecodeReturnsUnsupportedRequestWhenWebViewIsNil() throws {
        let mock = WKScriptMessageMock(body: """
        {
            "jsonrpc": "2.0",
            "id": "test-id",
            "method": "checkout.addressChangeStart",
            "params": {
                "addressType": "shipping"
            }
        }
        """)

        let result = try CheckoutBridge.decode(mock)

        guard result is UnsupportedRequest else {
            return XCTFail("expected UnsupportedRequest when webView is nil, got \(result)")
        }
    }

    func testDecodeHandlesUnsupportedEventsGracefully() throws {
        let mock = WKScriptMessageMock(body: """
        {
            "jsonrpc": "2.0",
            "id": "test-id",
            "method": "unknown",
            "params": {}
        }
        """, webView: mockWebView)

        let result = try CheckoutBridge.decode(mock)

        guard result is UnsupportedRequest else {
            return XCTFail("expected UnsupportedRequest, got \(result)")
        }
    }

    func testDecodeSupportsCheckoutExpiredError() throws {
        let mock = WKScriptMessageMock(body: """
        {
            "jsonrpc": "2.0",
            "id": "test-id",
            "method": "error",
            "params": [{
                "group": "expired",
                "type": "invalidCart",
                "reason": "Cart is invalid",
                "flowType": "regular",
                "code": "cart_expired"
            }]
        }
        """, webView: mockWebView)

        let result = try CheckoutBridge.decode(mock)

        guard let errorRequest = result as? CheckoutErrorRequest else {
            XCTFail("Expected CheckoutErrorRequest, got \(result)")
            return
        }

        XCTAssertEqual(errorRequest.firstError?.group, .expired)
        XCTAssertEqual(errorRequest.firstError?.reason, "Cart is invalid")
    }

    func testDecodeSupportsCheckoutModalToggled() throws {
        let mock = WKScriptMessageMock(body: """
        {
            "jsonrpc": "2.0",
            "id": "test-id",
            "method": "checkoutBlockingEvent",
            "params": "true"
        }
        """, webView: mockWebView)

        let result = try CheckoutBridge.decode(mock)

        guard let modalRequest = result as? CheckoutModalToggledRequest else {
            XCTFail("Expected CheckoutModalToggledRequest, got \(result)")
            return
        }

        XCTAssertTrue(modalRequest.params.modalVisible)
    }

    func testDecodeSupportsCheckoutAddressChangeStart() throws {
        let mock = WKScriptMessageMock(body: """
        {
          "jsonrpc":"2.0",
          "id":"2fee28d3-e10f-4f5e-b6e5-e63c061029b3",
          "method":"checkout.addressChangeStart",
          "params":{
            "addressType":"shipping",
            "cart":{
              "id":"gid://shopify/Cart/test-cart-123",
              "lines":[],
              "cost":{
                "subtotalAmount":{"amount":"100.00","currencyCode":"USD"},
                "totalAmount":{"amount":"100.00","currencyCode":"USD"}
              },
              "buyerIdentity":{
                "email":"test@example.com"
              },
              "deliveryGroups":[],
              "discountCodes":[],
              "appliedGiftCards":[],
              "discountAllocations":[],
              "delivery":{"addresses":[]},
              "payment":{"instruments":[]}
            }
          }
        }
        """, webView: mockWebView)

        let result = try CheckoutBridge.decode(mock)

        guard let addressRequest = result as? CheckoutAddressChangeStartEvent else {
            XCTFail("Expected CheckoutAddressChangeStart, got \(result)")
            return
        }

        XCTAssertEqual("2fee28d3-e10f-4f5e-b6e5-e63c061029b3", addressRequest.id)
        XCTAssertEqual("shipping", addressRequest.addressType)
        XCTAssertEqual("gid://shopify/Cart/test-cart-123", addressRequest.cart.id)
    }

    func testDecodeSupportsCheckoutPaymentMethodChangeStart() throws {
        let mock = WKScriptMessageMock(body: """
        {
            "jsonrpc": "2.0",
            "id": "card-change-123",
            "method": "checkout.paymentMethodChangeStart",
            "params": {
                "cart": \(createTestCartJSON())
            }
        }
        """, webView: mockWebView)

        let result = try CheckoutBridge.decode(mock)

        guard let cardRequest = result as? CheckoutPaymentMethodChangeStartEvent else {
            XCTFail("Expected CheckoutPaymentMethodChangeStart, got \(result)")
            return
        }

        XCTAssertEqual("card-change-123", cardRequest.id)
        XCTAssertEqual("gid://shopify/Cart/test-cart-123", cardRequest.cart.id)
    }

    func testDecodeSupportsCheckoutPaymentMethodChangeStartWithPaymentInstruments() throws {
        let mock = WKScriptMessageMock(body: """
        {
            "jsonrpc": "2.0",
            "id": "card-change-456",
            "method": "checkout.paymentMethodChangeStart",
            "params": {
                "cart": {
                    "id": "gid://shopify/Cart/test-cart-456",
                    "lines": [],
                    "cost": {
                        "subtotalAmount": { "amount": "10.00", "currencyCode": "USD" },
                        "totalAmount": { "amount": "10.00", "currencyCode": "USD" }
                    },
                    "buyerIdentity": { "email": null, "phone": null, "customer": null, "countryCode": "US" },
                    "deliveryGroups": [],
                    "discountCodes": [],
                    "appliedGiftCards": [],
                    "discountAllocations": [],
                    "delivery": { "addresses": [] },
                    "payment": { "instruments": [{ "externalReference": "instrument-123" }] }
                }
            }
        }
        """, webView: mockWebView)

        let result = try CheckoutBridge.decode(mock)

        guard let cardRequest = result as? CheckoutPaymentMethodChangeStartEvent else {
            XCTFail("Expected CheckoutPaymentMethodChangeStart, got \(result)")
            return
        }

        XCTAssertEqual("card-change-456", cardRequest.id)
        XCTAssertEqual("gid://shopify/Cart/test-cart-456", cardRequest.cart.id)
        XCTAssertEqual(1, cardRequest.cart.payment.instruments.count)
        XCTAssertEqual("instrument-123", cardRequest.cart.payment.instruments.first?.externalReference)
    }

    func testDecodeSupportsCheckoutStart() throws {
        let mock = WKScriptMessageMock(
            body: createCheckoutStartJSON(
                cartId: "gid://shopify/Cart/test-cart-123",
                totalAmount: "100.00"
            ),
            webView: mockWebView
        )

        let result = try CheckoutBridge.decode(mock)

        guard let startEvent = result as? CheckoutStartEvent else {
            XCTFail("Expected CheckoutStartEvent, got \(result)")
            return
        }

        XCTAssertEqual("gid://shopify/Cart/test-cart-123", startEvent.cart.id)
        XCTAssertEqual("100.00", startEvent.cart.cost.totalAmount.amount)
        XCTAssertEqual("USD", startEvent.cart.cost.totalAmount.currencyCode)
        XCTAssertEqual("test@example.com", startEvent.cart.buyerIdentity.email)
    }

    func testDecodeSupportsCheckoutComplete() throws {
        let mock = WKScriptMessageMock(
            body: createCheckoutCompleteJSON(
                orderId: "gid://shopify/Order/test-order-123",
                cartId: "gid://shopify/Cart/test-cart-123"
            ),
            webView: mockWebView
        )

        let result = try CheckoutBridge.decode(mock)

        guard let completeEvent = result as? CheckoutCompleteEvent else {
            XCTFail("Expected CheckoutCompleteEvent, got \(result)")
            return
        }

        XCTAssertEqual("gid://shopify/Order/test-order-123", completeEvent.orderConfirmation.order.id)
        XCTAssertEqual("gid://shopify/Cart/test-cart-123", completeEvent.cart.id)
    }

    func testDecodeSupportsCheckoutSubmitStart() throws {
        let mock = WKScriptMessageMock(
            body: """
            {
                "jsonrpc": "2.0",
                "method": "checkout.submitStart",
                "id": "submit-123",
                "params": {
                    "cart": {
                        "id": "gid://shopify/Cart/test-cart-456",
                        "lines": [],
                        "cost": {
                            "subtotalAmount": {
                                "amount": "100.00",
                                "currencyCode": "USD"
                            },
                            "totalAmount": {
                                "amount": "100.00",
                                "currencyCode": "USD"
                            }
                        },
                        "buyerIdentity": {
                            "email": "buyer@example.com",
                            "phone": null,
                            "customer": null,
                            "countryCode": "US"
                        },
                        "deliveryGroups": [],
                        "discountCodes": [],
                        "appliedGiftCards": [],
                        "discountAllocations": [],
                        "delivery": {
                            "addresses": []
                        },
                        "payment": {
                            "instruments": []
                        }
                    },
                    "sessionId": "checkout-session-789"
                }
            }
            """,
            webView: mockWebView
        )

        let result = try CheckoutBridge.decode(mock)

        guard let submitRequest = result as? CheckoutSubmitStartEvent else {
            XCTFail("Expected CheckoutSubmitStart, got \(result)")
            return
        }

        XCTAssertEqual("submit-123", submitRequest.id)
        XCTAssertEqual("gid://shopify/Cart/test-cart-456", submitRequest.cart.id)
        XCTAssertEqual("checkout-session-789", submitRequest.sessionId)
        XCTAssertEqual("buyer@example.com", submitRequest.cart.buyerIdentity.email)
    }
}
