// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension Storefront.Objects {
    /// A specific version of a [product](https://shopify.dev/docs/api/storefront/current/objects/Product) available for sale, differentiated by options like size or color. For example, a small blue t-shirt and a large blue t-shirt are separate variants of the same product. For more information, see the docs on [Shopify's product model](https://shopify.dev/docs/apps/build/product-merchandising/products-and-collections).
    ///
    /// For products with quantity rules, variants enforce minimum, maximum, and increment constraints on purchases.
    ///
    /// Variants also support subscriptions and pre-orders through [selling plan allocations](https://shopify.dev/docs/api/storefront/current/objects/SellingPlanAllocation) objects, bundle configurations through [product variant components](https://shopify.dev/docs/api/storefront/current/objects/ProductVariantComponent) objects, and [shop pay installments pricing](https://shopify.dev/docs/api/storefront/current/objects/ShopPayInstallmentsPricing) for flexible payment options.
    static let ProductVariant = ApolloAPI.Object(
        typename: "ProductVariant",
        implementedInterfaces: [
            Storefront.Interfaces.HasMetafields.self,
            Storefront.Interfaces.Node.self
        ],
        keyFields: nil
    )
}
