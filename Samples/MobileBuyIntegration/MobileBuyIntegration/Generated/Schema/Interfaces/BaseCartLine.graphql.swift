// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension Storefront.Interfaces {
    /// Defines the shared fields for items in a shopping cart. Implemented by [`CartLine`](https://shopify.dev/docs/api/storefront/current/objects/CartLine) for individual merchandise and [`ComponentizableCartLine`](https://shopify.dev/docs/api/storefront/current/objects/ComponentizableCartLine) for grouped merchandise like bundles.
    ///
    /// Each implementation includes the merchandise being purchased, quantity, cost breakdown, applied discounts, custom attributes, and any associated [`SellingPlan`](https://shopify.dev/docs/api/storefront/current/objects/SellingPlan).
    static let BaseCartLine = ApolloAPI.Interface(
        name: "BaseCartLine",
        keyFields: nil,
        implementingObjects: [
            "CartLine",
            "ComponentizableCartLine"
        ]
    )
}
