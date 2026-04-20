// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension Storefront.Objects {
    /// Any file that doesn't fit into a designated type like image or video. For example, a PDF or JSON document. Use this object to manage files in a merchant's store.
    ///
    /// Generic files are commonly referenced through [file reference metafields](https://shopify.dev/docs/apps/build/metafields/list-of-data-types) and returned as part of the [`MetafieldReference`](https://shopify.dev/docs/api/storefront/current/unions/MetafieldReference) union.
    ///
    /// Includes the file's URL, MIME type, size in bytes, and an optional preview image.
    static let GenericFile = ApolloAPI.Object(
        typename: "GenericFile",
        implementedInterfaces: [Storefront.Interfaces.Node.self],
        keyFields: nil
    )
}
