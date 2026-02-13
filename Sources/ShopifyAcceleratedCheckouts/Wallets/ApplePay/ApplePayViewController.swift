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
    @Published var storefrontJulyRelease: StorefrontAPIProtocol
    @Published var paymentController: PKPaymentAuthorizationController?

    var cart: StorefrontAPI.Types.Cart?

    var client: (any CheckoutCommunicationProtocol)?

    // MARK: - Callback Properties

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

    /// Initialization workaround for passing self to ApplePayAuthorizationDelegate
    private var __authorizationDelegate: ApplePayAuthorizationDelegate!
    var authorizationDelegate: ApplePayAuthorizationDelegate {
        __authorizationDelegate
    }

    init(
        identifier: CheckoutIdentifier,
        configuration: ApplePayConfigurationWrapper,
        client: (any CheckoutCommunicationProtocol)? = nil
    ) {
        storefrontJulyRelease = StorefrontAPI(
            storefrontDomain: configuration.common.storefrontDomain,
            storefrontAccessToken: configuration.common.storefrontAccessToken,
            apiVersion: "2025-07"
        )
        super.init(
            identifier: identifier,
            storefront: StorefrontAPI(
                storefrontDomain: configuration.common.storefrontDomain,
                storefrontAccessToken: configuration.common.storefrontAccessToken
            ),
            configuration: configuration.common
        )
        __authorizationDelegate = ApplePayAuthorizationDelegate(
            configuration: configuration,
            controller: self
        )

        self.client = LifecycleObservingClient(base: client, onComplete: { [weak self] in
            guard let self else { return }
            Task {
                try? await self.authorizationDelegate.transition(to: .completed)
            }
        })
    }

    func onPress() async {
        do {
            let cart = try await createOrfetchCart()

            self.cart = cart

            return try await authorizationDelegate.transition(to: .startPaymentRequest)
        } catch {
            ShopifyAcceleratedCheckouts.logger.error(
                "[startPayment] Failed to setup cart: \(error)"
            )
            Task { @MainActor in
                self.onCheckoutFail?(.sdkError(underlying: error, recoverable: false))
            }
        }

        do {
            return try await authorizationDelegate.transition(to: .completed)
        } catch {
            ShopifyAcceleratedCheckouts.logger.error(
                "[startPayment] Failed to reset ApplePayState: \(error)"
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
        try await present(url: url, client: client)
    }
}
