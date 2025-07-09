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
