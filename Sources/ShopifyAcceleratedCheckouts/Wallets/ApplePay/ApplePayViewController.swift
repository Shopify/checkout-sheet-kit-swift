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
@preconcurrency import ShopifyCheckoutSheetKit
import SwiftUI

@available(iOS 16.0, *)
protocol PayController: AnyObject {
    var cart: StorefrontAPI.Types.Cart? { get set }
    var storefront: StorefrontAPIProtocol { get set }
    /// Temporary workaround due to July release changing the validation strategy
    var storefrontJulyRelease: StorefrontAPIProtocol { get set }

    /// Opens ShopifyCheckoutSheetKit
    func present(url: URL) async throws
}

@available(iOS 16.0, *)
class ApplePayViewController: WalletController, PayController {
    @Published var configuration: ApplePayConfigurationWrapper
    @Published var storefrontJulyRelease: StorefrontAPIProtocol
    @Published var paymentController: PKPaymentAuthorizationController?

    var cart: StorefrontAPI.Types.Cart?

    // MARK: - Callback Properties

    /// Callback invoked when the checkout process completes successfully.
    /// This closure is called on the main thread after a successful payment.
    ///
    /// Example usage:
    /// ```swift
    /// applePayViewController.onCheckoutComplete = { [weak self] event in
    ///     self?.presentSuccessScreen()
    ///     self?.logAnalyticsEvent(.checkoutCompleted, orderId: event.orderId)
    /// }
    /// ```
    @MainActor
    public var onCheckoutComplete: ((CheckoutCompletedEvent) -> Void)?

    /// Callback invoked when an error occurs during the checkout process.
    /// This closure is called on the main thread when the payment fails.
    ///
    /// Example usage:
    /// ```swift
    /// applePayViewController.onCheckoutFail = { [weak self] error in
    ///     self?.showErrorAlert(for: error)
    ///     self?.logAnalyticsEvent(.checkoutFailed, error: error)
    /// }
    /// ```
    @MainActor
    public var onCheckoutFail: ((CheckoutError) -> Void)?

    /// Callback invoked when the checkout process is cancelled by the user.
    /// This closure is called on the main thread when the user dismisses the checkout.
    ///
    /// Example usage:
    /// ```swift
    /// applePayViewController.onCheckoutCancel = { [weak self] in
    ///     self?.resetCheckoutState()
    ///     self?.logAnalyticsEvent(.checkoutCancelled)
    /// }
    /// ```
    @MainActor
    public var onCheckoutCancel: (() -> Void)?

    /// Callback invoked to determine if checkout should recover from an error.
    /// This closure is called on the main thread when an error occurs.
    /// Return true to attempt recovery, false to fail immediately.
    ///
    /// Example usage:
    /// ```swift
    /// applePayViewController.onShouldRecoverFromError = { [weak self] error in
    ///     // Custom error recovery logic
    ///     return error.isRecoverable
    /// }
    /// ```
    @MainActor
    public var onShouldRecoverFromError: ((CheckoutError) -> Bool)?

    /// Callback invoked when the user clicks a link during checkout.
    /// This closure is called on the main thread when a link is clicked.
    ///
    /// Example usage:
    /// ```swift
    /// applePayViewController.onCheckoutClickLink = { [weak self] url in
    ///     self?.handleExternalLink(url)
    ///     self?.logAnalyticsEvent(.linkClicked, url: url)
    /// }
    /// ```
    @MainActor
    public var onCheckoutClickLink: ((URL) -> Void)?

    /// Callback invoked when a web pixel event is emitted during checkout.
    /// This closure is called on the main thread when pixel events occur.
    ///
    /// Example usage:
    /// ```swift
    /// applePayViewController.onCheckoutWebPixelEvent = { [weak self] event in
    ///     self?.trackPixelEvent(event)
    ///     self?.logAnalyticsEvent(.pixelFired, event: event)
    /// }
    /// ```
    @MainActor
    public var onCheckoutWebPixelEvent: ((PixelEvent) -> Void)?

    /// Initialization workaround for passing self to ApplePayAuthorizationDelegate
    private var __authorizationDelegate: ApplePayAuthorizationDelegate!
    var authorizationDelegate: ApplePayAuthorizationDelegate {
        __authorizationDelegate
    }

    init(
        identifier: CheckoutIdentifier,
        configuration: ApplePayConfigurationWrapper
    ) {
        self.configuration = configuration
        storefrontJulyRelease = StorefrontAPI(
            storefrontDomain: configuration.common.storefrontDomain,
            storefrontAccessToken: configuration.common.storefrontAccessToken,
            apiVersion: "2025-07"
        )
        super.init(identifier: identifier, storefront: StorefrontAPI(
            storefrontDomain: configuration.common.storefrontDomain,
            storefrontAccessToken: configuration.common.storefrontAccessToken
        ))
        __authorizationDelegate = ApplePayAuthorizationDelegate(
            configuration: configuration,
            controller: self
        )
    }

    func onPress() async {
        do {
            let cart = try await createOrfetchCart()

            self.cart = cart

            return try await authorizationDelegate.transition(to: .startPaymentRequest)
        } catch {
            await onCheckoutFail?(.sdkError(underlying: error))
            ShopifyAcceleratedCheckouts.logger.error(
                "[startPayment] Failed to setup cart: \(error)"
            )
        }

        do {
            return try await authorizationDelegate.transition(to: .completed)
        } catch {
            ShopifyAcceleratedCheckouts.logger.error(
                "[startPayment] Failed to setup cart: \(error)"
            )
        }
    }

    func createOrfetchCart() async throws -> StorefrontAPI.Types.Cart {
        do {
            return try await fetchCartByCheckoutIdentifier()
        } catch let error as StorefrontAPI.Errors {
            return try await handleStorefrontError(error)
        } catch {
            try? await authorizationDelegate.transition(to: .terminalError(error: error))
            throw error
        }
    }

    private func handleStorefrontError(_ error: StorefrontAPI.Errors) async throws
        -> StorefrontAPI.Types.Cart
    {
        switch error {
        case let .userError(userErrors, cart):
            guard let cart else { throw error }
            let action = ErrorHandler.map(errors: userErrors, shippingCountry: nil, cart: cart)
            try await handleErrorAction(action: action, cart: cart)
            return cart

        case let .warning(type, cart):
            guard let cart else { throw error }
            let action = ErrorHandler.map(warningType: type, cart: cart)
            try await handleErrorAction(action: action, cart: cart)
            return cart

        default:
            try? await authorizationDelegate.transition(to: .unexpectedError(error: error))
            throw error
        }
    }

    /// action.showError will no-op prior to ApplePayState.appleSheetPresented
    private func handleErrorAction(
        action: ErrorHandler.PaymentSheetAction,
        cart: StorefrontAPI.Types.Cart
    ) async throws {
        if case let .interrupt(reason, _) = action {
            try authorizationDelegate.setCart(to: cart)
            try? await authorizationDelegate.transition(to: .interrupt(reason: reason))
        }
    }

    func present(url: URL) async throws {
        try await present(url: url, delegate: self)
    }
}

@available(iOS 16.0, *)
extension ApplePayViewController: CheckoutDelegate {
    func checkoutDidComplete(event: CheckoutCompletedEvent) {
        Task { @MainActor in
            self.onCheckoutComplete?(event)
            try await authorizationDelegate.transition(to: .completed)
        }
    }

    func checkoutDidFail(error: CheckoutError) {
        Task { @MainActor in
            self.onCheckoutFail?(error)
        }
    }

    func checkoutDidCancel() {
        Task { @MainActor in
            /// x right button on CSK doesn't dismiss automatically
            checkoutViewController?.dismiss(animated: true)
            self.onCheckoutCancel?()
            try await authorizationDelegate.transition(to: .completed)
        }
    }

    @MainActor func shouldRecoverFromError(error: CheckoutError) -> Bool {
        return onShouldRecoverFromError?(error) ?? error.isRecoverable
    }

    func checkoutDidClickLink(url: URL) {
        Task { @MainActor in
            self.onCheckoutClickLink?(url)
        }
    }

    func checkoutDidEmitWebPixelEvent(event: PixelEvent) {
        Task { @MainActor in
            self.onCheckoutWebPixelEvent?(event)
        }
    }
}
