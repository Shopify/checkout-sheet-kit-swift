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

/// High-level API for Storefront operations using the custom GraphQL client
@available(iOS 16.0, *)
class StorefrontAPI: ObservableObject, StorefrontAPIProtocol {
    let client: GraphQLClient

    /// Initialize the Storefront API
    /// - Parameters:
    ///   - storefrontDomain: The shop domain (e.g., "example.myshopify.com")
    ///   - storefrontAccessToken: The storefront access token
    ///   - apiVersion: The API version to use (defaults to "2025-07")
    ///   - countryCode: Optional country code for localization
    ///   - languageCode: Optional language code for localization
    init(
        storefrontDomain: String,
        storefrontAccessToken: String,
        apiVersion: String = ShopifyAcceleratedCheckouts.apiVersion,
        countryCode: CountryCode? = nil,
        languageCode: LanguageCode? = nil
    ) {
        let url = URL(string: "https://\(storefrontDomain)/api/\(apiVersion)/graphql.json")!

        client = GraphQLClient(
            url: url,
            headers: ["X-Shopify-Storefront-Access-Token": storefrontAccessToken],
            context: InContextDirective(
                countryCode: countryCode,
                languageCode: languageCode
            )
        )
    }
}

@available(iOS 16.0, *)
protocol StorefrontAPIProtocol {
    // MARK: - Query Methods

    func cart(by id: GraphQLScalars.ID) async throws -> StorefrontAPI.Cart?
    func shop() async throws -> StorefrontAPI.Shop

    // MARK: - Mutation Methods

    @discardableResult func cartCreate(
        with items: [GraphQLScalars.ID], customer: ShopifyAcceleratedCheckouts.Customer?
    ) async throws -> StorefrontAPI.Cart

    @discardableResult func cartBuyerIdentityUpdate(
        id: GraphQLScalars.ID,
        input buyerIdentity: StorefrontAPI.CartBuyerIdentityUpdateInput
    ) async throws -> StorefrontAPI.Cart

    @discardableResult func cartDeliveryAddressesAdd(
        id: GraphQLScalars.ID,
        address: StorefrontAPI.Address,
        validate: Bool
    ) async throws -> StorefrontAPI.Cart

    @discardableResult func cartDeliveryAddressesUpdate(
        id: GraphQLScalars.ID,
        addressId: GraphQLScalars.ID,
        address: StorefrontAPI.Address,
        validate: Bool
    ) async throws -> StorefrontAPI.Cart

    @discardableResult func cartDeliveryAddressesRemove(
        id: GraphQLScalars.ID,
        addressId: GraphQLScalars.ID
    ) async throws -> StorefrontAPI.Cart

    @discardableResult func cartSelectedDeliveryOptionsUpdate(
        id: GraphQLScalars.ID,
        deliveryGroupId: GraphQLScalars.ID,
        deliveryOptionHandle: String
    ) async throws -> StorefrontAPI.Cart?

    @discardableResult func cartPaymentUpdate(
        id: GraphQLScalars.ID,
        totalAmount: StorefrontAPI.MoneyV2,
        applePayPayment: StorefrontAPI.ApplePayPayment
    ) async throws -> StorefrontAPI.Cart

    @discardableResult func cartBillingAddressUpdate(
        id: GraphQLScalars.ID,
        billingAddress: StorefrontAPI.Address
    ) async throws -> StorefrontAPI.Cart

    func cartRemovePersonalData(id: GraphQLScalars.ID) async throws

    func cartPrepareForCompletion(id: GraphQLScalars.ID) async throws
        -> StorefrontAPI.CartStatusReady

    func cartSubmitForCompletion(id: GraphQLScalars.ID) async throws -> StorefrontAPI.SubmitSuccess
}
