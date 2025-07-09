//
//  ApplePayAuthorizationDelegate+Controller.swift
//  ShopifyAcceleratedCheckouts
//
//  Created by Kieran Barrie Osgood on 05/06/2025.
//

import PassKit
import ShopifyCheckoutSheetKit

@available(iOS 17.0, *)
extension ApplePayAuthorizationDelegate: PKPaymentAuthorizationControllerDelegate {
    /**
     * First called on payment sheet presentation, is re-called every time a user changes their
     * shipping address, only applies if the cart contains shippable products
     */
    func paymentAuthorizationController(
        _: PKPaymentAuthorizationController,
        didSelectShippingContact contact: PKContact
    ) async -> PKPaymentRequestShippingContactUpdate {
        pkEncoder.shippingContact = .success(contact)

        do {
            print("ApplePay: didSelectShippingContact do")
            let cartID = try pkEncoder.cartID.get()

            let shippingAddress = try pkEncoder.shippingAddress.get()
            let cart = try await upsertShippingAddress(to: shippingAddress)
            try setCart(to: cart)

            let result = try await controller.storefront.cartPrepareForCompletion(
                id: cartID
            )

            try setCart(to: result.cart)

            return pkDecoder.paymentRequestShippingContactUpdate()
        } catch {
            print("ApplePay: didSelectShippingContact error: \(error)")
            guard let action = ErrorHandler.map(error: error, shippingCountry: getShippingCountry())
            else {
                isFailure = true
                return pkDecoder.paymentRequestShippingContactUpdate(errors: [abortError])
            }
            switch action {
            case let .showError(errors):
                return pkDecoder.paymentRequestShippingContactUpdate(errors: errors)
            case let .interrupt(reason, checkoutURL):
                isFailure = true
                self.checkoutURL = checkoutURL
                interruptReason = reason
                return pkDecoder.paymentRequestShippingContactUpdate(errors: [abortError])
            }
        }
    }

    func paymentAuthorizationController(
        _: PKPaymentAuthorizationController,
        didSelectShippingMethod shippingMethod: PKShippingMethod
    ) async -> PKPaymentRequestShippingMethodUpdate {
        pkEncoder.selectedShippingMethod = shippingMethod
        pkDecoder.selectedShippingMethod = shippingMethod

        do {
            let cartID = try pkEncoder.cartID.get()
            let selectedDeliveryOptionHandle = try pkEncoder.selectedDeliveryOptionHandle.get()
            let deliveryGroupID = try pkEncoder.deliveryGroupID.get()

            let cart = try await controller.storefront
                .cartSelectedDeliveryOptionsUpdate(
                    id: cartID,
                    deliveryGroupId: deliveryGroupID,
                    deliveryOptionHandle: selectedDeliveryOptionHandle.rawValue
                )
            try setCart(to: cart)

            let result = try await controller.storefront
                .cartPrepareForCompletion(id: cartID)

            try setCart(to: result.cart)

            return pkDecoder.paymentRequestShippingMethodUpdate()
        } catch {
            print("ApplePay: didSelectShippingMethod error: \(error)")
            return pkDecoder.paymentRequestShippingMethodUpdate()
        }
    }

    func paymentAuthorizationController(
        _: PKPaymentAuthorizationController,
        didAuthorizePayment payment: PKPayment
    ) async -> PKPaymentAuthorizationResult {
        pkEncoder.payment = payment
        do {
            let cartID = try pkEncoder.cartID.get()

            guard let email = try? pkEncoder.email.get() else {
                throw ValidationErrors.emailInvalid(message: "errors.missing.email".localizedString)
            }

            /**
             * (Optional) If the user is a guest then email becomes available now
             */
            var cart = try await controller.storefront.cartBuyerIdentityUpdate(
                id: cartID,
                email: email
            )
            try setCart(to: cart)

            if try pkDecoder.isShippingRequired() {
                let shippingAddress = try pkEncoder.shippingAddress.get()
                _ = try await upsertShippingAddress(to: shippingAddress, validate: true)
                let result = try await controller.storefront.cartPrepareForCompletion(
                    id: cartID
                )
                try setCart(to: result.cart)
            }

            let totalAmount = try pkEncoder.totalAmount.get()
            let applePayPayment = try pkEncoder.applePayPayment.get()

            cart = try await controller.storefront.cartPaymentUpdate(
                id: cartID,
                totalAmount: totalAmount,
                applePayPayment: applePayPayment
            )

            try setCart(to: cart)

            let response = try await controller.storefront.cartSubmitForCompletion(
                id: cartID
            )
            redirectURL = response.redirectUrl.url

            return pkDecoder.paymentAuthorizationResult()
        } catch {
            print("ApplePay: didAuthorizePayment error: \(error)")
            guard let action = ErrorHandler.map(error: error, shippingCountry: getShippingCountry())
            else {
                isFailure = true
                return pkDecoder.paymentAuthorizationResult(errors: [abortError])
            }
            switch action {
            case let .showError(errors):
                return pkDecoder.paymentAuthorizationResult(errors: errors)
            case let .interrupt(reason, checkoutURL):
                isFailure = true
                self.checkoutURL = checkoutURL
                interruptReason = reason
                return pkDecoder.paymentAuthorizationResult(errors: [abortError])
            }
        }
    }

    func getShippingCountry() -> String? {
        let shippingAddress =
            controller.cart?.delivery?.addresses.first(where: { $0.selected })?
                .address as? StorefrontAPI.CartDeliveryAddress
        return shippingAddress?.countryCode
    }

    func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        print("ApplePay: paymentAuthorizationControllerDidFinish")

        Task {
            defer {
                controller.dismiss {
                    self.reset()
                }
            }

            if self.isFailure {
                let cartID = try self.pkEncoder.cartID.get()
                await _Concurrency.Task.retrying {
                    try await self.controller.storefrontJulyRelease.cartRemovePersonalData(
                        id: cartID
                    )
                }.value
            }

            let topViewController = await MainActor.run { self.getTopViewController() }

            guard let topViewController else {
                print("Failed to get top view controller")
                return
            }

            guard let url = self.url else {
                print("url not set. Check if cart was stored on AuthorizationDelegate.")
                return
            }

            _ = await MainActor.run {
                self.checkoutViewController = ShopifyCheckoutSheetKit.present(
                    checkout: url,
                    from: topViewController,
                    delegate: self
                )
            }
        }
    }
}
