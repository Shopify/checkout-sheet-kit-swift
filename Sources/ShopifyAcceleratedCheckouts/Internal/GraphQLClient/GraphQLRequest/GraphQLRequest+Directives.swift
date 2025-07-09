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
