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
final class StorefrontAPIQueriesTests: XCTestCase {
    // MARK: - Mock URLProtocol for Network Mocking

    class MockURLProtocol: URLProtocol {
        static var mockResponseData: Data?
        static var mockError: Error?
        static var mockStatusCode: Int = 200
        static var capturedRequest: URLRequest?
        static var capturedRequestBody: Data?

        override class func canInit(with _: URLRequest) -> Bool {
            return true
        }

        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }

        override func startLoading() {
            Self.capturedRequest = request

            // Capture the request body properly
            if let bodyStream = request.httpBodyStream {
                bodyStream.open()
                defer { bodyStream.close() }

                var data = Data()
                let bufferSize = 1024
                let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
                defer { buffer.deallocate() }

                while bodyStream.hasBytesAvailable {
                    let bytesRead = bodyStream.read(buffer, maxLength: bufferSize)
                    if bytesRead > 0 {
                        data.append(buffer, count: bytesRead)
                    } else {
                        break
                    }
                }
                Self.capturedRequestBody = data
            } else {
                Self.capturedRequestBody = request.httpBody
            }

            if let error = Self.mockError {
                client?.urlProtocol(self, didFailWithError: error)
            } else if let data = Self.mockResponseData {
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: Self.mockStatusCode,
                    httpVersion: nil,
                    headerFields: nil
                )!
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: data)
            }
            client?.urlProtocolDidFinishLoading(self)
        }

        override func stopLoading() {}

        static func reset() {
            mockResponseData = nil
            mockError = nil
            mockStatusCode = 200
            capturedRequest = nil
            capturedRequestBody = nil
        }
    }

    // MARK: - Test Setup

    var storefrontAPI: StorefrontAPI!

    override func setUp() {
        super.setUp()

        // Register our mock protocol
        URLProtocol.registerClass(MockURLProtocol.self)

        // Create StorefrontAPI instance - it will use the default URLSession which will pick up our mock
        storefrontAPI = StorefrontAPI(
            shopDomain: "test.myshopify.com",
            storefrontAccessToken: "test-token",
            countryCode: CountryCode.US,
            languageCode: LanguageCode.EN
        )
    }

    override func tearDown() {
        URLProtocol.unregisterClass(MockURLProtocol.self)
        MockURLProtocol.reset()
        storefrontAPI = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    private func mockJSONResponse(_ json: String, statusCode: Int = 200) {
        MockURLProtocol.mockResponseData = json.data(using: .utf8)!
        MockURLProtocol.mockStatusCode = statusCode
    }

    private func mockErrorResponse(_ error: Error) {
        MockURLProtocol.mockError = error
    }

    // MARK: - Cart Query Tests with Real JSON

    func testCartQuerySuccessWithCompleteJSON() async throws {
        let json = """
        {
            "data": {
                "cart": {
                    "id": "gid://shopify/Cart/123",
                    "checkoutUrl": "https://test.myshopify.com/checkout/123",
                    "totalQuantity": 2,
                    "buyerIdentity": {
                        "email": "test@example.com"
                    },
                    "deliveryGroups": {
                        "nodes": [{
                            "id": "gid://shopify/CartDeliveryGroup/1",
                            "groupType": "ONE_TIME_PURCHASE",
                            "deliveryOptions": [],
                            "selectedDeliveryOption": null
                        }]
                    },
                    "delivery": null,
                    "lines": {
                        "nodes": [{
                            "id": "gid://shopify/CartLine/1",
                            "quantity": 2,
                            "merchandise": {
                                "id": "gid://shopify/ProductVariant/1",
                                "title": "Small",
                                "price": {"amount": "19.99", "currencyCode": "USD"},
                                "product": {
                                    "id": "gid://shopify/Product/1",
                                    "title": "T-Shirt",
                                    "vendor": "Test Vendor",
                                    "featuredImage": null,
                                    "variants": null
                                },
                                "requiresShipping": true
                            },
                            "cost": {
                                "totalAmount": {"amount": "39.98", "currencyCode": "USD"},
                                "subtotalAmount": {"amount": "39.98", "currencyCode": "USD"}
                            },
                            "discountAllocations": []
                        }]
                    },
                    "cost": {
                        "totalAmount": {"amount": "39.98", "currencyCode": "USD"},
                        "subtotalAmount": {"amount": "39.98", "currencyCode": "USD"},
                        "totalTaxAmount": null
                    },
                    "discountCodes": [],
                    "discountAllocations": []
                }
            }
        }
        """
        mockJSONResponse(json)

        let cart = try await storefrontAPI.cart(by: GraphQLScalars.ID("gid://shopify/Cart/123"))

        XCTAssertNotNil(cart)
        XCTAssertEqual(cart?.id.rawValue, "gid://shopify/Cart/123")
        XCTAssertEqual(cart?.totalQuantity, 2)
        XCTAssertEqual(cart?.buyerIdentity?.email, "test@example.com")
        XCTAssertEqual(cart?.lines.nodes.count, 1)
        XCTAssertEqual(cart?.lines.nodes.first?.quantity, 2)
        XCTAssertEqual(cart?.deliveryGroups.nodes.count, 1)
        XCTAssertEqual(cart?.cost.totalAmount.amount, Decimal(string: "39.98")!)
    }

    func testCartQueryNotFound() async throws {
        let json = """
        {
            "data": {
                "cart": null
            }
        }
        """
        mockJSONResponse(json)

        let cart = try await storefrontAPI.cart(by: GraphQLScalars.ID("gid://shopify/Cart/nonexistent"))

        XCTAssertNil(cart)
    }

    func testCartQueryWithMinimalJSON() async throws {
        let json = """
        {
            "data": {
                "cart": {
                    "id": "gid://shopify/Cart/minimal",
                    "checkoutUrl": "https://test.myshopify.com/checkout/minimal",
                    "totalQuantity": 0,
                    "buyerIdentity": null,
                    "deliveryGroups": {"nodes": []},
                    "delivery": null,
                    "lines": {"nodes": []},
                    "cost": {
                        "totalAmount": {"amount": "0.00", "currencyCode": "USD"},
                        "subtotalAmount": null,
                        "totalTaxAmount": null
                    },
                    "discountCodes": [],
                    "discountAllocations": []
                }
            }
        }
        """
        mockJSONResponse(json)

        let cart = try await storefrontAPI.cart(by: GraphQLScalars.ID("gid://shopify/Cart/minimal"))

        XCTAssertNotNil(cart)
        XCTAssertEqual(cart?.totalQuantity, 0)
        XCTAssertNil(cart?.buyerIdentity)
        XCTAssertTrue(cart?.lines.nodes.isEmpty ?? false)
    }

    func testCartQueryWithMalformedJSON() async {
        let json = """
        {
            "data": {
                "cart": "this should be an object not a string"
            }
        }
        """
        mockJSONResponse(json)

        do {
            _ = try await storefrontAPI.cart(by: GraphQLScalars.ID("gid://shopify/Cart/123"))
            XCTFail("Should throw decoding error")
        } catch {
            // Expected error
            XCTAssertTrue(error is DecodingError || (error as? GraphQLError) != nil)
        }
    }

    func testCartQueryWithMissingRequiredFields() async {
        let json = """
        {
            "data": {
                "cart": {
                    "id": "gid://shopify/Cart/123",
                    "totalQuantity": 1
                }
            }
        }
        """
        mockJSONResponse(json)

        do {
            _ = try await storefrontAPI.cart(by: GraphQLScalars.ID("gid://shopify/Cart/123"))
            XCTFail("Should throw decoding error for missing required fields")
        } catch {
            // Expected error
            XCTAssertTrue(error is DecodingError || (error as? GraphQLError) != nil)
        }
    }

    func testCartQueryWithTypeMismatch() async {
        let json = """
        {
            "data": {
                "cart": {
                    "id": "gid://shopify/Cart/123",
                    "checkoutUrl": "https://test.myshopify.com/checkout/123",
                    "totalQuantity": "should-be-number",
                    "buyerIdentity": null,
                    "deliveryGroups": {"nodes": []},
                    "delivery": null,
                    "lines": {"nodes": []},
                    "cost": {
                        "totalAmount": {"amount": "0.00", "currencyCode": "USD"},
                        "subtotalAmount": null,
                        "totalTaxAmount": null
                    }
                }
            }
        }
        """
        mockJSONResponse(json)

        do {
            _ = try await storefrontAPI.cart(by: GraphQLScalars.ID("gid://shopify/Cart/123"))
            XCTFail("Should throw decoding error for type mismatch")
        } catch {
            // Expected error
            XCTAssertTrue(error is DecodingError || (error as? GraphQLError) != nil)
        }
    }

    func testCartQueryWithGraphQLErrors() async {
        let json = """
        {
            "data": null,
            "errors": [
                {
                    "message": "Cart not found",
                    "path": ["cart"],
                    "locations": [{"line": 2, "column": 3}]
                }
            ]
        }
        """
        mockJSONResponse(json)

        do {
            _ = try await storefrontAPI.cart(by: GraphQLScalars.ID("gid://shopify/Cart/123"))
            XCTFail("Should throw GraphQL error")
        } catch {
            guard case let .graphQLErrors(errors) = error as? GraphQLError else {
                XCTFail("Expected GraphQLError.graphQLErrors but got: \(error)")
                return
            }

            XCTAssertEqual(errors.first?.message, "Cart not found")
        }
    }

    func testCartQueryWithPartialDataAndErrors() async throws {
        let json = """
        {
            "data": {
                "cart": {
                    "id": "gid://shopify/Cart/123",
                    "checkoutUrl": "https://test.myshopify.com/checkout/123",
                    "totalQuantity": 1,
                    "buyerIdentity": null,
                    "deliveryGroups": {"nodes": []},
                    "delivery": null,
                    "lines": {"nodes": []},
                    "cost": {
                        "totalAmount": {"amount": "0.00", "currencyCode": "USD"},
                        "subtotalAmount": null,
                        "totalTaxAmount": null
                    },
                    "discountCodes": [],
                    "discountAllocations": []
                }
            },
            "errors": [
                {
                    "message": "Field 'someField' is deprecated",
                    "path": ["cart", "someField"]
                }
            ]
        }
        """
        mockJSONResponse(json)

        do {
            _ = try await storefrontAPI.cart(by: GraphQLScalars.ID("gid://shopify/Cart/123"))
            XCTFail("Should throw error when response contains errors")
        } catch {
            // Expected - GraphQLClient throws on any errors
            XCTAssertTrue(error is GraphQLError)
        }
    }

    // MARK: - Network Error Tests

    func testQueryWithNetworkError() async {
        mockErrorResponse(URLError(.notConnectedToInternet))

        do {
            _ = try await storefrontAPI.cart(by: GraphQLScalars.ID("gid://shopify/Cart/123"))
            XCTFail("Should throw network error")
        } catch {
            XCTAssertTrue(error is URLError)
        }
    }

    func testQueryWithTimeout() async {
        mockErrorResponse(URLError(.timedOut))

        do {
            _ = try await storefrontAPI.cart(by: GraphQLScalars.ID("gid://shopify/Cart/123"))
            XCTFail("Should throw timeout error")
        } catch {
            guard let urlError = error as? URLError else {
                XCTFail("Expected URLError but got: \(error)")
                return
            }

            XCTAssertEqual(urlError.code, .timedOut)
        }
    }

    func testQueryWithHTTPError() async {
        let json = """
        {
            "errors": [{"message": "Internal Server Error"}]
        }
        """
        mockJSONResponse(json, statusCode: 500)

        do {
            _ = try await storefrontAPI.cart(by: GraphQLScalars.ID("gid://shopify/Cart/123"))
            XCTFail("Should throw HTTP error")
        } catch {
            guard case let .httpError(statusCode, _) = error as? GraphQLError else {
                XCTFail("Expected GraphQLError.httpError but got: \(error)")
                return
            }

            XCTAssertEqual(statusCode, 500)
        }
    }

    // MARK: - Large Response Tests

    func testCartQueryWithLargeResponse() async throws {
        var lineNodes: [String] = []
        for i in 1 ... 100 {
            lineNodes.append("""
                {
                    "id": "gid://shopify/CartLine/\(i)",
                    "quantity": 1,
                    "merchandise": {
                        "id": "gid://shopify/ProductVariant/\(i)",
                        "title": "Variant \(i)",
                        "price": {"amount": "10.00", "currencyCode": "USD"},
                        "product": {
                            "id": "gid://shopify/Product/\(i)",
                            "title": "Product \(i)",
                            "vendor": "Vendor",
                            "featuredImage": null,
                            "variants": null
                        },
                        "requiresShipping": true
                    },
                    "cost": {
                        "totalAmount": {"amount": "10.00", "currencyCode": "USD"},
                        "subtotalAmount": {"amount": "10.00", "currencyCode": "USD"}
                    },
                    "discountAllocations": []
                }
            """)
        }

        let json = """
        {
            "data": {
                "cart": {
                    "id": "gid://shopify/Cart/large",
                    "checkoutUrl": "https://test.myshopify.com/checkout/large",
                    "totalQuantity": 100,
                    "buyerIdentity": null,
                    "deliveryGroups": {"nodes": []},
                    "delivery": null,
                    "lines": {
                        "nodes": [\(lineNodes.joined(separator: ","))]
                    },
                    "cost": {
                        "totalAmount": {"amount": "1000.00", "currencyCode": "USD"},
                        "subtotalAmount": {"amount": "1000.00", "currencyCode": "USD"},
                        "totalTaxAmount": null
                    },
                    "discountCodes": [],
                    "discountAllocations": []
                }
            }
        }
        """
        mockJSONResponse(json)

        let cart = try await storefrontAPI.cart(by: GraphQLScalars.ID("gid://shopify/Cart/large"))

        XCTAssertNotNil(cart)
        XCTAssertEqual(cart?.lines.nodes.count, 100)
        XCTAssertEqual(cart?.totalQuantity, 100)
        XCTAssertEqual(cart?.cost.totalAmount.amount, Decimal(string: "1000.00")!)
    }

    // MARK: - Request Validation Tests

    func testCartQuerySendsCorrectVariables() async throws {
        let json = """
        {"data": {"cart": null}}
        """
        mockJSONResponse(json)

        _ = try await storefrontAPI.cart(by: GraphQLScalars.ID("gid://shopify/Cart/test-123"))

        XCTAssertNotNil(MockURLProtocol.capturedRequest)

        // Wait a bit for the request to be fully captured
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        guard let body = MockURLProtocol.capturedRequestBody else {
            XCTFail("Expected request body to be captured")
            return
        }

        do {
            let jsonBody = try JSONSerialization.jsonObject(with: body) as? [String: Any]
            XCTAssertNotNil(jsonBody)

            let variables = jsonBody?["variables"] as? [String: Any]
            XCTAssertEqual(variables?["id"] as? String, "gid://shopify/Cart/test-123")
        } catch {
            XCTFail("Failed to parse request body: \(error)")
        }
    }
}
