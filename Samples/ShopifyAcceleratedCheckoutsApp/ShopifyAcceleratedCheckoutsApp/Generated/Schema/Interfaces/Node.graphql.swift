// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension Storefront.Interfaces {
    /// An object with an ID field to support global identification, in accordance with the
    /// [Relay specification](https://relay.dev/graphql/objectidentification.htm#sec-Node-Interface).
    /// This interface is used by the [node](/docs/api/storefront/latest/queries/node)
    /// and [nodes](/docs/api/storefront/latest/queries/nodes) queries.
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
