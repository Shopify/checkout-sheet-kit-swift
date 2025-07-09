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

@testable import ShopifyAcceleratedCheckouts
import XCTest

@available(iOS 17.0, *)
final class GraphQLClientTests: XCTestCase {
    // MARK: - Helper Methods

    private func createTestClient(
        shopDomain: String = "test.myshopify.com",
        storefrontAccessToken: String? = "test-token",
        apiVersion: String = "2025-07",
        context: InContextDirective = InContextDirective()
    ) -> GraphQLClient {
        let url = URL(string: "https://\(shopDomain)/api/\(apiVersion)/graphql.json")!
        var headers: [String: String] = [:]

        if let token = storefrontAccessToken {
            headers["X-Shopify-Storefront-Access-Token"] = token
        }

        return GraphQLClient(
            url: url,
            headers: headers,
            context: context
        )
    }

    // MARK: - Initialization Tests

    func testInitializationWithValidDomain() {
        let client = createTestClient(
            shopDomain: "test.myshopify.com",
            storefrontAccessToken: "test-token",
            apiVersion: "2025-07"
        )

        XCTAssertNotNil(client)
        XCTAssertEqual(client.inContextDirective.countryCode, CountryCode.US)
        XCTAssertEqual(client.inContextDirective.languageCode, LanguageCode.EN)
    }

    func testInitializationWithContext() {
        let context = InContextDirective(countryCode: CountryCode.CA, languageCode: LanguageCode.FR)
        let client = createTestClient(
            shopDomain: "test.myshopify.com",
            context: context
        )

        XCTAssertEqual(client.inContextDirective.countryCode, CountryCode.CA)
        XCTAssertEqual(client.inContextDirective.languageCode, LanguageCode.FR)
    }

    func testInitializationWithDefaultApiVersion() {
        let client = createTestClient(
            shopDomain: "test.myshopify.com"
        )

        XCTAssertNotNil(client)
        // Default API version is 2025-07
    }

    func testInitializationWithCustomContext() {
        // Test with custom country code and language
        let context1 = InContextDirective(countryCode: CountryCode.GB, languageCode: LanguageCode.EN)
        let client1 = createTestClient(
            shopDomain: "test.myshopify.com",
            context: context1
        )

        XCTAssertEqual(client1.inContextDirective.countryCode, CountryCode.GB)
        XCTAssertEqual(client1.inContextDirective.languageCode, LanguageCode.EN)

        // Test with different values
        let context2 = InContextDirective(countryCode: CountryCode.DE, languageCode: LanguageCode.DE)
        let client2 = createTestClient(
            shopDomain: "test.myshopify.com",
            context: context2
        )

        XCTAssertEqual(client2.inContextDirective.countryCode, CountryCode.DE)
        XCTAssertEqual(client2.inContextDirective.languageCode, LanguageCode.DE)
    }

    // MARK: - Context Tests

    func testContextInitialization() {
        // Test default initialization
        let defaultContext = InContextDirective()
        XCTAssertEqual(defaultContext.countryCode, CountryCode.US)
        XCTAssertEqual(defaultContext.languageCode, LanguageCode.EN)

        // Test with custom values
        let context = InContextDirective(countryCode: CountryCode.CA, languageCode: LanguageCode.FR)
        XCTAssertEqual(context.countryCode, CountryCode.CA)
        XCTAssertEqual(context.languageCode, LanguageCode.FR)
    }

    // MARK: - GraphQL Request Integration Tests

    func testGraphQLRequestWithQuery() {
        // Test that GraphQLRequest works with query enum
        let operation = GraphQLRequest(
            operation: GraphQLDocument.Queries.cart,
            responseType: StorefrontAPI.CartQueryResponse.self
        )

        XCTAssertFalse(operation.query.isEmpty)
        XCTAssertTrue(operation.responseType == StorefrontAPI.CartQueryResponse.self)
    }

    func testGraphQLRequestWithMutation() {
        // Test that GraphQLRequest works with mutation enum
        let operation = GraphQLRequest(
            operation: GraphQLDocument.Mutations.cartCreate,
            responseType: StorefrontAPI.CartCreateResponse.self
        )

        XCTAssertFalse(operation.query.isEmpty)
        XCTAssertTrue(operation.responseType == StorefrontAPI.CartCreateResponse.self)
    }

    func testGraphQLRequestWithRawDocument() {
        struct TestResponse: Codable {
            let test: String
        }

        let operation = GraphQLRequest(
            query: "query Test { test }",
            responseType: TestResponse.self
        )

        XCTAssertEqual(operation.query, "query Test { test }")
        XCTAssertTrue(operation.responseType == TestResponse.self)
    }

    // MARK: - Pre-defined Operations Tests

    func testPreDefinedQueryOperations() {
        // Test cart query
        let cartOp = Operations.getCart()
        XCTAssertTrue(cartOp.responseType == StorefrontAPI.CartQueryResponse.self)
        XCTAssertFalse(cartOp.query.isEmpty)

        // Test products query
        let productsOp = Operations.getProducts()
        XCTAssertTrue(productsOp.responseType == StorefrontAPI.ProductsQueryResponse.self)
        XCTAssertFalse(productsOp.query.isEmpty)
    }

    func testPreDefinedMutationOperations() {
        // Test cart mutations
        let createOp = Operations.cartCreate()
        XCTAssertTrue(createOp.responseType == StorefrontAPI.CartCreateResponse.self)
        XCTAssertFalse(createOp.query.isEmpty)

        let updateBuyerOp = Operations.cartBuyerIdentityUpdate()
        XCTAssertTrue(updateBuyerOp.responseType == StorefrontAPI.CartBuyerIdentityUpdateResponse.self)

        let addAddressOp = Operations.cartDeliveryAddressesAdd()
        XCTAssertTrue(addAddressOp.responseType == StorefrontAPI.CartDeliveryAddressesAddResponse.self)

        let updateDeliveryOp = Operations.cartSelectedDeliveryOptionsUpdate()
        XCTAssertTrue(updateDeliveryOp.responseType == StorefrontAPI.CartSelectedDeliveryOptionsUpdateResponse.self)

        let paymentOp = Operations.cartPaymentUpdate()
        XCTAssertTrue(paymentOp.responseType == StorefrontAPI.CartPaymentUpdateResponse.self)

        let removeDataOp = Operations.cartRemovePersonalData()
        XCTAssertTrue(removeDataOp.responseType == StorefrontAPI.CartRemovePersonalDataResponse.self)

        let prepareOp = Operations.cartPrepareForCompletion()
        XCTAssertTrue(prepareOp.responseType == StorefrontAPI.CartPrepareForCompletionResponse.self)

        let submitOp = Operations.cartSubmitForCompletion()
        XCTAssertTrue(submitOp.responseType == StorefrontAPI.CartSubmitForCompletionResponse.self)
    }

    // MARK: - GraphQL Document Integration Tests

    func testGraphQLDocumentQueries() {
        // Verify that GraphQL queries are properly formatted
        let cartQuery = GraphQLDocument.build(operation: .cart)
        XCTAssertTrue(cartQuery.contains("query GetCart"))
        XCTAssertTrue(cartQuery.contains("cart(id: $id)"))

        let productsQuery = GraphQLDocument.build(operation: .products)
        XCTAssertTrue(productsQuery.contains("query GetProducts"))
        XCTAssertTrue(productsQuery.contains("products(first: $first)"))
    }

    func testGraphQLDocumentMutations() {
        // Verify that GraphQL mutations are properly formatted
        let createMutation = GraphQLDocument.build(operation: .cartCreate)
        XCTAssertTrue(createMutation.contains("mutation CartCreate"))
        XCTAssertTrue(createMutation.contains("cartCreate(input: $input)"))

        let updateMutation = GraphQLDocument.build(operation: .cartBuyerIdentityUpdate)
        XCTAssertTrue(updateMutation.contains("mutation CartBuyerIdentityUpdate"))
        XCTAssertTrue(updateMutation.contains("cartBuyerIdentityUpdate(cartId: $cartId"))
    }

    // MARK: - Client Configuration Tests

    func testClientWithDifferentConfigurations() {
        // Test with all parameters
        let fullClient = createTestClient(
            shopDomain: "shop.myshopify.com",
            storefrontAccessToken: "token123",
            apiVersion: "2025-01",
            context: InContextDirective(countryCode: CountryCode.AU, languageCode: LanguageCode.EN)
        )
        XCTAssertNotNil(fullClient)

        // Test with minimal parameters
        let minimalClient = createTestClient(
            shopDomain: "shop.myshopify.com"
        )
        XCTAssertNotNil(minimalClient)
    }

    // MARK: - Error Types Tests

    func testGraphQLErrorTypes() {
        // Test error descriptions
        let networkError = GraphQLError.networkError("Connection failed")
        XCTAssertEqual(networkError.errorDescription, "Network error: Connection failed")

        let httpError = GraphQLError.httpError(statusCode: 404, data: Data())
        XCTAssertTrue(httpError.errorDescription?.contains("HTTP error 404") ?? false)

        let invalidResponse = GraphQLError.invalidResponse
        XCTAssertEqual(invalidResponse.errorDescription, "Invalid response from server")

        // Test GraphQL response errors
        let responseError = GraphQLResponseError(
            message: "Field not found",
            path: ["user", "name"],
            locations: [GraphQLResponseError.Location(line: 2, column: 5)],
            extensions: nil
        )
        XCTAssertEqual(responseError.message, "Field not found")
        XCTAssertEqual(responseError.path, ["user", "name"])
        XCTAssertEqual(responseError.locations?.first?.line, 2)
        XCTAssertEqual(responseError.locations?.first?.column, 5)
    }

    // MARK: - Response Wrapper Types Tests

    func testResponseWrapperTypes() {
        // Verify response wrapper types exist and are properly defined
        // This ensures the types used in Operations are available

        // Query response types
        _ = StorefrontAPI.CartQueryResponse.self
        _ = StorefrontAPI.ProductsQueryResponse.self

        // Mutation response types
        _ = StorefrontAPI.CartCreateResponse.self
        _ = StorefrontAPI.CartBuyerIdentityUpdateResponse.self
        _ = StorefrontAPI.CartDeliveryAddressesAddResponse.self
        _ = StorefrontAPI.CartSelectedDeliveryOptionsUpdateResponse.self
        _ = StorefrontAPI.CartPaymentUpdateResponse.self
        _ = StorefrontAPI.CartRemovePersonalDataResponse.self
        _ = StorefrontAPI.CartPrepareForCompletionResponse.self
        _ = StorefrontAPI.CartSubmitForCompletionResponse.self

        // If we get here without compiler errors, the types exist
        XCTAssertTrue(true)
    }
}
