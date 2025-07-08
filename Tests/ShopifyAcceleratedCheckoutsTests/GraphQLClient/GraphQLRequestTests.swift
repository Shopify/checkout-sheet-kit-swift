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
//  GraphQLRequestTests.swift
//  ShopifyAcceleratedCheckoutsTests
//

@testable import ShopifyAcceleratedCheckouts
import XCTest

final class GraphQLRequestTests: XCTestCase {
    // MARK: - Test Response Types

    struct TestResponse: Codable {
        let success: Bool
    }

    // MARK: - Initialization Tests

    func testInitWithDocumentString() {
        // Given
        let query = "query { test }"

        // When
        let operation = GraphQLRequest(
            query: query,
            responseType: TestResponse.self
        )

        // Then
        XCTAssertEqual(operation.query, query)
        XCTAssertTrue(operation.responseType == TestResponse.self)
    }

    func testInitWithQueryEnum() {
        // Given
        let queryEnum = GraphQLDocument.Queries.cart

        // When
        let operation = GraphQLRequest(
            operation: queryEnum,
            responseType: StorefrontAPI.CartQueryResponse.self
        )

        // Then
        XCTAssertFalse(operation.query.isEmpty)
        XCTAssertTrue(operation.responseType == StorefrontAPI.CartQueryResponse.self)
        // Verify it contains the expected query structure
        XCTAssertTrue(operation.query.contains("query GetCart("))
        XCTAssertTrue(operation.query.contains("cart("))
    }

    func testInitWithMutationEnum() {
        // Given
        let mutation = GraphQLDocument.Mutations.cartCreate

        // When
        let operation = GraphQLRequest(
            operation: mutation,
            responseType: StorefrontAPI.CartCreateResponse.self
        )

        // Then
        XCTAssertFalse(operation.query.isEmpty)
        XCTAssertTrue(operation.responseType == StorefrontAPI.CartCreateResponse.self)
        // Verify it contains the expected mutation structure
        XCTAssertTrue(operation.query.contains("mutation CartCreate("))
        XCTAssertTrue(operation.query.contains("cartCreate("))
    }

    // MARK: - Pre-defined Operations Tests

    func testCartCreateOperation() {
        // When
        let operation = Operations.cartCreate()

        // Then
        XCTAssertTrue(operation.responseType == StorefrontAPI.CartCreateResponse.self)
        XCTAssertTrue(operation.query.contains("mutation CartCreate("))
        XCTAssertTrue(operation.query.contains("cartCreate("))
    }

    func testCartBuyerIdentityUpdateOperation() {
        // When
        let operation = Operations.cartBuyerIdentityUpdate()

        // Then
        XCTAssertTrue(operation.responseType == StorefrontAPI.CartBuyerIdentityUpdateResponse.self)
        XCTAssertTrue(operation.query.contains("mutation CartBuyerIdentityUpdate("))
        XCTAssertTrue(operation.query.contains("cartBuyerIdentityUpdate("))
    }

    func testCartDeliveryAddressesAddOperation() {
        // When
        let operation = Operations.cartDeliveryAddressesAdd()

        // Then
        XCTAssertTrue(operation.responseType == StorefrontAPI.CartDeliveryAddressesAddResponse.self)
        XCTAssertTrue(operation.query.contains("mutation CartDeliveryAddressesAdd("))
        XCTAssertTrue(operation.query.contains("cartDeliveryAddressesAdd("))
    }

    func testCartSelectedDeliveryOptionsUpdateOperation() {
        // When
        let operation = Operations.cartSelectedDeliveryOptionsUpdate()

        // Then
        XCTAssertTrue(operation.responseType == StorefrontAPI.CartSelectedDeliveryOptionsUpdateResponse.self)
        XCTAssertTrue(operation.query.contains("mutation CartSelectedDeliveryOptionsUpdate("))
        XCTAssertTrue(operation.query.contains("cartSelectedDeliveryOptionsUpdate("))
    }

    func testCartPaymentUpdateOperation() {
        // When
        let operation = Operations.cartPaymentUpdate()

        // Then
        XCTAssertTrue(operation.responseType == StorefrontAPI.CartPaymentUpdateResponse.self)
        XCTAssertTrue(operation.query.contains("mutation CartPaymentUpdate("))
        XCTAssertTrue(operation.query.contains("cartPaymentUpdate("))
    }

    func testCartRemovePersonalDataOperation() {
        // When
        let operation = Operations.cartRemovePersonalData()

        // Then
        XCTAssertTrue(operation.responseType == StorefrontAPI.CartRemovePersonalDataResponse.self)
        XCTAssertTrue(operation.query.contains("mutation CartRemovePersonalData("))
        XCTAssertTrue(operation.query.contains("cartRemovePersonalData("))
    }

    func testCartPrepareForCompletionOperation() {
        // When
        let operation = Operations.cartPrepareForCompletion()

        // Then
        XCTAssertTrue(operation.responseType == StorefrontAPI.CartPrepareForCompletionResponse.self)
        XCTAssertTrue(operation.query.contains("mutation CartPrepareForCompletion("))
        XCTAssertTrue(operation.query.contains("cartPrepareForCompletion("))
    }

    func testCartSubmitForCompletionOperation() {
        // When
        let operation = Operations.cartSubmitForCompletion()

        // Then
        XCTAssertTrue(operation.responseType == StorefrontAPI.CartSubmitForCompletionResponse.self)
        XCTAssertTrue(operation.query.contains("mutation CartSubmitForCompletion("))
        XCTAssertTrue(operation.query.contains("cartSubmitForCompletion("))
    }

    func testGetCartOperation() {
        // When
        let operation = Operations.getCart()

        // Then
        XCTAssertTrue(operation.responseType == StorefrontAPI.CartQueryResponse.self)
        XCTAssertTrue(operation.query.contains("query GetCart("))
        XCTAssertTrue(operation.query.contains("cart("))
    }

    func testGetProductsOperation() {
        // When
        let operation = Operations.getProducts()

        // Then
        XCTAssertTrue(operation.responseType == StorefrontAPI.ProductsQueryResponse.self)
        XCTAssertTrue(operation.query.contains("query GetProducts("))
        XCTAssertTrue(operation.query.contains("products("))
    }

    // MARK: - Type Safety Tests

    func testOperationTypeInference() {
        // This test verifies that the type system correctly infers types
        // When using pre-defined operations
        let cartCreateOp = Operations.cartCreate()
        let cartQueryOp = Operations.getCart()

        // These should be different types
        XCTAssertFalse(type(of: cartCreateOp) == type(of: cartQueryOp))
    }

    func testOperationDocumentConsistency() {
        // Test that operations consistently build their queries
        let operation1 = GraphQLRequest(
            operation: .cartCreate,
            responseType: StorefrontAPI.CartCreateResponse.self
        )
        let operation2 = Operations.cartCreate()

        // Both should produce the same query
        XCTAssertEqual(operation1.query, operation2.query)
    }

    // MARK: - Variables Tests

    func testOperationsWithVariables() {
        // Test that operations can accept variables
        let variables: [String: Any] = ["cartId": "test123", "input": ["name": "test"]]

        let cartOperation = Operations.getCart(variables: variables)
        XCTAssertEqual(cartOperation.variables["cartId"] as? String, "test123")

        let createOperation = Operations.cartCreate(variables: variables)
        let inputDict = createOperation.variables["input"] as? [String: Any]
        XCTAssertEqual(inputDict?["name"] as? String, "test")
    }

    func testOperationsWithEmptyVariables() {
        // Test that operations work with empty variables
        let operation = Operations.cartCreate()
        XCTAssertTrue(operation.variables.isEmpty)
    }

    // MARK: - Directive Tests

    func testWithContextDirective() {
        // Given
        let operation = GraphQLRequest(
            query: "query GetCart { cart(id: $id) { id } }",
            responseType: StorefrontAPI.CartQueryResponse.self
        )
        let context = InContextDirective(countryCode: CountryCode.CA, languageCode: LanguageCode.FR)

        // When
        let operationWithDirective = operation.withContextDirective(context)

        // Then
        XCTAssertTrue(operationWithDirective.query.contains("@inContext(country: CA, language: FR)"))
        XCTAssertTrue(operationWithDirective.query.contains("query GetCart"))
    }

    func testMinifyQuery() {
        // Given
        let operation = GraphQLRequest(
            query: """
            query GetCart {
                cart(id: $id) {
                    id
                    # This is a comment
                    lines {
                        id
                    }
                }
            }
            """,
            responseType: StorefrontAPI.CartQueryResponse.self
        )

        // When
        let minifiedOperation = operation.minify()

        // Then
        XCTAssertFalse(minifiedOperation.query.contains("\n"))
        XCTAssertFalse(minifiedOperation.query.contains("# This is a comment"))
        XCTAssertTrue(minifiedOperation.query.contains("query GetCart"))
        XCTAssertTrue(minifiedOperation.query.contains("cart(id: $id)"))
    }
}
