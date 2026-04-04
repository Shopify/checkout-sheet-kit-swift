// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension Storefront.Objects {
    /// A customer account with the shop. Includes data such as contact information, [addresses](https://shopify.dev/docs/api/storefront/current/objects/MailingAddress) and marketing preferences for logged-in customers, so they don't have to provide these details at every checkout.
    ///
    /// Access the customer through the [`customer`](https://shopify.dev/docs/api/storefront/current/queries/customer) query using a customer access token obtained from the [`customerAccessTokenCreate`](https://shopify.dev/docs/api/storefront/current/mutations/customerAccessTokenCreate) mutation.
    ///
    /// The object implements the [`HasMetafields`](https://shopify.dev/docs/api/storefront/current/interfaces/HasMetafields) interface, enabling retrieval of [custom data](https://shopify.dev/docs/apps/build/custom-data) associated with the customer.
    static let Customer = ApolloAPI.Object(
        typename: "Customer",
        implementedInterfaces: [Storefront.Interfaces.HasMetafields.self],
        keyFields: nil
    )
}
