// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension Storefront.Objects {
    /// Contact information about the buyer interacting with a [cart](https://shopify.dev/docs/api/storefront/current/objects/Cart). The buyer's country determines [international pricing](https://shopify.dev/docs/storefronts/headless/building-with-the-storefront-api/markets/international-pricing) and should match their shipping address.
    ///
    /// For B2B scenarios, the [`purchasingCompany`](https://shopify.dev/docs/api/storefront/current/objects/CartBuyerIdentity#field-CartBuyerIdentity.fields.purchasingCompany) field identifies the company and location on whose behalf a business customer purchases. The [`preferences`](https://shopify.dev/docs/api/storefront/current/objects/CartBuyerIdentity#field-CartBuyerIdentity.fields.preferences) field stores delivery and wallet settings that prefill checkout fields to streamline the buying process.
    static let CartBuyerIdentity = ApolloAPI.Object(
        typename: "CartBuyerIdentity",
        implementedInterfaces: [],
        keyFields: nil
    )
}
