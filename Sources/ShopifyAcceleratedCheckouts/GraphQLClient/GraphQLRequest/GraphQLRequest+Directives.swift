//
//  GraphQLRequest+Directives.swift
//  ShopifyAcceleratedCheckouts
//
//  Created by Kieran Barrie Osgood on 27/06/2025.
//

import Foundation

/// The country and language context for the API requests
/// see: https://shopify.dev/changelog/storefront-api-incontext-directive-supports-languages
struct InContextDirective {
    let countryCode: CountryCode
    let languageCode: LanguageCode

    init(countryCode: CountryCode = .US, languageCode: LanguageCode = .EN) {
        self.countryCode = countryCode
        self.languageCode = languageCode
    }

    /// Returns the formatted GraphQL directive string
    var toString: String {
        let directiveArgs = [
            "country: \(countryCode.rawValue)",
            "language: \(languageCode.rawValue)"
        ].joined(separator: ", ")

        return "@inContext(\(directiveArgs))"
    }
}

extension GraphQLRequest {
    /// Apply the @inContext directive to queries & mutations
    /// We only handle a single query/mutation per request, additional queries/mutations are ignored
    func withContextDirective(_ contextDirective: InContextDirective) -> GraphQLRequest<T> {
        var lines = query.components(separatedBy: .newlines)

        let pattern = #"^(\s*(?:query|mutation)\s+\w+(?:\s*\([^)]*\))?)(\s*\{)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return self
        }

        for (i, line) in zip(lines.indices, lines) {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            guard trimmedLine.hasPrefix("query ") || trimmedLine.hasPrefix("mutation ") else {
                continue
            }

            guard
                let match = regex.firstMatch(
                    in: line, options: [], range: NSRange(line.startIndex..., in: line)
                )
            else { continue }

            /// pattern matches upto and including the opening brace
            /// insertIndex is the index of the opening brace
            let insertIndex = line.index(line.startIndex, offsetBy: match.range(at: 1).length)
            let textBeforeOpeningBrace = line[..<insertIndex]
            let textAfterOpeningBrace = line[insertIndex...]
            lines[i] =
                "\(textBeforeOpeningBrace) \(contextDirective.toString) \(textAfterOpeningBrace)"
            break
        }

        return GraphQLRequest(
            query: lines.joined(separator: "\n"),
            responseType: responseType,
            variables: variables
        )
    }
}
