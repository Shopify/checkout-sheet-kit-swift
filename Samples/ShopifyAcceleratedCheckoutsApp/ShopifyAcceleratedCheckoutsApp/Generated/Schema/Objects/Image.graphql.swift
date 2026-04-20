// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension Storefront.Objects {
    /// An image resource with URL, dimensions, and transformation options. Used for product images, collection images, media previews, and other visual content throughout the storefront.
    ///
    /// The [`url`](https://shopify.dev/docs/api/storefront/current/objects/Image#field-Image.fields.url) field accepts an [`ImageTransformInput`](https://shopify.dev/docs/api/storefront/current/input-objects/ImageTransformInput) argument for resizing, cropping, scaling for retina displays, and converting between image formats. Use the [`thumbhash`](https://shopify.dev/docs/api/storefront/current/objects/Image#field-Image.fields.thumbhash) field to display lightweight placeholders while images load.
    static let Image = ApolloAPI.Object(
        typename: "Image",
        implementedInterfaces: [],
        keyFields: nil
    )
}
