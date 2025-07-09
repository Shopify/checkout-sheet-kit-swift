//
//  CheckoutIdentifier.swift
//  ShopifyAcceleratedCheckouts
//
//  Created by Kieran Barrie Osgood on 04/06/2025.
//

// MARK: Identifier helpers

/// Type of identifier used for checkout
enum CheckoutIdentifier {
    case variant(variantID: String, quantity: Int)
    case cart(cartID: String)
    case invariant

    static let cartPrefix = "gid://Shopify/Cart/"
    static let variantPrefix = "gid://Shopify/ProductVariant/"

    /// Extracts the final portion of the cartID or variantID
    ///
    /// Example "gid://shopify/Cart/Z2NwLXVzLWV4YW1wbGU6MDEyMzQ1Njc4OTAxMjM0NTY3ODkw?key=examplekey1234567890"
    /// Returns "Z2NwLXVzLWV4YW1wbGU6MDEyMzQ1Njc4OTAxMjM0NTY3ODkw?key=examplekey1234567890"
    ///
    /// See: https://shopify.dev/docs/storefronts/headless/building-with-the-storefront-api/cart/manage#cart-id
    func getTokenComponent() -> String {
        switch self {
        case let .cart(cartID):
            return cartID.components(separatedBy: "/").last ?? ""
        case let .variant(variantID, _):
            return variantID.components(separatedBy: "/").last ?? ""
        case .invariant:
            return ""
        }
    }

    /// Checks for valid ID signature,
    /// Returns .invariant if validation fails
    func isValid() -> Bool {
        if case .invariant = parse() {
            return false
        }
        return true
    }

    /// Checks the `id` component is a valid shopify identifier
    /// Returns `self` if parsing was succesful
    /// Returns `.invariant` if parsing fails
    func parse() -> CheckoutIdentifier {
        switch self {
        case let .cart(cartID):
            guard cartID.lowercased().hasPrefix(Self.cartPrefix.lowercased()) else {
                print(
                    "[invariant_violation] Invalid 'cartID' format. Expected to start with '\(Self.cartPrefix)', received: \(cartID)"
                )
                return .invariant
            }
            return self

        case let .variant(variantID, quantity):
            guard variantID.lowercased().hasPrefix(Self.variantPrefix.lowercased()) else {
                print(
                    "[invariant_violation] Invalid 'variantID' format. Expected to start with '\(Self.variantPrefix)', received: \(variantID)"
                )
                return .invariant
            }
            guard quantity > 0 else {
                print(
                    "[invariant_violation] Quantity must be greater than 0, received: \(quantity)"
                )
                return .invariant
            }
            return self

        default: return self
        }
    }
}
