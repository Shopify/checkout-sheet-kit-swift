// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension Storefront.Interfaces {
    /// A common set of fields for media content associated with [products](https://shopify.dev/docs/api/storefront/current/objects/Product). Implementations include [`MediaImage`](https://shopify.dev/docs/api/storefront/current/objects/MediaImage) for Shopify-hosted images, [`Video`](https://shopify.dev/docs/api/storefront/current/objects/Video) for Shopify-hosted videos, [`ExternalVideo`](https://shopify.dev/docs/api/storefront/current/objects/ExternalVideo) for videos hosted on platforms like YouTube or Vimeo, and [`Model3d`](https://shopify.dev/docs/api/storefront/current/objects/Model3d) for 3D models.
    ///
    /// Each implementation shares fields for alt text, content type, and preview images, while adding type-specific fields like embed URLs for external videos or source files for 3D models.
    static let Media = ApolloAPI.Interface(
        name: "Media",
        keyFields: nil,
        implementingObjects: [
            "ExternalVideo",
            "MediaImage",
            "Model3d",
            "Video"
        ]
    )
}
