// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension Storefront.Objects {
    /// The `Product` object lets you manage products in a merchant’s store.
    ///
    /// Products are the goods and services that merchants offer to customers.
    /// They can include various details such as title, description, price, images, and options such as size or color.
    /// You can use [product variants](/docs/api/storefront/latest/objects/ProductVariant)
    /// to create or update different versions of the same product.
    /// You can also add or update product [media](/docs/api/storefront/latest/interfaces/Media).
    /// Products can be organized by grouping them into a [collection](/docs/api/storefront/latest/objects/Collection).
    ///
    /// Learn more about working with [products and collections](/docs/storefronts/headless/building-with-the-storefront-api/products-collections).
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
