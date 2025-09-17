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
            "method": "checkout.addressChangeRequested",
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

    func testDecodeSupportsAddressChangeRequested() throws {
        let mock = WKScriptMessageMock(body: """
        {
          "jsonrpc":"2.0",
          "id":"2fee28d3-e10f-4f5e-b6e5-e63c061029b3",
          "method":"checkout.addressChangeRequested",
          "params":{
            "addressType":"shipping",
            "selectedAddress":{
              "city":"Toronto",
              "countryCode":"CA",
              "postalCode":"M5V 1M7",
              "address1":"650 King Street",
              "address2":"Shopify HQ",
              "firstName":"Evelyn",
              "lastName":"Hartley",
              "name":"Evelyn",
              "zoneCode":"ON",
              "phone":"1-888-746-7439",
              "oneTimeUse":false,
              "coordinates":{
                "latitude":45.416311,
                "longitude":-75.68683
              }
            }
          }
        }
        """, webView: mockWebView)

        let result = try CheckoutBridge.decode(mock)

        guard let addressRequest = result as? AddressChangeRequested else {
            XCTFail("Expected AddressChangeRequested, got \(result)")
            return
        }

        XCTAssertEqual("2fee28d3-e10f-4f5e-b6e5-e63c061029b3", addressRequest.id)
        XCTAssertEqual("shipping", addressRequest.params.addressType)

        let address = addressRequest.params.selectedAddress
        XCTAssertNotNil(address)
        XCTAssertEqual("Toronto", address?.city)
        XCTAssertEqual("CA", address?.countryCode)
        XCTAssertEqual("M5V 1M7", address?.postalCode)
    }

    func testDecodeSupportsWebPixelsEvent() throws {
        let mock = WKScriptMessageMock(body: """
        {
            "jsonrpc": "2.0",
            "id": "test-id",
            "method": "webPixels",
            "params": {
                "name": "page_viewed",
                "event": {
                    "id": "123",
                    "name": "page_viewed",
                    "type": "standard",
                    "timestamp": "2024-01-04T09:48:53.358Z",
                    "data": {},
                    "context": {}
                }
            }
        }
        """, webView: mockWebView)

        let result = try CheckoutBridge.decode(mock)

        guard let pixelsRequest = result as? WebPixelsRequest else {
            XCTFail("Expected WebPixelsRequest, got \(result)")
            return
        }

        guard case let .standardEvent(standardEvent) = pixelsRequest.pixelEvent else {
            XCTFail("Expected standardEvent")
            return
        }

        XCTAssertEqual("page_viewed", standardEvent.name)
        XCTAssertEqual("123", standardEvent.id)
    }

    func testDecodeSupportsCheckoutCardChangeRequested() throws {
        let mock = WKScriptMessageMock(body: """
        {
            "jsonrpc": "2.0",
            "id": "card-change-123",
            "method": "checkout.cardChangeRequested",
            "params": {
                "currentCard": {
                    "last4": "4242",
                    "brand": "visa"
                }
            }
        }
        """, webView: mockWebView)

        let result = try CheckoutBridge.decode(mock)

        guard let cardRequest = result as? CheckoutCardChangeRequested else {
            XCTFail("Expected CheckoutCardChangeRequested, got \(result)")
            return
        }

        XCTAssertEqual("card-change-123", cardRequest.id)
        XCTAssertNotNil(cardRequest.params.currentCard)
        XCTAssertEqual("4242", cardRequest.params.currentCard?.last4)
        XCTAssertEqual("visa", cardRequest.params.currentCard?.brand)
    }

    func testDecodeSupportsCheckoutCardChangeRequestedWithoutCurrentCard() throws {
        let mock = WKScriptMessageMock(body: """
        {
            "jsonrpc": "2.0",
            "id": "card-change-456",
            "method": "checkout.cardChangeRequested",
            "params": {
                "currentCard": null
            }
        }
        """, webView: mockWebView)

        let result = try CheckoutBridge.decode(mock)

        guard let cardRequest = result as? CheckoutCardChangeRequested else {
            XCTFail("Expected CheckoutCardChangeRequested, got \(result)")
            return
        }

        XCTAssertEqual("card-change-456", cardRequest.id)
        XCTAssertNil(cardRequest.params.currentCard)
    }
}
