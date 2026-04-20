// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension Storefront.Objects {
    /// A specific value for a [`ProductOption`](https://shopify.dev/docs/api/storefront/current/objects/ProductOption), such as "Red" or "Blue" for a "Color" option. Option values combine across different options to create [`ProductVariant`](https://shopify.dev/docs/api/storefront/current/objects/ProductVariant) objects.
    ///
    /// Each value can include a visual swatch that displays a color or image. The [`firstSelectableVariant`](https://shopify.dev/docs/api/storefront/current/objects/ProductOptionValue#field-ProductOptionValue.fields.firstSelectableVariant) field returns the variant that combines this option value with the lowest-position values for all other options. This is useful for building product selection interfaces.
    ///
    /// Learn more about [Shopify's product model](https://shopify.dev/docs/apps/build/product-merchandising/products-and-collections).
    static let ProductOptionValue = ApolloAPI.Object(
        typename: "ProductOptionValue",
        implementedInterfaces: [Storefront.Interfaces.Node.self],
        keyFields: nil
    )
}
