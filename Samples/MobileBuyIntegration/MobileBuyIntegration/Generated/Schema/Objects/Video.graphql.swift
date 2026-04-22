// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension Storefront.Objects {
    /// A video hosted on Shopify's servers. Implements the [`Media`](https://shopify.dev/docs/api/storefront/current/interfaces/Media) interface and provides multiple video sources through the [`sources`](https://shopify.dev/docs/api/storefront/current/objects/Video#field-Video.fields.sources) field, each with [format](https://shopify.dev/docs/api/storefront/current/objects/Video#field-Video.fields.sources.format), dimensions, and [URL information](https://shopify.dev/docs/api/storefront/current/objects/Video#field-Video.fields.sources.url) for adaptive playback.
    ///
    /// For videos hosted on external platforms like YouTube or Vimeo, use [`ExternalVideo`](https://shopify.dev/docs/api/storefront/current/objects/ExternalVideo) instead.
    static let Video = ApolloAPI.Object(
        typename: "Video",
        implementedInterfaces: [
            Storefront.Interfaces.Media.self,
            Storefront.Interfaces.Node.self
        ],
        keyFields: nil
    )
}
