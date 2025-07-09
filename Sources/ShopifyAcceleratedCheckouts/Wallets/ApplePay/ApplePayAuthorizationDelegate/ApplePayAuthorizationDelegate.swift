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
    let abortError = ShopifyAcceleratedCheckouts.Error.invariant(message: .nilCart)
    var controller: PayController
    var checkoutViewController: CheckoutViewController?

    var checkoutURL: URL?
    var redirectURL: URL?
    var url: URL? {
        if let redirectURL {
            return redirectURL
        }
        if let checkoutURL {
            if let interruptUrl = checkoutURL.appendQueryParam(name: interruptReason?.queryParam, value: "true") {
                return interruptUrl
            }

            return checkoutURL
        }
        return nil
    }

    var interruptReason: ErrorHandler.InterruptReason?

    var paymentRequest: PKPaymentRequest?

    var selectedShippingAddressID: StorefrontAPI.Types.ID?

    var pkEncoder: PKEncoder
    var pkDecoder: PKDecoder

    var isFailure = false

    init(configuration: ApplePayConfigurationWrapper, controller: PayController) {
        self.configuration = configuration
        self.controller = controller

        pkEncoder = PKEncoder(configuration: configuration, cart: { controller.cart })
        pkDecoder = PKDecoder(configuration: configuration, cart: { controller.cart })
    }

    func presentPaymentSheet() async throws {
        guard let cart = controller.cart else { return }
        try setCart(to: cart)
        let paymentRequest = try pkDecoder.createPaymentRequest()
        self.paymentRequest = paymentRequest

        let paymentController = PKPaymentAuthorizationController(paymentRequest: paymentRequest)
        paymentController.delegate = self
        let presented = await paymentController.present()
        print("Controller presented: \(presented)")
    }

    func reset() {
        redirectURL = nil
        interruptReason = nil
        paymentRequest = nil
        isFailure = false
        pkEncoder = PKEncoder(configuration: configuration, cart: { self.controller.cart })
        pkDecoder = PKDecoder(configuration: configuration, cart: { self.controller.cart })
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

extension ApplePayAuthorizationDelegate: CheckoutDelegate {
    func checkoutDidComplete(event _: ShopifyCheckoutSheetKit.CheckoutCompletedEvent) {
        if let applePayViewController = controller as? ApplePayViewController {
            Task { @MainActor in
                applePayViewController.onComplete?()
            }
        }
    }

    func checkoutDidFail(error _: ShopifyCheckoutSheetKit.CheckoutError) {
        if let applePayViewController = controller as? ApplePayViewController {
            Task { @MainActor in
                applePayViewController.onFail?()
            }
        }
    }

    func checkoutDidCancel() {
        /// x right button on CSK doesn't dismiss automatically
        checkoutViewController?.dismiss(animated: true)

        if let applePayViewController = controller as? ApplePayViewController {
            Task { @MainActor in
                applePayViewController.onCancel?()
            }
        }
    }

    func shouldRecoverFromError(error: ShopifyCheckoutSheetKit.CheckoutError) {
        if let applePayViewController = controller as? ApplePayViewController {
            Task { @MainActor in
                applePayViewController.onShouldRecoverFromError?(error)
            }
        }
    }

    func checkoutDidClickLink(url: URL) {
        if let applePayViewController = controller as? ApplePayViewController {
            Task { @MainActor in
                applePayViewController.onClickLink?(url)
            }
        }
    }

    func checkoutDidEmitWebPixelEvent(event: ShopifyCheckoutSheetKit.PixelEvent) {
        if let applePayViewController = controller as? ApplePayViewController {
            Task { @MainActor in
                applePayViewController.onWebPixelEvent?(event)
            }
        }
    }
}
