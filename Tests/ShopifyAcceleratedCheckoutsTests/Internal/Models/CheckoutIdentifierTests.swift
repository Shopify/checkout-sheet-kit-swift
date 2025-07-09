//
//  CheckoutIdentifierTests.swift
//  ShopifyAcceleratedCheckouts
//
//  Created by Kieran Barrie Osgood on 05/06/2025.
//

import Foundation
@testable import ShopifyAcceleratedCheckouts
import XCTest

// Type alias for the ID type
private typealias ID = GraphQLScalars.ID

struct CheckoutIdentifierTestError: Error, Equatable {
    let message: String
}

class CheckoutIdentifierTests: XCTestCase {
    // MARK: - ID Validation Tests

    func testIsValidCartIDReturnsTrueForValidFormat() throws {
        let validCartID = ID("gid://Shopify/Cart/12345")
        let identifier = CheckoutIdentifier.cart(cartID: validCartID.rawValue)

        let isValid = identifier.isValid()

        XCTAssertTrue(isValid)
    }

    func testIsValidCartIDReturnsFalseForInvalidFormat() throws {
        let invalidCartID = ID("invalid-cart-id")
        let identifier = CheckoutIdentifier.cart(cartID: invalidCartID.rawValue)

        let isValid = identifier.isValid()

        XCTAssertFalse(isValid)
    }

    func testIsValidCartIDIsCaseInsensitive() throws {
        let upperCaseCartID = ID("GID://SHOPIFY/CART/12345")
        let mixedCaseCartID = ID("Gid://Shopify/Cart/12345")

        let upperIdentifier = CheckoutIdentifier.cart(cartID: upperCaseCartID.rawValue)
        let mixedIdentifier = CheckoutIdentifier.cart(cartID: mixedCaseCartID.rawValue)

        XCTAssertTrue(upperIdentifier.isValid())
        XCTAssertTrue(mixedIdentifier.isValid())
    }

    func testIsValidVariantIDReturnsTrueForValidFormat() throws {
        let validVariantID = ID("gid://Shopify/ProductVariant/67890")
        let identifier = CheckoutIdentifier.variant(variantID: validVariantID.rawValue, quantity: 1)

        let isValid = identifier.isValid()

        XCTAssertTrue(isValid)
    }

    func testIsValidVariantIDReturnsFalseForInvalidFormat() throws {
        let invalidVariantID = ID("invalid-variant-id")
        let identifier = CheckoutIdentifier.variant(variantID: invalidVariantID.rawValue, quantity: 1)

        let isValid = identifier.isValid()

        XCTAssertFalse(isValid)
    }

    func testIsValidVariantIDIsCaseInsensitive() throws {
        let upperCaseVariantID = ID("GID://SHOPIFY/PRODUCTVARIANT/67890")
        let mixedCaseVariantID = ID("Gid://Shopify/ProductVariant/67890")

        let upperIdentifier = CheckoutIdentifier.variant(variantID: upperCaseVariantID.rawValue, quantity: 1)
        let mixedIdentifier = CheckoutIdentifier.variant(variantID: mixedCaseVariantID.rawValue, quantity: 1)

        XCTAssertTrue(upperIdentifier.isValid())
        XCTAssertTrue(mixedIdentifier.isValid())
    }

    // MARK: - Parse Method Tests

    func testValidateReturnsValidCartForValidCartID() throws {
        let validCartID = ID("gid://Shopify/Cart/12345")
        let identifier = CheckoutIdentifier.cart(cartID: validCartID.rawValue)

        let parsed = identifier.parse()

        if case let .cart(id) = parsed {
            XCTAssertEqual(id, "gid://Shopify/Cart/12345")
        } else {
            XCTFail("Expected cart case")
        }
    }

    func testValidateReturnsInvariantForInvalidCartID() throws {
        let invalidCartID = ID("invalid-cart-id")
        let identifier = CheckoutIdentifier.cart(cartID: invalidCartID.rawValue)

        let parsed = identifier.parse()

        if case .invariant = parsed {
            // Expected
        } else {
            XCTFail("Expected invariant case")
        }
    }

    func testValidateReturnsValidVariantForValidVariantIDAndQuantity() throws {
        let validVariantID = ID("gid://Shopify/ProductVariant/67890")
        let identifier = CheckoutIdentifier.variant(variantID: validVariantID.rawValue, quantity: 2)

        let parsed = identifier.parse()

        if case let .variant(id, quantity) = parsed {
            XCTAssertEqual(id, "gid://Shopify/ProductVariant/67890")
            XCTAssertEqual(quantity, 2)
        } else {
            XCTFail("Expected variant case")
        }
    }

    func testValidateReturnsInvariantForInvalidVariantID() throws {
        let invalidVariantID = ID("invalid-variant-id")
        let identifier = CheckoutIdentifier.variant(variantID: invalidVariantID.rawValue, quantity: 1)

        let parsed = identifier.parse()

        if case .invariant = parsed {
            // Expected
        } else {
            XCTFail("Expected invariant case")
        }
    }

    func testValidateReturnsInvariantForZeroQuantity() throws {
        let validVariantID = ID("gid://Shopify/ProductVariant/67890")
        let identifier = CheckoutIdentifier.variant(variantID: validVariantID.rawValue, quantity: 0)

        let parsed = identifier.parse()

        if case .invariant = parsed {
            // Expected
        } else {
            XCTFail("Expected invariant case")
        }
    }

    func testValidateReturnsInvariantForNegativeQuantity() throws {
        let validVariantID = ID("gid://Shopify/ProductVariant/67890")
        let identifier = CheckoutIdentifier.variant(variantID: validVariantID.rawValue, quantity: -1)

        let parsed = identifier.parse()

        if case .invariant = parsed {
            // Expected
        } else {
            XCTFail("Expected invariant case")
        }
    }

    func testValidateReturnsInvariantAsIs() throws {
        let identifier = CheckoutIdentifier.invariant

        let parsed = identifier.parse()

        if case .invariant = parsed {
            // Expected
        } else {
            XCTFail("Expected invariant case")
        }
    }

    // MARK: - Edge Cases

    func testValidateWorksWithEmptyIDs() throws {
        let emptyCartID = ID("")
        let emptyVariantID = ID("")

        let cartIdentifier = CheckoutIdentifier.cart(cartID: emptyCartID.rawValue)
        let variantIdentifier = CheckoutIdentifier.variant(variantID: emptyVariantID.rawValue, quantity: 1)

        if case .invariant = cartIdentifier.parse() {
            // Expected
        } else {
            XCTFail("Expected invariant for empty cart ID")
        }

        if case .invariant = variantIdentifier.parse() {
            // Expected
        } else {
            XCTFail("Expected invariant for empty variant ID")
        }
    }

    func testValidateWorksWithMaxQuantity() throws {
        let validVariantID = ID("gid://Shopify/ProductVariant/67890")
        let identifier = CheckoutIdentifier.variant(variantID: validVariantID.rawValue, quantity: Int.max)

        let parsed = identifier.parse()

        if case let .variant(_, quantity) = parsed {
            XCTAssertEqual(quantity, Int.max)
        } else {
            XCTFail("Expected variant case")
        }
    }

    func testPrefixConstantsAreCorrect() throws {
        XCTAssertEqual(CheckoutIdentifier.cartPrefix, "gid://Shopify/Cart/")
        XCTAssertEqual(CheckoutIdentifier.variantPrefix, "gid://Shopify/ProductVariant/")
    }

    // MARK: - Integration Tests

    func testValidateHandlesComplexIDs() throws {
        let complexCartID = ID(
            "gid://Shopify/Cart/Z2lkOi8vc2hvcGlmeS9DYXJ0LzEyMzQ1")
        let complexVariantID = ID(
            "gid://Shopify/ProductVariant/Z2lkOi8vc2hvcGlmeS9Qcm9kdWN0VmFyaWFudC82Nzg5MA==")

        let cartIdentifier = CheckoutIdentifier.cart(cartID: complexCartID.rawValue).parse()
        let variantIdentifier = CheckoutIdentifier.variant(variantID: complexVariantID.rawValue, quantity: 5)
            .parse()

        if case let .cart(id) = cartIdentifier {
            XCTAssertTrue(id.contains("Z2lkOi8vc2hvcGlmeS9DYXJ0LzEyMzQ1"))
        } else {
            XCTFail("Expected valid cart")
        }

        if case let .variant(id, quantity) = variantIdentifier {
            XCTAssertTrue(
                id.contains("Z2lkOi8vc2hvcGlmeS9Qcm9kdWN0VmFyaWFudC82Nzg5MA=="))
            XCTAssertEqual(quantity, 5)
        } else {
            XCTFail("Expected valid variant")
        }
    }
}
