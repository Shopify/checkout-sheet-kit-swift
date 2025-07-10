@testable import ShopifyAcceleratedCheckouts
import XCTest

class ErrorHandler_CartPrepareForCompletionTests: XCTestCase {
    func testMap_whenPayloadResultIsNil_returnsInterruptWithOtherReason() {
        let payload = StorefrontAPI.CartPrepareForCompletionPayload(
            result: nil,
            userErrors: []
        )

        let result = ErrorHandler.map(payload: payload)

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

        let result = ErrorHandler.map(payload: payload)

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

        let result = ErrorHandler.map(payload: payload)

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

        let result = ErrorHandler.map(payload: payload)

        switch result {
        case let .interrupt(reason, checkoutURL):
            XCTAssertEqual(reason, .other)
            XCTAssertNil(checkoutURL)
        default:
            XCTFail("Expected interrupt with .other reason for success result (CartStatusReady)")
        }
    }

    // Note: Testing for unknown types is not applicable with the current enum-based implementation
    // as Swift's exhaustive pattern matching ensures all cases are handled
}
