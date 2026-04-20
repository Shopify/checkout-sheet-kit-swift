// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension Storefront.Objects {
    /// An item in a customer's [`Cart`](https://shopify.dev/docs/api/storefront/current/objects/Cart) representing a product variant they intend to purchase. Each cart line tracks the merchandise, quantity, cost breakdown, and any applied discounts.
    ///
    /// Cart lines can include custom attributes for additional information like gift wrapping requests, and can be associated with a [`SellingPlanAllocation`](https://shopify.dev/docs/api/storefront/current/objects/SellingPlanAllocation) for purchase options like subscriptions, pre-orders, or try-before-you-buy. The [`instructions`](https://shopify.dev/docs/api/storefront/current/objects/CartLine#field-CartLine.fields.instructions) field indicates whether the line can be removed or have its quantity updated.
    static let CartLine = ApolloAPI.Object(
        typename: "CartLine",
        implementedInterfaces: [
            Storefront.Interfaces.BaseCartLine.self,
            Storefront.Interfaces.Node.self
        ],
        keyFields: nil
    )
}
