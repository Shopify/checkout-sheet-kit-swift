// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension Storefront.Objects {
    /// Groups cart line items that share the same delivery destination. Each group provides the available [`CartDeliveryOption`](https://shopify.dev/docs/api/storefront/current/objects/CartDeliveryOption) choices for that address, along with the customer's selected option.
    ///
    /// Access through the [`Cart`](https://shopify.dev/docs/api/storefront/current/objects/Cart) object's `deliveryGroups` field. Items are grouped by merchandise type (one-time purchase vs subscription), allowing different delivery methods for each.
    static let CartDeliveryGroup = ApolloAPI.Object(
        typename: "CartDeliveryGroup",
        implementedInterfaces: [],
        keyFields: nil
    )
}
