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
    var storefront: StorefrontAPI { get set }
    /// Temporary workaround due to July release changing the validation strategy
    var storefrontJulyRelease: StorefrontAPI { get set }

    /// Opens ShopifyCheckoutSheetKit
    func present(url: URL) async throws
}

@available(iOS 16.0, *)
class ApplePayViewController: PayController, ObservableObject {
    @Published var configuration: ApplePayConfigurationWrapper
    @Published var storefront: StorefrontAPI
    @Published var storefrontJulyRelease: StorefrontAPI
    @Published var identifier: CheckoutIdentifier
    @Published var checkoutViewController: CheckoutViewController?
    @Published var paymentController: PKPaymentAuthorizationController?

    var cart: StorefrontAPI.Types.Cart?

    /// The checkout delegate for handling checkout flow events
    private weak var checkoutDelegate: CheckoutDelegate?

    // MARK: - Callback Properties

    /// Callback invoked when cart validation fails.
    /// This closure is called on the main thread when the input data is rejected by the API.
    ///
    /// Example usage:
    /// ```swift
    /// applePayViewController.onValidationFail = { [weak self] validationError in
    ///     // Handle validation error
    ///     print("Validation failed: \(validationError)")
    /// }
    /// ```
    @MainActor
    public var onValidationFail: ((AcceleratedCheckoutError) -> Void)?

    /// Initialization workaround for passing self to ApplePayAuthorizationDelegate
    private var __authorizationDelegate: ApplePayAuthorizationDelegate!
    var authorizationDelegate: ApplePayAuthorizationDelegate {
        __authorizationDelegate
    }

    init(
        identifier: CheckoutIdentifier,
        configuration: ApplePayConfigurationWrapper,
        checkoutDelegate: CheckoutDelegate? = nil
    ) {
        self.configuration = configuration
        self.identifier = identifier.parse()
        self.checkoutDelegate = checkoutDelegate
        storefront = StorefrontAPI(
            storefrontDomain: configuration.common.storefrontDomain,
            storefrontAccessToken: configuration.common.storefrontAccessToken
        )
        storefrontJulyRelease = StorefrontAPI(
            storefrontDomain: configuration.common.storefrontDomain,
            storefrontAccessToken: configuration.common.storefrontAccessToken,
            apiVersion: "2025-07"
        )
        __authorizationDelegate = ApplePayAuthorizationDelegate(
            configuration: configuration,
            controller: self
        )
    }

    func startPayment() async {
        do {
            cart = try await createOrfetchCart()
            guard cart != nil else {
                throw ShopifyAcceleratedCheckouts.Error.invariant(expected: "cart")
            }
            try? await authorizationDelegate.transition(to: .startPaymentRequest)
        } catch {
            ShopifyAcceleratedCheckouts.logger.error("[startPayment] Failed to setup cart: \(error)")
            try? await authorizationDelegate.transition(to: .completed)
        }
    }

    func createOrfetchCart() async throws -> StorefrontAPI.Types.Cart {
        do {
            switch identifier {
            case let .cart(id):
                guard let cart = try await storefront.cart(by: .init(id)) else {
                    throw ShopifyAcceleratedCheckouts.Error.invariant(expected: "cart")
                }
                return cart
            case let .variant(id, quantity):
                let items: [StorefrontAPI.Types.ID] = Array(repeating: .init(id), count: quantity)
                return try await storefront.cartCreate(with: items)
            case .invariant:
                throw ShopifyAcceleratedCheckouts.Error.invariant(expected: "checkoutIdentifier")
            }
        } catch let error as StorefrontAPI.Errors {
            return try await handleStorefrontError(error)
        } catch let validationError as StorefrontAPI.CartValidationError {
            // Direct path for validation errors - never becomes CheckoutError.sdkError
            let publicValidationError = ValidationError(from: validationError)
            let acceleratedError = AcceleratedCheckoutError.validation(publicValidationError)
            await onValidationFail?(acceleratedError)
            try? await authorizationDelegate.transition(to: .terminalError(error: validationError))
            throw validationError
        } catch {
            if let checkoutError = error as? CheckoutError {
                await checkoutDelegate?.checkoutDidFail(error: checkoutError)
            }
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

    private func handleErrorAction(
        /// showError action is not handled uniqely and will present the apple pay sheet with errors
        action: ErrorHandler.PaymentSheetAction,
        cart: StorefrontAPI.Types.Cart
    ) async throws {
        if case let .interrupt(reason, _) = action {
            try authorizationDelegate.setCart(to: cart)
            try? await authorizationDelegate.transition(to: .interrupt(reason: reason))
        }
    }

    func present(url: URL) async throws {
        let topViewController = await MainActor.run { authorizationDelegate.getTopViewController() }

        guard let topViewController else {
            throw ShopifyAcceleratedCheckouts.Error.invariant(expected: "topViewController")
        }

        _ = await MainActor.run {
            self.checkoutViewController = ShopifyCheckoutSheetKit.present(
                checkout: url,
                from: topViewController,
                entryPoint: .acceleratedCheckouts,
                delegate: self
            )
        }
    }
}

@available(iOS 16.0, *)
extension ApplePayViewController: CheckoutDelegate {
    func checkoutDidComplete(event: CheckoutCompletedEvent) {
        Task { @MainActor in
            self.checkoutDelegate?.checkoutDidComplete(event: event)
            try await authorizationDelegate.transition(to: .completed)
        }
    }

    func checkoutDidFail(error: CheckoutError) {
        Task { @MainActor in
            self.checkoutDelegate?.checkoutDidFail(error: error)
        }
    }

    func checkoutDidCancel() {
        Task { @MainActor in
            /// x right button on CSK doesn't dismiss automatically
            checkoutViewController?.dismiss(animated: true)
            self.checkoutDelegate?.checkoutDidCancel()
            try await authorizationDelegate.transition(to: .completed)
        }
    }

    @MainActor func shouldRecoverFromError(error: CheckoutError) -> Bool {
        return checkoutDelegate?.shouldRecoverFromError(error: error) ?? false
    }

    func checkoutDidClickLink(url: URL) {
        Task { @MainActor in
            self.checkoutDelegate?.checkoutDidClickLink(url: url)
        }
    }

    func checkoutDidEmitWebPixelEvent(event: PixelEvent) {
        Task { @MainActor in
            self.checkoutDelegate?.checkoutDidEmitWebPixelEvent(event: event)
        }
    }
}
