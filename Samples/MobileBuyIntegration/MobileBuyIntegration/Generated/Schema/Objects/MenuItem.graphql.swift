// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension Storefront.Objects {
    /// A navigation link within a [`Menu`](https://shopify.dev/docs/api/storefront/current/objects/Menu). Each item has a title, URL, and can link to store resources like [products](https://shopify.dev/docs/api/storefront/current/objects/Product), [collections](https://shopify.dev/docs/api/storefront/current/objects/Collection), [pages](https://shopify.dev/docs/api/storefront/current/objects/Page), [blogs](https://shopify.dev/docs/api/storefront/current/objects/Blog), or external URLs.
    ///
    /// Menu items support nested hierarchies through the [`items`](https://shopify.dev/docs/api/storefront/current/objects/MenuItem#field-MenuItem.fields.items) field, enabling dropdown or multi-level navigation structures. The [`tags`](https://shopify.dev/docs/api/storefront/current/objects/MenuItem#field-MenuItem.fields.tags) field filters results when the item links to a collection specifically.
    static let MenuItem = ApolloAPI.Object(
        typename: "MenuItem",
        implementedInterfaces: [Storefront.Interfaces.Node.self],
        keyFields: nil
    )
}
