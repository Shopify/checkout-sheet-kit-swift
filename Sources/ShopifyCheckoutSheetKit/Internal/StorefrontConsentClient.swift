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

/// Internal client for communicating with Shopify's Storefront API consent management
internal class StorefrontConsentClient {
    private let shopDomain: String
    private let accessToken: String
    private let session: URLSession

    init(shopDomain: String, accessToken: String) throws {
        guard !shopDomain.isEmpty else {
            throw ConsentEncodingError.invalidShopDomain
        }
        guard !accessToken.isEmpty else {
            throw ConsentEncodingError.missingAccessToken
        }

        self.shopDomain = shopDomain
        self.accessToken = accessToken

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10.0
        config.timeoutIntervalForResource = 30.0
        session = URLSession(configuration: config)
    }

    /// Encodes consent using the Storefront API consentManagement query
    func encodeConsent(_ consent: Configuration.PrivacyConsent) async throws -> String? {
        let query = """
        query EncodeConsent($visitorConsent: VisitorConsent!) {
          consentManagement {
            cookies(visitorConsent: $visitorConsent) {
              trackingConsentCookie
            }
          }
        }
        """

        let variables: [String: Any] = [
            "visitorConsent": [
                "analytics": consent.contains(.analytics),
                "marketing": consent.contains(.marketing),
                "preferences": consent.contains(.preferences),
                "saleOfData": consent.contains(.saleOfData)
            ]
        ]

        let requestBody: [String: Any] = [
            "query": query,
            "variables": variables
        ]

        guard let url = URL(string: "https://\(shopDomain)/api/unstable/graphql.json") else {
            throw ConsentEncodingError.invalidShopDomain
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(accessToken, forHTTPHeaderField: "X-Shopify-Storefront-Access-Token")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            throw ConsentEncodingError.networkError(error)
        }

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw ConsentEncodingError.invalidResponse("Invalid HTTP response")
            }

            guard 200 ... 299 ~= httpResponse.statusCode else {
                if httpResponse.statusCode == 401 {
                    throw ConsentEncodingError.authenticationFailed
                }
                throw ConsentEncodingError.invalidResponse("HTTP \(httpResponse.statusCode)")
            }

            let graphQLResponse = try JSONDecoder().decode(GraphQLResponse.self, from: data)

            if let errors = graphQLResponse.errors, !errors.isEmpty {
                let errorMessage = errors.map { $0.message }.joined(separator: ", ")
                throw ConsentEncodingError.invalidResponse("GraphQL errors: \(errorMessage)")
            }

            return graphQLResponse.data?.consentManagement?.cookies?.trackingConsentCookie

        } catch let error as ConsentEncodingError {
            throw error
        } catch {
            throw ConsentEncodingError.networkError(error)
        }
    }
}

// MARK: - GraphQL Response Models

private struct GraphQLResponse: Codable {
    let data: ConsentData?
    let errors: [GraphQLError]?
}

private struct GraphQLError: Codable {
    let message: String
}

private struct ConsentData: Codable {
    let consentManagement: ConsentManagement?
}

private struct ConsentManagement: Codable {
    let cookies: ConsentCookies?
}

private struct ConsentCookies: Codable {
    let trackingConsentCookie: String?
}
