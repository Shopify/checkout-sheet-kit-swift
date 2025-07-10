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

import PassKit
import ShopifyCheckoutSheetKit
import SwiftUI

/// Renders a Checkout buttons for a cart or product variant
///
/// Note:
/// - The `withWallets` modifier can be used to limit the buttons rendered
/// - The order of the buttons is the same as the order of the `withWallets` modifier
/// - omission of the `withWallets` modifier will render all buttons
@available(iOS 17.0, *)
public struct AcceleratedCheckoutButtons: View {
    @Environment(ShopifyAcceleratedCheckouts.Configuration.self)
    private var configuration

    let identifier: CheckoutIdentifier
    var wallets: [Wallet] = [.shoppay, .applepay]
    var eventHandlers: EventHandlers = .init()

    @State private var shopSettings: ShopSettings?

    /// Initializes an Apple Pay button with a cart ID
    /// - Parameters:
    ///   - cartID: The cart ID to checkout (must start with gid://shopify/Cart/)
    ///   - label: The label to display on the Apple Pay button
    public init(cartID: String) {
        identifier = .cart(cartID: cartID).parse()
    }

    /// Initializes an Apple Pay button with a variant ID
    /// - Parameters:
    ///  - variantID: The variant ID to checkout (must start with gid://shopify/ProductVariant/)
    ///  - quantity: The quantity of the variant to checkout
    ///  - label: The label to display on the Apple Pay button
    public init(variantID: String, quantity: Int) {
        identifier = .variant(variantID: variantID, quantity: quantity).parse()
    }

    public var body: some View {
        if identifier.isValid() {
            VStack {
                if let shopSettings {
                    VStack {
                        ForEach(wallets, id: \.self) {
                            switch $0 {
                            case .applepay:
                                ApplePayButton(
                                    identifier: identifier,
                                    eventHandlers: eventHandlers
                                )
                            case .shoppay:
                                ShopPayButton(
                                    identifier: identifier,
                                    eventHandlers: eventHandlers
                                )
                            }
                        }
                    }.environment(shopSettings)
                }
            }
            .task { await loadShopSettings() }
        }
    }

    private func loadShopSettings() async {
        do {
            shopSettings = try await ShopSettings.load(
                storefront: StorefrontAPI(
                    storefrontDomain: configuration.storefrontDomain,
                    storefrontAccessToken: configuration.storefrontAccessToken
                ))
        } catch {
            print("Error loading shop settings: \(error)")
        }
    }
}

// MARK: AcceleratedCheckoutButtons Modifiers

@available(iOS 17.0, *)
extension AcceleratedCheckoutButtons {
    /// Modifies the wallet options supported
    /// Defaults: [.applepay]
    public func withWallets(_ wallets: [Wallet]) -> AcceleratedCheckoutButtons {
        var newView = self
        newView.wallets = wallets
        return newView
    }

    /// Adds an action to perform when the checkout completes successfully.
    ///
    /// Use this modifier to handle successful checkout events:
    ///
    /// ```swift
    /// AcceleratedCheckoutButtons(cartID: cartId)
    ///     .onComplete {
    ///         // Navigate to success screen
    ///         showSuccessView = true
    ///     }
    /// ```
    ///
    /// - Parameter action: The action to perform when checkout succeeds
    /// - Returns: A view with the checkout success handler set
    public func onComplete(_ action: @escaping () -> Void) -> AcceleratedCheckoutButtons {
        var newView = self
        newView.eventHandlers.checkoutDidComplete = action
        return newView
    }

    /// Adds an action to perform when the checkout encounters an error.
    ///
    /// Use this modifier to handle checkout errors:
    ///
    /// ```swift
    /// AcceleratedCheckoutButtons(cartID: cartId)
    ///     .onFail {
    ///         // Show error alert
    ///         showErrorAlert = true
    ///     }
    /// ```
    ///
    /// - Parameter action: The action to perform when checkout fails
    /// - Returns: A view with the checkout error handler set
    public func onFail(_ action: @escaping () -> Void) -> AcceleratedCheckoutButtons {
        var newView = self
        newView.eventHandlers.checkoutDidFail = action
        return newView
    }

    /// Adds an action to perform when the checkout is cancelled by the user.
    ///
    /// Use this modifier to handle checkout cancellation:
    ///
    /// ```swift
    /// AcceleratedCheckoutButtons(cartID: cartId)
    ///     .onCancel {
    ///         // Reset checkout state
    ///         resetCheckoutState()
    ///     }
    /// ```
    ///
    /// - Parameter action: The action to perform when checkout is cancelled
    /// - Returns: A view with the checkout cancel handler set
    public func onCancel(_ action: @escaping () -> Void) -> AcceleratedCheckoutButtons {
        var newView = self
        newView.eventHandlers.checkoutDidCancel = action
        return newView
    }

    /// Adds an action to determine if checkout should recover from an error.
    ///
    /// Use this modifier to handle error recovery decisions:
    ///
    /// ```swift
    /// AcceleratedCheckoutButtons(cartID: cartId)
    ///     .onShouldRecoverFromError { error in
    ///         // Return true to attempt recovery, false to fail
    ///         return error.isRecoverable
    ///     }
    /// ```
    ///
    /// - Parameter action: The action to determine if recovery should be attempted
    /// - Returns: A view with the error recovery handler set
    public func onShouldRecoverFromError(
        _ action: @escaping (ShopifyCheckoutSheetKit.CheckoutError) -> Bool
    ) -> AcceleratedCheckoutButtons {
        var newView = self
        newView.eventHandlers.shouldRecoverFromError = action
        return newView
    }

    /// Adds an action to perform when a link is clicked during checkout.
    ///
    /// Use this modifier to handle link clicks:
    ///
    /// ```swift
    /// AcceleratedCheckoutButtons(cartID: cartId)
    ///     .onClickLink { url in
    ///         // Handle external link
    ///         UIApplication.shared.open(url)
    ///     }
    /// ```
    ///
    /// - Parameter action: The action to perform when a link is clicked
    /// - Returns: A view with the link click handler set
    public func onClickLink(_ action: @escaping (URL) -> Void) -> AcceleratedCheckoutButtons {
        var newView = self
        newView.eventHandlers.checkoutDidClickLink = action
        return newView
    }

    /// Adds an action to perform when a web pixel event is emitted.
    ///
    /// Use this modifier to handle web pixel events:
    ///
    /// ```swift
    /// AcceleratedCheckoutButtons(cartID: cartId)
    ///     .onWebPixelEvent { event in
    ///         // Track analytics event
    ///         Analytics.track(event)
    ///     }
    /// ```
    ///
    /// - Parameter action: The action to perform when a pixel event is emitted
    /// - Returns: A view with the web pixel event handler set
    public func onWebPixelEvent(_ action: @escaping (ShopifyCheckoutSheetKit.PixelEvent) -> Void)
        -> AcceleratedCheckoutButtons
    {
        var newView = self
        newView.eventHandlers.checkoutDidEmitWebPixelEvent = action
        return newView
    }
}

// MARK: Previews

@available(iOS 17.0, *)
#Preview {
    AcceleratedCheckoutButtons(cartID: .init(""))
        .withWallets([.applepay, .shoppay])
        .environment(mockCommonConfiguration)
        .environment(mockController as ApplePayViewController)
}
