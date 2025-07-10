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

import PassKit
@testable import ShopifyAcceleratedCheckouts
import XCTest

@available(iOS 17.0, *)
class ErrorHandler_UserErrorsTest: XCTestCase {
    struct TestCase {
        let errorCode: StorefrontAPI.CartErrorCode
        let field: [String]?
        let shippingCountry: String
        let expectedAction: ExpectedAction
        let expectedField: String?
        let expectedMessageKey: String?
        let testDescription: String

        enum ExpectedAction {
            case showError(ValidationError)
            case interrupt(ErrorHandler.InterruptReason)

            enum ValidationError {
                case emailInvalid
                case phoneNumberInvalid
                case nameInvalid
                case deliveryAddressInvalid
                case addressUnserviceableError
            }
        }
    }

    func testMap_allUserErrorCodes() {
        let testCases: [TestCase] = [
            // MARK: - Address Field Contains Emojis

            TestCase(
                errorCode: .addressFieldContainsEmojis,
                field: ["addresses", "0", "address", "deliveryAddress", "firstName"],
                shippingCountry: "US",
                expectedAction: .showError(.nameInvalid),
                expectedField: nil,
                expectedMessageKey: "errors.emojis.first_name",
                testDescription: "returns nameInvalid error when firstName contains emojis"
            ),
            TestCase(
                errorCode: .addressFieldContainsEmojis,
                field: ["addresses", "0", "address", "deliveryAddress", "lastName"],
                shippingCountry: "US",
                expectedAction: .showError(.nameInvalid),
                expectedField: nil,
                expectedMessageKey: "errors.emojis.last_name",
                testDescription: "returns nameInvalid error when lastName contains emojis"
            ),
            TestCase(
                errorCode: .addressFieldContainsEmojis,
                field: ["addresses", "0", "address", "deliveryAddress", "address1"],
                shippingCountry: "US",
                expectedAction: .showError(.deliveryAddressInvalid),
                expectedField: CNPostalAddressStreetKey,
                expectedMessageKey: "errors.emojis.address1",
                testDescription: "returns deliveryAddressInvalid error when address1 contains emojis"
            ),
            TestCase(
                errorCode: .addressFieldContainsEmojis,
                field: ["addresses", "0", "address", "deliveryAddress", "city"],
                shippingCountry: "US",
                expectedAction: .showError(.deliveryAddressInvalid),
                expectedField: CNPostalAddressCityKey,
                expectedMessageKey: "errors.emojis.city",
                testDescription: "returns deliveryAddressInvalid error when city contains emojis"
            ),
            TestCase(
                errorCode: .addressFieldContainsEmojis,
                field: ["addresses", "0", "address", "deliveryAddress", "zip"],
                shippingCountry: "US",
                expectedAction: .showError(.deliveryAddressInvalid),
                expectedField: CNPostalAddressPostalCodeKey,
                expectedMessageKey: "errors.emojis.postal_code",
                testDescription: "returns deliveryAddressInvalid error when zip contains emojis"
            ),
            TestCase(
                errorCode: .addressFieldContainsEmojis,
                field: ["addresses", "0", "address", "deliveryAddress", "province"],
                shippingCountry: "US",
                expectedAction: .interrupt(.unhandled),
                expectedField: nil,
                expectedMessageKey: nil,
                testDescription: "returns unhandled interrupt when unsupported field contains emojis"
            ),

            // MARK: - Address Field Contains HTML Tags

            TestCase(
                errorCode: .addressFieldContainsHtmlTags,
                field: ["addresses", "0", "address", "deliveryAddress", "firstName"],
                shippingCountry: "US",
                expectedAction: .showError(.nameInvalid),
                expectedField: nil,
                expectedMessageKey: "errors.html_tags.first_name",
                testDescription: "returns nameInvalid error when firstName contains HTML tags"
            ),
            TestCase(
                errorCode: .addressFieldContainsHtmlTags,
                field: ["addresses", "0", "address", "deliveryAddress", "address1"],
                shippingCountry: "US",
                expectedAction: .showError(.deliveryAddressInvalid),
                expectedField: CNPostalAddressStreetKey,
                expectedMessageKey: "errors.html_tags.address1",
                testDescription: "returns deliveryAddressInvalid error when address1 contains HTML tags"
            ),

            // MARK: - Address Field Contains URL

            TestCase(
                errorCode: .addressFieldContainsUrl,
                field: ["addresses", "0", "address", "deliveryAddress", "firstName"],
                shippingCountry: "US",
                expectedAction: .showError(.nameInvalid),
                expectedField: nil,
                expectedMessageKey: "errors.url.first_name",
                testDescription: "returns nameInvalid error when firstName contains URL"
            ),
            TestCase(
                errorCode: .addressFieldContainsUrl,
                field: ["addresses", "0", "address", "deliveryAddress", "address1"],
                shippingCountry: "US",
                expectedAction: .interrupt(.unhandled),
                expectedField: nil,
                expectedMessageKey: nil,
                testDescription: "returns unhandled interrupt when address1 contains URL"
            ),

            // MARK: - Address Field Is Required

            TestCase(
                errorCode: .addressFieldIsRequired,
                field: ["addresses", "0", "address", "deliveryAddress", "firstName"],
                shippingCountry: "US",
                expectedAction: .showError(.nameInvalid),
                expectedField: nil,
                expectedMessageKey: "errors.missing.first_name",
                testDescription: "returns nameInvalid error when firstName is required"
            ),
            TestCase(
                errorCode: .addressFieldIsRequired,
                field: ["addresses", "0", "address", "deliveryAddress", "address1"],
                shippingCountry: "US",
                expectedAction: .showError(.deliveryAddressInvalid),
                expectedField: CNPostalAddressStreetKey,
                expectedMessageKey: "errors.missing.address1",
                testDescription: "returns deliveryAddressInvalid error when address1 is required"
            ),

            // MARK: - Invalid Errors

            TestCase(
                errorCode: .invalid,
                field: ["buyerIdentity", "email"],
                shippingCountry: "US",
                expectedAction: .showError(.emailInvalid),
                expectedField: nil,
                expectedMessageKey: "errors.invalid.email",
                testDescription: "returns emailInvalid error when email is invalid"
            ),
            TestCase(
                errorCode: .invalid,
                field: ["input", "lines", "0", "quantity"],
                shippingCountry: "US",
                expectedAction: .interrupt(.outOfStock),
                expectedField: nil,
                expectedMessageKey: nil,
                testDescription: "returns outOfStock interrupt when quantity is invalid"
            ),
            TestCase(
                errorCode: .invalid,
                field: ["buyerIdentity", "phone"],
                shippingCountry: "US",
                expectedAction: .showError(.phoneNumberInvalid),
                expectedField: nil,
                expectedMessageKey: "errors.invalid.phone",
                testDescription: "returns phoneNumberInvalid error when phone is invalid"
            ),

            // MARK: - Unserviceable Address Errors

            TestCase(
                errorCode: .zipCodeNotSupported,
                field: nil,
                shippingCountry: "US",
                expectedAction: .showError(.addressUnserviceableError),
                expectedField: nil,
                expectedMessageKey: nil,
                testDescription: "returns addressUnserviceableError when zip code not supported"
            ),

            // MARK: - Postal Code Errors

            TestCase(
                errorCode: .invalidZipCodeForCountry,
                field: nil,
                shippingCountry: "US",
                expectedAction: .showError(.deliveryAddressInvalid),
                expectedField: CNPostalAddressPostalCodeKey,
                expectedMessageKey: "errors.invalid.postal_code",
                testDescription: "returns deliveryAddressInvalid error when zip code invalid for country"
            ),

            // MARK: - Province Not Found - Country Specific

            TestCase(
                errorCode: .provinceNotFound,
                field: nil,
                shippingCountry: "AE",
                expectedAction: .showError(.deliveryAddressInvalid),
                expectedField: CNPostalAddressSubLocalityKey,
                expectedMessageKey: "errors.invalid.emirate",
                testDescription: "returns deliveryAddressInvalid error for emirate when province not found in UAE"
            ),
            TestCase(
                errorCode: .provinceNotFound,
                field: nil,
                shippingCountry: "US",
                expectedAction: .showError(.deliveryAddressInvalid),
                expectedField: CNPostalAddressSubAdministrativeAreaKey,
                expectedMessageKey: "errors.invalid.zone",
                testDescription: "returns deliveryAddressInvalid error for zone when province not found in non-UAE country"
            ),

            // MARK: - Payment Method Not Supported

            TestCase(
                errorCode: .paymentMethodNotSupported,
                field: ["payment", "walletPaymentMethod", "applePayWalletContent"],
                shippingCountry: "US",
                expectedAction: .interrupt(.other),
                expectedField: nil,
                expectedMessageKey: nil,
                testDescription: "returns other interrupt when Apple Pay not supported"
            ),

            // MARK: - Custom Validation

            TestCase(
                errorCode: .validationCustom,
                field: nil,
                shippingCountry: "US",
                expectedAction: .interrupt(.other),
                expectedField: nil,
                expectedMessageKey: nil,
                testDescription: "returns other interrupt for custom validation errors"
            ),

            // MARK: - Unknown Error Codes

            TestCase(
                errorCode: .unknownValue,
                field: nil,
                shippingCountry: "US",
                expectedAction: .interrupt(.unhandled),
                expectedField: nil,
                expectedMessageKey: nil,
                testDescription: "returns unhandled interrupt for unknown error codes"
            )
        ]

        for testCase in testCases {
            let userError = createCartUserError(code: testCase.errorCode, field: testCase.field)
            let result = ErrorHandler.map(errors: [userError], shippingCountry: testCase.shippingCountry, cart: nil)

            switch (testCase.expectedAction, result) {
            case let (.showError(.emailInvalid), .showError(errors)):
                XCTAssertEqual(errors.count, 1, "Test failed: \(testCase.testDescription)")
                XCTAssertNotNil(errors.first, "Test failed: \(testCase.testDescription)")

            case let (.showError(.phoneNumberInvalid), .showError(errors)):
                XCTAssertEqual(errors.count, 1, "Test failed: \(testCase.testDescription)")
                XCTAssertNotNil(errors.first, "Test failed: \(testCase.testDescription)")

            case let (.showError(.nameInvalid), .showError(errors)):
                XCTAssertEqual(errors.count, 1, "Test failed: \(testCase.testDescription)")
                XCTAssertNotNil(errors.first, "Test failed: \(testCase.testDescription)")

            case let (.showError(.deliveryAddressInvalid), .showError(errors)):
                XCTAssertEqual(errors.count, 1, "Test failed: \(testCase.testDescription)")
                XCTAssertNotNil(errors.first, "Test failed: \(testCase.testDescription)")

            case let (.showError(.addressUnserviceableError), .showError(errors)):
                XCTAssertEqual(errors.count, 1, "Test failed: \(testCase.testDescription)")
                XCTAssertNotNil(errors.first, "Test failed: \(testCase.testDescription)")

            case let (.interrupt(expectedReason), .interrupt(actualReason, _)):
                XCTAssertEqual(actualReason, expectedReason, "Test failed: \(testCase.testDescription)")

            default:
                XCTFail("Unexpected result type. Expected: \(testCase.expectedAction), Got: \(result). Test: \(testCase.testDescription)")
            }
        }
    }

    // MARK: - Additional Individual Tests

    func testMap_withEmptyErrors_returnsOtherInterrupt() {
        let result = ErrorHandler.map(errors: [], shippingCountry: "US", cart: nil)

        switch result {
        case let .interrupt(reason, checkoutURL):
            XCTAssertEqual(reason, .other)
            XCTAssertNil(checkoutURL)
        default:
            XCTFail("Expected interrupt with .other reason for empty errors")
        }
    }

    func testMap_withMultipleErrors_returnsHighestPriorityAction() {
        let nameError = createCartUserError(code: .addressFieldIsRequired, field: ["addresses", "0", "address", "deliveryAddress", "firstName"])
        let emailError = createCartUserError(code: .invalid, field: ["buyerIdentity", "email"])
        let unhandledError = createCartUserError(code: .unknownValue, field: nil)

        let result = ErrorHandler.map(errors: [unhandledError, nameError, emailError], shippingCountry: "US", cart: nil)

        // Should return combined show errors (higher priority than interrupt)
        switch result {
        case let .showError(errors):
            XCTAssertEqual(errors.count, 2, "nameError and emailError should be combined")
        default:
            XCTFail("Expected showError action with combined errors")
        }
    }

    func testMap_withNilErrorCode() {
        let error = createCartUserError(code: nil, field: nil)
        let result = ErrorHandler.map(errors: [error], shippingCountry: "US", cart: nil)

        switch result {
        case let .interrupt(reason, _):
            XCTAssertEqual(reason, .unhandled)
        default:
            XCTFail("Expected unhandled interrupt for nil error code")
        }
    }
}

// MARK: - Mock Helper Methods

@available(iOS 17.0, *)
private func createCartUserError(code: StorefrontAPI.CartErrorCode?, field: [String]?) -> StorefrontAPI.CartUserError {
    return StorefrontAPI.CartUserError(
        code: code,
        message: "Mock error message",
        field: field
    )
}
