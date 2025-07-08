//
//  GraphQLClient.swift
//  ShopifyAcceleratedCheckouts
//

import Foundation

/// A lightweight GraphQL client for the Storefront API without external dependencies
@available(iOS 17.0, *)
class GraphQLClient {
    private let url: URL
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
}

extension GraphQLClient {
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
            throw GraphQLError.networkError("Invalid response")
        }

        if httpResponse.statusCode != 200 {
            throw GraphQLError.httpError(statusCode: httpResponse.statusCode, data: data)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let decodedResponse = try decoder.decode(GraphQLResponse<T>.self, from: data)

        if let errors = decodedResponse.errors, !errors.isEmpty {
            throw GraphQLError.graphQLErrors(errors)
        }

        return decodedResponse
    }

    private func getURLRequest(body: Encodable) throws -> URLRequest {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add all provided headers
        for (key, value) in headers {
            let value = value as String
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        urlRequest.httpBody = try JSONEncoder().encode(body)
        return urlRequest
    }
}
