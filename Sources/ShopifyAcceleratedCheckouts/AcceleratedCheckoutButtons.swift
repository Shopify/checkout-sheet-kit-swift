//
//  AcceleratedCheckoutButtons.swift
//  ShopifyAcceleratedCheckouts
//
//  Created by Kieran Barrie Osgood on 06/06/2025.
//
import PassKit
import ShopifyCheckoutSheetKit
import SwiftUI

/// Renders a set of accelerated checkout buttons for the given cart or variant
///
/// Note:
/// - The buttons will be rendered in the order of the `withWallets` modifier
/// - If `withWallets` modifier is not used, the order is not guaranteed
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
        .isVisible(when: identifier.isValid())
    }

    private func loadShopSettings() async {
        do {
            shopSettings = try await ShopSettings.load(storefront: StorefrontAPI(
                shopDomain: configuration.shopDomain,
                storefrontAccessToken: configuration.storefrontAccessToken
            ))
        } catch {
            print("Error loading shop settings: \(error)")
        }
    }
}

// MARK: AcceleratedCheckoutButtons Modifiers

public extension AcceleratedCheckoutButtons {
    /// Modifies the wallet options supported
    /// Defaults: [.applepay]
    func withWallets(_ wallets: [Wallet]) -> AcceleratedCheckoutButtons {
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
    func onComplete(_ action: @escaping () -> Void) -> AcceleratedCheckoutButtons {
        var newView = self
        newView.eventHandlers.checkoutSuccessHandler = action
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
    func onFail(_ action: @escaping () -> Void) -> AcceleratedCheckoutButtons {
        var newView = self
        newView.eventHandlers.checkoutErrorHandler = action
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
    func onCancel(_ action: @escaping () -> Void) -> AcceleratedCheckoutButtons {
        var newView = self
        newView.eventHandlers.checkoutCancelHandler = action
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
    func onShouldRecoverFromError(_ action: @escaping (ShopifyCheckoutSheetKit.CheckoutError) -> Bool) -> AcceleratedCheckoutButtons {
        var newView = self
        newView.eventHandlers.shouldRecoverFromErrorHandler = action
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
    func onClickLink(_ action: @escaping (URL) -> Void) -> AcceleratedCheckoutButtons {
        var newView = self
        newView.eventHandlers.clickLinkHandler = action
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
    func onWebPixelEvent(_ action: @escaping (ShopifyCheckoutSheetKit.PixelEvent) -> Void) -> AcceleratedCheckoutButtons {
        var newView = self
        newView.eventHandlers.webPixelEventHandler = action
        return newView
    }
}

// MARK: Previews

#Preview {
    AcceleratedCheckoutButtons(cartID: .init(""))
        .withWallets([.applepay, .shoppay])
        .environment(mockCommonConfiguration)
        .environment(mockController as ApplePayViewController)
}
