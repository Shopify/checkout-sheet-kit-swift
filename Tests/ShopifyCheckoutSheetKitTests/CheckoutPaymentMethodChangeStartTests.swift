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

class CheckoutPaymentMethodChangeStartTests: XCTestCase {
    // MARK: - Validation Tests

    func testValidateAcceptsValidPaymentInstrument() throws {
        let request = createRequest()
        let payload = CheckoutPaymentMethodChangeStartResponsePayload(
            cart: CartInput(
                paymentInstruments: [
                    createTestPaymentInstrumentInput()
                ]
            )
        )

        XCTAssertNoThrow(try request.validate(payload: payload))
    }

    func testValidateAcceptsNilCart() throws {
        let request = createRequest()
        let payload = CheckoutPaymentMethodChangeStartResponsePayload(cart: nil)

        XCTAssertNoThrow(try request.validate(payload: payload))
    }

    func testValidateAcceptsNilPaymentInstruments() throws {
        let request = createRequest()
        let payload = CheckoutPaymentMethodChangeStartResponsePayload(
            cart: CartInput(paymentInstruments: nil)
        )

        XCTAssertNoThrow(try request.validate(payload: payload))
    }

    func testValidateAcceptsEmptyPaymentInstruments() throws {
        let request = createRequest()
        let payload = CheckoutPaymentMethodChangeStartResponsePayload(
            cart: CartInput(paymentInstruments: [])
        )

        XCTAssertNoThrow(try request.validate(payload: payload))
    }

    func testValidateRejectsInvalidLastDigits() throws {
        let request = createRequest()
        let payload = CheckoutPaymentMethodChangeStartResponsePayload(
            cart: CartInput(
                paymentInstruments: [
                    createTestPaymentInstrumentInput(lastDigits: "123")
                ]
            )
        )

        XCTAssertThrowsError(try request.validate(payload: payload)) { error in
            guard case let CheckoutEventResponseError.validationFailed(message) = error else {
                XCTFail("Expected validationFailed error, got \(error)")
                return
            }
            XCTAssertTrue(message.contains("lastDigits must be exactly 4 characters"))
        }
    }

    func testValidateRejectsInvalidExpiryMonthTooLow() throws {
        let request = createRequest()
        let payload = CheckoutPaymentMethodChangeStartResponsePayload(
            cart: CartInput(
                paymentInstruments: [
                    createTestPaymentInstrumentInput(expiryMonth: 0)
                ]
            )
        )

        XCTAssertThrowsError(try request.validate(payload: payload)) { error in
            guard case let CheckoutEventResponseError.validationFailed(message) = error else {
                XCTFail("Expected validationFailed error, got \(error)")
                return
            }
            XCTAssertTrue(message.contains("expiryMonth must be between 1 and 12"))
        }
    }

    func testValidateRejectsInvalidExpiryMonthTooHigh() throws {
        let request = createRequest()
        let payload = CheckoutPaymentMethodChangeStartResponsePayload(
            cart: CartInput(
                paymentInstruments: [
                    createTestPaymentInstrumentInput(expiryMonth: 13)
                ]
            )
        )

        XCTAssertThrowsError(try request.validate(payload: payload)) { error in
            guard case let CheckoutEventResponseError.validationFailed(message) = error else {
                XCTFail("Expected validationFailed error, got \(error)")
                return
            }
            XCTAssertTrue(message.contains("expiryMonth must be between 1 and 12"))
        }
    }

    func testValidateRejectsInvalidCountryCode() throws {
        let request = createRequest()
        let payload = CheckoutPaymentMethodChangeStartResponsePayload(
            cart: CartInput(
                paymentInstruments: [
                    createTestPaymentInstrumentInput(countryCode: "USA")
                ]
            )
        )

        XCTAssertThrowsError(try request.validate(payload: payload)) { error in
            guard case let CheckoutEventResponseError.validationFailed(message) = error else {
                XCTFail("Expected validationFailed error, got \(error)")
                return
            }
            XCTAssertTrue(message.contains("Country code must be exactly 2 characters"))
            XCTAssertTrue(message.contains("got: 'USA'"))
        }
    }

    func testValidateIncludesIndexInErrorMessage() throws {
        let request = createRequest()
        let payload = CheckoutPaymentMethodChangeStartResponsePayload(
            cart: CartInput(
                paymentInstruments: [
                    createTestPaymentInstrumentInput(),
                    createTestPaymentInstrumentInput(lastDigits: "12")
                ]
            )
        )

        XCTAssertThrowsError(try request.validate(payload: payload)) { error in
            guard case let CheckoutEventResponseError.validationFailed(message) = error else {
                XCTFail("Expected validationFailed error, got \(error)")
                return
            }
            XCTAssertTrue(message.contains("at index 1"))
        }
    }

    func testValidateAcceptsMultipleValidPaymentInstruments() throws {
        let request = createRequest()
        let payload = CheckoutPaymentMethodChangeStartResponsePayload(
            cart: CartInput(
                paymentInstruments: [
                    createTestPaymentInstrumentInput(identifier: "card-1"),
                    createTestPaymentInstrumentInput(identifier: "card-2"),
                    createTestPaymentInstrumentInput(identifier: "card-3")
                ]
            )
        )

        XCTAssertNoThrow(try request.validate(payload: payload))
    }

    func testValidateAcceptsNilCountryCode() throws {
        let request = createRequest()
        let payload = CheckoutPaymentMethodChangeStartResponsePayload(
            cart: CartInput(
                paymentInstruments: [
                    createTestPaymentInstrumentInput(countryCode: nil)
                ]
            )
        )

        XCTAssertNoThrow(try request.validate(payload: payload))
    }

    // MARK: - Helper Methods

    private func createRequest() -> CheckoutPaymentMethodChangeStart {
        let params = CheckoutPaymentMethodChangeStartParams(cart: createTestCart())
        return CheckoutPaymentMethodChangeStart(id: nil, params: params)
    }

    private func createTestPaymentInstrumentInput(
        identifier: String = "instrument-123",
        lastDigits: String = "4242",
        cardHolderName: String = "John Doe",
        brand: CardBrand = .visa,
        expiryMonth: Int = 12,
        expiryYear: Int = 2025,
        countryCode: String? = "US"
    ) -> CartPaymentInstrumentInput {
        CartPaymentInstrumentInput(
            identifier: identifier,
            lastDigits: lastDigits,
            cardHolderName: cardHolderName,
            brand: brand,
            expiryMonth: expiryMonth,
            expiryYear: expiryYear,
            billingAddress: CartDeliveryAddressInput(countryCode: countryCode)
        )
    }
}
