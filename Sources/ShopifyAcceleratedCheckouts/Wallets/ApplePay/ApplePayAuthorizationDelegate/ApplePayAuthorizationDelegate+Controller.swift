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

@available(iOS 16.0, *)
extension ApplePayAuthorizationDelegate: PKPaymentAuthorizationControllerDelegate {
    /// Triggers on payment sheet presentation, and if user changes shipping address
    ///
    /// Only triggered if the PKPaymentRequest has `requiredShippingContactFields` set
    /// see: `createPaymentRequest`
    func paymentAuthorizationController(
        _: PKPaymentAuthorizationController,
        didSelectShippingContact contact: PKContact
    ) async -> PKPaymentRequestShippingContactUpdate {
        pkEncoder.shippingContact = .success(contact)

        // Clear selected shipping method to prevent stale identifier errors
        pkEncoder.selectedShippingMethod = nil
        pkDecoder.selectedShippingMethod = nil

        do {
            let cartID = try pkEncoder.cartID.get()

            let shippingAddress = try pkEncoder.shippingAddress.get()

            // Store current cart state before attempting address update
            let previousCart = controller.cart

            var cart = try await upsertShippingAddress(to: shippingAddress)

            // If address update cleared delivery groups, revert to previous cart and show error
            if cart.deliveryGroups.nodes.isEmpty, previousCart?.deliveryGroups.nodes.isEmpty == false {
                try setCart(to: previousCart)

                return pkDecoder.paymentRequestShippingContactUpdate(errors: [ValidationErrors.addressUnserviceableError])
            }

            try setCart(to: cart)

            cart = try await controller.storefront.cartPrepareForCompletion(id: cartID)

            try setCart(to: cart)

            return pkDecoder.paymentRequestShippingContactUpdate()
        } catch {
            ShopifyAcceleratedCheckouts.logger.error("ApplePay: didSelectShippingContact error: \(error)")
            return await handleError(error: error, cart: controller.cart) {
                pkDecoder.paymentRequestShippingContactUpdate(errors: $0)
            }
        }
    }

    /// Triggers on payment sheet presentation with default card, and if user changes payment method
    /// NOTE: If the user changes the card, the billingContact field will be nil when this fires again
    ///
    /// This event is necessary in 'digital' (non-shippable) products flow.
    /// Allows access to country so cart can determine taxes prior to `didAuthorizePayment`,
    /// minimizing payment.amount discrepancies.
    func paymentAuthorizationController(
        _: PKPaymentAuthorizationController,
        didSelectPaymentMethod paymentMethod: PKPaymentMethod
    ) async -> PKPaymentRequestPaymentMethodUpdate {
        pkEncoder.selectedPaymentMethod = paymentMethod

        do {
            /// PassKit populates `paymentMethod.billingAddress` conditionally:
            /// 1. This is the first call to `didSelectPaymentMethod`
            ///    (users default card)
            /// 2. The PKPaymentRequest doesn't request shipping info
            ///    (we rely on country from `didSelectShippingContact` for calculating taxes)
            guard try pkDecoder.isShippingRequired() == false,
                  let billingPostalAddress = try? pkEncoder.billingPostalAddress.get(),
                  let country = billingPostalAddress.country
            else {
                return pkDecoder.paymentRequestPaymentMethodUpdate()
            }
            let cartID = try pkEncoder.cartID.get()
            try await controller.storefront.cartBuyerIdentityUpdate(
                id: cartID,
                input: .init(
                    countryCode: country,
                    customerAccessToken: configuration.common.customer?.customerAccessToken
                )
            )

            try await controller.storefront
                .cartBillingAddressUpdate(id: cartID, billingAddress: billingPostalAddress)

            let cart = try await controller.storefront.cartPrepareForCompletion(id: cartID)
            try setCart(to: cart)

            return pkDecoder.paymentRequestPaymentMethodUpdate()
        } catch {
            ShopifyAcceleratedCheckouts.logger.error("ApplePay: didSelectPaymentMethod error: \(error)")

            return await handleError(error: error, cart: controller.cart) {
                pkDecoder.paymentRequestPaymentMethodUpdate(errors: $0)
            }
        }
    }

    func paymentAuthorizationController(
        _: PKPaymentAuthorizationController,
        didSelectShippingMethod shippingMethod: PKShippingMethod
    ) async -> PKPaymentRequestShippingMethodUpdate {
        // Check if this shipping method identifier is still valid
        let availableShippingMethods = pkDecoder.shippingMethods
        let isValidMethod = availableShippingMethods.contains { $0.identifier == shippingMethod.identifier }
        let methodToUse: PKShippingMethod = isValidMethod ? shippingMethod : (availableShippingMethods.first ?? shippingMethod)

        pkEncoder.selectedShippingMethod = methodToUse
        pkDecoder.selectedShippingMethod = methodToUse

        do {
            let cartID = try pkEncoder.cartID.get()
            let selectedDeliveryOptionHandle = try pkEncoder.selectedDeliveryOptionHandle.get()
            let deliveryGroupID = try pkEncoder.deliveryGroupID.get()

            var cart = try await controller.storefront
                .cartSelectedDeliveryOptionsUpdate(
                    id: cartID,
                    deliveryGroupId: deliveryGroupID,
                    deliveryOptionHandle: selectedDeliveryOptionHandle.rawValue
                )
            try setCart(to: cart)

            cart = try await controller.storefront.cartPrepareForCompletion(id: cartID)

            try setCart(to: cart)

            return pkDecoder.paymentRequestShippingMethodUpdate()
        } catch {
            ShopifyAcceleratedCheckouts.logger.error("didSelectShippingMethod error: \(error)")

            return await handleError(error: error, cart: controller.cart) { _ in
                pkDecoder.paymentRequestShippingMethodUpdate()
            }
        }
    }

    func paymentAuthorizationController(
        _: PKPaymentAuthorizationController,
        didAuthorizePayment payment: PKPayment
    ) async -> PKPaymentAuthorizationResult {
        do {
            pkEncoder.payment = payment
            try? await transition(to: .paymentAuthorized(payment: payment))
            let cartID = try pkEncoder.cartID.get()

            if pkDecoder.requiredContactFields.count > 0
                || configuration.common.customer?.email != nil
                || configuration.common.customer?.phoneNumber != nil
                || configuration.common.customer?.customerAccessToken != nil
            {
                try await controller.storefront.cartBuyerIdentityUpdate(
                    id: cartID,
                    input: .init(
                        email: try? pkEncoder.email.get(),
                        phoneNumber: try? pkEncoder.phoneNumber.get(),
                        customerAccessToken: configuration.common.customer?.customerAccessToken
                    )
                )
                let cart = try await controller.storefront.cartPrepareForCompletion(id: cartID)
                try setCart(to: cart)
            }

            if try pkDecoder.isShippingRequired() {
                let shippingAddress = try pkEncoder.shippingAddress.get()
                _ = try await upsertShippingAddress(to: shippingAddress, validate: true)

                let cart = try await controller.storefront.cartPrepareForCompletion(id: cartID)
                try setCart(to: cart)
            } else {
                /// If the cart is entirely digital updating with a complete billingAddress
                /// allows us to resolve pending terms on taxes prior to cartPaymentUpdate
                guard
                    let billingPostalAddress = try? pkEncoder.billingPostalAddress.get()
                else {
                    return pkDecoder.paymentAuthorizationResult()
                }

                try await controller.storefront.cartBillingAddressUpdate(
                    id: cartID,
                    billingAddress: billingPostalAddress
                )

                let cart = try await controller.storefront.cartPrepareForCompletion(id: cartID)
                try setCart(to: cart)
            }

            let totalAmount = try pkEncoder.totalAmount.get()
            let applePayPayment = try pkEncoder.applePayPayment.get()

            /// Taxes may become pending again fail to resolve despite updating within the didUpdatePaymentMethod
            /// So we retry one time to see if the error clears on retry
            _ = try await Task.retrying(priority: nil, maxRetryCount: 1) {
                try await self.controller.storefront.cartPaymentUpdate(
                    id: cartID,
                    totalAmount: totalAmount,
                    applePayPayment: applePayPayment
                )
            }.value

            let response = try await controller.storefront.cartSubmitForCompletion(id: cartID)
            try? await transition(
                to: .cartSubmittedForCompletion(redirectURL: response.redirectUrl.url)
            )

            return pkDecoder.paymentAuthorizationResult()
        } catch {
            ShopifyAcceleratedCheckouts.logger.error("didAuthorizePayment error: \(error)")
            return await handleError(error: error, cart: controller.cart) {
                pkDecoder.paymentAuthorizationResult(errors: $0)
            }
        }
    }

    func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        ShopifyAcceleratedCheckouts.logger.debug("paymentAuthorizationControllerDidFinish, state: \(state)")

        controller.dismiss {
            Task { try? await self.transition(to: .completed) }
        }
    }

    func handleError<T>(
        error: Error,
        cart _: StorefrontAPI.Cart?,
        completion: (_: [Error]) -> T
    ) async -> T {
        guard let action = ErrorHandler.map(error: error, cart: controller.cart) else {
            try? await transition(to: .unexpectedError(error: abortError))
            return completion([abortError])
        }

        switch action {
        case let .showError(errors):
            try? await transition(to: .appleSheetPresented)
            return completion(errors)
        case let .interrupt(reason, checkoutURL):
            try? await transition(to: .interrupt(reason: reason))
            if let checkoutURL {
                self.checkoutURL = checkoutURL
            }
            return completion([abortError])
        }
    }
}
