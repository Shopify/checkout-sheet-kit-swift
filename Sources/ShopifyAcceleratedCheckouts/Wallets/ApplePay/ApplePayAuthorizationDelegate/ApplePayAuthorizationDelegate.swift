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

import Foundation
import PassKit
import ShopifyCheckoutSheetKit

// MARK: - PaymentAuthorizationController Protocol

/// Protocol to abstract PKPaymentAuthorizationController for testing
@available(iOS 16.0, *)
protocol PaymentAuthorizationController {
    var delegate: PKPaymentAuthorizationControllerDelegate? { get set }
    func present() async -> Bool
    func dismiss(completion: (() -> Void)?)
}

extension PKPaymentAuthorizationController: PaymentAuthorizationController {}

@available(iOS 16.0, *)
typealias PKAuthorizationControllerFactory = (PKPaymentRequest) -> PaymentAuthorizationController

@available(iOS 16.0, *)
class ApplePayAuthorizationDelegate: NSObject, ObservableObject, Loggable {
    let configuration: ApplePayConfigurationWrapper
    let abortError = ShopifyAcceleratedCheckouts.Error.invariant(expected: "cart")
    var controller: PayController

    /// Factory for creating PaymentAuthorizationController instances - injectable for testing
    var paymentControllerFactory: PKAuthorizationControllerFactory

    /// Clock dependency for controlling time-based operations - injectable for testing
    let clock: Clock

    /// A URL that will render checkout for the cart contents
    var checkoutURL: URL?

    /// Computes URL for a given state
    func createSheetKitURL(for state: ApplePayState) -> URL? {
        if case let .cartSubmittedForCompletion(redirectURL) = state {
            return redirectURL
        }

        guard let checkoutURL else { return nil }
        guard case let .interrupt(reason) = state else {
            return checkoutURL
        }

        // If there's no query param to add, just return the checkout URL
        guard let queryParam = reason.queryParam else {
            return checkoutURL
        }

        // Try to append the query param, fall back to checkout URL if it fails
        return checkoutURL.appendQueryParam(name: queryParam, value: "true") ?? checkoutURL
    }

    var selectedShippingAddressID: StorefrontAPI.Types.ID?

    var pkEncoder: PKEncoder
    var pkDecoder: PKDecoder

    init(
        configuration: ApplePayConfigurationWrapper,
        controller: PayController,
        paymentControllerFactory: @escaping PKAuthorizationControllerFactory = {
            PKPaymentAuthorizationController(paymentRequest: $0)
        },
        clock: Clock = SystemClock()
    ) {
        self.configuration = configuration
        self.controller = controller
        self.paymentControllerFactory = paymentControllerFactory
        self.clock = clock

        pkEncoder = PKEncoder(configuration: configuration, cart: { controller.cart })
        pkDecoder = PKDecoder(configuration: configuration, cart: { controller.cart })
    }

    private(set) var state: ApplePayState = .idle {
        didSet {
            logDebug("State transition: \(String(describing: oldValue)) -> \(String(describing: state))")
        }
    }

    private func startPaymentRequest() async throws {
        logDebug("Starting Apple Pay payment request")
        guard let cart = controller.cart else {
            logError("No cart available for payment request")
            return
        }
        try setCart(to: cart)
        let paymentRequest = try pkDecoder.createPaymentRequest()

        var paymentController = paymentControllerFactory(paymentRequest)
        paymentController.delegate = self
        let presented = await paymentController.present()

        logDebug("Apple Pay sheet presented: \(presented)")
        try await transition(to: presented ? .appleSheetPresented : .reset)
    }

    func transition(to nextState: ApplePayState) async throws {
        guard state.canTransition(to: nextState) else {
            logError("Invalid state transition: \(String(describing: state)) -> \(String(describing: nextState)).")
            throw InvalidStateTransitionError(fromState: state, toState: nextState)
        }

        let previousState = state
        state = nextState

        switch state {
        case .startPaymentRequest:
            try? await startPaymentRequest()

        case .reset:
            try await onReset()

        case let .presentingCSK(url):
            try await onPresentingCSK(to: url, previousState: previousState)

        /// As a "terminal" state, acts as a decision point to either:
        /// - present TYP (redirectUrl)
        /// - present Checkout to resolve errors (checkoutUrl, possibly with interrupt query params)
        /// - transition to .reset e.g. if user is dismissing/cancelling the payment sheets
        case .completed:
            try await onCompleted(previousState: previousState)

        default:
            break
        }
    }

    private func onReset() async throws {
        pkEncoder = PKEncoder(configuration: configuration, cart: { self.controller.cart })
        pkDecoder = PKDecoder(configuration: configuration, cart: { self.controller.cart })
        selectedShippingAddressID = nil
        checkoutURL = nil
        try await transition(to: .idle)
    }

    private func onPresentingCSK(to url: URL?, previousState: ApplePayState) async throws {
        guard let url else {
            logError("No URL available for checkout sheet presentation")
            try await transition(
                to: .terminalError(
                    error: ShopifyAcceleratedCheckouts.Error.invariant(expected: "url")
                )
            )
            return
        }

        switch previousState {
        case .cartSubmittedForCompletion:
            break
        default:
            let cartID = try pkEncoder.cartID.get()
            try? await _Concurrency.Task.retrying(clock: clock) {
                try await self.controller.storefrontJulyRelease.cartRemovePersonalData(id: cartID)
            }.value

            logDebug("Cleared PII from cart")

            do {
                /// `cartRemovePersonalData` is used to clear PII collected via ApplePay
                /// This removes some data potentially provided externally
                /// e.g. via ShopifyAcceleratedCheckouts.Configuration.Customer
                /// It is safe for us to re-attach this prior to displaying CSK
                if let customer = configuration.common.customer,
                   customer.email != nil || customer.phoneNumber != nil
                   || customer.customerAccessToken != nil
                {
                    try await controller.storefront.cartBuyerIdentityUpdate(
                        id: cartID,
                        input: .init(
                            email: configuration.common.customer?.email,
                            phoneNumber: configuration.common.customer?.phoneNumber,
                            customerAccessToken: configuration.common.customer?.customerAccessToken
                        )
                    )

                    logDebug("Updated cart with ShopifyAcceleratedCheckouts.Customer")
                }
            } catch {
                /// Whilst it would be best to be able to re-attach this, we can still present CSK
                /// without a successful response on `cartBuyerIdentityUpdate`
                logError("Failed to attach cart buyer identity: \(error) continuing with CheckoutKit.present()")
            }
        }

        try? await controller.present(url: url)
    }

    private func onCompleted(previousState: ApplePayState) async throws {
        switch previousState {
        case .paymentAuthorizationFailed,
             .unexpectedError,
             .interrupt:
            try await transition(to: .presentingCSK(url: createSheetKitURL(for: previousState)))

        case let .cartSubmittedForCompletion(redirectURL):
            try await transition(to: .presentingCSK(url: redirectURL))

        default:
            try await transition(to: .reset)
        }
    }

    func setCart(to cart: StorefrontAPI.Types.Cart?) throws {
        controller.cart = cart
        checkoutURL = cart?.checkoutUrl.url

        try ensureCurrencyNotChanged()
    }

    func ensureCurrencyNotChanged() throws {
        guard let initialCurrencyCode = pkDecoder.initialCurrencyCode else {
            logError("initialCurrencyCode was nil")
            return
        }
        let currentCurrencyCode = controller.cart?.cost.totalAmount.currencyCode

        guard initialCurrencyCode == currentCurrencyCode else {
            logError("currencyCodeChanged")
            throw StorefrontAPI.Errors.currencyChanged
        }
    }

    func upsertShippingAddress(to address: StorefrontAPI.Types.Address, validate: Bool = false)
        async throws -> StorefrontAPI.Types.Cart
    {
        let cartID = try pkEncoder.cartID.get()

        if let addressID = selectedShippingAddressID {
            do {
                // First, remove the existing delivery address to clear any tax policy contamination
                _ = try await controller.storefront.cartDeliveryAddressesRemove(
                    id: cartID,
                    addressId: addressID
                )

                logDebug("Clearing selectedShippingAddress")
                // Clear the selected address ID since we removed it
                selectedShippingAddressID = nil
            } catch {
                logError("Delivery address remove failed: \(error)")
            }
        }

        let cart = try await controller.storefront.cartDeliveryAddressesAdd(
            id: cartID,
            address: address,
            validate: validate
        )
        logDebug("cartDeliveryAddressesAdd complete: \(address)")

        selectedShippingAddressID = cart.delivery?.addresses.first { $0.selected }?.id
        logDebug("New selectedShippingAddressID: \(address)")

        return cart
    }
}

// MARK: - InvalidStateTransitionError

/// Error thrown when an invalid state transition is attempted
@available(iOS 16.0, *)
struct InvalidStateTransitionError: Error {
    let fromState: ApplePayState
    let toState: ApplePayState

    var localizedDescription: String {
        return
            "Invalid state transition attempted: \(String(describing: fromState)) -> \(String(describing: toState))"
    }
}
