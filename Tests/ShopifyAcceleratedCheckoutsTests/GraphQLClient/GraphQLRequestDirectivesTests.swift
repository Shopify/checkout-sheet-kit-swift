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
//  GraphQLRequestDirectivesTests.swift
//  ShopifyAcceleratedCheckoutsTests
//

@testable import ShopifyAcceleratedCheckouts
import XCTest

final class GraphQLRequestDirectivesTests: XCTestCase {
    // MARK: - InContextDirective Tests

    func testInContextDirectiveDefaultInitialization() {
        let directive = InContextDirective()

        XCTAssertEqual(directive.countryCode, CountryCode.US)
        XCTAssertEqual(directive.languageCode, LanguageCode.EN)
    }

    func testInContextDirectiveCustomInitialization() {
        let directive = InContextDirective(countryCode: CountryCode.CA, languageCode: LanguageCode.FR)

        XCTAssertEqual(directive.countryCode, CountryCode.CA)
        XCTAssertEqual(directive.languageCode, LanguageCode.FR)
    }

    func testInContextDirectivePartialInitialization() {
        // Test with only country code provided
        let directive1 = InContextDirective(countryCode: CountryCode.GB)
        XCTAssertEqual(directive1.countryCode, CountryCode.GB)
        XCTAssertEqual(directive1.languageCode, LanguageCode.EN) // default

        // Test with only language code provided
        let directive2 = InContextDirective(languageCode: LanguageCode.DE)
        XCTAssertEqual(directive2.countryCode, CountryCode.US) // default
        XCTAssertEqual(directive2.languageCode, LanguageCode.DE)
    }

    // MARK: - ToString Tests

    func testToStringWithDefaults() {
        let directive = InContextDirective()

        XCTAssertEqual(directive.toString, "@inContext(country: US, language: EN)")
    }

    func testToStringWithCustomValues() {
        let directive = InContextDirective(countryCode: CountryCode.CA, languageCode: LanguageCode.FR)

        XCTAssertEqual(directive.toString, "@inContext(country: CA, language: FR)")
    }

    func testToStringWithDifferentCountries() {
        let directives = [
            InContextDirective(countryCode: CountryCode.GB, languageCode: LanguageCode.EN),
            InContextDirective(countryCode: CountryCode.DE, languageCode: LanguageCode.DE),
            InContextDirective(countryCode: CountryCode.JP, languageCode: LanguageCode.JA),
            InContextDirective(countryCode: CountryCode.AU, languageCode: LanguageCode.EN)
        ]

        let expectedStrings = [
            "@inContext(country: GB, language: EN)",
            "@inContext(country: DE, language: DE)",
            "@inContext(country: JP, language: JA)",
            "@inContext(country: AU, language: EN)"
        ]

        for (directive, expected) in zip(directives, expectedStrings) {
            XCTAssertEqual(directive.toString, expected)
        }
    }

    func testToStringFormat() {
        let directive = InContextDirective(countryCode: CountryCode.IT, languageCode: LanguageCode.IT)
        let toStringResult = directive.toString

        // Verify the string starts with @inContext
        XCTAssertTrue(toStringResult.hasPrefix("@inContext("))

        // Verify it ends with a closing parenthesis
        XCTAssertTrue(toStringResult.hasSuffix(")"))

        // Verify it contains both country and language
        XCTAssertTrue(toStringResult.contains("country: IT"))
        XCTAssertTrue(toStringResult.contains("language: IT"))

        // Verify they are separated by comma and space
        XCTAssertTrue(toStringResult.contains("country: IT, language: IT"))
    }

    // MARK: - WithContextDirective Tests

    func testWithContextDirectiveAddsToQueryOperation() {
        let operation = GraphQLRequest(
            query: "query GetCart { cart(id: $id) { id } }",
            responseType: StorefrontAPI.CartQueryResponse.self
        )
        let context = InContextDirective(countryCode: CountryCode.CA, languageCode: LanguageCode.FR)

        let operationWithDirective = operation.withContextDirective(context)

        // Verify the directive string is properly formatted
        XCTAssertEqual(context.toString, "@inContext(country: CA, language: FR)")

        // Verify the directive is added to the query
        XCTAssertTrue(operationWithDirective.query.contains(context.toString))
        XCTAssertTrue(operationWithDirective.query.contains("query GetCart"))
        XCTAssertTrue(operationWithDirective.query.contains("cart(id: $id)"))
    }

    func testWithContextDirectiveAddsToMutationOperation() {
        let operation = GraphQLRequest(
            query: "mutation CartCreate($input: CartInput!) { cartCreate(input: $input) { cart { id } } }",
            responseType: StorefrontAPI.CartCreateResponse.self
        )
        let context = InContextDirective(countryCode: CountryCode.GB, languageCode: LanguageCode.EN)

        let operationWithDirective = operation.withContextDirective(context)

        // Verify the directive string matches expected format
        XCTAssertEqual(context.toString, "@inContext(country: GB, language: EN)")

        // Verify the directive is added to the mutation
        XCTAssertTrue(operationWithDirective.query.contains(context.toString))
        XCTAssertTrue(operationWithDirective.query.contains("mutation CartCreate"))
        XCTAssertTrue(operationWithDirective.query.contains("cartCreate(input: $input)"))
    }

    func testWithContextDirectiveWithComplexQuery() {
        let operation = GraphQLRequest(
            query: """
            query GetCartWithOptions($id: ID!, $first: Int) {
                cart(id: $id) {
                    id
                    lines(first: $first) {
                        edges {
                            node {
                                id
                            }
                        }
                    }
                }
            }
            """,
            responseType: StorefrontAPI.CartQueryResponse.self
        )
        let context = InContextDirective(countryCode: CountryCode.AU, languageCode: LanguageCode.EN)

        let operationWithDirective = operation.withContextDirective(context)

        XCTAssertTrue(operationWithDirective.query.contains("@inContext(country: AU, language: EN)"))
        XCTAssertTrue(operationWithDirective.query.contains("query GetCartWithOptions"))
        // Verify the directive is added to the operation line, not nested within
        let lines = operationWithDirective.query.components(separatedBy: CharacterSet.newlines)
        let operationLine = lines.first { $0.trimmingCharacters(in: CharacterSet.whitespaces).hasPrefix("query") }
        XCTAssertNotNil(operationLine)
        XCTAssertTrue(operationLine?.contains("@inContext") ?? false)
    }

    func testWithContextDirectiveWithQueryParameters() {
        let operation = GraphQLRequest(
            query: "query GetProducts($first: Int!, $sortKey: ProductSortKeys) { products(first: $first, sortKey: $sortKey) { edges { node { id } } } }",
            responseType: StorefrontAPI.ProductsQueryResponse.self
        )
        let context = InContextDirective(countryCode: CountryCode.DE, languageCode: LanguageCode.DE)

        let operationWithDirective = operation.withContextDirective(context)

        XCTAssertTrue(operationWithDirective.query.contains("@inContext(country: DE, language: DE)"))
        XCTAssertTrue(operationWithDirective.query.contains("query GetProducts($first: Int!, $sortKey: ProductSortKeys)"))
    }

    func testWithContextDirectivePreservesVariables() {
        let variables: [String: Any] = ["id": "test123", "first": 10]
        let operation = GraphQLRequest(
            query: "query GetCart($id: ID!, $first: Int) { cart(id: $id) { id } }",
            responseType: StorefrontAPI.CartQueryResponse.self,
            variables: variables
        )
        let context = InContextDirective(countryCode: CountryCode.JP, languageCode: LanguageCode.JA)

        let operationWithDirective = operation.withContextDirective(context)

        XCTAssertEqual(operationWithDirective.variables["id"] as? String, "test123")
        XCTAssertEqual(operationWithDirective.variables["first"] as? Int, 10)
        XCTAssertTrue(operationWithDirective.responseType == StorefrontAPI.CartQueryResponse.self)
    }

    // MARK: - Minify Tests

    func testMinifyRemovesNewlines() {
        let operation = GraphQLRequest(
            query: """
            query GetCart {
                cart(id: $id) {
                    id
                    lines {
                        id
                    }
                }
            }
            """,
            responseType: StorefrontAPI.CartQueryResponse.self
        )

        let minifiedOperation = operation.minify()

        XCTAssertFalse(minifiedOperation.query.contains("\n"))
        XCTAssertTrue(minifiedOperation.query.contains("query GetCart"))
        XCTAssertTrue(minifiedOperation.query.contains("cart(id: $id)"))
        XCTAssertTrue(minifiedOperation.query.contains("{ id }"))
    }

    func testMinifyRemovesComments() {
        let operation = GraphQLRequest(
            query: """
            query GetCart {
                # This is a comment
                cart(id: $id) {
                    id
                    # Yet another comment
                    lines {
                        id
                    }
                }
            }
            """,
            responseType: StorefrontAPI.CartQueryResponse.self
        )

        let minifiedOperation = operation.minify()

        // Should remove full-line comments but preserve inline content
        XCTAssertFalse(minifiedOperation.query.contains("# This is a comment"))
        XCTAssertFalse(minifiedOperation.query.contains("# Yet another comment"))
        XCTAssertTrue(minifiedOperation.query.contains("query GetCart"))
        XCTAssertTrue(minifiedOperation.query.contains("cart(id: $id)"))
        XCTAssertTrue(minifiedOperation.query.contains("id"))
    }

    func testMinifyNormalizesWhitespace() {
        let operation = GraphQLRequest(
            query: "query GetCart    {     cart(id: $id)   {    id     }   }",
            responseType: StorefrontAPI.CartQueryResponse.self
        )

        let minifiedOperation = operation.minify()

        // Should have single spaces between tokens
        XCTAssertTrue(minifiedOperation.query.contains("query GetCart {"))
        XCTAssertTrue(minifiedOperation.query.contains("cart(id: $id) {"))
        XCTAssertFalse(minifiedOperation.query.contains("    "))
        XCTAssertFalse(minifiedOperation.query.contains("   "))
    }

    func testMinifyPreservesVariables() {
        let variables: [String: Any] = ["id": "test123", "active": true]
        let operation = GraphQLRequest(
            query: """
            query GetCart {
                cart(id: $id) {
                    id
                }
            }
            """,
            responseType: StorefrontAPI.CartQueryResponse.self,
            variables: variables
        )

        let minifiedOperation = operation.minify()

        XCTAssertEqual(minifiedOperation.variables["id"] as? String, "test123")
        XCTAssertEqual(minifiedOperation.variables["active"] as? Bool, true)
        XCTAssertTrue(minifiedOperation.responseType == StorefrontAPI.CartQueryResponse.self)
    }

    func testMinifyHandlesEmptyQuery() {
        let operation = GraphQLRequest(
            query: "",
            responseType: StorefrontAPI.CartQueryResponse.self
        )

        let minifiedOperation = operation.minify()

        XCTAssertEqual(minifiedOperation.query, "")
    }

    // MARK: - Combined Operations Tests

    func testWithContextDirectiveAndMinifyTogether() {
        let operation = GraphQLRequest(
            query: """
            query GetCart {
                # Get the cart
                cart(id: $id) {
                    id
                    lines {
                        id
                    }
                }
            }
            """,
            responseType: StorefrontAPI.CartQueryResponse.self,
            variables: ["id": "test123"]
        )
        let context = InContextDirective(countryCode: CountryCode.FR, languageCode: LanguageCode.FR)

        let transformedOperation = operation
            .withContextDirective(context)
            .minify()

        XCTAssertTrue(transformedOperation.query.contains("@inContext(country: FR, language: FR)"))
        XCTAssertFalse(transformedOperation.query.contains("\n"))
        XCTAssertFalse(transformedOperation.query.contains("# Get the cart"))
        XCTAssertTrue(transformedOperation.query.contains("query GetCart"))
        XCTAssertEqual(transformedOperation.variables["id"] as? String, "test123")
    }

    func testMinifyAndWithContextDirectiveTogether() {
        let operation = GraphQLRequest(
            query: """
            query GetCart {
                # Get the cart
                cart(id: $id) {
                    id
                    lines {
                        id
                    }
                }
            }
            """,
            responseType: StorefrontAPI.CartQueryResponse.self,
            variables: ["id": "test123"]
        )
        let context = InContextDirective(countryCode: CountryCode.IT, languageCode: LanguageCode.IT)

        let transformedOperation = operation
            .minify()
            .withContextDirective(context)

        XCTAssertTrue(transformedOperation.query.contains("@inContext(country: IT, language: IT)"))
        XCTAssertFalse(transformedOperation.query.contains("\n"))
        XCTAssertFalse(transformedOperation.query.contains("# Get the cart"))
        XCTAssertTrue(transformedOperation.query.contains("query GetCart"))
        XCTAssertEqual(transformedOperation.variables["id"] as? String, "test123")
    }
}
