// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension Storefront.Objects {
    /// Cost breakdown for a single line item in a [cart](https://shopify.dev/docs/api/storefront/current/objects/Cart). Includes the per-unit price, the subtotal before line-level discounts, and the final total amount the buyer pays.
    ///
    /// The [`compareAtAmountPerQuantity`](https://shopify.dev/docs/api/storefront/current/objects/CartLineCost#field-CartLineCost.fields.compareAtAmountPerQuantity) field shows the original price when the item is on sale, enabling the display of savings to customers.
    static let CartLineCost = ApolloAPI.Object(
        typename: "CartLineCost",
        implementedInterfaces: [],
        keyFields: nil
    )
}
