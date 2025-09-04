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
import ShopifyCheckoutSheetKit

/// A lightweight GraphQL client for the Storefront API without external dependencies
@available(iOS 16.0, *)
class GraphQLClient: Loggable {
    let url: URL
    private let headers: [String: String]
    private let session: URLSession
    let inContextDirective: InContextDirective

    /// Initialize a new GraphQL client
    /// - Parameters:
    ///   - url: The GraphQL endpoint URL
    ///   - headers: HTTP headers to include with requests
    ///   - context: The context for localization
    ///   - session: Custom URLSession (defaults to shared)
    init(
        url: URL,
        headers: [String: String] = [:],
        context: InContextDirective = InContextDirective(),
        session: URLSession = .shared
    ) {
        self.url = url
        self.headers = headers
        inContextDirective = context
        self.session = session
    }

    /// Execute a GraphQL query
    /// - Parameter operation: The GraphQL query operation
    /// - Returns: The decoded response
    func query<T: Decodable>(_ operation: GraphQLRequest<T>) async throws -> GraphQLResponse<T> {
        return try await execute(operation: operation)
    }

    /// Execute a GraphQL mutation
    /// - Parameter operation: The GraphQL mutation operation
    /// - Returns: The decoded response
    func mutate<T: Decodable>(_ operation: GraphQLRequest<T>) async throws -> GraphQLResponse<T> {
        return try await execute(operation: operation)
    }

    /// Execute a raw GraphQL request
    private func execute<T: Decodable>(
        operation: GraphQLRequest<T>
    ) async throws -> GraphQLResponse<T> {
        let urlRequest = try getURLRequest(
            body:
            operation
                .withContextDirective(inContextDirective)
                .minify()
        )

        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            logError("Could not decode response into expected: HTTPURLResponse")
            throw GraphQLError.networkError("Invalid response")
        }

        if httpResponse.statusCode != 200 {
            logError("Expected statusCode: 200, received: \(httpResponse.statusCode)")
            throw GraphQLError.httpError(statusCode: httpResponse.statusCode, data: data)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let decodedResponse = try decoder.decode(GraphQLResponse<T>.self, from: data)

        if let errors = decodedResponse.errors, !errors.isEmpty {
            logError("Reponse contained \(errors.count) error(s)")
            throw GraphQLError.graphQLErrors(errors)
        }

        return decodedResponse
    }

    private func getURLRequest(body: Encodable) throws -> URLRequest {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Set User-Agent header
        let userAgent = UserAgent.string(
            type: .standard,
            colorScheme: .automatic,
            entryPoint: .acceleratedCheckouts
        )
        urlRequest.setValue(userAgent, forHTTPHeaderField: "User-Agent")

        // Add all provided headers
        for (key, value) in headers {
            let value = value as String
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        urlRequest.httpBody = try JSONEncoder().encode(body)
        return urlRequest
    }
}
