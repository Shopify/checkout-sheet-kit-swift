/*
 MIT License

 Copyright 2023 - Present, Shopify Inc.

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import Foundation

/// High-level API for Storefront operations using the custom GraphQL client
@available(iOS 17.0, *)
@Observable class StorefrontAPI {
    let client: GraphQLClient

    /// Initialize the Storefront API
    /// - Parameters:
    ///   - storefrontDomain: The shop domain (e.g., "example.myshopify.com")
    ///   - storefrontAccessToken: The storefront access token
    ///   - apiVersion: The API version to use (defaults to "2025-07")
    ///   - countryCode: Optional country code for localization
    ///   - languageCode: Optional language code for localization
    init(
        storefrontDomain: String,
        storefrontAccessToken: String,
        apiVersion: String = ShopifyAcceleratedCheckouts.apiVersion,
        countryCode: CountryCode? = nil,
        languageCode: LanguageCode? = nil
    ) {
        let url = URL(string: "https://\(storefrontDomain)/api/\(apiVersion)/graphql.json")!

        client = GraphQLClient(
            url: url,
            headers: ["X-Shopify-Storefront-Access-Token": storefrontAccessToken],
            context: InContextDirective(
                countryCode: countryCode,
                languageCode: languageCode
            )
        )
    }
}
