// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension Storefront.Objects {
    /// A branch or office of a [`Company`](https://shopify.dev/docs/api/storefront/current/objects/Company) where B2B customers can place orders. When a B2B customer selects a location after logging in, the Storefront API contextualizes product queries to return location-specific pricing and quantity rules.
    ///
    /// Access through the [`PurchasingCompany`](https://shopify.dev/docs/api/storefront/current/objects/PurchasingCompany) object, which associates the location with the buyer's [`Cart`](https://shopify.dev/docs/api/storefront/current/objects/Cart).
    static let CompanyLocation = ApolloAPI.Object(
        typename: "CompanyLocation",
        implementedInterfaces: [
            Storefront.Interfaces.HasMetafields.self,
            Storefront.Interfaces.Node.self
        ],
        keyFields: nil
    )
}
