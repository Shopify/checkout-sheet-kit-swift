// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension Storefront.Objects {
    /// A shipping or delivery choice available to customers during checkout. Each option includes a title, estimated cost, and delivery method type such as shipping or local pickup.
    ///
    /// Returned by the [`CartDeliveryGroup`](https://shopify.dev/docs/api/storefront/current/objects/CartDeliveryGroup) object's [`deliveryOptions`](https://shopify.dev/docs/api/storefront/current/objects/CartDeliveryGroup#field-CartDeliveryGroup.fields.deliveryOptions) field and [`selectedDeliveryOption`](https://shopify.dev/docs/api/storefront/current/objects/CartDeliveryGroup#field-CartDeliveryGroup.fields.selectedDeliveryOption) field.
    static let CartDeliveryOption = ApolloAPI.Object(
        typename: "CartDeliveryOption",
        implementedInterfaces: [],
        keyFields: nil
    )
}
