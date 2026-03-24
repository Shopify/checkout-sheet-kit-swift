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

@testable import ShopifyAcceleratedCheckouts
import XCTest

@available(iOS 17.0, *)
class ErrorHandler_CartPrepareForCompletionTests: XCTestCase {
    func testMap_whenPayloadResultIsNil_returnsInterruptWithOtherReason() {
        let payload = StorefrontAPI.CartPrepareForCompletionPayload(
            result: nil,
            userErrors: []
        )

        let result = ErrorHandler.map(stage: .prepare(payload), shippingCountry: nil)

        switch result {
        case let .interrupt(reason, checkoutURL):
            XCTAssertEqual(reason, .other)
            XCTAssertNil(checkoutURL)
        default:
            XCTFail("Expected interrupt with .other reason when payload.result is nil")
        }
    }

    func testMap_whenResultIsCartStatusNotReady_returnsInterruptWithCartNotReadyReason() {
        let cartStatusNotReady = StorefrontAPI.CartStatusNotReady(
            cart: nil,
            errors: []
        )
        let payload = StorefrontAPI.CartPrepareForCompletionPayload(
            result: .notReady(cartStatusNotReady),
            userErrors: []
        )

        let result = ErrorHandler.map(stage: .prepare(payload), shippingCountry: nil)

        switch result {
        case let .interrupt(reason, checkoutURL):
            XCTAssertEqual(reason, .cartNotReady)
            XCTAssertNil(checkoutURL)
        default:
            XCTFail("Expected interrupt with .cartNotReady reason for CartStatusNotReady result")
        }
    }

    func testMap_whenResultIsCartThrottled_returnsInterruptWithCartThrottledReason() {
        let cartThrottled = StorefrontAPI.CartThrottled(
            pollAfter: GraphQLScalars.DateTime(Date())
        )
        let payload = StorefrontAPI.CartPrepareForCompletionPayload(
            result: .throttled(cartThrottled),
            userErrors: []
        )

        let result = ErrorHandler.map(stage: .prepare(payload), shippingCountry: nil)

        switch result {
        case let .interrupt(reason, checkoutURL):
            XCTAssertEqual(reason, .cartThrottled)
            XCTAssertNil(checkoutURL)
        default:
            XCTFail("Expected interrupt with .cartThrottled reason for CartThrottled result")
        }
    }

    func testMap_whenResultIsCartStatusReady_returnsInterruptWithOtherReason() {
        let cartStatusReady = StorefrontAPI.CartStatusReady(
            cart: nil,
            checkoutURL: nil
        )
        let payload = StorefrontAPI.CartPrepareForCompletionPayload(
            result: .ready(cartStatusReady),
            userErrors: []
        )

        let result = ErrorHandler.map(stage: .prepare(payload), shippingCountry: nil)

        switch result {
        case let .interrupt(reason, checkoutURL):
            XCTAssertEqual(reason, .other)
            XCTAssertNil(checkoutURL)
        default:
            XCTFail("Expected interrupt with .other reason for success result (CartStatusReady)")
        }
    }

    // MARK: - Apple Pay Resolvable Violation Filtering

    func testMap_whenNotReadyWithOnlyApplePayResolvableErrors_returnsContinueFlow() {
        let errors: [StorefrontAPI.CartCompletionError] = [
            .init(code: .deliveryFirstNameRequired, message: "Enter a first name"),
            .init(code: .deliveryLastNameRequired, message: "Enter a last name"),
            .init(code: .deliveryAddress1Required, message: "Enter an address"),
            .init(code: .deliveryPhoneNumberRequired, message: "Enter a phone number")
        ]
        let payload = StorefrontAPI.CartPrepareForCompletionPayload(
            result: .notReady(StorefrontAPI.CartStatusNotReady(cart: nil, errors: errors)),
            userErrors: []
        )

        let result = ErrorHandler.map(stage: .prepare(payload), shippingCountry: nil)

        switch result {
        case .continueFlow:
            break
        default:
            XCTFail("Expected continueFlow when all errors are Apple Pay resolvable, got: \(result)")
        }
    }

    func testMap_whenNotReadyWithBuyerIdentityErrors_returnsContinueFlow() {
        let errors: [StorefrontAPI.CartCompletionError] = [
            .init(code: .buyerIdentityEmailRequired, message: "Email required"),
            .init(code: .buyerIdentityEmailIsInvalid, message: "Email invalid")
        ]
        let payload = StorefrontAPI.CartPrepareForCompletionPayload(
            result: .notReady(StorefrontAPI.CartStatusNotReady(cart: nil, errors: errors)),
            userErrors: []
        )

        let result = ErrorHandler.map(stage: .prepare(payload), shippingCountry: nil)

        switch result {
        case .continueFlow:
            break
        default:
            XCTFail("Expected continueFlow when all errors are BUYER_IDENTITY_*, got: \(result)")
        }
    }

    func testMap_whenNotReadyWithMixOfApplePayResolvableAndActionableError_returnsActionForActionableError() {
        let errors: [StorefrontAPI.CartCompletionError] = [
            .init(code: .deliveryFirstNameRequired, message: "Enter a first name"),
            .init(code: .merchandiseOutOfStock, message: "Item out of stock")
        ]
        let payload = StorefrontAPI.CartPrepareForCompletionPayload(
            result: .notReady(StorefrontAPI.CartStatusNotReady(cart: nil, errors: errors)),
            userErrors: []
        )

        let result = ErrorHandler.map(stage: .prepare(payload), shippingCountry: nil)

        switch result {
        case let .interrupt(reason, _):
            XCTAssertEqual(reason, .outOfStock)
        default:
            XCTFail("Expected interrupt with .outOfStock for actionable error")
        }
    }

    func testMap_whenNotReadyWithMultipleActionableErrors_returnsHighestPriorityAction() {
        let errors: [StorefrontAPI.CartCompletionError] = [
            .init(code: .deliveryFirstNameRequired, message: "Apple Pay resolvable - filtered"),
            .init(code: .merchandiseOutOfStock, message: "Out of stock"),
            .init(code: .taxesMustBeDefined, message: "Tax error")
        ]
        let payload = StorefrontAPI.CartPrepareForCompletionPayload(
            result: .notReady(StorefrontAPI.CartStatusNotReady(cart: nil, errors: errors)),
            userErrors: []
        )

        let result = ErrorHandler.map(stage: .prepare(payload), shippingCountry: nil)

        switch result {
        case let .interrupt(reason, _):
            XCTAssertEqual(reason, .outOfStock, "outOfStock should take priority over unhandled tax error")
        default:
            XCTFail("Expected interrupt for multiple actionable errors")
        }
    }

    func testMap_whenNotReadyWithMultipleDeceleration_returnsHighestPriorityInterrupt() {
        let errors: [StorefrontAPI.CartCompletionError] = [
            .init(code: .merchandiseNotEnoughStockAvailable, message: "Not enough stock"),
            .init(code: .paymentsUnacceptablePaymentAmount, message: "Payment amount issue")
        ]
        let payload = StorefrontAPI.CartPrepareForCompletionPayload(
            result: .notReady(StorefrontAPI.CartStatusNotReady(cart: nil, errors: errors)),
            userErrors: []
        )

        let result = ErrorHandler.map(stage: .prepare(payload), shippingCountry: nil)

        switch result {
        case let .interrupt(reason, _):
            XCTAssertEqual(reason, .notEnoughStock, "notEnoughStock should win when paymentsUnacceptable is filtered by filterGenericViolations")
        default:
            XCTFail("Expected interrupt for multiple deceleration errors")
        }
    }

    func testFilterApplePayResolvableViolations_preservesNonResolvableErrors() {
        let errors: [StorefrontAPI.CartCompletionError] = [
            .init(code: .deliveryFirstNameRequired, message: ""),
            .init(code: .merchandiseOutOfStock, message: ""),
            .init(code: .buyerIdentityEmailRequired, message: ""),
            .init(code: .paymentsUnacceptablePaymentAmount, message: "")
        ]

        let filtered = ErrorHandler.filterApplePayResolvableViolations(errors: errors)

        XCTAssertEqual(filtered.count, 2)
        XCTAssertEqual(filtered[0].code, .merchandiseOutOfStock)
        XCTAssertEqual(filtered[1].code, .paymentsUnacceptablePaymentAmount)
    }

    func testFilterApplePayResolvableViolations_preservesUnknownDeliveryCodes() throws {
        let json = """
        {"code": "DELIVERY_DETAIL_CHANGED", "message": "Delivery details changed"}
        """
        let error = try JSONDecoder().decode(StorefrontAPI.CartCompletionError.self, from: Data(json.utf8))

        XCTAssertEqual(error.code, .unknownValue)
        XCTAssertEqual(error.rawCode, "DELIVERY_DETAIL_CHANGED")

        let filtered = ErrorHandler.filterApplePayResolvableViolations(errors: [error])
        XCTAssertEqual(filtered.count, 1, "Unknown DELIVERY_* codes should not be assumed Apple Pay resolvable")
    }

    func testFilterApplePayResolvableViolations_filtersDeliveryNoDeliveryAvailableForMerchandiseLine() {
        let errors: [StorefrontAPI.CartCompletionError] = [
            .init(code: .deliveryNoDeliveryAvailableForMerchandiseLine, message: "Can't ship to address")
        ]

        let filtered = ErrorHandler.filterApplePayResolvableViolations(errors: errors)

        XCTAssertEqual(filtered.count, 0)
    }

    func testFilterApplePayResolvableViolations_preservesDeliveryNoDeliveryAvailable() {
        let errors: [StorefrontAPI.CartCompletionError] = [
            .init(code: .deliveryNoDeliveryAvailable, message: "No delivery available")
        ]

        let filtered = ErrorHandler.filterApplePayResolvableViolations(errors: errors)

        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered[0].code, .deliveryNoDeliveryAvailable)
    }

    func testMap_whenNotReadyWithResolvableAndDeliveryNoDeliveryForMerchandiseLine_returnsContinueFlow() {
        let errors: [StorefrontAPI.CartCompletionError] = [
            .init(code: .deliveryLastNameRequired, message: "Enter a last name"),
            .init(code: .deliveryAddress1Required, message: "Enter an address"),
            .init(code: .deliveryNoDeliveryAvailableForMerchandiseLine, message: "Can't be shipped to your address")
        ]
        let payload = StorefrontAPI.CartPrepareForCompletionPayload(
            result: .notReady(StorefrontAPI.CartStatusNotReady(cart: nil, errors: errors)),
            userErrors: []
        )

        let result = ErrorHandler.map(stage: .prepare(payload), shippingCountry: nil)

        switch result {
        case .continueFlow:
            break
        default:
            XCTFail("Expected continueFlow when all errors are Apple Pay resolvable, got: \(result)")
        }
    }
}
