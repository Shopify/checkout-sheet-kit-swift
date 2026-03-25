// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension Storefront.Objects {
    /// A post that belongs to a [`Blog`](https://shopify.dev/docs/api/storefront/current/objects/Blog). Each article includes content with optional HTML formatting, an excerpt for previews, [`ArticleAuthor`](https://shopify.dev/docs/api/storefront/current/objects/ArticleAuthor) information, and an associated [`Image`](https://shopify.dev/docs/api/storefront/current/objects/Image).
    ///
    /// Articles can be organized with tags and include [`SEO`](https://shopify.dev/docs/api/storefront/current/objects/SEO) metadata. You can manage [comments](https://shopify.dev/docs/api/storefront/current/objects/Comment) when the blog's comment policy enables them.
    static let Article = ApolloAPI.Object(
        typename: "Article",
        implementedInterfaces: [
            Storefront.Interfaces.HasMetafields.self,
            Storefront.Interfaces.Node.self,
            Storefront.Interfaces.OnlineStorePublishable.self,
            Storefront.Interfaces.Trackable.self
        ],
        keyFields: nil
    )
}
