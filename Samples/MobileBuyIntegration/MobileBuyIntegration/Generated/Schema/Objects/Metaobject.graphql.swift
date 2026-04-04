// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension Storefront.Objects {
    /// An instance of [custom structured data](https://shopify.dev/docs/apps/build/metaobjects) defined by a metaobject definition. Metaobjects store reusable content that extends beyond standard Shopify resources, such as size charts, author profiles, or custom content sections.
    ///
    /// Each metaobject contains fields that match the types and validation rules specified in its definition. [`Metafield`](https://shopify.dev/docs/api/storefront/current/objects/Metafield) references can point to metaobjects, connecting custom data with products, collections, and other resources. If the definition has the `renderable` capability, then the [`seo`](https://shopify.dev/docs/api/storefront/current/objects/Metaobject#field-Metaobject.fields.seo) field provides SEO metadata. If it has the `online_store` capability, then the [`onlineStoreUrl`](https://shopify.dev/docs/api/storefront/current/objects/Metaobject#field-Metaobject.fields.onlineStoreUrl) field returns the public URL.
    static let Metaobject = ApolloAPI.Object(
        typename: "Metaobject",
        implementedInterfaces: [
            Storefront.Interfaces.Node.self,
            Storefront.Interfaces.OnlineStorePublishable.self
        ],
        keyFields: nil
    )
}
