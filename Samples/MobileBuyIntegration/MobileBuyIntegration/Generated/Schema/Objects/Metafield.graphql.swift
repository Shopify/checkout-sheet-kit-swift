// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension Storefront.Objects {
    /// [Custom metadata](https://shopify.dev/docs/apps/build/metafields) attached to a Shopify resource such as a [`Product`](https://shopify.dev/docs/api/storefront/current/objects/Product), [`Collection`](https://shopify.dev/docs/api/storefront/current/objects/Collection), or [`Customer`](https://shopify.dev/docs/api/storefront/current/objects/Customer). Each metafield is identified by a namespace and key, and stores a value with an associated type.
    ///
    /// Values are always stored as strings, but the [`type`](https://shopify.dev/docs/api/storefront/current/objects/Metafield#field-Metafield.fields.type) field indicates how to interpret the data. When a metafield's type is a resource reference, use the [`reference`](https://shopify.dev/docs/api/storefront/current/objects/Metafield#field-Metafield.fields.reference) or [`references`](https://shopify.dev/docs/api/storefront/current/objects/Metafield#field-Metafield.fields.references) fields to retrieve the linked objects. Access metafields on any resource that implements the [`HasMetafields`](https://shopify.dev/docs/api/storefront/current/interfaces/HasMetafields) interface.
    static let Metafield = ApolloAPI.Object(
        typename: "Metafield",
        implementedInterfaces: [Storefront.Interfaces.Node.self],
        keyFields: nil
    )
}
