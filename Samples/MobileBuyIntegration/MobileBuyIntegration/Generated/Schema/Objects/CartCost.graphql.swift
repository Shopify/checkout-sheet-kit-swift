// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension Storefront.Objects {
    /// The estimated costs that a buyer will pay at checkout. The `Cart` object's [`cost`](https://shopify.dev/docs/api/storefront/current/objects/Cart#field-Cart.fields.cost) field returns this. The costs are subject to change and changes will be reflected at checkout. Costs reflect [international pricing](https://shopify.dev/docs/storefronts/headless/building-with-the-storefront-api/markets/international-pricing) based on the buyer's context.
    ///
    /// Amounts include the subtotal before taxes and cart-level discounts, the checkout charge amount excluding deferred payments, and the total. The subtotal and total amounts each include a corresponding boolean field indicating whether the value is an estimate.
    static let CartCost = ApolloAPI.Object(
        typename: "CartCost",
        implementedInterfaces: [],
        keyFields: nil
    )
}
