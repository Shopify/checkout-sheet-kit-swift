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

@available(iOS 17.0, *)
class ApplePayAuthorizationDelegate: NSObject, ObservableObject {
    let configuration: ApplePayConfigurationWrapper
    let abortError = ShopifyAcceleratedCheckouts.Error.invariant(expected: "cart")
    var controller: PayController

    /// A URL that will render checkout for the cart contents
    var checkoutURL: URL?

    /// URL to be passed to ShopifyCheckoutSheetKit.present
    /// Selects the url based on the current State
    var url: URL? {
        if case let .cartSubmittedForCompletion(redirectURL) = state {
            return redirectURL
        }

        guard let checkoutURL else { return nil }
        guard case let .interrupt(reason) = state else { return checkoutURL }

        return checkoutURL.appendQueryParam(name: reason.queryParam, value: "true")
    }

    var selectedShippingAddressID: StorefrontAPI.Types.ID?

    var pkEncoder: PKEncoder
    var pkDecoder: PKDecoder

    init(configuration: ApplePayConfigurationWrapper, controller: PayController) {
        self.configuration = configuration
        self.controller = controller

        pkEncoder = PKEncoder(configuration: configuration, cart: { controller.cart })
        pkDecoder = PKDecoder(configuration: configuration, cart: { controller.cart })
    }

    private(set) var state: ApplePayState = .idle {
        didSet {
            #if DEBUG
                print(
                    "ApplePayState: \(String(describing: oldValue)) -> \(String(describing: state))",
                    terminator: "\n---\n"
                )
            #endif
        }
    }

    private func startPaymentRequest() async throws {
        guard let cart = controller.cart else { return }
        try setCart(to: cart)
        let paymentRequest = try pkDecoder.createPaymentRequest()

        let paymentController = PKPaymentAuthorizationController(paymentRequest: paymentRequest)
        paymentController.delegate = self
        let presented = await paymentController.present()

        await transition(to: presented ? .appleSheetPresented : .reset)
    }

    func transition(to nextState: ApplePayState) async {
        guard state.canTransition(to: nextState) else {
            #if DEBUG
                print(
                    "⚠️ Invalid state transition attempted: \(String(describing: state)) -> \(String(describing: nextState))"
                )
            #endif
            return
        }

        let previousState = state
        state = nextState

        switch state {
        case .startPaymentRequest:
            try? await startPaymentRequest()

        case .reset:
            await onReset()

        case let .presentingCSK(url):
            await onPresentingCSK(to: url, previousState: previousState)

        /// As a "terminal" state, acts as a decision point to either:
        /// - present TYP (redirectUrl)
        /// - present Checkout to resolve errors (checkoutUrl, possibly with interrupt query params)
        /// - transition to .reset e.g. if user is dismissing/cancelling the payment sheets
        case .completed:
            await onCompleted(previousState: previousState)

        default:
            break
        }
    }

    private func onReset() async {
        pkEncoder = PKEncoder(configuration: configuration, cart: { self.controller.cart })
        pkDecoder = PKDecoder(configuration: configuration, cart: { self.controller.cart })
        selectedShippingAddressID = nil
        checkoutURL = nil
        await transition(to: .idle)
    }

    private func onPresentingCSK(to url: URL?, previousState: ApplePayState) async {
        guard let url else { return }

        if case let .cartSubmittedForCompletion(redirectURL) = previousState {
        } else {
            try? await _Concurrency.Task.retrying {
                let cartID = try self.pkEncoder.cartID.get()
                try await self.controller.storefrontJulyRelease.cartRemovePersonalData(
                    id: cartID
                )
            }.value
        }

        try? await controller.present(url: url)
    }

    private func onCompleted(previousState: ApplePayState) async {
        switch previousState {
        case .paymentAuthorizationFailed,
            .unexpectedError,
            .interrupt:
            await transition(to: .presentingCSK(url: url))

        case let .cartSubmittedForCompletion(redirectURL):
            await transition(to: .presentingCSK(url: redirectURL))

        default:
            await transition(to: .reset)
        }
    }

    func setCart(to cart: StorefrontAPI.Types.Cart?) throws {
        controller.cart = cart
        checkoutURL = cart?.checkoutUrl.url

        try ensureCurrencyNotChanged()
    }

    func ensureCurrencyNotChanged() throws {
        guard let initialCurrencyCode = pkDecoder.initialCurrencyCode else {
            return
        }
        let currentCurrencyCode = controller.cart?.cost.totalAmount.currencyCode

        guard initialCurrencyCode == currentCurrencyCode else {
            throw StorefrontAPI.Errors.currencyChanged
        }
    }

    func getTopViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let window = windowScene.windows.first
        else {
            return nil
        }

        var topController = window.rootViewController
        while let presentedController = topController?.presentedViewController {
            topController = presentedController
        }
        return topController
    }

    func upsertShippingAddress(to address: StorefrontAPI.Types.Address, validate: Bool = false)
        async throws -> StorefrontAPI.Types.Cart
    {
        let cartID = try pkEncoder.cartID.get()

        if let addressID = selectedShippingAddressID {
            return try await controller.storefront.cartDeliveryAddressesUpdate(
                id: cartID,
                addressId: addressID,
                address: address,
                validate: validate
            )
        }

        let cart = try await controller.storefront.cartDeliveryAddressesAdd(
            id: cartID,
            address: address,
            validate: validate
        )

        selectedShippingAddressID = cart.delivery?.addresses.first { $0.selected }?.id

        return cart
    }
}
