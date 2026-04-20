// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension Storefront.Objects {
    /// A physical store location where product inventory is held and that supports in-store pickup. Provides the location's name, address, and geographic coordinates for proximity-based sorting. Use with [`StoreAvailability`](https://shopify.dev/docs/api/storefront/current/objects/StoreAvailability) to show customers where a [`ProductVariant`](https://shopify.dev/docs/api/storefront/current/objects/ProductVariant) is available for pickup.
    ///
    /// Learn more about [supporting local pickup on storefronts](https://shopify.dev/docs/storefronts/headless/building-with-the-storefront-api/products-collections/local-pickup).
    static let Location = ApolloAPI.Object(
        typename: "Location",
        implementedInterfaces: [
            Storefront.Interfaces.HasMetafields.self,
            Storefront.Interfaces.Node.self
        ],
        keyFields: nil
    )
}
