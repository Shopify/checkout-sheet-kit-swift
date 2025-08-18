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

// MARK: - Protocol for PaymentKit types that can be updated with errors

protocol PKPaymentRequestUpdatable {
    var status: PKPaymentAuthorizationStatus { get set }
    var errors: [any Error]! { get set }
}

extension PKPaymentRequestShippingContactUpdate: PKPaymentRequestUpdatable {}
extension PKPaymentRequestPaymentMethodUpdate: PKPaymentRequestUpdatable {}
extension PKPaymentAuthorizationResult: PKPaymentRequestUpdatable {}

/// Decodes Storefront -> PassKit
@available(iOS 16.0, *)
class PKDecoder {
    var cart: () -> StorefrontAPI.Types.Cart?

    var selectedShippingMethod: PKShippingMethod?
    var configuration: ApplePayConfigurationWrapper
    var initialCurrencyCode: String?
    private let logger = ShopifyAcceleratedCheckouts.logger.extend("PKDecoder")

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
            throw ShopifyAcceleratedCheckouts.Error.invariant(expected: "cart")
        }
        let paymentRequest = PKPaymentRequest()
        let currencyCode = cart.cost.totalAmount.currencyCode

        paymentRequest.merchantIdentifier = configuration.applePay.merchantIdentifier

        // Map accepted card brands from Shopify to PKPaymentNetwork
        let acceptedCardBrands = configuration.shopSettings.paymentSettings.acceptedCardBrands
        paymentRequest.supportedNetworks = CardBrandMapper.mapToPKPaymentNetworks(acceptedCardBrands)

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
            ShopifyAcceleratedCheckouts.logger.error("Error creating discount allocations: \(error)")
            return []
        }
    }

    // MARK: - Error handling helpers

    private func setErrorStatus(
        for request: inout some PKPaymentRequestUpdatable,
        with errors: [any Error]
    ) {
        if errors.compactMap({ $0 as? PKPaymentError }).count != errors.count {
            request.status = .failure
        }
        request.errors = errors
    }

    func paymentRequestShippingContactUpdate(errors: [any Error]? = [])
        -> PKPaymentRequestShippingContactUpdate
    {
        var paymentRequestUpdate = PKPaymentRequestShippingContactUpdate(
            errors: errors,
            paymentSummaryItems: paymentSummaryItems,
            shippingMethods: shippingMethods
        )
        if let errors {
            setErrorStatus(for: &paymentRequestUpdate, with: errors)
        }
        return paymentRequestUpdate
    }

    func paymentRequestPaymentMethodUpdate(errors: [any Error]? = [])
        -> PKPaymentRequestPaymentMethodUpdate
    {
        var paymentRequestUpdate = PKPaymentRequestPaymentMethodUpdate(
            paymentSummaryItems: paymentSummaryItems
        )
        if let errors {
            setErrorStatus(for: &paymentRequestUpdate, with: errors)
        }
        return paymentRequestUpdate
    }

    func paymentRequestShippingMethodUpdate() -> PKPaymentRequestShippingMethodUpdate {
        return PKPaymentRequestShippingMethodUpdate(paymentSummaryItems: paymentSummaryItems)
    }

    func paymentAuthorizationResult(errors: [any Error]? = []) -> PKPaymentAuthorizationResult {
        var paymentAuthorizationResult = PKPaymentAuthorizationResult(status: .success, errors: [])
        if let errors {
            setErrorStatus(for: &paymentAuthorizationResult, with: errors)
        }
        return paymentAuthorizationResult
    }

    /// Required contact fields for all transactions.
    /// - Used for billing address in all cases
    /// - Also used for shipping address when `isShippingRequired() == true`
    static let requiredAddressFields: Set<PKContactField> = [
        .name,
        .postalAddress
    ]

    // https://github.com/shop/world/blob/db694ab60e8e23ad2d1c6e9e1d2491f3d48ecde0/areas/clients/checkout-web/app/utilities/wallets/hooks/index.ts#L106
    var requiredContactFields: Set<PKContactField> {
        var fields: Set<PKContactField> = []

        let buyerIdentity = cart()?.buyerIdentity
        let isEmailEmpty = buyerIdentity?.email?.isEmpty ?? true
        let isPhoneEmpty = buyerIdentity?.phone?.isEmpty ?? true

        // Only request email if it's not already in buyerIdentity
        if configuration.applePay.contactFields.contains(.email), isEmailEmpty {
            fields.insert(.emailAddress)
        }

        // Only request phone if it's not already in buyerIdentity
        if configuration.applePay.contactFields.contains(.phone), isPhoneEmpty {
            fields.insert(.phoneNumber)
        }

        // Ensure at least one contact field is required for Apple Pay to complete checkout
        // If no fields are required, and buyer identity is empty, default to email
        if fields.isEmpty, isEmailEmpty, isPhoneEmpty {
            fields.insert(.emailAddress)
        }

        return fields
    }

    /// https://github.com/Shopify/portable-wallets/blob/85f2f8ec83d801d2b93e405aa71237fb7316c838/src/components/AcceleratedCheckout/AcceleratedCheckout.ts#L450
    func isShippingRequired() throws -> Bool {
        guard let cart = cart() else {
            throw ShopifyAcceleratedCheckouts.Error.invariant(expected: "cart")
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
