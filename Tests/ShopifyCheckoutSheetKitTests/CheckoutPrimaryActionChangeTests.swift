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

class CheckoutPrimaryActionChangeEventTests: XCTestCase {
    // MARK: - Basic Decoding Tests

    func testDecodeWithEnabledAndPayAction() throws {
        let jsonString = """
        {
            "jsonrpc": "2.0",
            "method": "checkout.primaryActionChange",
            "params": {
                "state": "enabled",
                "action": "pay",
                "cart": \(createTestCartJSON())
            }
        }
        """
        let data = jsonString.data(using: .utf8)!
        let event = try CheckoutPrimaryActionChangeEvent.decode(from: data)

        XCTAssertEqual(event.state, .enabled)
        XCTAssertEqual(event.action, .pay)
        XCTAssertEqual(event.cart.id, "gid://shopify/Cart/test-cart-123")
    }

    func testDecodeWithDisabledAndReviewAction() throws {
        let jsonString = """
        {
            "jsonrpc": "2.0",
            "method": "checkout.primaryActionChange",
            "params": {
                "state": "disabled",
                "action": "review",
                "cart": \(createTestCartJSON())
            }
        }
        """
        let data = jsonString.data(using: .utf8)!
        let event = try CheckoutPrimaryActionChangeEvent.decode(from: data)

        XCTAssertEqual(event.state, .disabled)
        XCTAssertEqual(event.action, .review)
        XCTAssertNotNil(event.cart)
    }

    func testDecodeWithLoadingState() throws {
        let jsonString = """
        {
            "jsonrpc": "2.0",
            "method": "checkout.primaryActionChange",
            "params": {
                "state": "loading",
                "action": "pay",
                "cart": \(createTestCartJSON())
            }
        }
        """
        let data = jsonString.data(using: .utf8)!
        let event = try CheckoutPrimaryActionChangeEvent.decode(from: data)

        XCTAssertEqual(event.state, .loading)
        XCTAssertEqual(event.action, .pay)
    }

    // MARK: - Method Name Test

    func testMethodNameIsCorrect() {
        XCTAssertEqual(CheckoutPrimaryActionChangeEvent.method, "checkout.primaryActionChange")
    }

    // MARK: - State Enum Tests

    func testStateEnumValues() {
        XCTAssertEqual(CheckoutPrimaryActionChangeEvent.PrimaryActionState.enabled.rawValue, "enabled")
        XCTAssertEqual(CheckoutPrimaryActionChangeEvent.PrimaryActionState.disabled.rawValue, "disabled")
        XCTAssertEqual(CheckoutPrimaryActionChangeEvent.PrimaryActionState.loading.rawValue, "loading")
    }

    // MARK: - Action Enum Tests

    func testActionEnumValues() {
        XCTAssertEqual(CheckoutPrimaryActionChangeEvent.PrimaryAction.review.rawValue, "review")
        XCTAssertEqual(CheckoutPrimaryActionChangeEvent.PrimaryAction.pay.rawValue, "pay")
    }

    // MARK: - Cart Field Tests

    func testCartIncludesAllExpectedFields() throws {
        let jsonString = """
        {
            "jsonrpc": "2.0",
            "method": "checkout.primaryActionChange",
            "params": {
                "state": "enabled",
                "action": "pay",
                "cart": \(createTestCartJSON(
                    id: "gid://shopify/Cart/custom-cart-456",
                    totalAmount: "99.99",
                    email: "buyer@example.com"
                ))
            }
        }
        """
        let data = jsonString.data(using: .utf8)!
        let event = try CheckoutPrimaryActionChangeEvent.decode(from: data)

        XCTAssertEqual(event.cart.id, "gid://shopify/Cart/custom-cart-456")
        XCTAssertEqual(event.cart.cost.totalAmount.amount, "99.99")
        XCTAssertEqual(event.cart.cost.totalAmount.currencyCode, "USD")
        XCTAssertEqual(event.cart.buyerIdentity.email, "buyer@example.com")
    }

    // MARK: - Invalid JSON Tests

    func testDecodeThrowsErrorForInvalidJSONRPC() {
        let jsonString = """
        {
            "jsonrpc": "1.0",
            "method": "checkout.primaryActionChange",
            "params": {
                "state": "enabled",
                "action": "pay",
                "cart": \(createTestCartJSON())
            }
        }
        """
        let data = jsonString.data(using: .utf8)!

        XCTAssertThrowsError(try CheckoutPrimaryActionChangeEvent.decode(from: data)) { error in
            guard let bridgeError = error as? BridgeError else {
                XCTFail("Expected BridgeError, got \(type(of: error))")
                return
            }

            if case .invalidBridgeEvent = bridgeError {
                // Success - this is the expected error
            } else {
                XCTFail("Expected invalidBridgeEvent, got \(bridgeError)")
            }
        }
    }

    func testDecodeThrowsErrorForWrongMethod() {
        let jsonString = """
        {
            "jsonrpc": "2.0",
            "method": "checkout.wrongMethod",
            "params": {
                "state": "enabled",
                "action": "pay",
                "cart": \(createTestCartJSON())
            }
        }
        """
        let data = jsonString.data(using: .utf8)!

        XCTAssertThrowsError(try CheckoutPrimaryActionChangeEvent.decode(from: data)) { error in
            guard let bridgeError = error as? BridgeError else {
                XCTFail("Expected BridgeError, got \(type(of: error))")
                return
            }

            if case .invalidBridgeEvent = bridgeError {
                // Success - this is the expected error
            } else {
                XCTFail("Expected invalidBridgeEvent, got \(bridgeError)")
            }
        }
    }

    func testDecodeThrowsErrorForMissingState() {
        let jsonString = """
        {
            "jsonrpc": "2.0",
            "method": "checkout.primaryActionChange",
            "params": {
                "action": "pay",
                "cart": \(createTestCartJSON())
            }
        }
        """
        let data = jsonString.data(using: .utf8)!

        XCTAssertThrowsError(try CheckoutPrimaryActionChangeEvent.decode(from: data))
    }

    func testDecodeThrowsErrorForMissingAction() {
        let jsonString = """
        {
            "jsonrpc": "2.0",
            "method": "checkout.primaryActionChange",
            "params": {
                "state": "enabled",
                "cart": \(createTestCartJSON())
            }
        }
        """
        let data = jsonString.data(using: .utf8)!

        XCTAssertThrowsError(try CheckoutPrimaryActionChangeEvent.decode(from: data))
    }

    func testDecodeThrowsErrorForMissingCart() {
        let jsonString = """
        {
            "jsonrpc": "2.0",
            "method": "checkout.primaryActionChange",
            "params": {
                "state": "enabled",
                "action": "pay"
            }
        }
        """
        let data = jsonString.data(using: .utf8)!

        XCTAssertThrowsError(try CheckoutPrimaryActionChangeEvent.decode(from: data))
    }

    // MARK: - All State and Action Combinations

    func testAllStateAndActionCombinations() throws {
        let states: [CheckoutPrimaryActionChangeEvent.PrimaryActionState] = [.enabled, .disabled, .loading]
        let actions: [CheckoutPrimaryActionChangeEvent.PrimaryAction] = [.review, .pay]

        for state in states {
            for action in actions {
                let jsonString = """
                {
                    "jsonrpc": "2.0",
                    "method": "checkout.primaryActionChange",
                    "params": {
                        "state": "\(state.rawValue)",
                        "action": "\(action.rawValue)",
                        "cart": \(createTestCartJSON())
                    }
                }
                """
                let data = jsonString.data(using: .utf8)!
                let event = try CheckoutPrimaryActionChangeEvent.decode(from: data)

                XCTAssertEqual(event.state, state, "State should be \(state)")
                XCTAssertEqual(event.action, action, "Action should be \(action)")
            }
        }
    }
}
