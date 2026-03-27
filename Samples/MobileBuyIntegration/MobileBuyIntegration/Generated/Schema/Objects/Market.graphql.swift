// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension Storefront.Objects {
    /// An audience of buyers that a merchant targets for sales. Audiences can include geographic regions, company locations, and retail locations. Markets enable localized shopping experiences with region-specific languages, currencies, and pricing.
    ///
    /// Each market has a unique [`handle`](https://shopify.dev/docs/api/storefront/current/objects/Market#field-Market.fields.handle) for identification and supports custom data through [`metafields`](https://shopify.dev/docs/api/storefront/current/objects/Metafield). Learn more about [building localized experiences with Shopify Markets](https://shopify.dev/docs/storefronts/headless/building-with-the-storefront-api/markets).
    static let Market = ApolloAPI.Object(
        typename: "Market",
        implementedInterfaces: [
            Storefront.Interfaces.HasMetafields.self,
            Storefront.Interfaces.Node.self
        ],
        keyFields: nil
    )
}
