import PassKit
@testable import ShopifyAcceleratedCheckouts
import XCTest

class ErrorHandler_CartSubmitForCompletionTests: XCTestCase {
    struct TestCase {
        let errorCode: StorefrontAPI.SubmissionErrorCode
        let country: String
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
                case billingAddressInvalid
                case addressUnserviceableError
            }
        }
    }

    func testGetErrorAction_allErrorCodes() {
        let testCases: [TestCase] = [
            // Contact information errors
            TestCase(
                errorCode: .buyerIdentityEmailRequired,
                country: "US",
                expectedAction: .showError(.emailInvalid),
                expectedField: nil,
                expectedMessageKey: "errors.missing.email",
                testDescription: "returns emailInvalid error when email is required"
            ),
            TestCase(
                errorCode: .buyerIdentityEmailIsInvalid,
                country: "US",
                expectedAction: .showError(.emailInvalid),
                expectedField: nil,
                expectedMessageKey: "errors.invalid.email",
                testDescription: "returns emailInvalid error when email is invalid"
            ),
            TestCase(
                errorCode: .deliveryPhoneNumberRequired,
                country: "US",
                expectedAction: .showError(.phoneNumberInvalid),
                expectedField: nil,
                expectedMessageKey: "errors.missing.phone",
                testDescription: "returns phoneNumberInvalid error when phone is required"
            ),
            TestCase(
                errorCode: .deliveryPhoneNumberInvalid,
                country: "US",
                expectedAction: .showError(.phoneNumberInvalid),
                expectedField: nil,
                expectedMessageKey: "errors.invalid.phone",
                testDescription: "returns phoneNumberInvalid error when phone is invalid"
            ),

            // Name validation errors
            TestCase(
                errorCode: .deliveryFirstNameRequired,
                country: "US",
                expectedAction: .showError(.nameInvalid),
                expectedField: nil,
                expectedMessageKey: "errors.missing.first_name",
                testDescription: "returns nameInvalid error when delivery first name is required"
            ),
            TestCase(
                errorCode: .paymentsFirstNameRequired,
                country: "US",
                expectedAction: .showError(.nameInvalid),
                expectedField: nil,
                expectedMessageKey: "errors.missing.first_name",
                testDescription: "returns nameInvalid error when payments first name is required"
            ),
            TestCase(
                errorCode: .deliveryFirstNameInvalid,
                country: "US",
                expectedAction: .showError(.nameInvalid),
                expectedField: nil,
                expectedMessageKey: "errors.invalid.first_name",
                testDescription: "returns nameInvalid error when delivery first name is invalid"
            ),
            TestCase(
                errorCode: .deliveryFirstNameTooLong,
                country: "US",
                expectedAction: .showError(.nameInvalid),
                expectedField: nil,
                expectedMessageKey: "errors.too_long.first_name",
                testDescription: "returns nameInvalid error when delivery first name is too long"
            ),
            TestCase(
                errorCode: .deliveryLastNameRequired,
                country: "US",
                expectedAction: .showError(.nameInvalid),
                expectedField: nil,
                expectedMessageKey: "errors.missing.last_name",
                testDescription: "returns nameInvalid error when delivery last name is required"
            ),
            TestCase(
                errorCode: .paymentsLastNameTooLong,
                country: "US",
                expectedAction: .showError(.nameInvalid),
                expectedField: nil,
                expectedMessageKey: "errors.too_long.last_name",
                testDescription: "returns nameInvalid error when payments last name is too long"
            ),

            // Delivery address errors
            TestCase(
                errorCode: .deliveryAddress1Required,
                country: "US",
                expectedAction: .showError(.deliveryAddressInvalid),
                expectedField: CNPostalAddressStreetKey,
                expectedMessageKey: "errors.missing.address1",
                testDescription: "returns deliveryAddressInvalid error when address1 is required"
            ),
            TestCase(
                errorCode: .deliveryAddress1Invalid,
                country: "US",
                expectedAction: .showError(.deliveryAddressInvalid),
                expectedField: CNPostalAddressStreetKey,
                expectedMessageKey: "errors.invalid.address1",
                testDescription: "returns deliveryAddressInvalid error when address1 is invalid"
            ),
            TestCase(
                errorCode: .deliveryAddress2TooLong,
                country: "US",
                expectedAction: .showError(.deliveryAddressInvalid),
                expectedField: CNPostalAddressStreetKey,
                expectedMessageKey: "errors.too_long.address2",
                testDescription: "returns deliveryAddressInvalid error when address2 is too long"
            ),
            TestCase(
                errorCode: .deliveryPostalCodeRequired,
                country: "US",
                expectedAction: .showError(.deliveryAddressInvalid),
                expectedField: CNPostalAddressPostalCodeKey,
                expectedMessageKey: "errors.missing.postal_code",
                testDescription: "returns deliveryAddressInvalid error when postal code is required"
            ),
            TestCase(
                errorCode: .deliveryPostalCodeInvalid,
                country: "US",
                expectedAction: .showError(.deliveryAddressInvalid),
                expectedField: CNPostalAddressPostalCodeKey,
                expectedMessageKey: "errors.invalid.postal_code",
                testDescription: "returns deliveryAddressInvalid error when postal code is invalid"
            ),
            TestCase(
                errorCode: .deliveryInvalidPostalCodeForCountry,
                country: "US",
                expectedAction: .showError(.deliveryAddressInvalid),
                expectedField: CNPostalAddressPostalCodeKey,
                expectedMessageKey: "errors.invalid.postal_code",
                testDescription: "returns deliveryAddressInvalid error when postal code is invalid for country"
            ),
            TestCase(
                errorCode: .deliveryCityRequired,
                country: "US",
                expectedAction: .showError(.deliveryAddressInvalid),
                expectedField: CNPostalAddressCityKey,
                expectedMessageKey: "errors.missing.city",
                testDescription: "returns deliveryAddressInvalid error when city is required"
            ),
            TestCase(
                errorCode: .deliveryCityInvalid,
                country: "US",
                expectedAction: .showError(.deliveryAddressInvalid),
                expectedField: CNPostalAddressCityKey,
                expectedMessageKey: "errors.invalid.city",
                testDescription: "returns deliveryAddressInvalid error when city is invalid"
            ),
            TestCase(
                errorCode: .deliveryCityTooLong,
                country: "US",
                expectedAction: .showError(.deliveryAddressInvalid),
                expectedField: CNPostalAddressCityKey,
                expectedMessageKey: "errors.too_long.city",
                testDescription: "returns deliveryAddressInvalid error when city is too long"
            ),

            // Zone validation - UAE specific
            TestCase(
                errorCode: .deliveryZoneNotFound,
                country: "AE",
                expectedAction: .showError(.deliveryAddressInvalid),
                expectedField: CNPostalAddressSubLocalityKey,
                expectedMessageKey: "errors.invalid.emirate",
                testDescription: "returns deliveryAddressInvalid error for emirate when zone not found in UAE"
            ),
            TestCase(
                errorCode: .deliveryZoneNotFound,
                country: "US",
                expectedAction: .showError(.deliveryAddressInvalid),
                expectedField: CNPostalAddressSubAdministrativeAreaKey,
                expectedMessageKey: "errors.invalid.zone",
                testDescription: "returns deliveryAddressInvalid error for zone when zone not found in non-UAE country"
            ),
            TestCase(
                errorCode: .deliveryZoneRequiredForCountry,
                country: "AE",
                expectedAction: .showError(.deliveryAddressInvalid),
                expectedField: CNPostalAddressSubLocalityKey,
                expectedMessageKey: "errors.missing.emirate",
                testDescription: "returns deliveryAddressInvalid error for emirate when zone required in UAE"
            ),
            TestCase(
                errorCode: .deliveryZoneRequiredForCountry,
                country: "US",
                expectedAction: .showError(.deliveryAddressInvalid),
                expectedField: CNPostalAddressSubAdministrativeAreaKey,
                expectedMessageKey: "errors.missing.zone",
                testDescription: "returns deliveryAddressInvalid error for zone when zone required in non-UAE country"
            ),
            TestCase(
                errorCode: .deliveryCountryRequired,
                country: "US",
                expectedAction: .showError(.deliveryAddressInvalid),
                expectedField: CNPostalAddressCountryKey,
                expectedMessageKey: "errors.missing.country",
                testDescription: "returns deliveryAddressInvalid error when country is required"
            ),

            // Billing address errors
            TestCase(
                errorCode: .paymentsAddress1Required,
                country: "US",
                expectedAction: .showError(.billingAddressInvalid),
                expectedField: CNPostalAddressStreetKey,
                expectedMessageKey: "errors.missing.address1",
                testDescription: "returns billingAddressInvalid error when billing address1 is required"
            ),
            TestCase(
                errorCode: .paymentsPostalCodeInvalid,
                country: "US",
                expectedAction: .showError(.billingAddressInvalid),
                expectedField: CNPostalAddressPostalCodeKey,
                expectedMessageKey: "errors.invalid.postal_code",
                testDescription: "returns billingAddressInvalid error when billing postal code is invalid"
            ),
            TestCase(
                errorCode: .paymentsBillingAddressZoneNotFound,
                country: "AE",
                expectedAction: .showError(.billingAddressInvalid),
                expectedField: CNPostalAddressSubLocalityKey,
                expectedMessageKey: "errors.invalid.emirate",
                testDescription: "returns billingAddressInvalid error for emirate when billing zone not found in UAE"
            ),
            TestCase(
                errorCode: .paymentsCountryRequired,
                country: "US",
                expectedAction: .showError(.billingAddressInvalid),
                expectedField: CNPostalAddressCountryKey,
                expectedMessageKey: "errors.missing.country",
                testDescription: "returns billingAddressInvalid error when billing country is required"
            ),

            // Address unserviceable errors
            TestCase(
                errorCode: .deliveryNoDeliveryAvailable,
                country: "US",
                expectedAction: .showError(.addressUnserviceableError),
                expectedField: nil,
                expectedMessageKey: nil,
                testDescription: "returns addressUnserviceableError when no delivery available"
            ),
            TestCase(
                errorCode: .noDeliveryGroupSelected,
                country: "US",
                expectedAction: .showError(.addressUnserviceableError),
                expectedField: nil,
                expectedMessageKey: nil,
                testDescription: "returns addressUnserviceableError when no delivery group selected"
            ),

            // Interrupt errors - Unhandled
            TestCase(
                errorCode: .deliveryAddressRequired,
                country: "US",
                expectedAction: .interrupt(.unhandled),
                expectedField: nil,
                expectedMessageKey: nil,
                testDescription: "returns unhandled interrupt when delivery address is required"
            ),
            TestCase(
                errorCode: .buyerIdentityPhoneIsInvalid,
                country: "US",
                expectedAction: .interrupt(.unhandled),
                expectedField: nil,
                expectedMessageKey: nil,
                testDescription: "returns unhandled interrupt for buyer identity phone invalid"
            ),
            TestCase(
                errorCode: .deliveryCompanyRequired,
                country: "US",
                expectedAction: .interrupt(.unhandled),
                expectedField: nil,
                expectedMessageKey: nil,
                testDescription: "returns unhandled interrupt when company field is required"
            ),
            TestCase(
                errorCode: .paymentsCreditCardBaseExpired,
                country: "US",
                expectedAction: .interrupt(.unhandled),
                expectedField: nil,
                expectedMessageKey: nil,
                testDescription: "returns unhandled interrupt for credit card errors"
            ),
            TestCase(
                errorCode: .paymentsMethodRequired,
                country: "US",
                expectedAction: .interrupt(.unhandled),
                expectedField: nil,
                expectedMessageKey: nil,
                testDescription: "returns unhandled interrupt for payment method errors"
            ),

            // Interrupt errors - Specific reasons
            TestCase(
                errorCode: .paymentsUnacceptablePaymentAmount,
                country: "US",
                expectedAction: .interrupt(.dynamicTax),
                expectedField: nil,
                expectedMessageKey: nil,
                testDescription: "returns dynamicTax interrupt for unacceptable payment amount"
            ),
            TestCase(
                errorCode: .merchandiseNotEnoughStockAvailable,
                country: "US",
                expectedAction: .interrupt(.notEnoughStock),
                expectedField: nil,
                expectedMessageKey: nil,
                testDescription: "returns notEnoughStock interrupt when not enough stock available"
            ),
            TestCase(
                errorCode: .merchandiseOutOfStock,
                country: "US",
                expectedAction: .interrupt(.outOfStock),
                expectedField: nil,
                expectedMessageKey: nil,
                testDescription: "returns outOfStock interrupt when merchandise is out of stock"
            ),
            TestCase(
                errorCode: .merchandiseLineLimitReached,
                country: "US",
                expectedAction: .interrupt(.outOfStock),
                expectedField: nil,
                expectedMessageKey: nil,
                testDescription: "returns outOfStock interrupt when merchandise line limit reached"
            ),
            TestCase(
                errorCode: .validationCustom,
                country: "US",
                expectedAction: .interrupt(.other),
                expectedField: nil,
                expectedMessageKey: nil,
                testDescription: "returns other interrupt for custom validation errors"
            ),
            TestCase(
                errorCode: .error,
                country: "US",
                expectedAction: .interrupt(.unhandled),
                expectedField: nil,
                expectedMessageKey: nil,
                testDescription: "returns unhandled interrupt for generic errors"
            )
        ]

        for testCase in testCases {
            let error = StorefrontAPI.SubmissionError(
                code: testCase.errorCode,
                message: "Test error message"
            )
            let checkoutURL = URL(string: "https://example.com")
            let submitFailed = StorefrontAPI.SubmitFailed(
                checkoutUrl: checkoutURL.map { GraphQLScalars.URL($0) },
                errors: [error]
            )
            let payload = StorefrontAPI.CartSubmitForCompletionPayload(
                result: .failed(submitFailed),
                userErrors: []
            )

            let result = ErrorHandler.map(payload: payload, shippingCountry: testCase.country)

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

            case let (.showError(.billingAddressInvalid), .showError(errors)):
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

    // MARK: - Main map function tests (non-parameterized)

    func testMap_whenPayloadResultIsNil_returnsInterruptWithOtherReason() {
        let payload = StorefrontAPI.CartSubmitForCompletionPayload(
            result: nil,
            userErrors: []
        )

        let result = ErrorHandler.map(payload: payload, shippingCountry: "US")

        switch result {
        case let .interrupt(reason, checkoutURL):
            XCTAssertEqual(reason, .other)
            XCTAssertNil(checkoutURL)
        default:
            XCTFail("Expected interrupt with .other reason when payload.result is nil")
        }
    }

    func testMap_whenResultIsSubmitAlreadyAccepted_returnsInterruptWithOtherReason() {
        let submitAlreadyAccepted = StorefrontAPI.SubmitAlreadyAccepted(
            attemptId: "test-attempt-id"
        )
        let payload = StorefrontAPI.CartSubmitForCompletionPayload(
            result: .alreadyAccepted(submitAlreadyAccepted),
            userErrors: []
        )

        let result = ErrorHandler.map(payload: payload, shippingCountry: "US")

        switch result {
        case let .interrupt(reason, checkoutURL):
            XCTAssertEqual(reason, .other)
            XCTAssertNil(checkoutURL)
        default:
            XCTFail("Expected interrupt with .other reason for SubmitAlreadyAccepted")
        }
    }

    func testMap_whenResultIsSubmitThrottled_returnsInterruptWithCartThrottledReason() {
        let submitThrottled = StorefrontAPI.SubmitThrottled(
            pollAfter: GraphQLScalars.DateTime(Date())
        )
        let payload = StorefrontAPI.CartSubmitForCompletionPayload(
            result: .throttled(submitThrottled),
            userErrors: []
        )

        let result = ErrorHandler.map(payload: payload, shippingCountry: "US")

        switch result {
        case let .interrupt(reason, checkoutURL):
            XCTAssertEqual(reason, .cartThrottled)
            XCTAssertNil(checkoutURL)
        default:
            XCTFail("Expected interrupt with .cartThrottled reason for SubmitThrottled")
        }
    }

    func testFilterGenericViolations_withOnlyPaymentsUnacceptablePaymentAmount_returnsError() {
        let error = StorefrontAPI.SubmissionError(
            code: .paymentsUnacceptablePaymentAmount,
            message: "Test error"
        )
        let submitFailed = StorefrontAPI.SubmitFailed(
            checkoutUrl: nil,
            errors: [error]
        )
        let payload = StorefrontAPI.CartSubmitForCompletionPayload(
            result: .failed(submitFailed),
            userErrors: []
        )

        let result = ErrorHandler.map(payload: payload, shippingCountry: "US")

        switch result {
        case let .interrupt(reason, _):
            XCTAssertEqual(reason, .dynamicTax)
        default:
            XCTFail("Expected interrupt with .dynamicTax reason")
        }
    }

    func testFilterGenericViolations_withMultipleErrorsIncludingPaymentsUnacceptablePaymentAmount_filtersOutPaymentsUnacceptablePaymentAmount() {
        let error1 = StorefrontAPI.SubmissionError(
            code: .paymentsUnacceptablePaymentAmount,
            message: "Payment amount error"
        )
        let error2 = StorefrontAPI.SubmissionError(
            code: .buyerIdentityEmailRequired,
            message: "Email required"
        )
        let submitFailed = StorefrontAPI.SubmitFailed(
            checkoutUrl: nil,
            errors: [error1, error2]
        )
        let payload = StorefrontAPI.CartSubmitForCompletionPayload(
            result: .failed(submitFailed),
            userErrors: []
        )

        let result = ErrorHandler.map(payload: payload, shippingCountry: "US")

        // Should return the email error, not the payment amount error
        switch result {
        case let .showError(errors):
            XCTAssertEqual(errors.count, 1)
            XCTAssertNotNil(errors.first, "Should return an error")
        default:
            XCTFail("Expected showError action")
        }
    }
}
