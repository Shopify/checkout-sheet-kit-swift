// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension Storefront.Objects {
    /// The entry point for all Storefront API queries. Provides access to shop resources including products, collections, carts, and customer data, as well as content like articles and pages. This query acts as the public, top-level type from which all queries must start.
    ///
    /// Use individual queries like [`product`](https://shopify.dev/docs/api/storefront/current/queries/product) or [`collection`](https://shopify.dev/docs/api/storefront/current/queries/collection) to fetch specific resources by ID or handle. Use plural queries like [`products`](https://shopify.dev/docs/api/storefront/current/queries/products) or [`collections`](https://shopify.dev/docs/api/storefront/current/queries/collections) to retrieve paginated lists with optional filtering and sorting. The [`search`](https://shopify.dev/docs/api/storefront/current/queries/search) and [`predictiveSearch`](https://shopify.dev/docs/api/storefront/current/queries/predictiveSearch) queries enable storefront search functionality.
    ///
    /// Explore queries interactively with the [GraphiQL explorer and sample query kit](https://shopify.dev/docs/storefronts/headless/building-with-the-storefront-api/api-exploration).
    static let QueryRoot = ApolloAPI.Object(
        typename: "QueryRoot",
        implementedInterfaces: [],
        keyFields: nil
    )
}
