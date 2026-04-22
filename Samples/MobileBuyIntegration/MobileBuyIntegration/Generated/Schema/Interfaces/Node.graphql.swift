// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension Storefront.Interfaces {
    /// Enables global object identification following the [Relay specification](https://relay.dev/graphql/objectidentification.htm#sec-Node-Interface). Any type implementing this interface has a globally-unique `id` field and can be fetched directly using the [`node`](https://shopify.dev/docs/api/storefront/current/queries/node) or [`nodes`](https://shopify.dev/docs/api/storefront/current/queries/nodes) queries.
    static let Node = ApolloAPI.Interface(
        name: "Node",
        keyFields: nil,
        implementingObjects: [
            "AppliedGiftCard",
            "Article",
            "Blog",
            "Cart",
            "CartLine",
            "Collection",
            "Comment",
            "Company",
            "CompanyContact",
            "CompanyLocation",
            "ComponentizableCartLine",
            "ExternalVideo",
            "GenericFile",
            "Location",
            "MailingAddress",
            "Market",
            "MediaImage",
            "MediaPresentation",
            "Menu",
            "MenuItem",
            "Metafield",
            "Metaobject",
            "Model3d",
            "Order",
            "Page",
            "Product",
            "ProductOption",
            "ProductOptionValue",
            "ProductVariant",
            "Shop",
            "ShopPayInstallmentsFinancingPlan",
            "ShopPayInstallmentsFinancingPlanTerm",
            "ShopPayInstallmentsProductVariantPricing",
            "ShopPolicy",
            "TaxonomyCategory",
            "UrlRedirect",
            "Video"
        ]
    )
}
