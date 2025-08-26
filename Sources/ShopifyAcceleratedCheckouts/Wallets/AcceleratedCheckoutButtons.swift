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
public enum RenderState: Equatable {
    case loading
    case rendered
    case error(reason: String)
}

/// Renders a Checkout buttons for a cart or product variant
///
/// Note:
/// - The `wallets` modifier can be used to limit the buttons rendered
/// - The order of the buttons is the same as the order of the `wallets` modifier
/// - omission of the `wallets` modifier will render all buttons
@available(iOS 16.0, *)
public struct AcceleratedCheckoutButtons: View {
    @EnvironmentObject
    private var configuration: ShopifyAcceleratedCheckouts.Configuration

    let identifier: CheckoutIdentifier
    public var wallets: [Wallet] = [.shopPay, .applePay]
    var eventHandlers: EventHandlers = .init()
    var checkoutDelegate: CheckoutDelegate?
    var cornerRadius: CGFloat?

    /// The Apple Pay button label style
    private var applePayLabel: PayWithApplePayButtonLabel = .plain

    @State private var shopSettings: ShopSettings?
    @State private var currentRenderState: RenderState = .loading {
        didSet {
            eventHandlers.renderStateDidChange?(currentRenderState)
        }
    }

    /// Initializes an Apple Pay button with a cart ID
    /// - Parameters:
    ///   - cartID: The cart ID to checkout (must start with gid://shopify/Cart/)
    ///   - label: The label to display on the Apple Pay button
    public init(cartID: String) {
        identifier = .cart(cartID: cartID).parse()
        if case let .invariant(reason) = identifier {
            ShopifyAcceleratedCheckouts.logger.error(reason)
            _currentRenderState = State(initialValue: .error(reason: reason))
        }
    }

    /// Initializes an Apple Pay button with a variant ID
    /// - Parameters:
    ///  - variantID: The variant ID to checkout (must start with gid://shopify/ProductVariant/)
    ///  - quantity: The quantity of the variant to checkout
    ///  - label: The label to display on the Apple Pay button
    public init(variantID: String, quantity: Int) {
        identifier = .variant(variantID: variantID, quantity: quantity).parse()
        if case let .invariant(reason) = identifier {
            _currentRenderState = State(initialValue: .error(reason: reason))
            ShopifyAcceleratedCheckouts.logger.error(reason)
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
                                checkoutDelegate: checkoutDelegate,
                                cornerRadius: cornerRadius
                            )
                            .label(applePayLabel)
                        case .shopPay:
                            ShopPayButton(
                                identifier: identifier,
                                eventHandlers: eventHandlers,
                                checkoutDelegate: checkoutDelegate,
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
            let reason = "Error loading shop settings: \(error)"
            ShopifyAcceleratedCheckouts.logger.error(reason)
            currentRenderState = .error(reason: reason)
        }
    }
}

// MARK: AcceleratedCheckoutButtons Modifiers

@available(iOS 16.0, *)
extension AcceleratedCheckoutButtons {
    public func applePayLabel(_ label: PayWithApplePayButtonLabel) -> AcceleratedCheckoutButtons {
        var view = self
        view.applePayLabel = label
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

    /// Sets the checkout delegate for handling checkout flow events
    ///
    /// Use this modifier to provide a delegate for checkout completion, failure, and cancellation events:
    ///
    /// ```swift
    /// AcceleratedCheckoutButtons(cartID: cartId)
    ///     .checkout(delegate: MyCheckoutDelegate())
    /// ```
    ///
    /// - Parameter delegate: The checkout delegate to handle checkout flow events
    /// - Returns: A view with the checkout delegate set
    public func checkout(delegate: CheckoutDelegate) -> AcceleratedCheckoutButtons {
        var newView = self
        newView.checkoutDelegate = delegate
        return newView
    }

    /// Adds an action to perform when validation or configuration errors occur
    ///
    /// Use this modifier to handle validation errors and configuration issues:
    ///
    /// ```swift
    /// AcceleratedCheckoutButtons(cartID: cartId)
    ///     .onError { error in
    ///         switch error {
    ///         case .validation(let validationError):
    ///             // Handle validation errors
    ///             print("Validation failed: \(validationError.description)")
    ///         }
    ///     }
    /// ```
    ///
    /// - Parameter action: The action to perform when errors occur
    /// - Returns: A view with the error handler set
    public func onError(_ action: @escaping (AcceleratedCheckoutError) -> Void) -> AcceleratedCheckoutButtons {
        var newView = self
        newView.eventHandlers.validationDidFail = action
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
