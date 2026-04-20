// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension Storefront.Interfaces {
    /// Implemented by resources that support custom metadata through [`Metafield`](https://shopify.dev/docs/api/storefront/current/objects/Metafield) objects. Types like [`Product`](https://shopify.dev/docs/api/storefront/current/objects/Product), [`Collection`](https://shopify.dev/docs/api/storefront/current/objects/Collection), and [`Customer`](https://shopify.dev/docs/api/storefront/current/objects/Customer) implement this interface to provide consistent access to metafields.
    ///
    /// You can retrieve a [single metafield](https://shopify.dev/docs/api/storefront/current/interfaces/HasMetafields#fields-metafield) by namespace and key, or fetch [multiple metafields](https://shopify.dev/docs/api/storefront/current/interfaces/HasMetafields#fields-metafields) in a single request. If you omit the namespace, then the [app-reserved namespace](https://shopify.dev/docs/apps/build/metafields#app-owned-metafields) is used by default.
    static let HasMetafields = ApolloAPI.Interface(
        name: "HasMetafields",
        keyFields: nil,
        implementingObjects: [
            "Article",
            "Blog",
            "Cart",
            "Collection",
            "Company",
            "CompanyLocation",
            "Customer",
            "Location",
            "Market",
            "Order",
            "Page",
            "Product",
            "ProductVariant",
            "SellingPlan",
            "Shop"
        ]
    )
}
