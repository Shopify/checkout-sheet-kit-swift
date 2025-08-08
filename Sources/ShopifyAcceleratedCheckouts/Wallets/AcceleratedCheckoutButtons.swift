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

/// Render state for AcceleratedCheckoutButtons
public enum RenderState {
    case loading
    case rendered
    case error
}

/// Renders a Checkout buttons for a cart or product variant
///
/// Note:
/// - The `wallets` modifier can be used to limit the buttons rendered
/// - The order of the buttons is the same as the order of the `wallets` modifier
/// - omission of the `wallets` modifier will render all buttons
@available(iOS 15.0, *)
public struct AcceleratedCheckoutButtons: View {
    @EnvironmentObject
    private var configuration: ShopifyAcceleratedCheckouts.Configuration

    let identifier: CheckoutIdentifier
    var wallets: [Wallet] = [.shopPay, .applePay]
    var eventHandlers: EventHandlers = .init()
    var cornerRadius: CGFloat?

    @State private var shopSettings: ShopSettings?
    @State private var currentRenderState: RenderState = .loading {
        didSet {
            eventHandlers.renderStateDidChange?(currentRenderState)
        }
    }

    /// The Apple Pay button label style
    private var label: PKPaymentButtonType = .plain

    /// Initializes an Apple Pay button with a cart ID
    /// - Parameters:
    ///   - cartID: The cart ID to checkout (must start with gid://shopify/Cart/)
    ///   - label: The label to display on the Apple Pay button
    public init(cartID: String) {
        identifier = .cart(cartID: cartID).parse()
        if case .invariant = identifier {
            _currentRenderState = State(initialValue: .error)
        }
    }

    /// Initializes an Apple Pay button with a variant ID
    /// - Parameters:
    ///  - variantID: The variant ID to checkout (must start with gid://shopify/ProductVariant/)
    ///  - quantity: The quantity of the variant to checkout
    ///  - label: The label to display on the Apple Pay button
    public init(variantID: String, quantity: Int) {
        identifier = .variant(variantID: variantID, quantity: quantity).parse()
        if case .invariant = identifier {
            _currentRenderState = State(initialValue: .error)
        }
    }

    public var body: some View {
        VStack {
            if let shopSettings {
                VStack {
                    ForEach(wallets, id: \.self) {
                        switch $0 {
                        case .applePay:
                            ApplePayButton(
                                identifier: identifier,
                                eventHandlers: eventHandlers,
                                cornerRadius: cornerRadius
                            )
                            .label(label)
                        case .shopPay:
                            ShopPayButton(
                                identifier: identifier,
                                eventHandlers: eventHandlers,
                                cornerRadius: cornerRadius
                            )
                        }
                    }
                }.environmentObject(shopSettings)
            }
        }
        .task { await loadShopSettings() }
        .onAppear {
            eventHandlers.renderStateDidChange?(currentRenderState)
        }
    }

    private func loadShopSettings() async {
        guard identifier.isValid() else { return }

        do {
            currentRenderState = .loading
            let storefront = StorefrontAPI(
                storefrontDomain: configuration.storefrontDomain,
                storefrontAccessToken: configuration.storefrontAccessToken
            )
            let shop = try await storefront.shop()
            shopSettings = ShopSettings(from: shop)
            currentRenderState = .rendered
        } catch {
            print("Error loading shop settings: \(error)")
            currentRenderState = .error
        }
    }
}

// MARK: AcceleratedCheckoutButtons Modifiers

@available(iOS 15.0, *)
extension AcceleratedCheckoutButtons {
    public func label(_ label: ApplePayButtonLabel) -> AcceleratedCheckoutButtons {
        var view = self
        view.label = label.toPKPaymentButtonType()
        return view
    }

    /// Modifies the wallet options supported
    /// Defaults: [.applePay]
    public func wallets(_ wallets: [Wallet]) -> AcceleratedCheckoutButtons {
        var newView = self
        newView.wallets = wallets
        return newView
    }

    /// Sets the corner radius for all checkout buttons
    ///
    /// Use this modifier to customize the corner radius of the buttons:
    ///
    /// ```swift
    /// AcceleratedCheckoutButtons(cartID: cartId)
    ///     .cornerRadius(12)
    /// ```
    ///
    /// - Parameter radius: The corner radius to apply to all buttons (default: 8). Negative values will use the default.
    /// - Returns: A view with the custom corner radius applied
    public func cornerRadius(_ radius: CGFloat) -> AcceleratedCheckoutButtons {
        var newView = self
        newView.cornerRadius = radius
        return newView
    }

    /// Adds an action to perform when the checkout completes successfully.
    ///
    /// Use this modifier to handle successful checkout events:
    ///
    /// ```swift
    /// AcceleratedCheckoutButtons(cartID: cartId)
    ///     .onComplete { event in
    ///         // Navigate to success screen with order ID
    ///         showSuccessView(orderId: event.orderId)
    ///     }
    /// ```
    ///
    /// - Parameter action: The action to perform when checkout succeeds
    /// - Returns: A view with the checkout success handler set
    public func onComplete(_ action: @escaping (CheckoutCompletedEvent) -> Void)
        -> AcceleratedCheckoutButtons
    {
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
    ///     .onFail { error in
    ///         // Show error alert with details
    ///         showErrorAlert(error: error)
    ///     }
    /// ```
    ///
    /// - Parameter action: The action to perform when checkout fails
    /// - Returns: A view with the checkout error handler set
    public func onFail(_ action: @escaping (CheckoutError) -> Void) -> AcceleratedCheckoutButtons {
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
        _ action: @escaping (CheckoutError) -> Bool
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
    public func onWebPixelEvent(_ action: @escaping (PixelEvent) -> Void)
        -> AcceleratedCheckoutButtons
    {
        var newView = self
        newView.eventHandlers.checkoutDidEmitWebPixelEvent = action
        return newView
    }

    /// Adds an action to perform when the render state changes.
    ///
    /// Use this modifier to handle render state changes:
    ///
    /// ```swift
    /// AcceleratedCheckoutButtons(cartID: cartId)
    ///     .onRenderStateChange { state in
    ///         switch state {
    ///         case .loading:
    ///             // Show skeleton loading state
    ///         case .rendered:
    ///             // Show rendered buttons
    ///         case .fallback:
    ///             // Show error fallback state
    ///         }
    ///     }
    /// ```
    ///
    /// - Parameter action: The action to perform when render state changes
    /// - Returns: A view with the render state change handler set
    public func onRenderStateChange(_ action: @escaping (RenderState) -> Void)
        -> AcceleratedCheckoutButtons
    {
        var newView = self
        newView.eventHandlers.renderStateDidChange = action
        return newView
    }
}
