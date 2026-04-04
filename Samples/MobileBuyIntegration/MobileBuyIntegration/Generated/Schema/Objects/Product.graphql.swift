// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension Storefront.Objects {
    /// Represents an item listed in a shop's catalog.
    ///
    /// Products support multiple [product variants](https://shopify.dev/docs/api/storefront/current/objects/ProductVariant), representing different versions of the same product, and can include various [media](https://shopify.dev/docs/api/storefront/current/interfaces/Media) types. Use the [`selectedOrFirstAvailableVariant`](https://shopify.dev/docs/api/storefront/current/objects/Product#field-Product.fields.selectedOrFirstAvailableVariant) or [`variantBySelectedOptions`](https://shopify.dev/docs/api/storefront/current/objects/Product#field-Product.fields.variantBySelectedOptions) fields to help customers find the right variant based on their selections.
    ///
    /// Products can be organized into [collections](https://shopify.dev/docs/api/storefront/current/objects/Collection), associated with [selling plans](https://shopify.dev/docs/api/storefront/current/objects/SellingPlanGroup) for subscriptions, and extended with custom data through [metafields](https://shopify.dev/docs/api/storefront/current/objects/Metafield).
    ///
    /// Learn more about working with [products and collections](https://shopify.dev/docs/storefronts/headless/building-with-the-storefront-api/products-collections).
    static let Product = ApolloAPI.Object(
        typename: "Product",
        implementedInterfaces: [
            Storefront.Interfaces.HasMetafields.self,
            Storefront.Interfaces.Node.self,
            Storefront.Interfaces.OnlineStorePublishable.self,
            Storefront.Interfaces.Trackable.self
        ],
        keyFields: nil
    )
}
