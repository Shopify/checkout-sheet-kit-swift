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

import Foundation
@testable import ShopifyAcceleratedCheckouts
import XCTest

class CheckoutIdentifierTests: XCTestCase {
    // MARK: - Test Data Factory Methods

    private func validCartIDs() -> [String] {
        return [
            "gid://shopify/Cart/test-id",
            "gid://Shopify/Cart/Z2NwLXVzLWV4YW1wbGU6MDEyMzQ1Njc4OTAxMjM0NTY3ODkw?key=example",
            "GID://SHOPIFY/CART/uppercase-test",
            "gid://shopify/Cart/complex-id-123?key=value&param=test",
            "gid://shopify/cart/lowercase-type"
        ]
    }

    private func invalidCartIDs() -> [String] {
        return [
            "",
            "invalid-cart-id",
            "cart/test-id",
            "gid://shopify/Product/test-id",
            "gid://other/Cart/test-id",
            "gid://different/Cart/test-id"
        ]
    }

    private func validVariantIDs() -> [String] {
        return [
            "gid://shopify/ProductVariant/test-id",
            "gid://Shopify/ProductVariant/Z2NwLXVzLWV4YW1wbGU6MDEyMzQ1Njc4OTAxMjM0NTY3ODkw",
            "GID://SHOPIFY/PRODUCTVARIANT/uppercase-test",
            "gid://shopify/ProductVariant/complex-variant-456",
            "gid://shopify/productvariant/lowercase-type"
        ]
    }

    private func invalidVariantIDs() -> [String] {
        return [
            "",
            "invalid-variant-id",
            "variant/test-id",
            "gid://shopify/Product/test-id",
            "gid://other/ProductVariant/test-id",
            "gid://different/ProductVariant/test-id"
        ]
    }

    private func validQuantities() -> [Int] {
        return [1, 2, 5, 10, 100, 999]
    }

    private func invalidQuantities() -> [Int] {
        return [0, -1, -5, -100]
    }

    // MARK: - 1. Initialization Tests

    func test_cartInit_whenValidID_createsCartCase() {
        let cartID = "gid://shopify/Cart/test-id"
        let identifier = CheckoutIdentifier.cart(cartID: cartID)

        if case let .cart(id) = identifier {
            XCTAssertEqual(id, cartID)
        } else {
            XCTFail("Expected cart case, got \(identifier)")
        }
    }

    func test_cartInit_whenEmptyID_createsCartCase() {
        let cartID = ""
        let identifier = CheckoutIdentifier.cart(cartID: cartID)

        if case let .cart(id) = identifier {
            XCTAssertEqual(id, cartID)
        } else {
            XCTFail("Expected cart case, got \(identifier)")
        }
    }

    func test_variantInit_whenValidIDAndQuantity_createsVariantCase() {
        let variantID = "gid://shopify/ProductVariant/test-id"
        let quantity = 5
        let identifier = CheckoutIdentifier.variant(variantID: variantID, quantity: quantity)

        if case let .variant(id, qty) = identifier {
            XCTAssertEqual(id, variantID)
            XCTAssertEqual(qty, quantity)
        } else {
            XCTFail("Expected variant case, got \(identifier)")
        }
    }

    func test_variantInit_whenValidIDAndZeroQuantity_createsVariantCase() {
        let variantID = "gid://shopify/ProductVariant/test-id"
        let quantity = 0
        let identifier = CheckoutIdentifier.variant(variantID: variantID, quantity: quantity)

        if case let .variant(id, qty) = identifier {
            XCTAssertEqual(id, variantID)
            XCTAssertEqual(qty, quantity)
        } else {
            XCTFail("Expected variant case, got \(identifier)")
        }
    }

    func test_variantInit_whenValidIDAndNegativeQuantity_createsVariantCase() {
        let variantID = "gid://shopify/ProductVariant/test-id"
        let quantity = -1
        let identifier = CheckoutIdentifier.variant(variantID: variantID, quantity: quantity)

        if case let .variant(id, qty) = identifier {
            XCTAssertEqual(id, variantID)
            XCTAssertEqual(qty, quantity)
        } else {
            XCTFail("Expected variant case, got \(identifier)")
        }
    }

    func test_variantInit_whenEmptyID_createsVariantCase() {
        let variantID = ""
        let quantity = 1
        let identifier = CheckoutIdentifier.variant(variantID: variantID, quantity: quantity)

        if case let .variant(id, qty) = identifier {
            XCTAssertEqual(id, variantID)
            XCTAssertEqual(qty, quantity)
        } else {
            XCTFail("Expected variant case, got \(identifier)")
        }
    }

    func test_invariantInit_whenReasonProvided_createsInvariantCase() {
        let reason = "Test error reason"
        let identifier = CheckoutIdentifier.invariant(reason: reason)

        if case let .invariant(errorReason) = identifier {
            XCTAssertEqual(errorReason, reason)
        } else {
            XCTFail("Expected invariant case, got \(identifier)")
        }
    }

    // MARK: - 2. Parse Method Tests - Cart

    func test_parse_whenValidCartFormats_returnsSelf() {
        for cartID in validCartIDs() {
            let identifier = CheckoutIdentifier.cart(cartID: cartID)
            let parsed = identifier.parse()

            if case let .cart(id) = parsed {
                XCTAssertEqual(id, cartID, "Cart ID '\(cartID)' should parse successfully")
            } else {
                XCTFail("Cart ID '\(cartID)' should parse successfully, got \(parsed)")
            }
        }
    }

    func test_parse_whenInvalidCartFormats_returnsInvariantWithReason() {
        for cartID in invalidCartIDs() {
            let identifier = CheckoutIdentifier.cart(cartID: cartID)
            let parsed = identifier.parse()

            if case let .invariant(reason) = parsed {
                XCTAssertTrue(reason.contains("Invalid 'cartID' format"), "Reason should mention invalid cartID format for '\(cartID)'")
                if !cartID.isEmpty {
                    XCTAssertTrue(reason.contains(cartID), "Reason should include the invalid cartID '\(cartID)'")
                }
            } else {
                XCTFail("Cart ID '\(cartID)' should return invariant with reason, got \(parsed)")
            }
        }
    }

    func test_parse_whenCartIDCaseInsensitive_returnsSelf() {
        let cartID = "GID://SHOPIFY/CART/test-id"
        let identifier = CheckoutIdentifier.cart(cartID: cartID)
        let parsed = identifier.parse()

        if case let .cart(id) = parsed {
            XCTAssertEqual(id, cartID)
        } else {
            XCTFail("Case insensitive cart ID should parse successfully, got \(parsed)")
        }
    }

    func test_parse_whenInvalidCartID_returnsInvariantWithCorrectErrorMessage() {
        let invalidCartID = "invalid-cart-id"
        let identifier = CheckoutIdentifier.cart(cartID: invalidCartID)
        let parsed = identifier.parse()

        if case let .invariant(reason) = parsed {
            let expectedPrefix = "[invariant_violation] Invalid 'cartID' format. Expected to start with 'gid://Shopify/Cart/', received: 'invalid-cart-id'"
            XCTAssertEqual(reason, expectedPrefix)
        } else {
            XCTFail("Invalid cart ID should return invariant with error message")
        }
    }

    // MARK: - 2. Parse Method Tests - Variant

    func test_parse_whenValidVariantFormats_returnsSelf() {
        for variantID in validVariantIDs() {
            for quantity in validQuantities() {
                let identifier = CheckoutIdentifier.variant(variantID: variantID, quantity: quantity)
                let parsed = identifier.parse()

                if case let .variant(id, qty) = parsed {
                    XCTAssertEqual(id, variantID, "Variant ID '\(variantID)' should parse successfully")
                    XCTAssertEqual(qty, quantity, "Quantity '\(quantity)' should be preserved")
                } else {
                    XCTFail("Variant ID '\(variantID)' with quantity '\(quantity)' should parse successfully, got \(parsed)")
                }
            }
        }
    }

    func test_parse_whenInvalidVariantFormats_returnsInvariantWithReason() {
        for variantID in invalidVariantIDs() {
            let identifier = CheckoutIdentifier.variant(variantID: variantID, quantity: 1)
            let parsed = identifier.parse()

            if case let .invariant(reason) = parsed {
                XCTAssertTrue(reason.contains("Invalid 'variantID' format"), "Reason should mention invalid variantID format for '\(variantID)'")
                if !variantID.isEmpty {
                    XCTAssertTrue(reason.contains(variantID), "Reason should include the invalid variantID '\(variantID)'")
                }
            } else {
                XCTFail("Variant ID '\(variantID)' should return invariant with reason, got \(parsed)")
            }
        }
    }

    func test_parse_whenVariantZeroQuantity_returnsInvariantWithReason() {
        let validVariantID = "gid://shopify/ProductVariant/test-id"
        let identifier = CheckoutIdentifier.variant(variantID: validVariantID, quantity: 0)
        let parsed = identifier.parse()

        if case let .invariant(reason) = parsed {
            XCTAssertTrue(reason.contains("Quantity must be greater than 0"), "Reason should mention quantity validation")
            XCTAssertTrue(reason.contains("0"), "Reason should include the invalid quantity")
        } else {
            XCTFail("Zero quantity should return invariant with reason, got \(parsed)")
        }
    }

    func test_parse_whenVariantNegativeQuantity_returnsInvariantWithReason() {
        let validVariantID = "gid://shopify/ProductVariant/test-id"
        for invalidQuantity in invalidQuantities() {
            let identifier = CheckoutIdentifier.variant(variantID: validVariantID, quantity: invalidQuantity)
            let parsed = identifier.parse()

            if case let .invariant(reason) = parsed {
                XCTAssertTrue(reason.contains("Quantity must be greater than 0"), "Reason should mention quantity validation for quantity \(invalidQuantity)")
                XCTAssertTrue(reason.contains("\(invalidQuantity)"), "Reason should include the invalid quantity \(invalidQuantity)")
            } else {
                XCTFail("Invalid quantity \(invalidQuantity) should return invariant with reason, got \(parsed)")
            }
        }
    }

    func test_parse_whenVariantValidQuantity_returnsSelf() {
        let validVariantID = "gid://shopify/ProductVariant/test-id"
        for quantity in validQuantities() {
            let identifier = CheckoutIdentifier.variant(variantID: validVariantID, quantity: quantity)
            let parsed = identifier.parse()

            if case let .variant(id, qty) = parsed {
                XCTAssertEqual(id, validVariantID)
                XCTAssertEqual(qty, quantity)
            } else {
                XCTFail("Valid quantity \(quantity) should return self, got \(parsed)")
            }
        }
    }

    func test_parse_whenVariantIDCaseInsensitive_returnsSelf() {
        let variantID = "GID://SHOPIFY/PRODUCTVARIANT/test-id"
        let identifier = CheckoutIdentifier.variant(variantID: variantID, quantity: 1)
        let parsed = identifier.parse()

        if case let .variant(id, qty) = parsed {
            XCTAssertEqual(id, variantID)
            XCTAssertEqual(qty, 1)
        } else {
            XCTFail("Case insensitive variant ID should parse successfully, got \(parsed)")
        }
    }

    func test_parse_whenInvalidVariantID_returnsInvariantWithCorrectErrorMessage() {
        let invalidVariantID = "invalid-variant-id"
        let identifier = CheckoutIdentifier.variant(variantID: invalidVariantID, quantity: 1)
        let parsed = identifier.parse()

        if case let .invariant(reason) = parsed {
            let expectedPrefix = "[invariant_violation] Invalid 'variantID' format. Expected to start with 'gid://Shopify/ProductVariant/', received: 'invalid-variant-id'"
            XCTAssertEqual(reason, expectedPrefix)
        } else {
            XCTFail("Invalid variant ID should return invariant with error message")
        }
    }

    func test_parse_whenInvalidQuantity_returnsInvariantWithCorrectErrorMessage() {
        let validVariantID = "gid://shopify/ProductVariant/test-id"
        let invalidQuantity = -5
        let identifier = CheckoutIdentifier.variant(variantID: validVariantID, quantity: invalidQuantity)
        let parsed = identifier.parse()

        if case let .invariant(reason) = parsed {
            let expectedMessage = "[invariant_violation] Quantity must be greater than 0, received: -5"
            XCTAssertEqual(reason, expectedMessage)
        } else {
            XCTFail("Invalid quantity should return invariant with error message")
        }
    }

    // MARK: - 2. Parse Method Tests - Invariant

    func test_parse_whenInvariantCase_returnsSelf() {
        let reason = "Test error reason"
        let identifier = CheckoutIdentifier.invariant(reason: reason)
        let parsed = identifier.parse()

        if case let .invariant(errorReason) = parsed {
            XCTAssertEqual(errorReason, reason)
        } else {
            XCTFail("Invariant case should return self, got \(parsed)")
        }
    }

    // MARK: - 3. Helper Method Tests - getTokenComponent

    func test_getTokenComponent_whenValidCartID_returnsTokenPortion() {
        let cartID = "gid://shopify/Cart/test-token-123"
        let identifier = CheckoutIdentifier.cart(cartID: cartID)
        let token = identifier.getTokenComponent()

        XCTAssertEqual(token, "test-token-123")
    }

    func test_getTokenComponent_whenCartIDWithQueryParams_returnsTokenWithParams() {
        let cartID = "gid://shopify/Cart/test-token?key=value&param=test"
        let identifier = CheckoutIdentifier.cart(cartID: cartID)
        let token = identifier.getTokenComponent()

        XCTAssertEqual(token, "test-token?key=value&param=test")
    }

    func test_getTokenComponent_whenValidVariantID_returnsTokenPortion() {
        let variantID = "gid://shopify/ProductVariant/variant-token-456"
        let identifier = CheckoutIdentifier.variant(variantID: variantID, quantity: 1)
        let token = identifier.getTokenComponent()

        XCTAssertEqual(token, "variant-token-456")
    }

    func test_getTokenComponent_whenInvariantCase_returnsEmptyString() {
        let identifier = CheckoutIdentifier.invariant(reason: "Test error")
        let token = identifier.getTokenComponent()

        XCTAssertEqual(token, "")
    }

    // MARK: - 3. Helper Method Tests - isValid

    func test_isValid_whenValidCartID_returnsTrue() {
        for cartID in validCartIDs() {
            let identifier = CheckoutIdentifier.cart(cartID: cartID)
            XCTAssertTrue(identifier.isValid(), "Cart ID '\(cartID)' should be valid")
        }
    }

    func test_isValid_whenInvalidCartID_returnsFalse() {
        for cartID in invalidCartIDs() {
            let identifier = CheckoutIdentifier.cart(cartID: cartID)
            XCTAssertFalse(identifier.isValid(), "Cart ID '\(cartID)' should be invalid")
        }
    }

    func test_isValid_whenValidVariantID_returnsTrue() {
        for variantID in validVariantIDs() {
            for quantity in validQuantities() {
                let identifier = CheckoutIdentifier.variant(variantID: variantID, quantity: quantity)
                XCTAssertTrue(identifier.isValid(), "Variant ID '\(variantID)' with quantity \(quantity) should be valid")
            }
        }
    }

    func test_isValid_whenInvalidVariantID_returnsFalse() {
        for variantID in invalidVariantIDs() {
            let identifier = CheckoutIdentifier.variant(variantID: variantID, quantity: 1)
            XCTAssertFalse(identifier.isValid(), "Variant ID '\(variantID)' should be invalid")
        }

        let validVariantID = "gid://shopify/ProductVariant/test-id"
        for invalidQuantity in invalidQuantities() {
            let identifier = CheckoutIdentifier.variant(variantID: validVariantID, quantity: invalidQuantity)
            XCTAssertFalse(identifier.isValid(), "Variant with quantity \(invalidQuantity) should be invalid")
        }
    }

    func test_isValid_whenInvariantCase_returnsFalse() {
        let identifier = CheckoutIdentifier.invariant(reason: "Test error")
        XCTAssertFalse(identifier.isValid())
    }

    // MARK: - 4. Edge Cases Tests

    func test_parse_whenEmptyStrings_returnsInvariantWithReason() {
        let cartIdentifier = CheckoutIdentifier.cart(cartID: "")
        let cartParsed = cartIdentifier.parse()

        if case let .invariant(reason) = cartParsed {
            XCTAssertTrue(reason.contains("Invalid 'cartID' format"))
        } else {
            XCTFail("Empty cart ID should return invariant")
        }

        let variantIdentifier = CheckoutIdentifier.variant(variantID: "", quantity: 1)
        let variantParsed = variantIdentifier.parse()

        if case let .invariant(reason) = variantParsed {
            XCTAssertTrue(reason.contains("Invalid 'variantID' format"))
        } else {
            XCTFail("Empty variant ID should return invariant")
        }
    }

    func test_parse_whenWhitespaceOnlyStrings_returnsInvariantWithReason() {
        let cartIdentifier = CheckoutIdentifier.cart(cartID: "   ")
        let cartParsed = cartIdentifier.parse()

        if case let .invariant(reason) = cartParsed {
            XCTAssertTrue(reason.contains("Invalid 'cartID' format"))
        } else {
            XCTFail("Whitespace-only cart ID should return invariant")
        }

        let variantIdentifier = CheckoutIdentifier.variant(variantID: "   ", quantity: 1)
        let variantParsed = variantIdentifier.parse()

        if case let .invariant(reason) = variantParsed {
            XCTAssertTrue(reason.contains("Invalid 'variantID' format"))
        } else {
            XCTFail("Whitespace-only variant ID should return invariant")
        }
    }

    func test_parse_whenExtremelyLongIDs_handlesGracefully() {
        let longValidCartID = "gid://shopify/Cart/" + String(repeating: "a", count: 1000)
        let cartIdentifier = CheckoutIdentifier.cart(cartID: longValidCartID)
        let cartParsed = cartIdentifier.parse()

        if case let .cart(id) = cartParsed {
            XCTAssertEqual(id, longValidCartID)
        } else {
            XCTFail("Long valid cart ID should parse successfully")
        }

        let longValidVariantID = "gid://shopify/ProductVariant/" + String(repeating: "b", count: 1000)
        let variantIdentifier = CheckoutIdentifier.variant(variantID: longValidVariantID, quantity: 1)
        let variantParsed = variantIdentifier.parse()

        if case let .variant(id, _) = variantParsed {
            XCTAssertEqual(id, longValidVariantID)
        } else {
            XCTFail("Long valid variant ID should parse successfully")
        }
    }

    func test_parse_whenSpecialCharactersInIDs_handlesCorrectly() {
        let specialCharsCartID = "gid://shopify/Cart/test-id_123%20with%20special&chars=true"
        let cartIdentifier = CheckoutIdentifier.cart(cartID: specialCharsCartID)
        let cartParsed = cartIdentifier.parse()

        if case let .cart(id) = cartParsed {
            XCTAssertEqual(id, specialCharsCartID)
        } else {
            XCTFail("Cart ID with special characters should parse successfully")
        }

        let specialCharsVariantID = "gid://shopify/ProductVariant/variant-id_456%20with%20special&chars=true"
        let variantIdentifier = CheckoutIdentifier.variant(variantID: specialCharsVariantID, quantity: 1)
        let variantParsed = variantIdentifier.parse()

        if case let .variant(id, _) = variantParsed {
            XCTAssertEqual(id, specialCharsVariantID)
        } else {
            XCTFail("Variant ID with special characters should parse successfully")
        }
    }

    // MARK: - 5. Error Message Validation Tests

    func test_parse_whenCartValidationFails_returnsExpectedErrorMessage() {
        let testCases = [
            ("invalid-cart", "[invariant_violation] Invalid 'cartID' format. Expected to start with 'gid://Shopify/Cart/', received: 'invalid-cart'"),
            ("", "[invariant_violation] Invalid 'cartID' format. Expected to start with 'gid://Shopify/Cart/', received: ''"),
            ("gid://shopify/Product/123", "[invariant_violation] Invalid 'cartID' format. Expected to start with 'gid://Shopify/Cart/', received: 'gid://shopify/Product/123'")
        ]

        for (cartID, expectedMessage) in testCases {
            let identifier = CheckoutIdentifier.cart(cartID: cartID)
            let parsed = identifier.parse()

            if case let .invariant(reason) = parsed {
                XCTAssertEqual(reason, expectedMessage, "Error message mismatch for cart ID '\(cartID)'")
            } else {
                XCTFail("Invalid cart ID '\(cartID)' should return invariant with error message")
            }
        }
    }

    func test_parse_whenVariantValidationFails_returnsExpectedErrorMessage() {
        let testCases = [
            ("invalid-variant", "[invariant_violation] Invalid 'variantID' format. Expected to start with 'gid://Shopify/ProductVariant/', received: 'invalid-variant'"),
            ("", "[invariant_violation] Invalid 'variantID' format. Expected to start with 'gid://Shopify/ProductVariant/', received: ''"),
            ("gid://shopify/Product/123", "[invariant_violation] Invalid 'variantID' format. Expected to start with 'gid://Shopify/ProductVariant/', received: 'gid://shopify/Product/123'")
        ]

        for (variantID, expectedMessage) in testCases {
            let identifier = CheckoutIdentifier.variant(variantID: variantID, quantity: 1)
            let parsed = identifier.parse()

            if case let .invariant(reason) = parsed {
                XCTAssertEqual(reason, expectedMessage, "Error message mismatch for variant ID '\(variantID)'")
            } else {
                XCTFail("Invalid variant ID '\(variantID)' should return invariant with error message")
            }
        }
    }

    func test_parse_whenQuantityValidationFails_returnsExpectedErrorMessage() {
        let validVariantID = "gid://shopify/ProductVariant/test-id"
        let testCases = [
            (0, "[invariant_violation] Quantity must be greater than 0, received: 0"),
            (-1, "[invariant_violation] Quantity must be greater than 0, received: -1"),
            (-100, "[invariant_violation] Quantity must be greater than 0, received: -100")
        ]

        for (quantity, expectedMessage) in testCases {
            let identifier = CheckoutIdentifier.variant(variantID: validVariantID, quantity: quantity)
            let parsed = identifier.parse()

            if case let .invariant(reason) = parsed {
                XCTAssertEqual(reason, expectedMessage, "Error message mismatch for quantity \(quantity)")
            } else {
                XCTFail("Invalid quantity \(quantity) should return invariant with error message")
            }
        }
    }

    // MARK: - 6. Integration Tests

    func test_parse_whenCalledMultipleTimes_remainsConsistent() {
        let cartID = "gid://shopify/Cart/test-id"
        let identifier = CheckoutIdentifier.cart(cartID: cartID)

        let firstParse = identifier.parse()
        let secondParse = identifier.parse()
        let thirdParse = identifier.parse()

        if case let .cart(firstID) = firstParse,
           case let .cart(secondID) = secondParse,
           case let .cart(thirdID) = thirdParse
        {
            XCTAssertEqual(firstID, secondID)
            XCTAssertEqual(secondID, thirdID)
            XCTAssertEqual(firstID, cartID)
        } else {
            XCTFail("Multiple parse calls should return consistent results")
        }

        let invalidCartID = "invalid-cart"
        let invalidIdentifier = CheckoutIdentifier.cart(cartID: invalidCartID)

        let firstInvalidParse = invalidIdentifier.parse()
        let secondInvalidParse = invalidIdentifier.parse()

        if case let .invariant(firstReason) = firstInvalidParse,
           case let .invariant(secondReason) = secondInvalidParse
        {
            XCTAssertEqual(firstReason, secondReason)
        } else {
            XCTFail("Multiple parse calls on invalid identifier should return consistent results")
        }
    }
}
