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

class CheckoutAddressChangeStartTests: XCTestCase {
    // MARK: - Response Tests

    func testRespondWithSendsJavaScriptToWebView() throws {
        let mockWebView = MockWebView()
        let params = CheckoutAddressChangeStartParams(
            addressType: "shipping",
            cart: createTestCart()
        )
        let request = CheckoutAddressChangeStart(id: "test-id-789", params: params)
        request.webview = mockWebView

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
        XCTAssertTrue(capturedJS.contains("\"id\":\"test-id-789\""), "Should include request ID")
        XCTAssertTrue(capturedJS.contains("\"result\""), "Should include result field")
        XCTAssertTrue(capturedJS.contains("\"cart\""), "Should include cart in result")
    }

    // MARK: - Validation Tests

    func testValidateAcceptsValid2CharacterCountryCode() throws {
        let request = createRequest()
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

        XCTAssertNoThrow(try request.validate(payload: payload))
    }

    func testValidateRejectsEmptyCountryCode() throws {
        let request = createRequest()
        let payload = CheckoutAddressChangeStartResponsePayload(
            cart: CartInput(
                delivery: CartDeliveryInput(
                    addresses: [
                        CartSelectableAddressInput(
                            address: CartDeliveryAddressInput(countryCode: "")
                        )
                    ]
                )
            )
        )

        XCTAssertThrowsError(try request.validate(payload: payload)) { error in
            guard case let CheckoutEventResponseError.validationFailed(message) = error else {
                XCTFail("Expected validationFailed error, got \(error)")
                return
            }
            XCTAssertTrue(message.contains("Country code is required"))
        }
    }

    func testValidateRejectsNilCountryCode() throws {
        let request = createRequest()
        let payload = CheckoutAddressChangeStartResponsePayload(
            cart: CartInput(
                delivery: CartDeliveryInput(
                    addresses: [
                        CartSelectableAddressInput(
                            address: CartDeliveryAddressInput(countryCode: nil)
                        )
                    ]
                )
            )
        )

        XCTAssertThrowsError(try request.validate(payload: payload)) { error in
            guard case let CheckoutEventResponseError.validationFailed(message) = error else {
                XCTFail("Expected validationFailed error, got \(error)")
                return
            }
            XCTAssertTrue(message.contains("Country code is required"))
        }
    }

    func testValidateRejects1CharacterCountryCode() throws {
        let request = createRequest()
        let payload = CheckoutAddressChangeStartResponsePayload(
            cart: CartInput(
                delivery: CartDeliveryInput(
                    addresses: [
                        CartSelectableAddressInput(
                            address: CartDeliveryAddressInput(countryCode: "U")
                        )
                    ]
                )
            )
        )

        XCTAssertThrowsError(try request.validate(payload: payload)) { error in
            guard case let CheckoutEventResponseError.validationFailed(message) = error else {
                XCTFail("Expected validationFailed error, got \(error)")
                return
            }
            XCTAssertTrue(message.contains("must be exactly 2 characters"))
            XCTAssertTrue(message.contains("got: 'U'"))
        }
    }

    func testValidateRejects3CharacterCountryCode() throws {
        let request = createRequest()
        let payload = CheckoutAddressChangeStartResponsePayload(
            cart: CartInput(
                delivery: CartDeliveryInput(
                    addresses: [
                        CartSelectableAddressInput(
                            address: CartDeliveryAddressInput(countryCode: "USA")
                        )
                    ]
                )
            )
        )

        XCTAssertThrowsError(try request.validate(payload: payload)) { error in
            guard case let CheckoutEventResponseError.validationFailed(message) = error else {
                XCTFail("Expected validationFailed error, got \(error)")
                return
            }
            XCTAssertTrue(message.contains("must be exactly 2 characters"))
            XCTAssertTrue(message.contains("got: 'USA'"))
        }
    }

    func testValidateRejectsEmptyAddressesList() throws {
        let request = createRequest()
        let payload = CheckoutAddressChangeStartResponsePayload(
            cart: CartInput(
                delivery: CartDeliveryInput(addresses: [])
            )
        )

        XCTAssertThrowsError(try request.validate(payload: payload)) { error in
            guard case let CheckoutEventResponseError.validationFailed(message) = error else {
                XCTFail("Expected validationFailed error, got \(error)")
                return
            }
            XCTAssertTrue(message.contains("At least one address is required"))
        }
    }

    func testValidateRejectsNilAddressesList() throws {
        let request = createRequest()
        let payload = CheckoutAddressChangeStartResponsePayload(
            cart: CartInput(
                delivery: CartDeliveryInput(addresses: nil)
            )
        )

        XCTAssertThrowsError(try request.validate(payload: payload)) { error in
            guard case let CheckoutEventResponseError.validationFailed(message) = error else {
                XCTFail("Expected validationFailed error, got \(error)")
                return
            }
            XCTAssertTrue(message.contains("At least one address is required"))
        }
    }

    func testValidateIncludesIndexInErrorMessage() throws {
        let request = createRequest()
        let payload = CheckoutAddressChangeStartResponsePayload(
            cart: CartInput(
                delivery: CartDeliveryInput(
                    addresses: [
                        CartSelectableAddressInput(
                            address: CartDeliveryAddressInput(countryCode: "US")
                        ),
                        CartSelectableAddressInput(
                            address: CartDeliveryAddressInput(countryCode: "CAN")
                        )
                    ]
                )
            )
        )

        XCTAssertThrowsError(try request.validate(payload: payload)) { error in
            guard case let CheckoutEventResponseError.validationFailed(message) = error else {
                XCTFail("Expected validationFailed error, got \(error)")
                return
            }
            XCTAssertTrue(message.contains("at index 1"))
            XCTAssertTrue(message.contains("got: 'CAN'"))
        }
    }

    func testValidateAllowsNilCart() throws {
        let request = createRequest()
        let payload = CheckoutAddressChangeStartResponsePayload(cart: nil)

        XCTAssertNoThrow(try request.validate(payload: payload))
    }

    func testValidateAcceptsMultipleValidAddresses() throws {
        let request = createRequest()
        let payload = CheckoutAddressChangeStartResponsePayload(
            cart: CartInput(
                delivery: CartDeliveryInput(
                    addresses: [
                        CartSelectableAddressInput(
                            address: CartDeliveryAddressInput(countryCode: "US")
                        ),
                        CartSelectableAddressInput(
                            address: CartDeliveryAddressInput(countryCode: "CA")
                        ),
                        CartSelectableAddressInput(
                            address: CartDeliveryAddressInput(countryCode: "GB")
                        )
                    ]
                )
            )
        )

        XCTAssertNoThrow(try request.validate(payload: payload))
    }

    // MARK: - Helper Methods

    private func createRequest() -> CheckoutAddressChangeStart {
        let params = CheckoutAddressChangeStartParams(addressType: "shipping", cart: createTestCart())
        return CheckoutAddressChangeStart(id: nil, params: params)
    }
}
