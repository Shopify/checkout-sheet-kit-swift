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
