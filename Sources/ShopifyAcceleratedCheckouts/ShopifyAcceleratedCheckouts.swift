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

import UIKit

@available(iOS 17.0, *)
public enum ShopifyAcceleratedCheckouts {
    /// Storefront API version used for cart operations
    /// Note: We also use `2025-07` for `cartRemovePersonalData` mutations. We are working towards migrating all requests to `2025-07`.
    static let apiVersion = "2025-04"

    /// The current configuration for accelerated checkouts
    internal static var currentConfiguration: Configuration?
}

// MARK: - Global Configuration

@available(iOS 17.0, *)
extension ShopifyAcceleratedCheckouts {
    /// Configures the ShopifyAcceleratedCheckouts module with storefront settings
    /// - Parameter configuration: The configuration containing storefront domain and access token
    public static func configure(_ configuration: Configuration) {
        currentConfiguration = configuration
    }

    /// A convenience function for configuring the ShopifyAcceleratedCheckouts module
    /// - Parameter block: A closure that receives a mutable configuration to modify
    public static func configure(_ block: (inout Configuration) -> Void) {
        var config = currentConfiguration ?? Configuration(storefrontDomain: "", storefrontAccessToken: "")
        block(&config)
        currentConfiguration = config
    }
}

// MARK: - Button Factory Methods

@available(iOS 17.0, *)
extension ShopifyAcceleratedCheckouts {
    /// Creates an Apple Pay button for the specified cart
    /// - Parameters:
    ///   - cartID: The cart ID to checkout (must start with gid://shopify/Cart/)
    /// - Returns: A configured AcceleratedCheckoutButton for Apple Pay
    public static func applePayButton(cartID: String) -> AcceleratedCheckoutButton {
        return AcceleratedCheckoutButton.applePay(cartID: cartID)
    }

    /// Creates an Apple Pay button for the specified product variant
    /// - Parameters:
    ///   - variantID: The variant ID to checkout (must start with gid://shopify/ProductVariant/)
    ///   - quantity: The quantity to add to cart
    /// - Returns: A configured AcceleratedCheckoutButton for Apple Pay
    public static func applePayButton(variantID: String, quantity: Int) -> AcceleratedCheckoutButton {
        return AcceleratedCheckoutButton.applePay(variantID: variantID, quantity: quantity)
    }

    /// Creates a Shop Pay button for the specified cart
    /// - Parameters:
    ///   - cartID: The cart ID to checkout (must start with gid://shopify/Cart/)
    /// - Returns: A configured AcceleratedCheckoutButton for Shop Pay
    public static func shopPayButton(cartID: String) -> AcceleratedCheckoutButton {
        return AcceleratedCheckoutButton.shopPay(cartID: cartID)
    }

    /// Creates a Shop Pay button for the specified product variant
    /// - Parameters:
    ///   - variantID: The variant ID to checkout (must start with gid://shopify/ProductVariant/)
    ///   - quantity: The quantity to add to cart
    /// - Returns: A configured AcceleratedCheckoutButton for Shop Pay
    public static func shopPayButton(variantID: String, quantity: Int) -> AcceleratedCheckoutButton {
        return AcceleratedCheckoutButton.shopPay(variantID: variantID, quantity: quantity)
    }
}

// MARK: - Utility Methods

@available(iOS 17.0, *)
extension ShopifyAcceleratedCheckouts {
    /// Checks if the specified wallet is available for use
    /// - Parameter wallet: The wallet type to check
    /// - Returns: true if the wallet can be presented, false otherwise
    public static func canPresent(wallet: Wallet) -> Bool {
        return AcceleratedCheckoutViewController.canPresent(wallet: wallet)
    }
}
