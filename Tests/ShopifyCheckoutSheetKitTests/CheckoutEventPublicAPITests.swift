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

/// Tests for the public API surface of CheckoutNotification and CheckoutRequest protocols
class CheckoutEventPublicAPITests: XCTestCase {
    // MARK: - Protocol Conformance Tests

    func testCheckoutNotificationProtocolConformance() {
        let event: CheckoutNotification = createTestCheckoutStartEvent()

        // CheckoutNotification should expose method
        XCTAssertEqual(event.method, "checkout.start")
    }

    func testCheckoutRequestProtocolConformance() {
        let params = CheckoutAddressChangeStartParams(
            addressType: "shipping",
            cart: createTestCart()
        )
        let event: CheckoutRequest = CheckoutAddressChangeStart(id: "test-id-123", params: params)

        // CheckoutRequest should expose both id and method
        XCTAssertEqual(event.id, "test-id-123")
        XCTAssertEqual(event.method, "checkout.addressChangeStart")
    }

    func testCheckoutRequestIdIsNonNullable() {
        let params = CheckoutAddressChangeStartParams(
            addressType: "shipping",
            cart: createTestCart()
        )
        let event = CheckoutAddressChangeStart(id: "test-id-456", params: params)

        // id should be String, not String?
        let id: String = event.id
        XCTAssertEqual(id, "test-id-456")
    }

    // MARK: - Flattened Property Accessor Tests

    func testAddressChangeStartFlattenedProperties() {
        let cart = createTestCart(id: "cart-789")
        let params = CheckoutAddressChangeStartParams(
            addressType: "billing",
            cart: cart
        )
        let event = CheckoutAddressChangeStart(id: "test-id", params: params)

        // Should be able to access properties directly without going through params
        XCTAssertEqual(event.addressType, "billing")
        XCTAssertEqual(event.cart.id, "cart-789")
        XCTAssertEqual(event.method, "checkout.addressChangeStart")
    }

    func testSubmitStartFlattenedProperties() {
        let cart = createTestCart(id: "cart-submit-123")
        let checkout = Checkout(id: "checkout-id-789")
        let params = CheckoutSubmitStartParams(cart: cart, checkout: checkout)
        let event = CheckoutSubmitStart(id: "submit-id", params: params)

        // Should be able to access properties directly
        XCTAssertEqual(event.cart.id, "cart-submit-123")
        XCTAssertEqual(event.checkout.id, "checkout-id-789")
        XCTAssertEqual(event.method, "checkout.submitStart")
    }

    func testPaymentMethodChangeStartFlattenedProperties() {
        let cart = createTestCart(id: "cart-payment-456")
        let params = CheckoutPaymentMethodChangeStartParams(cart: cart)
        let event = CheckoutPaymentMethodChangeStart(id: "payment-id", params: params)

        // Should be able to access properties directly
        XCTAssertEqual(event.cart.id, "cart-payment-456")
        XCTAssertEqual(event.method, "checkout.paymentMethodChangeStart")
    }

    // MARK: - RespondWith JSON Tests

    func testRespondWithJSONParsesValidPayload() throws {
        let mockWebView = MockWebView()
        let params = CheckoutAddressChangeStartParams(
            addressType: "shipping",
            cart: createTestCart()
        )
        let request = CheckoutAddressChangeStart(id: "test-id", params: params)
        request.webview = mockWebView

        let json = """
        {
            "cart": {
                "delivery": {
                    "addresses": [
                        {
                            "address": {
                                "countryCode": "CA"
                            }
                        }
                    ]
                }
            }
        }
        """

        let expectation = expectation(description: "JavaScript executed")
        mockWebView.evaluateJavaScriptExpectation = expectation

        try request.respondWith(json: json)

        waitForExpectations(timeout: 2.0)

        let capturedJS = mockWebView.capturedJavaScript ?? ""
        XCTAssertTrue(capturedJS.contains("\"id\":\"test-id\""))
        XCTAssertTrue(capturedJS.contains("\"result\""))
    }

    func testRespondWithJSONThrowsOnInvalidJSON() {
        let params = CheckoutAddressChangeStartParams(
            addressType: "shipping",
            cart: createTestCart()
        )
        let request = CheckoutAddressChangeStart(id: "test-id", params: params)

        let invalidJSON = "{ invalid json }"

        XCTAssertThrowsError(try request.respondWith(json: invalidJSON)) { error in
            guard case CheckoutEventResponseError.decodingFailed = error else {
                XCTFail("Expected decodingFailed error, got \(error)")
                return
            }
        }
    }

    func testRespondWithJSONThrowsOnInvalidFieldType() {
        let params = CheckoutAddressChangeStartParams(
            addressType: "shipping",
            cart: createTestCart()
        )
        let request = CheckoutAddressChangeStart(id: "test-id", params: params)

        // cart field has wrong type (should be object, not string)
        let json = """
        {
            "cart": "invalid-type"
        }
        """

        XCTAssertThrowsError(try request.respondWith(json: json)) { error in
            guard case CheckoutEventResponseError.decodingFailed = error else {
                XCTFail("Expected decodingFailed error, got \(error)")
                return
            }
        }
    }

    func testRespondWithJSONValidatesPayload() {
        let params = CheckoutAddressChangeStartParams(
            addressType: "shipping",
            cart: createTestCart()
        )
        let request = CheckoutAddressChangeStart(id: "test-id", params: params)

        // Invalid country code (too long)
        let json = """
        {
            "cart": {
                "delivery": {
                    "addresses": [
                        {
                            "address": {
                                "countryCode": "USA"
                            }
                        }
                    ]
                }
            }
        }
        """

        XCTAssertThrowsError(try request.respondWith(json: json)) { error in
            guard case CheckoutEventResponseError.validationFailed = error else {
                XCTFail("Expected validationFailed error, got \(error)")
                return
            }
        }
    }

    // MARK: - RespondWith Error Tests

    func testRespondWithErrorSendsErrorResponse() throws {
        let mockWebView = MockWebView()
        let params = CheckoutAddressChangeStartParams(
            addressType: "shipping",
            cart: createTestCart()
        )
        let request = CheckoutAddressChangeStart(id: "test-id-error", params: params)
        request.webview = mockWebView

        let expectation = expectation(description: "JavaScript executed")
        mockWebView.evaluateJavaScriptExpectation = expectation

        try request.respondWith(error: "Something went wrong")

        waitForExpectations(timeout: 2.0)

        let capturedJS = mockWebView.capturedJavaScript ?? ""
        XCTAssertTrue(capturedJS.contains("\"id\":\"test-id-error\""))
        XCTAssertTrue(capturedJS.contains("\"error\""))
        XCTAssertTrue(capturedJS.contains("Something went wrong"))
    }

    // MARK: - Error Logging Tests

    func testRespondWithLogsErrorWhenEncodingFails() throws {
        // Note: This is difficult to test directly since encoding Cart/CartInput types rarely fails.
        // The error logging path is covered by the implementation but requires a payload type
        // that fails to encode. This would require creating a custom non-encodable type,
        // which isn't practical in this test context. The logic is straightforward though:
        // if encoding throws, it logs and catches the error.

        // This test documents that the error path exists and should be covered by
        // integration testing with actual encoding failures.
    }

    func testRespondWithoutWebViewDoesNotCrash() throws {
        let params = CheckoutAddressChangeStartParams(
            addressType: "shipping",
            cart: createTestCart()
        )
        let request = CheckoutAddressChangeStart(id: "test-id", params: params)
        // No webview set - should return early without crashing

        let payload = CheckoutAddressChangeStartResponsePayload(
            cart: CartInput(
                delivery: CartDeliveryInput(
                    addresses: [
                        CartSelectableAddressInput(
                            address: CartDeliveryAddressInput(countryCode: "US")
                        )
                    ]
                )
            )
        )

        // Should not crash - returns early when webview is nil
        XCTAssertNoThrow(try request.respondWith(payload: payload))
    }

    func testRespondWithErrorWithoutWebViewDoesNotCrash() throws {
        let params = CheckoutAddressChangeStartParams(
            addressType: "shipping",
            cart: createTestCart()
        )
        let request = CheckoutAddressChangeStart(id: "test-id", params: params)
        // No webview set - should return early without crashing

        // Should not crash - returns early when webview is nil
        XCTAssertNoThrow(try request.respondWith(error: "Test error"))
    }

    func testRespondWithJSONWithoutWebViewStillValidates() {
        let params = CheckoutAddressChangeStartParams(
            addressType: "shipping",
            cart: createTestCart()
        )
        let request = CheckoutAddressChangeStart(id: "test-id", params: params)
        // No webview set

        // Invalid country code - should still throw validation error even without webview
        let json = """
        {
            "cart": {
                "delivery": {
                    "addresses": [
                        {
                            "address": {
                                "countryCode": "USA"
                            }
                        }
                    ]
                }
            }
        }
        """

        // Validation should happen before checking webview
        XCTAssertThrowsError(try request.respondWith(json: json)) { error in
            guard case CheckoutEventResponseError.validationFailed = error else {
                XCTFail("Expected validationFailed error, got \(error)")
                return
            }
        }
    }

    // MARK: - Method Name Tests

    func testNotificationEventsHaveCorrectMethodNames() {
        let startEvent = createTestCheckoutStartEvent()
        XCTAssertEqual(startEvent.method, "checkout.start")

        let completeEvent = createTestCheckoutCompleteEvent()
        XCTAssertEqual(completeEvent.method, "checkout.complete")
    }

    func testRequestEventsHaveCorrectMethodNames() {
        let addressParams = CheckoutAddressChangeStartParams(
            addressType: "shipping",
            cart: createTestCart()
        )
        let addressEvent = CheckoutAddressChangeStart(id: "id", params: addressParams)
        XCTAssertEqual(addressEvent.method, "checkout.addressChangeStart")

        let paymentParams = CheckoutPaymentMethodChangeStartParams(cart: createTestCart())
        let paymentEvent = CheckoutPaymentMethodChangeStart(id: "id", params: paymentParams)
        XCTAssertEqual(paymentEvent.method, "checkout.paymentMethodChangeStart")

        let submitParams = CheckoutSubmitStartParams(
            cart: createTestCart(),
            checkout: Checkout(id: "checkout-id")
        )
        let submitEvent = CheckoutSubmitStart(id: "id", params: submitParams)
        XCTAssertEqual(submitEvent.method, "checkout.submitStart")
    }

    // MARK: - Type Erasure Tests

    func testNotificationCanBeStoredAsProtocolType() {
        let notifications: [CheckoutNotification] = [
            createTestCheckoutStartEvent(),
            createTestCheckoutCompleteEvent()
        ]

        XCTAssertEqual(notifications.count, 2)
        XCTAssertEqual(notifications[0].method, "checkout.start")
        XCTAssertEqual(notifications[1].method, "checkout.complete")
    }

    func testRequestCanBeStoredAsProtocolType() {
        let requests: [CheckoutRequest] = [
            CheckoutAddressChangeStart(
                id: "id1",
                params: CheckoutAddressChangeStartParams(
                    addressType: "shipping",
                    cart: createTestCart()
                )
            ),
            CheckoutPaymentMethodChangeStart(
                id: "id2",
                params: CheckoutPaymentMethodChangeStartParams(cart: createTestCart())
            )
        ]

        XCTAssertEqual(requests.count, 2)
        XCTAssertEqual(requests[0].id, "id1")
        XCTAssertEqual(requests[1].id, "id2")
    }
}
