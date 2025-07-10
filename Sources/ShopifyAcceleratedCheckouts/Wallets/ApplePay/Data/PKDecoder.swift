//
//  PKDecoder.swift
//  ShopifyAcceleratedCheckouts
//
//  Created by Kieran Barrie Osgood on 05/06/2025.
//

//
//  GraphPKAdapter.swift
//  ShopifyAcceleratedCheckouts
//
//  Created by Kieran Barrie Osgood on 05/06/2025.
//

import PassKit

/// Decodes Storefront -> PassKit
@available(iOS 17.0, *)
class PKDecoder {
    var cart: () -> StorefrontAPI.Types.Cart?

    var selectedShippingMethod: PKShippingMethod?
    var configuration: ApplePayConfigurationWrapper
    var initialCurrencyCode: String?

    init(
        configuration: ApplePayConfigurationWrapper,
        cart: @escaping () -> StorefrontAPI.Types.Cart?
    ) {
        self.configuration = configuration
        self.cart = cart
    }

    // https:github.com/Shopify/portable-wallets/blob/main/src/components/ApplePayButton/helpers/create-payment-request.ts
    public func createPaymentRequest() throws -> PKPaymentRequest {
        guard let cart = cart() else {
            throw ShopifyAcceleratedCheckouts.Error.invariant(message: .nilCart)
        }
        let paymentRequest = PKPaymentRequest()
        let currencyCode = cart.cost.totalAmount.currencyCode

        paymentRequest.merchantIdentifier = configuration.applePay.merchantIdentifier
        paymentRequest.supportedNetworks = configuration.applePay.supportedNetworks
        paymentRequest.countryCode = configuration.shopSettings.paymentSettings.countryCode
        paymentRequest.currencyCode = currencyCode
        initialCurrencyCode = currencyCode
        paymentRequest.merchantCapabilities = [.threeDSecure]

        let requiresShipping = try isShippingRequired()
        if requiresShipping {
            paymentRequest.shippingMethods = shippingMethods
            paymentRequest.shippingType = .shipping
        }

        paymentRequest.requiredBillingContactFields = PKDecoder.requiredAddressFields

        paymentRequest.requiredShippingContactFields =
            requiresShipping
                ? PKDecoder.requiredAddressFields.union(requiredContactFields)
                : requiredContactFields

        paymentRequest.paymentSummaryItems = paymentSummaryItems

        return paymentRequest
    }

    // https://github.com/Shopify/portable-wallets/blob/main/src/components/ApplePayButton/helpers/map-to-apple-pay-line-items.ts
    var paymentSummaryItems: [PKPaymentSummaryItem] {
        return PassKitFactory.shared.mapToApplePayLineItems(
            cart: cart(),
            shippingMethod: selectedShippingMethod,
            merchantName: configuration.shopSettings.name
        )
    }

    // https:github.com/Shopify/portable-wallets/blob/main/src/components/ApplePayButton/helpers/map-to-apple-pay-shipping-methods.ts
    var shippingMethods: [PKShippingMethod] {
        PassKitFactory.shared.createShippingMethods(
            deliveryGroups: cart()?.deliveryGroups.nodes
        )
    }

    //        https:github.com/Shopify/portable-wallets/blob/main/src/components/ApplePayButton/helpers/get-discount-allocations-for-line-items.ts
    var discountAllocations: [PassKitFactory.DiscountAllocationInfo] {
        do {
            return try PassKitFactory.shared.createDiscountAllocations(
                cart: cart()
            )
        } catch {
            print("Error creating discount allocations: \(error)")
            return []
        }
    }

    func paymentRequestShippingContactUpdate(errors: [any Error]? = [])
        -> PKPaymentRequestShippingContactUpdate
    {
        let update = PKPaymentRequestShippingContactUpdate(
            errors: errors,
            paymentSummaryItems: paymentSummaryItems,
            shippingMethods: shippingMethods
        )

        if let errors {
            if errors.compactMap({ $0 as? PKPaymentError }).count != errors.count {
                update.status = .failure
            }
        }

        return update
    }

    func paymentRequestShippingMethodUpdate() -> PKPaymentRequestShippingMethodUpdate {
        return PKPaymentRequestShippingMethodUpdate(
            paymentSummaryItems: paymentSummaryItems
        )
    }

    func paymentAuthorizationResult(errors: [any Error]? = []) -> PKPaymentAuthorizationResult {
        let update = PKPaymentAuthorizationResult(status: .success, errors: [])
        if let errors {
            if errors.compactMap({ $0 as? PKPaymentError }).count != errors.count {
                update.status = .failure
            }
            update.errors = errors
        }

        return update
    }

    /**
     * Required contact fields for all transactions.
     * - Used for billing address in all cases
     * - Also used for shipping address when `isShippingRequired() == true`
     */
    static let requiredAddressFields: Set<PKContactField> = [
        .name,
        .postalAddress
    ]

    var requiredContactFields: Set<PKContactField> {
        var fields: Set<PKContactField> = []

        // https://github.com/shop/world/blob/db694ab60e8e23ad2d1c6e9e1d2491f3d48ecde0/areas/clients/checkout-web/app/utilities/wallets/hooks/index.ts#L106
        // TODO: These should come from shop configuration or checkout settings

        if configuration.applePay.contactFields.contains(.email) {
            fields.insert(.emailAddress)
        }
        if configuration.applePay.contactFields.contains(.phone) {
            fields.insert(.phoneNumber)
        }

        return fields
    }

    /// https://github.com/Shopify/portable-wallets/blob/85f2f8ec83d801d2b93e405aa71237fb7316c838/src/components/AcceleratedCheckout/AcceleratedCheckout.ts#L450
    func isShippingRequired() throws -> Bool {
        guard let cart = cart() else {
            throw ShopifyAcceleratedCheckouts.Error.invariant(message: .nilCart)
        }

        // Check if any line item's merchandise requires shipping
        for line in cart.lines.nodes {
            if let variant = line.merchandise, variant.requiresShipping {
                return true
            }
        }

        return false
    }
}
