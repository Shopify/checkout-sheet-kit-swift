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

// MARK: - Mutation Operations

@available(iOS 17.0, *)
extension StorefrontAPI {
    /// Create a new cart
    /// - Parameters:
    ///   - items: Array of product variant IDs to add to the cart
    ///   - customer: Optional customer information to associate with the cart
    /// - Returns: The created cart
    func cartCreate(
        with items: [GraphQLScalars.ID] = [],
        customer: ShopifyAcceleratedCheckouts.Customer? = nil
    ) async throws -> Cart {
        var input: [String: Any] = [
            "lines": items.map { ["merchandiseId": $0.rawValue] }
        ]

        if let customer {
            var buyerIdentity: [String: String] = [:]

            if let email = customer.email {
                buyerIdentity["email"] = email
            }
            if let phoneNumber = customer.phoneNumber {
                buyerIdentity["phone"] = phoneNumber
            }
            if let customerAccessToken = customer.customerAccessToken {
                buyerIdentity["customerAccessToken"] = customerAccessToken
            }

            if !buyerIdentity.isEmpty {
                input["buyerIdentity"] = buyerIdentity
            }
        }

        let variables: [String: Any] = ["input": input]

        let response = try await client.mutate(
            Operations.cartCreate(variables: variables)
        )

        guard let payload = response.data?.cartCreate else {
            throw GraphQLError.invalidResponse
        }

        let cart = try validateCart(payload.cart, requestName: "cartCreate")

        try validateUserErrors(payload.userErrors, checkoutURL: cart.checkoutUrl.url)

        return cart
    }

    struct CartBuyerIdentityUpdateInput: Codable {
        var email: String?
        var phoneNumber: String?
        var customerAccessToken: String?
        var countryCode: String?

        var dictionary: [String: String] {
            return [
                "email": email,
                "phone": phoneNumber,
                "customerAccessToken": customerAccessToken,
                "countryCode": countryCode
            ].compactMapValues { $0 }
        }

        var isEmpty: Bool { dictionary.isEmpty }

        init(email: String? = nil, phoneNumber: String? = nil, customerAccessToken: String? = nil) {
            self.email = email
            self.phoneNumber = phoneNumber
            self.customerAccessToken = customerAccessToken
        }

        init(countryCode: String, customerAccessToken: String? = nil) {
            self.countryCode = countryCode
            self.customerAccessToken = customerAccessToken
        }
    }

    /// Update buyer identity on a cart
    /// - Parameters:
    ///   - id: Cart ID
    ///   - email: Buyer email address
    ///   - phone: Buyers phone number
    ///   - customerAccessToken: Customer access token
    /// - Returns: Updated cart
    @discardableResult func cartBuyerIdentityUpdate(
        id: GraphQLScalars.ID,
        input buyerIdentity: CartBuyerIdentityUpdateInput
    ) async throws -> Cart {
        if buyerIdentity.isEmpty {
            throw GraphQLError.invalidVariables
        }

        let variables: [String: Any] = [
            "cartId": id.rawValue,
            "buyerIdentity": buyerIdentity.dictionary
        ]

        let response = try await client.mutate(
            Operations.cartBuyerIdentityUpdate(variables: variables)
        )

        guard let payload = response.data?.cartBuyerIdentityUpdate else {
            throw GraphQLError.invalidResponse
        }

        let cart = try validateCart(payload.cart, requestName: "cartBuyerIdentityUpdate")

        try validateUserErrors(payload.userErrors, checkoutURL: cart.checkoutUrl.url)

        return cart
    }

    /// Add delivery addresses to cart
    /// - Parameters:
    ///   - id: Cart ID
    ///   - address: Delivery address
    ///   - validate: Whether to validate the address
    /// - Returns: Updated cart
    func cartDeliveryAddressesAdd(
        id: GraphQLScalars.ID,
        address: Address,
        validate: Bool = false
    ) async throws -> Cart {
        let variables: [String: Any] = [
            "cartId": id.rawValue,
            "addresses": [
                [
                    "address": [
                        "deliveryAddress": address.asShippingAddressDict.compactMapValues { $0 }
                    ],
                    "selected": true,
                    "validationStrategy": validate ? "STRICT" : "COUNTRY_CODE_ONLY"
                ]
            ]
        ]

        let response = try await client.mutate(
            Operations.cartDeliveryAddressesAdd(variables: variables)
        )

        guard let payload = response.data?.cartDeliveryAddressesAdd else {
            throw GraphQLError.invalidResponse
        }

        let cart = try validateCart(payload.cart, requestName: "cartDeliveryAddressesAdd")

        try validateUserErrors(payload.userErrors, checkoutURL: cart.checkoutUrl.url)

        return cart
    }

    /// Update delivery addresses on cart
    /// - Parameters:
    ///   - id: Cart ID
    ///   - addressId: ID of the address to update
    ///   - address: Updated delivery address
    ///   - validate: Whether to validate the address
    /// - Returns: Updated cart
    func cartDeliveryAddressesUpdate(
        id: GraphQLScalars.ID,
        addressId: GraphQLScalars.ID,
        address: Address,
        validate: Bool = false
    ) async throws -> Cart {
        let variables: [String: Any] = [
            "cartId": id.rawValue,
            "addresses": [
                [
                    "id": addressId.rawValue,
                    "address": [
                        "deliveryAddress": address.asShippingAddressDict.compactMapValues { $0 }
                    ],
                    "selected": true,
                    "validationStrategy": validate ? "STRICT" : "COUNTRY_CODE_ONLY"
                ]
            ]
        ]

        let response = try await client.mutate(
            Operations.cartDeliveryAddressesUpdate(variables: variables)
        )

        guard let payload = response.data?.cartDeliveryAddressesUpdate else {
            throw GraphQLError.invalidResponse
        }

        let cart = try validateCart(payload.cart, requestName: "cartDeliveryAddressesUpdate")

        try validateUserErrors(payload.userErrors, checkoutURL: cart.checkoutUrl.url)

        return cart
    }

    /// Remove delivery addresses from cart
    /// - Parameters:
    ///   - id: Cart ID
    ///   - addressId: ID of the address to remove
    /// - Returns: Updated cart
    func cartDeliveryAddressesRemove(
        id: GraphQLScalars.ID,
        addressId: GraphQLScalars.ID
    ) async throws -> Cart {
        let variables: [String: Any] = [
            "cartId": id.rawValue,
            "addressIds": [addressId.rawValue]
        ]

        let response = try await client.mutate(
            Operations.cartDeliveryAddressesRemove(variables: variables)
        )

        guard let payload = response.data?.cartDeliveryAddressesRemove else {
            throw GraphQLError.invalidResponse
        }

        let cart = try validateCart(payload.cart, requestName: "cartDeliveryAddressesRemove")

        try validateUserErrors(payload.userErrors, checkoutURL: cart.checkoutUrl.url)

        return cart
    }

    /// Update selected delivery options
    /// - Parameters:
    ///   - id: Cart ID
    ///   - deliveryGroupId: Delivery group ID
    ///   - deliveryOptionHandle: Selected delivery option handle
    /// - Returns: Updated cart
    func cartSelectedDeliveryOptionsUpdate(
        id: GraphQLScalars.ID,
        deliveryGroupId: GraphQLScalars.ID,
        deliveryOptionHandle: String
    ) async throws -> Cart {
        let variables: [String: Any] = [
            "cartId": id.rawValue,
            "selectedDeliveryOptions": [
                [
                    "deliveryGroupId": deliveryGroupId.rawValue,
                    "deliveryOptionHandle": deliveryOptionHandle
                ]
            ]
        ]

        let response = try await client.mutate(
            Operations.cartSelectedDeliveryOptionsUpdate(variables: variables)
        )

        guard let payload = response.data?.cartSelectedDeliveryOptionsUpdate else {
            throw GraphQLError.invalidResponse
        }

        let cart = try validateCart(payload.cart, requestName: "cartSelectedDeliveryOptionsUpdate")

        try validateUserErrors(payload.userErrors, checkoutURL: cart.checkoutUrl.url)

        return cart
    }

    /// Update cart payment
    /// - Parameters:
    ///   - id: Cart ID
    ///   - totalAmount: Total payment amount
    ///   - applePayPayment: Apple Pay payment data
    /// - Returns: Updated cart
    @discardableResult func cartPaymentUpdate(
        id: GraphQLScalars.ID,
        totalAmount: MoneyV2,
        applePayPayment: ApplePayPayment
    ) async throws -> Cart {
        // Note: Apple Pay billing address uses country/province (not countryCode/provinceCode)
        let billingAddress: [String: Any?] = [
            "address1": applePayPayment.billingAddress.address1,
            "address2": applePayPayment.billingAddress.address2,
            "city": applePayPayment.billingAddress.city,
            "country": applePayPayment.billingAddress.country,
            "firstName": applePayPayment.billingAddress.firstName,
            "lastName": applePayPayment.billingAddress.lastName,
            "phone": applePayPayment.billingAddress.phone,
            "province": applePayPayment.billingAddress.province,
            "zip": applePayPayment.billingAddress.zip
        ]

        let header: [String: Any] = [
            "ephemeralPublicKey": applePayPayment.ephemeralPublicKey,
            "publicKeyHash": applePayPayment.publicKeyHash,
            "transactionId": applePayPayment.transactionId
        ]

        let applePayWalletContent: [String: Any] = [
            "billingAddress": billingAddress.compactMapValues { $0 },
            "data": applePayPayment.data,
            "header": header,
            "signature": applePayPayment.signature,
            "version": applePayPayment.version,
            "lastDigits": applePayPayment.lastDigits
        ]

        let walletPaymentMethod: [String: Any] = [
            "applePayWalletContent": applePayWalletContent
        ]

        let paymentInput: [String: Any] = [
            "amount": [
                "amount": "\(totalAmount.amount)",
                "currencyCode": totalAmount.currencyCode
            ],
            "walletPaymentMethod": walletPaymentMethod
        ]

        let variables: [String: Any] = [
            "cartId": id.rawValue,
            "payment": paymentInput
        ]

        let response = try await client.mutate(
            Operations.cartPaymentUpdate(variables: variables)
        )

        guard let payload = response.data?.cartPaymentUpdate else {
            throw GraphQLError.invalidResponse
        }

        let cart = try validateCart(payload.cart, requestName: "cartPaymentUpdate")

        try validateUserErrors(payload.userErrors, checkoutURL: cart.checkoutUrl.url)

        return cart
    }

    /// Update billing address on cart
    /// - Parameters:
    ///   - id: Cart ID
    ///   - billingAddress: Billing address to set
    /// - Returns: Updated cart
    @discardableResult func cartBillingAddressUpdate(
        id: GraphQLScalars.ID,
        billingAddress: Address
    ) async throws -> Cart {
        let billingAddressDict = billingAddress.asMailingAddressDict.compactMapValues { $0 }

        let variables: [String: Any] = [
            "cartId": id.rawValue,
            "billingAddress": billingAddressDict
        ]

        let response = try await client.mutate(
            Operations.cartBillingAddressUpdate(variables: variables)
        )

        guard let payload = response.data?.cartBillingAddressUpdate else {
            throw GraphQLError.invalidResponse
        }

        let cart = try validateCart(payload.cart, requestName: "cartBillingAddressUpdate")

        try validateUserErrors(payload.userErrors, checkoutURL: cart.checkoutUrl.url)

        return cart
    }

    /// Remove personal data from cart
    /// - Parameter id: Cart ID
    /// Available since 2025-07 - must be called with a custom StorefrontAPI
    func cartRemovePersonalData(id: GraphQLScalars.ID) async throws {
        let variables: [String: Any] = [
            "cartId": id.rawValue
        ]

        let response = try await client.mutate(
            Operations.cartRemovePersonalData(variables: variables)
        )

        guard let payload = response.data?.cartRemovePersonalData else {
            throw GraphQLError.invalidResponse
        }

        let cart = try validateCart(payload.cart, requestName: "cartRemovePersonalData")

        try validateUserErrors(payload.userErrors, checkoutURL: cart.checkoutUrl.url)
    }

    /// Prepare cart for completion
    /// - Parameter id: Cart ID
    /// - Returns: Cart status ready result
    func cartPrepareForCompletion(id: GraphQLScalars.ID) async throws -> CartStatusReady {
        let variables: [String: Any] = [
            "cartId": id.rawValue
        ]

        let response = try await client.mutate(
            Operations.cartPrepareForCompletion(variables: variables)
        )

        guard let payload = response.data?.cartPrepareForCompletion else {
            throw GraphQLError.invalidResponse
        }

        guard let result = payload.result else {
            throw GraphQLError.invalidResponse
        }

        switch result {
        case let .ready(ready):
            let cart = try validateCart(ready.cart, requestName: "cartPrepareForCompletion")
            try validateUserErrors(payload.userErrors, checkoutURL: cart.checkoutUrl.url)
            return ready
        case let .throttled(throttled):
            throw GraphQLError.networkError(
                "Cart preparation throttled. Poll after: \(throttled.pollAfter.date)")
        case let .notReady(notReady):
            let errorMessages = notReady.errors.map { "\($0.code): \($0.message)" }.joined(
                separator: ", ")
            throw GraphQLError.networkError("Cart not ready: \(errorMessages)")
        }
    }

    /// Submit cart for completion
    /// - Parameter id: Cart ID
    /// - Returns: Submit success result
    func cartSubmitForCompletion(id: GraphQLScalars.ID) async throws -> SubmitSuccess {
        let variables: [String: Any] = [
            "cartId": id.rawValue,
            "attemptToken": UUID().uuidString
        ]

        let response = try await client.mutate(
            Operations.cartSubmitForCompletion(variables: variables)
        )

        guard let payload = response.data?.cartSubmitForCompletion else {
            throw GraphQLError.invalidResponse
        }

        try validateUserErrors(payload.userErrors, checkoutURL: nil)

        guard let result = payload.result else {
            throw GraphQLError.invalidResponse
        }

        switch result {
        case let .success(success):
            return success
        case let .failed(failed):
            let errorMessages = failed.errors.map { "\($0.code): \($0.message)" }.joined(
                separator: ", ")
            throw GraphQLError.networkError("Cart submission failed: \(errorMessages)")
        case let .alreadyAccepted(accepted):
            throw GraphQLError.networkError(
                "Cart already accepted with attempt ID: \(accepted.attemptId)")
        case let .throttled(throttled):
            throw GraphQLError.networkError(
                "Cart submission throttled. Poll after: \(throttled.pollAfter.date)")
        }
    }
}

// MARK: - Validation Helpers

@available(iOS 17.0, *)
extension StorefrontAPI {
    private func validateUserErrors(_ userErrors: [CartUserError], checkoutURL _: URL?) throws {
        guard userErrors.isEmpty else {
            // Always throw the actual CartUserError so the error handler can properly map it
            throw userErrors.first!
        }
    }

    private func validateCart(_ cart: Cart?, requestName _: String) throws -> Cart {
        guard let cart else {
            throw GraphQLError.invalidResponse
        }
        return cart
    }
}

// MARK: - Response Wrappers

@available(iOS 17.0, *)
extension StorefrontAPI {
    struct CartCreateResponse: Codable {
        let cartCreate: CartCreatePayload
    }

    struct CartBuyerIdentityUpdateResponse: Codable {
        let cartBuyerIdentityUpdate: CartBuyerIdentityUpdatePayload
    }

    struct CartDeliveryAddressesAddResponse: Codable {
        let cartDeliveryAddressesAdd: CartDeliveryAddressesAddPayload
    }

    struct CartDeliveryAddressesUpdateResponse: Codable {
        let cartDeliveryAddressesUpdate: CartDeliveryAddressesUpdatePayload
    }

    struct CartDeliveryAddressesRemoveResponse: Codable {
        let cartDeliveryAddressesRemove: CartDeliveryAddressesRemovePayload
    }

    struct CartSelectedDeliveryOptionsUpdateResponse: Codable {
        let cartSelectedDeliveryOptionsUpdate: CartSelectedDeliveryOptionsUpdatePayload
    }

    struct CartPaymentUpdateResponse: Codable {
        let cartPaymentUpdate: CartPaymentUpdatePayload
    }

    struct CartBillingAddressUpdateResponse: Codable {
        let cartBillingAddressUpdate: CartBillingAddressUpdatePayload
    }

    struct CartRemovePersonalDataResponse: Codable {
        let cartRemovePersonalData: CartRemovePersonalDataPayload
    }

    struct CartPrepareForCompletionResponse: Codable {
        let cartPrepareForCompletion: CartPrepareForCompletionPayload
    }

    struct CartSubmitForCompletionResponse: Codable {
        let cartSubmitForCompletion: CartSubmitForCompletionPayload
    }
}
