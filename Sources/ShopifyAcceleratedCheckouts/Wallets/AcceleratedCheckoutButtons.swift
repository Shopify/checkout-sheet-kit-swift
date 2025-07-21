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
/// - The `wallets` modifier can be used to limit the buttons rendered
/// - The order of the buttons is the same as the order of the `wallets` modifier
/// - omission of the `wallets` modifier will render all buttons
@available(iOS 17.0, *)
public struct AcceleratedCheckoutButtons: View {
    @Environment(ShopifyAcceleratedCheckouts.Configuration.self)
    private var configuration

    let identifier: CheckoutIdentifier
    var wallets: [WalletType] = [.shopPay, .applePay]
    var eventHandlers: EventHandlers = .init()
    var cornerRadius: CGFloat?

    @State private var shopSettings: ShopSettings?
    @State private var currentState: RenderState = .loading

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
        if identifier.isValid() == false {
            let error = NSError(domain: "AcceleratedCheckoutButtons", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Invalid variant ID"])
            _currentState = State(initialValue: .fallback(reason: .configurationError(error)))
        }
    }

    public var body: some View {
        if identifier.isValid() {
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
                            case .shopPay:
                                ShopPayButton(
                                    identifier: identifier,
                                    eventHandlers: eventHandlers,
                                    cornerRadius: cornerRadius
                                )
                            }
                        }
                    }.environment(shopSettings)
                        .onAppear {
                            updateRenderState()
                        }
                }
            }
            .task { await loadShopSettings() }
        }
    }

    private func loadShopSettings() async {
        // Start in loading state
        await MainActor.run {
            currentState = .loading
            eventHandlers.stateDidChange?(currentState)
        }

        do {
            shopSettings = try await ShopSettings.load(
                storefront: StorefrontAPI(
                    storefrontDomain: configuration.storefrontDomain,
                    storefrontAccessToken: configuration.storefrontAccessToken
                ))

            // Once shop settings are loaded, update the render state
            await MainActor.run {
                updateRenderState()
            }
        } catch {
            print("Error loading shop settings: \(error)")
            await MainActor.run {
                currentState = .fallback(reason: .unexpectedError(error))
                eventHandlers.stateDidChange?(currentState)
            }
        }
    }

    private func updateRenderState() {
        Task {
            var availableWallets: [WalletType] = []
            var unavailableReasons: [UnavailableReason] = []

            // Check each wallet's availability
            for walletType in wallets {
                let isAvailable = await checkWalletAvailability(walletType)
                if isAvailable {
                    availableWallets.append(walletType)
                } else {
                    if let reason = await getUnavailableReason(for: walletType) {
                        unavailableReasons.append(reason)
                    }
                }
            }

            // Determine the render state
            let newState: RenderState
            if availableWallets.count == wallets.count {
                // All wallets are available
                newState = .ready(availableWallets: availableWallets)
            } else if availableWallets.isEmpty {
                // No wallets are available
                newState = .fallback(reason: .noWalletsAvailable)
            } else {
                // Some wallets are available
                newState = .partiallyReady(availableWallets: availableWallets, unavailableReasons: unavailableReasons)
            }

            await MainActor.run {
                currentState = newState
                eventHandlers.stateDidChange?(newState)
            }
        }
    }

    private func checkWalletAvailability(_ walletType: WalletType) async -> Bool {
        switch walletType {
        case .applePay:
            // First check if Apple Pay is supported by the shop
            guard let shopSettings,
                  shopSettings.paymentSettings.isApplePaySupported
            else {
                return false
            }

            // Check if Apple Pay is available on the device with shop's supported networks
            let supportedNetworks = shopSettings.paymentSettings.supportedNetworks
            if !supportedNetworks.isEmpty {
                return PKPaymentAuthorizationController.canMakePayments(usingNetworks: supportedNetworks)
            } else {
                // Fallback to general Apple Pay check if no specific networks
                return PKPaymentAuthorizationController.canMakePayments()
            }

        case .shopPay:
            // Check if Shop Pay is supported by the shop
            guard let shopSettings else {
                return false
            }
            return shopSettings.paymentSettings.isShopPaySupported
        }
    }

    private func getUnavailableReason(for walletType: WalletType) async -> UnavailableReason? {
        switch walletType {
        case .applePay:
            // Check shop support first
            guard let shopSettings else {
                return .networkUnavailable
            }

            guard shopSettings.paymentSettings.isApplePaySupported else {
                return .applePayUnsupportedRegion
            }

            // Check device support
            if !PKPaymentAuthorizationController.canMakePayments() {
                return .applePayNotSupported
            }

            // Check for specific card networks
            let supportedNetworks = shopSettings.paymentSettings.supportedNetworks
            if !supportedNetworks.isEmpty, !PKPaymentAuthorizationController.canMakePayments(usingNetworks: supportedNetworks) {
                return .applePayNotSetUp
            }

            return nil

        case .shopPay:
            guard let shopSettings else {
                return .networkUnavailable
            }

            guard shopSettings.paymentSettings.isShopPaySupported else {
                return .shopPayNotEnabled
            }

            return nil
        }
    }
}

// MARK: AcceleratedCheckoutButtons Modifiers

@available(iOS 17.0, *)
extension AcceleratedCheckoutButtons {
    /// Modifies the wallet options supported
    /// Defaults: [.applePay]
    public func wallets(_ wallets: [WalletType]) -> AcceleratedCheckoutButtons {
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

    /// Sets an event handler that's called when the render state changes.
    ///
    /// Use this to detect when payment methods become available/unavailable and provide alternative options or track analytics.
    ///
    /// ## Example
    /// ```swift
    /// AcceleratedCheckoutButtons(cartID: cartId)
    ///     .onRenderStateChange { state in
    ///         switch state {
    ///         case .loading:
    ///             showLoadingIndicator()
    ///         case .ready(let wallets):
    ///             hideLoadingIndicator()
    ///             analytics.track("accelerated_checkout_ready", properties: ["wallets": wallets.map(\.displayName)])
    ///         case .partiallyReady(let available, let unavailable):
    ///             hideLoadingIndicator()
    ///             analytics.track("accelerated_checkout_partial", properties: [
    ///                 "available": available.map(\.displayName),
    ///                 "unavailable": unavailable.map(\.displayName)
    ///             ])
    ///         case .fallback(let reason):
    ///             showFallbackUI()
    ///             analytics.track("accelerated_checkout_fallback", properties: ["reason": reason.displayName])
    ///         }
    ///     }
    /// ```
    ///
    /// - Parameter action: The action to perform when the render state changes
    /// - Returns: A view with the render state change handler set
    public func onRenderStateChange(_ action: @escaping RenderStateDidChange)
        -> AcceleratedCheckoutButtons
    {
        var newView = self
        newView.eventHandlers.stateDidChange = action
        return newView
    }
}
