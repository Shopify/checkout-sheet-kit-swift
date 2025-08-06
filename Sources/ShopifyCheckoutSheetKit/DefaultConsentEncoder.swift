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

/// Default implementation of ConsentEncoder using Shopify's Storefront API
public class DefaultConsentEncoder: ConsentEncoder {
    private let client: StorefrontConsentClient

    /// Creates a DefaultConsentEncoder
    /// - Parameters:
    ///   - shopDomain: The shop domain (e.g. "my-shop.myshopify.com")
    ///   - storefrontAccessToken: The Storefront API access token
    /// - Throws: ConsentEncodingError if parameters are invalid
    public init(shopDomain: String, storefrontAccessToken: String) throws {
        client = try StorefrontConsentClient(
            shopDomain: shopDomain,
            accessToken: storefrontAccessToken
        )
    }

    /// Encodes privacy consent using the Storefront API
    /// - Parameter consent: The privacy consent to encode
    /// - Returns: Encoded consent string, or nil if the API doesn't return a value
    /// - Throws: ConsentEncodingError for various failure scenarios
    public func encode(_ consent: Configuration.PrivacyConsent) async throws -> String? {
        return try await client.encodeConsent(consent)
    }
}
