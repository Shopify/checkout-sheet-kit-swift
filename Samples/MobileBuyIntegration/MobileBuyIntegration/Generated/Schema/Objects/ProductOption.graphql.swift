// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension Storefront.Objects {
    /// A customizable product attribute that customers select when purchasing, such as "Size", "Color", or "Material". Each option has a name and a set of [`ProductOptionValue`](https://shopify.dev/docs/api/storefront/current/objects/ProductOptionValue) objects representing the available choices.
    ///
    /// Different combinations of option values create distinct [`ProductVariant`](https://shopify.dev/docs/api/storefront/current/objects/ProductVariant) objects. Option values can include visual swatches that display colors or images to help customers make selections. Option names have a 255-character limit.
    ///
    /// Learn more about [Shopify's product model](https://shopify.dev/docs/apps/build/product-merchandising/products-and-collections).
    static let ProductOption = ApolloAPI.Object(
        typename: "ProductOption",
        implementedInterfaces: [Storefront.Interfaces.Node.self],
        keyFields: nil
    )
}
