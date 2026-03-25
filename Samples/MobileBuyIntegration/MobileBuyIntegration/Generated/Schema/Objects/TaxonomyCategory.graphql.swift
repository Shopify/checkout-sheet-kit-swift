// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension Storefront.Objects {
    /// A category from Shopify's [Standard Product Taxonomy](https://shopify.github.io/product-taxonomy/releases/unstable/?categoryId=sg-4-17-2-17) assigned to a [`Product`](https://shopify.dev/docs/api/storefront/current/objects/Product). Categories provide hierarchical classification through the `ancestors` field.
    ///
    /// The [`ancestors`](https://shopify.dev/docs/api/storefront/current/objects/TaxonomyCategory#field-TaxonomyCategory.fields.ancestors) field returns the parent chain from the immediate parent up to the root. Each ancestor category also includes its own `ancestors`.
    ///
    /// The [`name`](https://shopify.dev/docs/api/storefront/latest/objects/TaxonomyCategory#field-TaxonomyCategory.fields.name) field returns the localized category name based on the storefront's request language with shop locale fallbacks. If a translation isn't available for the resolved locale, the English taxonomy name is returned.
    static let TaxonomyCategory = ApolloAPI.Object(
        typename: "TaxonomyCategory",
        implementedInterfaces: [Storefront.Interfaces.Node.self],
        keyFields: nil
    )
}
