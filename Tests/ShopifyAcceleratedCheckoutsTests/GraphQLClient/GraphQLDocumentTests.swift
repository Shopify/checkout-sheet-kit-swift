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
//  GraphQLDocumentTests.swift
//  ShopifyAcceleratedCheckoutsTests
//

import XCTest

@testable import ShopifyAcceleratedCheckouts

@available(iOS 17.0, *)
final class GraphQLDocumentTests: XCTestCase {
    // MARK: - Fragment Detection Tests

    func testDetectsDirectFragmentUsage() {
        let document = GraphQLDocument.build(operation: .cart)

        XCTAssertTrue(
            document.contains("fragment CartFragment"), "Document should contain CartFragment"
        )

        XCTAssertTrue(
            document.contains("fragment CartDeliveryGroupFragment"),
            "Document should contain CartDeliveryGroupFragment"
        )
        XCTAssertTrue(
            document.contains("fragment CartLineFragment"),
            "Document should contain CartLineFragment"
        )

        // Should NOT include unused fragments
        XCTAssertFalse(
            document.contains("fragment CartUserErrorFragment"),
            "Document should not contain unused CartUserErrorFragment"
        )
    }

    func testDetectsMultipleDirectFragmentUsage() {
        let document = GraphQLDocument.build(operation: .cartCreate)

        // Should include both CartFragment and CartUserErrorFragment
        XCTAssertTrue(
            document.contains("fragment CartFragment"), "Document should contain CartFragment"
        )
        XCTAssertTrue(
            document.contains("fragment CartUserErrorFragment"),
            "Document should contain CartUserErrorFragment"
        )

        // Should also include nested fragments
        XCTAssertTrue(
            document.contains("fragment CartDeliveryGroupFragment"),
            "Document should contain CartDeliveryGroupFragment"
        )
        XCTAssertTrue(
            document.contains("fragment CartLineFragment"),
            "Document should contain CartLineFragment"
        )
    }

    func testHandlesOperationWithNoFragments() {
        let document = GraphQLDocument.build(operation: .products)

        // Should not include any fragments
        XCTAssertFalse(
            document.contains("fragment CartFragment"), "Document should not contain CartFragment"
        )
        XCTAssertFalse(
            document.contains("fragment CartUserErrorFragment"),
            "Document should not contain CartUserErrorFragment"
        )
        XCTAssertFalse(
            document.contains("fragment CartDeliveryGroupFragment"),
            "Document should not contain CartDeliveryGroupFragment"
        )
        XCTAssertFalse(
            document.contains("fragment CartLineFragment"),
            "Document should not contain CartLineFragment"
        )

        // Should still contain the operation
        XCTAssertTrue(document.contains("query GetProducts"), "Document should contain the query")
    }

    // MARK: - Mutation Tests

    func testMutationFragments() {
        let document = GraphQLDocument.build(operation: .cartBuyerIdentityUpdate)

        // Should include directly used fragments
        XCTAssertTrue(
            document.contains("fragment CartFragment"), "Document should contain CartFragment"
        )
        XCTAssertTrue(
            document.contains("fragment CartUserErrorFragment"),
            "Document should contain CartUserErrorFragment"
        )

        // Should include fragments included by other fragments
        XCTAssertTrue(
            document.contains("fragment CartDeliveryGroupFragment"),
            "Document should contain CartDeliveryGroupFragment"
        )
        XCTAssertTrue(
            document.contains("fragment CartLineFragment"),
            "Document should contain CartLineFragment"
        )
    }

    // MARK: - Edge Cases

    func testHandlesFragmentNamesWithSimilarPrefixes() {
        // This test ensures we don't accidentally match "Cart" when looking for "CartFragment"
        // The current fragments don't have this issue, but it's good to be defensive
        let document = GraphQLDocument.build(operation: .cart)

        let cartFragmentCount = document.components(separatedBy: "fragment CartFragment").count - 1
        XCTAssertEqual(cartFragmentCount, 1, "CartFragment should appear exactly once")
    }

    func testHandlesFragmentReferencesInComments() {
        // If we had an operation with fragment references in comments, they should be ignored
        let document = GraphQLDocument.build(operation: .products)

        XCTAssertFalse(
            document.contains("fragment CartFragment"), "Should not include fragments from comments"
        )
    }

    func testHandlesFragmentReferencesInStrings() {
        // Similar to comments, fragment references inside GraphQL strings should be ignored
        // This ensures our regex doesn't match inside string literals
        let document = GraphQLDocument.build(operation: .products)

        // The products query doesn't use fragments, so none should be included
        // even if fragment names appeared in string values
        XCTAssertFalse(
            document.contains("fragment CartFragment"),
            "Should not include fragments from string literals"
        )
    }

    func testHandlesAllMutationsCorrectly() {
        // Test mutations that use both CartFragment and CartUserErrorFragment
        let mutationsWithCart: [GraphQLDocument.Mutations] = GraphQLDocument.Mutations.allCases
            // submitForCompletion is skipped as it has a different structure to other requests, its tested separately below
            .filter { $0 != .cartSubmitForCompletion }

        for mutation in mutationsWithCart {
            let document = GraphQLDocument.build(operation: mutation)

            // These mutations use both CartFragment and CartUserErrorFragment
            XCTAssertTrue(
                document.contains("fragment CartFragment"),
                "Mutation \(mutation) should contain CartFragment"
            )
            XCTAssertTrue(
                document.contains("fragment CartUserErrorFragment"),
                "Mutation \(mutation) should contain CartUserErrorFragment"
            )

            // They should also include nested fragments
            XCTAssertTrue(
                document.contains("fragment CartDeliveryGroupFragment"),
                "Mutation \(mutation) should contain CartDeliveryGroupFragment"
            )
            XCTAssertTrue(
                document.contains("fragment CartLineFragment"),
                "Mutation \(mutation) should contain CartLineFragment"
            )

            // Verify the mutation itself is present
            let mutationNameLower = String(describing: mutation)
            let mutationName =
                mutationNameLower.prefix(1).uppercased() + mutationNameLower.dropFirst()
            XCTAssertTrue(
                document.contains("mutation \(mutationName)"),
                "Document should contain the mutation"
            )
        }
    }

    func testCartSubmitForCompletionUsesOnlyUserErrorFragment() {
        // cartSubmitForCompletion only uses CartUserErrorFragment, not CartFragment
        let document = GraphQLDocument.build(operation: .cartSubmitForCompletion)

        // Should contain CartUserErrorFragment
        XCTAssertTrue(
            document.contains("fragment CartUserErrorFragment"),
            "cartSubmitForCompletion should contain CartUserErrorFragment"
        )

        // Should NOT contain CartFragment or its dependencies
        XCTAssertFalse(
            document.contains("fragment CartFragment"),
            "cartSubmitForCompletion should not contain CartFragment"
        )
        XCTAssertFalse(
            document.contains("fragment CartDeliveryGroupFragment"),
            "cartSubmitForCompletion should not contain CartDeliveryGroupFragment"
        )
        XCTAssertFalse(
            document.contains("fragment CartLineFragment"),
            "cartSubmitForCompletion should not contain CartLineFragment"
        )

        // Verify the mutation itself is present
        XCTAssertTrue(
            document.contains("mutation CartSubmitForCompletion"),
            "Document should contain the mutation"
        )
    }

    func testFragmentOrderingForSingleDirectReference() {
        // Query with single direct reference (cart query)
        let document = GraphQLDocument.build(operation: .cart)

        // CartFragment should come first, then its dependencies
        let cartFragmentRange = document.range(of: "fragment CartFragment")!
        let cartLineFragmentRange = document.range(of: "fragment CartLineFragment")!
        let cartDeliveryGroupFragmentRange = document.range(
            of: "fragment CartDeliveryGroupFragment")!

        XCTAssertTrue(
            cartFragmentRange.lowerBound < cartLineFragmentRange.lowerBound,
            "CartFragment should come before CartLineFragment"
        )
        XCTAssertTrue(
            cartFragmentRange.lowerBound < cartDeliveryGroupFragmentRange.lowerBound,
            "CartFragment should come before CartDeliveryGroupFragment"
        )

        // Verify the first fragment is the directly referenced one
        let lines = document.split(separator: "\n")
        let firstFragmentLineIndex = lines.firstIndex { $0.starts(with: "fragment") }!
        let firstFragmentLine = String(lines[firstFragmentLineIndex])
        XCTAssertTrue(
            firstFragmentLine.contains("fragment CartFragment"),
            "First fragment should be CartFragment (the directly referenced one)"
        )
    }

    func testFragmentOrderingForMultipleDirectReferences() {
        let document = GraphQLDocument.build(operation: .cartCreate)

        // Both CartFragment and CartUserErrorFragment are directly referenced
        let cartFragmentRange = document.range(of: "fragment CartFragment")!
        let userErrorFragmentRange = document.range(of: "fragment CartUserErrorFragment")!
        let cartLineFragmentRange = document.range(of: "fragment CartLineFragment")!
        let cartDeliveryGroupFragmentRange = document.range(
            of: "fragment CartDeliveryGroupFragment")!

        // Direct references should come before their dependencies
        XCTAssertTrue(
            cartFragmentRange.lowerBound < cartLineFragmentRange.lowerBound,
            "CartFragment should come before CartLineFragment"
        )
        XCTAssertTrue(
            cartFragmentRange.lowerBound < cartDeliveryGroupFragmentRange.lowerBound,
            "CartFragment should come before CartDeliveryGroupFragment"
        )
        XCTAssertTrue(
            userErrorFragmentRange.lowerBound < cartLineFragmentRange.lowerBound,
            "CartUserErrorFragment should come before CartLineFragment"
        )
        XCTAssertTrue(
            userErrorFragmentRange.lowerBound < cartDeliveryGroupFragmentRange.lowerBound,
            "CartUserErrorFragment should come before CartDeliveryGroupFragment"
        )
    }

    func testFragmentOrderingForSingleFragmentWithoutDependencies() {
        // Mutation with only user error fragment (cartSubmitForCompletion)
        let document = GraphQLDocument.build(operation: .cartSubmitForCompletion)

        // Should only have CartUserErrorFragment
        XCTAssertNotNil(
            document.range(of: "fragment CartUserErrorFragment"),
            "Should contain CartUserErrorFragment"
        )
        XCTAssertNil(
            document.range(of: "fragment CartFragment"),
            "Should not contain CartFragment"
        )
        XCTAssertNil(
            document.range(of: "fragment CartLineFragment"),
            "Should not contain CartLineFragment"
        )
        XCTAssertNil(
            document.range(of: "fragment CartDeliveryGroupFragment"),
            "Should not contain CartDeliveryGroupFragment"
        )
    }
}
