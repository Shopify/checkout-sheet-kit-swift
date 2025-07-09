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
final class StorefrontAPIMutationsTests: XCTestCase {
    // MARK: - Helper for Async Error Testing

    func XCTAssertThrowsErrorAsync(
        _ expression: @autoclosure () async throws -> some Any,
        _ errorHandler: (Error) -> Void,
        _ message: @autoclosure () -> String = "Expected error to be thrown",
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            _ = try await expression()
            XCTFail(message(), file: file, line: line)
        } catch {
            errorHandler(error)
        }
    }

    // Specific helper for GraphQLError enum cases
    func XCTAssertThrowsGraphQLError(
        _ expression: @autoclosure () async throws -> some Any,
        _ expectedErrorMatcher: (GraphQLError) -> Bool,
        _ errorDescription: String = "Expected specific GraphQLError",
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            _ = try await expression()
            XCTFail(errorDescription, file: file, line: line)
        } catch {
            guard let graphQLError = error as? GraphQLError else {
                XCTFail("Expected GraphQLError but got \(type(of: error))", file: file, line: line)
                return
            }
            XCTAssertTrue(expectedErrorMatcher(graphQLError), errorDescription, file: file, line: line)
        }
    }

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

        // Create StorefrontAPI instance
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

    // MARK: - Cart Create Tests

    func testCartCreateSuccessWithItems() async throws {
        let json = """
        {
            "data": {
                "cartCreate": {
                    "cart": {
                        "id": "gid://shopify/Cart/created-123",
                        "checkoutUrl": "https://test.myshopify.com/checkout/created-123",
                        "totalQuantity": 2,
                        "buyerIdentity": null,
                        "deliveryGroups": {"nodes": []},
                        "delivery": null,
                        "lines": {
                            "nodes": [{
                                "id": "gid://shopify/CartLine/1",
                                "quantity": 1,
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
                                    "totalAmount": {"amount": "19.99", "currencyCode": "USD"},
                                    "subtotalAmount": {"amount": "19.99", "currencyCode": "USD"}
                                },
                                "discountAllocations": []
                            }]
                        },
                        "cost": {
                            "totalAmount": {"amount": "19.99", "currencyCode": "USD"},
                            "subtotalAmount": {"amount": "19.99", "currencyCode": "USD"},
                            "totalTaxAmount": null
                        },
                        "discountCodes": [],
                        "discountAllocations": []
                    },
                    "userErrors": []
                }
            }
        }
        """
        mockJSONResponse(json)

        let cart = try await storefrontAPI.cartCreate(with: [GraphQLScalars.ID("gid://shopify/ProductVariant/1")])

        XCTAssertEqual(cart.id.rawValue, "gid://shopify/Cart/created-123")
        XCTAssertEqual(cart.totalQuantity, 2)
        XCTAssertEqual(cart.lines.nodes.count, 1)
    }

    func testCartCreateSuccessEmptyCart() async throws {
        let json = """
        {
            "data": {
                "cartCreate": {
                    "cart": {
                        "id": "gid://shopify/Cart/empty-123",
                        "checkoutUrl": "https://test.myshopify.com/checkout/empty-123",
                        "totalQuantity": 0,
                        "buyerIdentity": null,
                        "deliveryGroups": {"nodes": []},
                        "delivery": null,
                        "lines": {"nodes": []},
                        "cost": {
                            "totalAmount": {"amount": "0.00", "currencyCode": "USD"},
                            "subtotalAmount": {"amount": "0.00", "currencyCode": "USD"},
                            "totalTaxAmount": null
                        },
                        "discountCodes": [],
                        "discountAllocations": []
                    },
                    "userErrors": []
                }
            }
        }
        """
        mockJSONResponse(json)

        let cart = try await storefrontAPI.cartCreate()

        XCTAssertEqual(cart.id.rawValue, "gid://shopify/Cart/empty-123")
        XCTAssertEqual(cart.totalQuantity, 0)
        XCTAssertTrue(cart.lines.nodes.isEmpty)
    }

    func testCartCreateWithUserErrors() async {
        let json = """
        {
            "data": {
                "cartCreate": {
                    "cart": null,
                    "userErrors": [{
                        "field": ["lines"],
                        "message": "Product variant is out of stock",
                        "code": "NOT_ENOUGH_STOCK"
                    }]
                }
            }
        }
        """
        mockJSONResponse(json)

        await XCTAssertThrowsGraphQLError(
            try await storefrontAPI
                .cartCreate(with: [GraphQLScalars.ID("gid://shopify/ProductVariant/1")]),
            { if case .invalidResponse = $0 { return true } else { return false } },
            "Expected GraphQLError.invalidResponse to be thrown"
        )
    }

    func testCartCreateRequestValidation() async throws {
        let json = """
        {
            "data": {
                "cartCreate": {
                    "cart": {
                        "id": "gid://shopify/Cart/123",
                        "checkoutUrl": "https://test.myshopify.com/checkout/123",
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
                    },
                    "userErrors": []
                }
            }
        }
        """
        mockJSONResponse(json)

        let variantIds = [
            GraphQLScalars.ID("gid://shopify/ProductVariant/1"),
            GraphQLScalars.ID("gid://shopify/ProductVariant/2")
        ]
        _ = try await storefrontAPI.cartCreate(with: variantIds)

        XCTAssertNotNil(MockURLProtocol.capturedRequestBody)

        guard let body = MockURLProtocol.capturedRequestBody else {
            XCTFail("Expected request body to be captured")
            return
        }

        let jsonBody = try JSONSerialization.jsonObject(with: body) as? [String: Any]
        let variables = jsonBody?["variables"] as? [String: Any]
        let input = variables?["input"] as? [String: Any]
        let lines = input?["lines"] as? [[String: Any]]

        XCTAssertEqual(lines?.count, 2)
        XCTAssertEqual(lines?[0]["merchandiseId"] as? String, "gid://shopify/ProductVariant/1")
        XCTAssertEqual(lines?[1]["merchandiseId"] as? String, "gid://shopify/ProductVariant/2")
    }

    // MARK: - Buyer Identity Update Tests

    func testCartBuyerIdentityUpdateSuccess() async throws {
        let json = """
        {
            "data": {
                "cartBuyerIdentityUpdate": {
                    "cart": {
                        "id": "gid://shopify/Cart/123",
                        "checkoutUrl": "https://test.myshopify.com/checkout/123",
                        "totalQuantity": 1,
                        "buyerIdentity": {
                            "email": "test@example.com"
                        },
                        "deliveryGroups": {"nodes": []},
                        "delivery": null,
                        "lines": {"nodes": []},
                        "cost": {
                            "totalAmount": {"amount": "19.99", "currencyCode": "USD"},
                            "subtotalAmount": {"amount": "19.99", "currencyCode": "USD"},
                            "totalTaxAmount": null
                        },
                        "discountCodes": [],
                        "discountAllocations": []
                    },
                    "userErrors": []
                }
            }
        }
        """
        mockJSONResponse(json)

        let cart = try await storefrontAPI.cartBuyerIdentityUpdate(
            id: GraphQLScalars.ID("gid://shopify/Cart/123"),
            email: "test@example.com"
        )

        XCTAssertEqual(cart.buyerIdentity?.email, "test@example.com")
    }

    func testCartBuyerIdentityUpdateInvalidEmail() async {
        let json = """
        {
            "data": {
                "cartBuyerIdentityUpdate": {
                    "cart": null,
                    "userErrors": [{
                        "field": ["buyerIdentity", "email"],
                        "message": "Email is invalid",
                        "code": "INVALID"
                    }]
                }
            }
        }
        """
        mockJSONResponse(json)

        await XCTAssertThrowsGraphQLError(
            try await storefrontAPI.cartBuyerIdentityUpdate(
                id: GraphQLScalars.ID("gid://shopify/Cart/123"),
                email: "invalid-email"
            ),
            { if case .invalidResponse = $0 { return true } else { return false } },
            "Expected GraphQLError.invalidResponse to be thrown"
        )
    }

    // MARK: - Delivery Address Add Tests

    func testCartDeliveryAddressesAddSuccess() async throws {
        let json = """
        {
            "data": {
                "cartDeliveryAddressesAdd": {
                    "cart": {
                        "id": "gid://shopify/Cart/123",
                        "checkoutUrl": "https://test.myshopify.com/checkout/123",
                        "totalQuantity": 1,
                        "buyerIdentity": null,
                        "deliveryGroups": {
                            "nodes": [{
                                "id": "gid://shopify/CartDeliveryGroup/1",
                                "groupType": "ONE_TIME_PURCHASE",
                                "deliveryOptions": [{
                                    "handle": "standard",
                                    "title": "Standard Shipping",
                                    "code": "STANDARD",
                                    "deliveryMethodType": "SHIPPING",
                                    "description": "5-7 business days",
                                    "estimatedCost": {"amount": "5.00", "currencyCode": "USD"}
                                }],
                                "selectedDeliveryOption": null
                            }]
                        },
                        "delivery": {
                            "addresses": [{
                                "id": "gid://shopify/CartSelectableAddress/1",
                                "selected": true,
                                "address": {
                                    "address1": "123 Test St",
                                    "city": "Test City",
                                    "countryCode": "US",
                                    "provinceCode": "CA",
                                    "zip": "12345"
                                }
                            }]
                        },
                        "lines": {"nodes": []},
                        "cost": {
                            "totalAmount": {"amount": "24.99", "currencyCode": "USD"},
                            "subtotalAmount": {"amount": "19.99", "currencyCode": "USD"},
                            "totalTaxAmount": null
                        },
                        "discountCodes": [],
                        "discountAllocations": []
                    },
                    "userErrors": []
                }
            }
        }
        """
        mockJSONResponse(json)

        let address = StorefrontAPI.Address(
            address1: "123 Test St",
            city: "Test City",
            country: "US",
            province: "CA",
            zip: "12345"
        )

        let cart = try await storefrontAPI.cartDeliveryAddressesAdd(
            id: GraphQLScalars.ID("gid://shopify/Cart/123"),
            address: address
        )

        XCTAssertNotNil(cart.delivery)
        XCTAssertEqual(cart.delivery?.addresses.first?.address?.address1, "123 Test St")
        XCTAssertEqual(cart.deliveryGroups.nodes.first?.deliveryOptions.count, 1)
    }

    func testCartDeliveryAddressesAddValidationError() async {
        let json = """
        {
            "data": {
                "cartDeliveryAddressesAdd": {
                    "cart": null,
                    "userErrors": [{
                        "field": ["addresses", "0", "address", "zip"],
                        "message": "Zip code is invalid for country",
                        "code": "INVALID"
                    }]
                }
            }
        }
        """
        mockJSONResponse(json)

        let address = StorefrontAPI.Address(
            address1: "123 Test St",
            city: "Test City",
            country: "US",
            province: "CA",
            zip: "INVALID"
        )

        do {
            _ = try await storefrontAPI.cartDeliveryAddressesAdd(
                id: GraphQLScalars.ID("gid://shopify/Cart/123"),
                address: address,
                validate: true
            )
            XCTFail("Expected error to be thrown")
        } catch {
            // Verify error type
            XCTAssertTrue(
                error is GraphQLError,
                "Unexpected error type: \(type(of: error))"
            )

            guard case .invalidResponse = error as? GraphQLError else {
                XCTFail("Expected GraphQLError.invalidResponse but got: \(error)")
                return
            }
        }
    }

    func testCartDeliveryAddressesAddRequestValidation() async throws {
        let json = """
        {"data": {"cartDeliveryAddressesAdd": {"cart": null, "userErrors": []}}}
        """
        mockJSONResponse(json)

        let address = StorefrontAPI.Address(
            address1: "123 Test St",
            address2: "Apt 4B",
            city: "New York",
            country: "US",
            firstName: "John",
            lastName: "Doe",
            phone: "+1234567890",
            province: "NY",
            zip: "10001"
        )

        do {
            _ = try await storefrontAPI.cartDeliveryAddressesAdd(
                id: GraphQLScalars.ID("gid://shopify/Cart/123"),
                address: address,
                validate: true
            )
            XCTFail("Expected error to be thrown")
        } catch {
            // Verify error type
            XCTAssertTrue(
                error is GraphQLError,
                "Unexpected error type: \(type(of: error))"
            )

            guard case .invalidResponse = error as? GraphQLError else {
                XCTFail("Expected GraphQLError.invalidResponse but got: \(error)")
                return
            }
        }

        XCTAssertNotNil(MockURLProtocol.capturedRequestBody)

        guard let body = MockURLProtocol.capturedRequestBody else {
            XCTFail("Expected request body to be captured")
            return
        }

        let jsonBody = try JSONSerialization.jsonObject(with: body) as? [String: Any]
        let variables = jsonBody?["variables"] as? [String: Any]
        let addresses = variables?["addresses"] as? [[String: Any]]
        let firstAddress = addresses?.first
        let addressData = firstAddress?["address"] as? [String: Any]
        let deliveryAddress = addressData?["deliveryAddress"] as? [String: Any]

        XCTAssertEqual(deliveryAddress?["address1"] as? String, "123 Test St")
        XCTAssertEqual(deliveryAddress?["address2"] as? String, "Apt 4B")
        XCTAssertEqual(deliveryAddress?["city"] as? String, "New York")
        XCTAssertEqual(deliveryAddress?["countryCode"] as? String, "US")
        XCTAssertEqual(deliveryAddress?["provinceCode"] as? String, "NY")
        XCTAssertEqual(firstAddress?["validationStrategy"] as? String, "STRICT")
        XCTAssertEqual(firstAddress?["selected"] as? Bool, true)
    }

    // MARK: - Selected Delivery Options Update Tests

    func testCartSelectedDeliveryOptionsUpdateSuccess() async throws {
        let json = """
        {
            "data": {
                "cartSelectedDeliveryOptionsUpdate": {
                    "cart": {
                        "id": "gid://shopify/Cart/123",
                        "checkoutUrl": "https://test.myshopify.com/checkout/123",
                        "totalQuantity": 1,
                        "buyerIdentity": null,
                        "deliveryGroups": {
                            "nodes": [{
                                "id": "gid://shopify/CartDeliveryGroup/1",
                                "groupType": "ONE_TIME_PURCHASE",
                                "deliveryOptions": [{
                                    "handle": "express",
                                    "title": "Express Shipping",
                                    "code": "EXPRESS",
                                    "deliveryMethodType": "SHIPPING",
                                    "description": "1-2 business days",
                                    "estimatedCost": {"amount": "15.00", "currencyCode": "USD"}
                                }],
                                "selectedDeliveryOption": {
                                    "handle": "express",
                                    "title": "Express Shipping",
                                    "code": "EXPRESS",
                                    "deliveryMethodType": "SHIPPING",
                                    "description": "1-2 business days",
                                    "estimatedCost": {"amount": "15.00", "currencyCode": "USD"}
                                }
                            }]
                        },
                        "delivery": null,
                        "lines": {"nodes": []},
                        "cost": {
                            "totalAmount": {"amount": "34.99", "currencyCode": "USD"},
                            "subtotalAmount": {"amount": "19.99", "currencyCode": "USD"},
                            "totalTaxAmount": null
                        },
                        "discountCodes": [],
                        "discountAllocations": []
                    },
                    "userErrors": []
                }
            }
        }
        """
        mockJSONResponse(json)

        let cart = try await storefrontAPI.cartSelectedDeliveryOptionsUpdate(
            id: GraphQLScalars.ID("gid://shopify/Cart/123"),
            deliveryGroupId: GraphQLScalars.ID("gid://shopify/CartDeliveryGroup/1"),
            deliveryOptionHandle: "express"
        )

        XCTAssertEqual(cart.deliveryGroups.nodes.first?.selectedDeliveryOption?.handle, "express")
        XCTAssertEqual(cart.cost.totalAmount.amount, Decimal(string: "34.99")!)
    }

    // MARK: - Cart Payment Update Tests

    func testCartPaymentUpdateSuccess() async throws {
        let json = """
        {
            "data": {
                "cartPaymentUpdate": {
                    "cart": {
                        "id": "gid://shopify/Cart/123",
                        "checkoutUrl": "https://test.myshopify.com/checkout/123",
                        "totalQuantity": 1,
                        "buyerIdentity": null,
                        "deliveryGroups": {"nodes": []},
                        "delivery": null,
                        "lines": {"nodes": []},
                        "cost": {
                            "totalAmount": {"amount": "34.99", "currencyCode": "USD"},
                            "subtotalAmount": {"amount": "19.99", "currencyCode": "USD"},
                            "totalTaxAmount": {"amount": "2.50", "currencyCode": "USD"}
                        },
                        "discountCodes": [],
                        "discountAllocations": []
                    },
                    "userErrors": []
                }
            }
        }
        """
        mockJSONResponse(json)

        let applePayPayment = StorefrontAPI.ApplePayPayment(
            billingAddress: StorefrontAPI.Address(
                address1: "123 Billing St",
                city: "Billing City",
                country: "United States",
                firstName: "John",
                lastName: "Doe",
                province: "California",
                zip: "90210"
            ),
            ephemeralPublicKey: "test-public-key",
            publicKeyHash: "test-key-hash",
            transactionId: "test-transaction-123",
            data: "encrypted-payment-data",
            signature: "test-signature",
            version: "EC_v1",
            lastDigits: "4242"
        )

        let totalAmount = StorefrontAPI.MoneyV2(amount: Decimal(string: "34.99")!, currencyCode: "USD")

        let cart = try await storefrontAPI.cartPaymentUpdate(
            id: GraphQLScalars.ID("gid://shopify/Cart/123"),
            totalAmount: totalAmount,
            applePayPayment: applePayPayment
        )

        XCTAssertEqual(cart.cost.totalAmount.amount, Decimal(string: "34.99")!)
        XCTAssertNotNil(cart.cost.totalTaxAmount)
    }

    func testCartPaymentUpdateRequestValidation() async throws {
        let json = """
        {"data": {"cartPaymentUpdate": {"cart": null, "userErrors": []}}}
        """
        mockJSONResponse(json)

        let applePayPayment = StorefrontAPI.ApplePayPayment(
            billingAddress: StorefrontAPI.Address(
                address1: "456 Test Ave",
                address2: "Suite 100",
                city: "Los Angeles",
                country: "United States",
                firstName: "Jane",
                lastName: "Smith",
                phone: "+13105551234",
                province: "California",
                zip: "90001"
            ),
            ephemeralPublicKey: "ephemeral-key",
            publicKeyHash: "key-hash",
            transactionId: "txn-456",
            data: "base64-encoded-data",
            signature: "signature-data",
            version: "EC_v1",
            lastDigits: "1234"
        )

        let totalAmount = StorefrontAPI.MoneyV2(amount: Decimal(string: "99.99")!, currencyCode: "USD")

        do {
            _ = try await storefrontAPI.cartPaymentUpdate(
                id: GraphQLScalars.ID("gid://shopify/Cart/456"),
                totalAmount: totalAmount,
                applePayPayment: applePayPayment
            )
            XCTFail("Expected error to be thrown")
        } catch {
            // Verify error type
            XCTAssertTrue(
                error is GraphQLError,
                "Unexpected error type: \(type(of: error))"
            )

            guard case .invalidResponse = error as? GraphQLError else {
                XCTFail("Expected GraphQLError.invalidResponse but got: \(error)")
                return
            }
        }

        XCTAssertNotNil(MockURLProtocol.capturedRequestBody)

        guard let body = MockURLProtocol.capturedRequestBody else {
            XCTFail("Expected request body to be captured")
            return
        }

        let jsonBody = try JSONSerialization.jsonObject(with: body) as? [String: Any]
        let variables = jsonBody?["variables"] as? [String: Any]
        let payment = variables?["payment"] as? [String: Any]
        let amount = payment?["amount"] as? [String: Any]
        let walletPaymentMethod = payment?["walletPaymentMethod"] as? [String: Any]
        let applePayContent = walletPaymentMethod?["applePayWalletContent"] as? [String: Any]
        let billingAddress = applePayContent?["billingAddress"] as? [String: Any]

        XCTAssertEqual(amount?["amount"] as? String, "99.99")
        XCTAssertEqual(amount?["currencyCode"] as? String, "USD")
        XCTAssertEqual(billingAddress?["address1"] as? String, "456 Test Ave")
        XCTAssertEqual(billingAddress?["country"] as? String, "United States")
        XCTAssertEqual(billingAddress?["province"] as? String, "California")
        XCTAssertEqual(applePayContent?["lastDigits"] as? String, "1234")
        XCTAssertEqual(applePayContent?["version"] as? String, "EC_v1")
    }

    // MARK: - Cart Remove Personal Data Tests

    func testCartRemovePersonalDataSuccess() async throws {
        let json = """
        {
            "data": {
                "cartRemovePersonalData": {
                    "cart": {
                        "id": "gid://shopify/Cart/123",
                        "checkoutUrl": "https://test.myshopify.com/checkout/123",
                        "totalQuantity": 1,
                        "buyerIdentity": null,
                        "deliveryGroups": {"nodes": []},
                        "delivery": null,
                        "lines": {"nodes": []},
                        "cost": {
                            "totalAmount": {"amount": "19.99", "currencyCode": "USD"},
                            "subtotalAmount": {"amount": "19.99", "currencyCode": "USD"},
                            "totalTaxAmount": null
                        },
                        "discountCodes": [],
                        "discountAllocations": []
                    },
                    "userErrors": []
                }
            }
        }
        """
        mockJSONResponse(json)

        try await storefrontAPI.cartRemovePersonalData(id: GraphQLScalars.ID("gid://shopify/Cart/123"))

        XCTAssertTrue(true)
    }

    // MARK: - Cart Prepare For Completion Tests

    func testCartPrepareForCompletionReady() async throws {
        let json = """
        {
            "data": {
                "cartPrepareForCompletion": {
                    "result": {
                        "__typename": "CartStatusReady",
                        "cart": {
                            "id": "gid://shopify/Cart/123",
                            "checkoutUrl": "https://test.myshopify.com/checkout/123",
                            "totalQuantity": 1,
                            "buyerIdentity": {"email": "test@example.com"},
                            "deliveryGroups": {"nodes": []},
                            "delivery": null,
                            "lines": {"nodes": []},
                            "cost": {
                                "totalAmount": {"amount": "34.99", "currencyCode": "USD"},
                                "subtotalAmount": {"amount": "19.99", "currencyCode": "USD"},
                                "totalTaxAmount": {"amount": "2.50", "currencyCode": "USD"}
                            },
                            "discountCodes": [],
                            "discountAllocations": []
                        },
                        "checkoutURL": "https://test.myshopify.com/checkout/ready-123"
                    },
                    "userErrors": []
                }
            }
        }
        """
        mockJSONResponse(json)

        let result = try await storefrontAPI.cartPrepareForCompletion(id: GraphQLScalars.ID("gid://shopify/Cart/123"))

        XCTAssertNotNil(result.cart)
        XCTAssertEqual(result.cart?.id.rawValue, "gid://shopify/Cart/123")
        XCTAssertEqual(result.cart?.buyerIdentity?.email, "test@example.com")
        XCTAssertNotNil(result.checkoutURL)
    }

    func testCartPrepareForCompletionNotReady() async {
        let json = """
        {
            "data": {
                "cartPrepareForCompletion": {
                    "result": {
                        "__typename": "CartStatusNotReady",
                        "cart": null,
                        "errors": [
                            {
                                "code": "DELIVERY_ADDRESS_REQUIRED",
                                "message": "Delivery address is required"
                            },
                            {
                                "code": "PAYMENT_METHOD_REQUIRED",
                                "message": "Payment method is required"
                            }
                        ]
                    },
                    "userErrors": []
                }
            }
        }
        """
        mockJSONResponse(json)

        do {
            _ = try await storefrontAPI.cartPrepareForCompletion(id: GraphQLScalars.ID("gid://shopify/Cart/123"))
            XCTFail("Expected error to be thrown")
        } catch {
            // Verify error type
            XCTAssertTrue(
                error is GraphQLError,
                "Unexpected error type: \(type(of: error))"
            )

            guard case let .networkError(message) = error as? GraphQLError else {
                XCTFail("Expected GraphQLError.networkError but got: \(error)")
                return
            }

            // Check that it contains the expected error format
            XCTAssertTrue(message.contains("Cart not ready"), "Error message should contain 'Cart not ready': \(message)")
            // The error codes are converted to camelCase in the error message
            XCTAssertTrue(message.contains("deliveryAddressRequired"), "Error message should contain 'deliveryAddressRequired': \(message)")
            XCTAssertTrue(message.contains("paymentMethodRequired"), "Error message should contain 'paymentMethodRequired': \(message)")
        }
    }

    func testCartPrepareForCompletionThrottled() async {
        let json = """
        {
            "data": {
                "cartPrepareForCompletion": {
                    "result": {
                        "__typename": "CartThrottled",
                        "pollAfter": "2025-01-15T10:00:00Z"
                    },
                    "userErrors": []
                }
            }
        }
        """
        mockJSONResponse(json)

        do {
            _ = try await storefrontAPI.cartPrepareForCompletion(id: GraphQLScalars.ID("gid://shopify/Cart/123"))
            XCTFail("Expected error to be thrown")
        } catch {
            // Verify error type
            XCTAssertTrue(
                error is GraphQLError,
                "Unexpected error type: \(type(of: error))"
            )

            guard case let .networkError(message) = error as? GraphQLError else {
                XCTFail("Expected GraphQLError.networkError but got: \(error)")
                return
            }

            XCTAssertTrue(message.contains("Cart preparation throttled"))
            XCTAssertTrue(message.contains("2025-01-15"))
        }
    }

    // MARK: - Cart Submit For Completion Tests

    func testCartSubmitForCompletionSuccess() async throws {
        let json = """
        {
            "data": {
                "cartSubmitForCompletion": {
                    "result": {
                        "__typename": "SubmitSuccess",
                        "redirectUrl": "https://test.myshopify.com/checkout/success/12345"
                    },
                    "userErrors": []
                }
            }
        }
        """
        mockJSONResponse(json)

        let result = try await storefrontAPI.cartSubmitForCompletion(id: GraphQLScalars.ID("gid://shopify/Cart/123"))

        XCTAssertEqual(result.redirectUrl.url.absoluteString, "https://test.myshopify.com/checkout/success/12345")
    }

    func testCartSubmitForCompletionFailed() async {
        let json = """
        {
            "data": {
                "cartSubmitForCompletion": {
                    "result": {
                        "__typename": "SubmitFailed",
                        "checkoutUrl": null,
                        "errors": [
                            {
                                "code": "PAYMENT_CARD_DECLINED",
                                "message": "Payment was declined"
                            }
                        ]
                    },
                    "userErrors": []
                }
            }
        }
        """
        mockJSONResponse(json)

        do {
            _ = try await storefrontAPI.cartSubmitForCompletion(id: GraphQLScalars.ID("gid://shopify/Cart/123"))
            XCTFail("Expected error to be thrown")
        } catch {
            // Verify error type
            XCTAssertTrue(
                error is GraphQLError,
                "Unexpected error type: \(type(of: error))"
            )

            guard case let .networkError(message) = error as? GraphQLError else {
                XCTFail("Expected GraphQLError.networkError but got: \(error)")
                return
            }

            // Check that it contains the expected error format
            XCTAssertTrue(message.contains("Cart submission failed"), "Error message should contain 'Cart submission failed': \(message)")
            // The error code is converted to camelCase in the error message
            XCTAssertTrue(message.contains("paymentCardDeclined"), "Error message should contain 'paymentCardDeclined': \(message)")
        }
    }

    func testCartSubmitForCompletionAlreadyAccepted() async {
        let json = """
        {
            "data": {
                "cartSubmitForCompletion": {
                    "result": {
                        "__typename": "SubmitAlreadyAccepted",
                        "attemptId": "gid://shopify/CartCompletionAttempt/99999"
                    },
                    "userErrors": []
                }
            }
        }
        """
        mockJSONResponse(json)

        do {
            _ = try await storefrontAPI.cartSubmitForCompletion(id: GraphQLScalars.ID("gid://shopify/Cart/123"))
            XCTFail("Expected error to be thrown")
        } catch {
            // Verify error type
            XCTAssertTrue(
                error is GraphQLError,
                "Unexpected error type: \(type(of: error))"
            )

            guard case let .networkError(message) = error as? GraphQLError else {
                XCTFail("Expected GraphQLError.networkError but got: \(error)")
                return
            }

            XCTAssertTrue(message.contains("Cart already accepted"))
            XCTAssertTrue(message.contains("gid://shopify/CartCompletionAttempt/99999"))
        }
    }

    func testCartSubmitForCompletionThrottled() async {
        let json = """
        {
            "data": {
                "cartSubmitForCompletion": {
                    "result": {
                        "__typename": "SubmitThrottled",
                        "pollAfter": "2025-01-15T11:00:00Z"
                    },
                    "userErrors": []
                }
            }
        }
        """
        mockJSONResponse(json)

        do {
            _ = try await storefrontAPI.cartSubmitForCompletion(id: GraphQLScalars.ID("gid://shopify/Cart/123"))
            XCTFail("Expected error to be thrown")
        } catch {
            // Verify error type
            XCTAssertTrue(
                error is GraphQLError,
                "Unexpected error type: \(type(of: error))"
            )

            guard case let .networkError(message) = error as? GraphQLError else {
                XCTFail("Expected GraphQLError.networkError but got: \(error)")
                return
            }

            XCTAssertTrue(message.contains("Cart submission throttled"))
            XCTAssertTrue(message.contains("2025-01-15"))
        }
    }

    func testCartSubmitForCompletionRequestValidation() async throws {
        let json = """
        {"data": {"cartSubmitForCompletion": {"result": null, "userErrors": []}}}
        """
        mockJSONResponse(json)

        do {
            _ = try await storefrontAPI.cartSubmitForCompletion(id: GraphQLScalars.ID("gid://shopify/Cart/789"))
            XCTFail("Expected error to be thrown")
        } catch {
            // Verify error type
            XCTAssertTrue(
                error is GraphQLError,
                "Unexpected error type: \(type(of: error))"
            )

            guard case .invalidResponse = error as? GraphQLError else {
                XCTFail("Expected GraphQLError.invalidResponse but got: \(error)")
                return
            }
        }

        XCTAssertNotNil(MockURLProtocol.capturedRequestBody)

        guard let body = MockURLProtocol.capturedRequestBody else {
            XCTFail("Expected request body to be captured")
            return
        }

        let jsonBody = try JSONSerialization.jsonObject(with: body) as? [String: Any]
        let variables = jsonBody?["variables"] as? [String: Any]

        XCTAssertEqual(variables?["cartId"] as? String, "gid://shopify/Cart/789")
        XCTAssertNotNil(variables?["attemptToken"] as? String)

        // Verify attempt token is a valid UUID
        if let attemptToken = variables?["attemptToken"] as? String {
            XCTAssertNotNil(UUID(uuidString: attemptToken))
        }
    }

    // MARK: - Error Handling Tests

    func testMutationWithNetworkError() async {
        mockErrorResponse(URLError(.notConnectedToInternet))

        do {
            _ = try await storefrontAPI.cartCreate()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(
                error is URLError,
                "Expected URLError but got: \(type(of: error))"
            )
        }
    }

    func testMutationWithGraphQLErrors() async {
        let json = """
        {
            "data": null,
            "errors": [
                {
                    "message": "Internal server error",
                    "path": ["cartCreate"],
                    "locations": [{"line": 2, "column": 3}]
                }
            ]
        }
        """
        mockJSONResponse(json)

        do {
            _ = try await storefrontAPI.cartCreate()
            XCTFail("Expected error to be thrown")
        } catch {
            // Verify error type
            XCTAssertTrue(
                error is GraphQLError,
                "Unexpected error type: \(type(of: error))"
            )

            guard case let .graphQLErrors(errors) = error as? GraphQLError else {
                XCTFail("Expected GraphQLError.graphQLErrors but got: \(error)")
                return
            }

            XCTAssertEqual(errors.first?.message, "Internal server error")
        }
    }

    func testMutationWithMalformedResponse() async {
        let json = """
        {
            "data": {
                "cartCreate": {
                    "cart": {
                        "id": "gid://shopify/Cart/123"
                    },
                    "userErrors": []
                }
            }
        }
        """
        mockJSONResponse(json)

        do {
            _ = try await storefrontAPI.cartCreate()
            XCTFail("Expected error to be thrown")
        } catch let error as DecodingError {
            // Expected - malformed JSON should fail during decoding into Cart struct
            _ = error
        } catch let error as GraphQLError {
            // Expected - might also be a GraphQLError depending on the response
            _ = error
        } catch {
            XCTFail("Unexpected error type: \(type(of: error))")
        }
    }

    func testUserErrorWithCheckoutURLThrowsCartUserError() async {
        let json = """
        {
            "data": {
                "cartCreate": {
                    "cart": {
                        "id": "gid://shopify/Cart/123",
                        "checkoutUrl": "https://test.myshopify.com/checkout/recovery-123",
                        "totalQuantity": 0,
                        "buyerIdentity": null,
                        "deliveryGroups": {"nodes": []},
                        "delivery": null,
                        "lines": {"nodes": []},
                        "cost": {
                            "totalAmount": {"amount": "0.00", "currencyCode": "USD"},
                            "subtotalAmount": {"amount": "0.00", "currencyCode": "USD"},
                            "totalTaxAmount": null
                        },
                        "discountCodes": [],
                        "discountAllocations": []
                    },
                    "userErrors": [{
                        "field": ["input"],
                        "message": "Cart limit exceeded",
                        "code": "TOO_MANY_LINE_ITEMS"
                    }]
                }
            }
        }
        """
        mockJSONResponse(json)

        do {
            _ = try await storefrontAPI.cartCreate()
            XCTFail("Expected error to be thrown")
        } catch let cartError as StorefrontAPI.CartUserError {
            // Expected - CartUserError is thrown directly
            XCTAssertEqual(cartError.code, .tooManyLineItems)
            XCTAssertEqual(cartError.message, "Cart limit exceeded")
            XCTAssertEqual(cartError.field, ["input"])
        } catch {
            XCTFail("Expected CartUserError but got: \(error)")
        }
    }

    func testUserErrorWithoutCheckoutURLThrowsCartUserError() async {
        let json = """
        {
            "data": {
                "cartBuyerIdentityUpdate": {
                    "cart": {
                        "id": "gid://shopify/Cart/123",
                        "checkoutUrl": "https://test.myshopify.com/checkout/123",
                        "totalQuantity": 0,
                        "buyerIdentity": null,
                        "deliveryGroups": {"nodes": []},
                        "delivery": null,
                        "lines": {"nodes": []},
                        "cost": {
                            "totalAmount": {"amount": "0.00", "currencyCode": "USD"},
                            "subtotalAmount": {"amount": "0.00", "currencyCode": "USD"},
                            "totalTaxAmount": null
                        },
                        "discountCodes": [],
                        "discountAllocations": []
                    },
                    "userErrors": [{
                        "field": ["buyerIdentity", "email"],
                        "message": "Email format is invalid",
                        "code": "INVALID"
                    }]
                }
            }
        }
        """
        mockJSONResponse(json)

        do {
            _ = try await storefrontAPI.cartBuyerIdentityUpdate(
                id: GraphQLScalars.ID("gid://shopify/Cart/123"),
                email: "bad-email"
            )
            XCTFail("Expected error to be thrown")
        } catch let cartError as StorefrontAPI.CartUserError {
            // Expected - CartUserError is thrown directly
            XCTAssertEqual(cartError.code, .invalid)
            XCTAssertEqual(cartError.message, "Email format is invalid")
            XCTAssertEqual(cartError.field, ["buyerIdentity", "email"])
        } catch {
            XCTFail("Expected CartUserError but got: \(error)")
        }
    }
}
