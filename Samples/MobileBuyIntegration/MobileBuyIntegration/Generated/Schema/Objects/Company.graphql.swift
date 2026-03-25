// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension Storefront.Objects {
    /// A B2B organization that purchases from the shop. In the Storefront API, company information is accessed through the [`PurchasingCompany`](https://shopify.dev/docs/api/storefront/current/objects/PurchasingCompany) object on [`CartBuyerIdentity`](https://shopify.dev/docs/api/storefront/current/objects/CartBuyerIdentity), which provides the associated location and contact for the current purchasing context.
    ///
    /// You can store custom data using [metafields](https://shopify.dev/docs/apps/build/metafields).
    static let Company = ApolloAPI.Object(
        typename: "Company",
        implementedInterfaces: [
            Storefront.Interfaces.HasMetafields.self,
            Storefront.Interfaces.Node.self
        ],
        keyFields: nil
    )
}
