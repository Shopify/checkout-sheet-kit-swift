//
//  StorefrontAPI.swift
//  ShopifyAcceleratedCheckouts
//

import Foundation

/// High-level API for Storefront operations using the custom GraphQL client
@available(iOS 17.0, *)
@Observable class StorefrontAPI {
    let client: GraphQLClient

    /// Initialize the Storefront API
    /// - Parameters:
    ///   - shopDomain: The shop domain (e.g., "example.myshopify.com")
    ///   - storefrontAccessToken: The storefront access token
    ///   - apiVersion: The API version to use (defaults to "2025-07")
    ///   - countryCode: Optional country code for localization
    ///   - languageCode: Optional language code for localization
    init(
        shopDomain: String,
        storefrontAccessToken: String,
        apiVersion: String = ShopifyAcceleratedCheckouts.apiVersion,
        countryCode: CountryCode = .US,
        languageCode: LanguageCode = .EN
    ) {
        let url = URL(string: "https://\(shopDomain)/api/\(apiVersion)/graphql.json")!

        client = GraphQLClient(
            url: url,
            headers: ["X-Shopify-Storefront-Access-Token": storefrontAccessToken],
            context: InContextDirective(countryCode: countryCode, languageCode: languageCode)
        )
    }
}
