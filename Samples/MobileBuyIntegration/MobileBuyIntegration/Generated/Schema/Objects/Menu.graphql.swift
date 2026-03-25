// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension Storefront.Objects {
    /// A navigation structure for building store [menus](https://help.shopify.com/manual/online-store/menus-and-links). Each menu contains [`MenuItem`](https://shopify.dev/docs/api/storefront/current/objects/MenuItem) objects that can be nested to create multi-level navigation hierarchies.
    ///
    /// Menu items can link to [collections](https://shopify.dev/docs/api/storefront/current/objects/Collection), [products](https://shopify.dev/docs/api/storefront/current/objects/Product), [pages](https://shopify.dev/docs/api/storefront/current/objects/Page), [blogs](https://shopify.dev/docs/api/storefront/current/objects/Blog), or external URLs. Use the [`menu`](https://shopify.dev/docs/api/storefront/current/queries/menu) query to retrieve a menu by its handle.
    static let Menu = ApolloAPI.Object(
        typename: "Menu",
        implementedInterfaces: [Storefront.Interfaces.Node.self],
        keyFields: nil
    )
}
