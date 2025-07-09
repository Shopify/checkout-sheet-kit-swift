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

// MARK: - GraphQL Operation

/// GraphQLOperation binds a query (data to be requested)
/// with a response Decoder(Codable to decode the data requested).
struct GraphQLRequest<T: Decodable>: Encodable {
    private(set) var query: String
    let responseType: T.Type
    let variables: [String: Any]

    enum CodingKeys: String, CodingKey {
        case query
        case variables
    }

    init(query: String, responseType: T.Type, variables: [String: Any] = [:]) {
        self.query = query
        self.responseType = responseType
        self.variables = variables
    }

    init(
        operation: GraphQLDocument.Queries,
        responseType: T.Type,
        variables: [String: Any] = [:]
    ) {
        self.init(
            query: GraphQLDocument.build(operation: operation),
            responseType: responseType,
            variables: variables
        )
    }

    init(
        operation: GraphQLDocument.Mutations,
        responseType: T.Type,
        variables: [String: Any] = [:]
    ) {
        self.init(
            query: GraphQLDocument.build(operation: operation),
            responseType: responseType,
            variables: variables
        )
    }

    /// Encodes for use as urlRequest.httpBody
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(query, forKey: .query)

        if !variables.isEmpty {
            try container.encode(AnyCodable(variables), forKey: .variables)
        }
    }

    /// Minify the GraphQL query by removing unnecessary whitespace and newlines
    func minify() -> GraphQLRequest<T> {
        let lines = query.components(separatedBy: .newlines)
        let nonCommentLines = lines.filter { line in
            !line.trimmingCharacters(in: .whitespaces).hasPrefix("#")
        }

        let joined = nonCommentLines.joined(separator: " ")

        // Replace multiple whitespace characters with a single space
        let whitespacePattern = "\\s+"
        guard let regex = try? NSRegularExpression(pattern: whitespacePattern, options: []) else {
            return self
        }

        let range = NSRange(location: 0, length: joined.utf16.count)
        let minified = regex.stringByReplacingMatches(
            in: joined, options: [], range: range, withTemplate: " "
        )

        let minifiedQuery = minified.trimmingCharacters(in: .whitespaces)
        return GraphQLRequest(
            query: minifiedQuery,
            responseType: responseType,
            variables: variables
        )
    }
}
