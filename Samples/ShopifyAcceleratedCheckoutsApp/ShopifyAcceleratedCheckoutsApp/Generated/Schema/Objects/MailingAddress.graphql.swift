// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension Storefront.Objects {
    /// A physical mailing address associated with a [`Customer`](https://shopify.dev/docs/api/storefront/current/objects/Customer) or [`Order`](https://shopify.dev/docs/api/storefront/current/objects/Order). Stores standard address components including street address, city, province, country, and postal code, along with customer name and company information.
    ///
    /// The address includes geographic coordinates and provides pre-formatted output through the [`formatted`](https://shopify.dev/docs/api/storefront/current/objects/MailingAddress#field-MailingAddress.fields.formatted) field, which can optionally include or exclude name and company details.
    static let MailingAddress = ApolloAPI.Object(
        typename: "MailingAddress",
        implementedInterfaces: [Storefront.Interfaces.Node.self],
        keyFields: nil
    )
}
