// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension Storefront.Objects {
    /// A suggested search term returned by the [`predictiveSearch`](https://shopify.dev/docs/api/storefront/current/queries/predictiveSearch) query. Query suggestions help customers refine their searches by showing relevant terms as they type.
    ///
    /// The [`text`](https://shopify.dev/docs/api/storefront/current/objects/SearchQuerySuggestion#field-SearchQuerySuggestion.fields.text) field provides the plain suggestion, while [`styledText`](https://shopify.dev/docs/api/storefront/current/objects/SearchQuerySuggestion#field-SearchQuerySuggestion.fields.styledText) includes HTML tags to highlight matching portions. Implements [`Trackable`](https://shopify.dev/docs/api/storefront/current/interfaces/Trackable) for analytics reporting on search traffic origins.
    static let SearchQuerySuggestion = ApolloAPI.Object(
        typename: "SearchQuerySuggestion",
        implementedInterfaces: [Storefront.Interfaces.Trackable.self],
        keyFields: nil
    )
}
