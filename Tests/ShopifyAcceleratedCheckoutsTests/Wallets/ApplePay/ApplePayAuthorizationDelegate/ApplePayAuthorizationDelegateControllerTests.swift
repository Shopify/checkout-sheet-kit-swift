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

import Contacts
import PassKit
import ShopifyCheckoutSheetKit
import XCTest

@testable import ShopifyAcceleratedCheckouts

@available(iOS 17.0, *)
@MainActor
final class ApplePayAuthorizationDelegateControllerTests: XCTestCase {
    private var configuration: ApplePayConfigurationWrapper = .testConfiguration
    private var mockController: MockPayController!
    private var delegate: ApplePayAuthorizationDelegate!

    override func setUp() async throws {
        try await super.setUp()

        URLProtocol.registerClass(MockURLProtocol.self)

        mockController = MockPayController()
        mockController.cart = StorefrontAPI.Cart.testCart

        delegate = ApplePayAuthorizationDelegate(
            configuration: configuration,
            controller: mockController,
            clock: MockClock()
        )

        try delegate.setCart(to: mockController.cart)
    }

    override func tearDown() async throws {
        delegate = nil
        mockController = nil
        URLProtocol.unregisterClass(MockURLProtocol.self)
        MockURLProtocol.reset()
        try await super.tearDown()
    }

    // MARK: - Shipping Method Selection Logic Tests

    func test_didSelectShippingMethod_withValidShippingMethod_shouldCompleteSuccessfully() async throws {
        let shippingMethod = PKShippingMethod()
        shippingMethod.identifier = "standard-shipping"
        shippingMethod.label = "Standard Shipping"
        shippingMethod.detail = "5-7 business days"
        shippingMethod.amount = NSDecimalNumber(string: "5.00")

        let result = await delegate.paymentAuthorizationController(
            PKPaymentAuthorizationController(),
            didSelectShippingMethod: shippingMethod
        )

        XCTAssertNotNil(result, "Should return a result for shipping method selection")
        XCTAssertNotNil(result.paymentSummaryItems, "Should have payment summary items")
    }

    func test_didSelectShippingMethod_withFallbackLogic_shouldHandleInvalidMethods() async throws {
        let invalidMethod = PKShippingMethod()
        invalidMethod.identifier = "non-existent-method"
        invalidMethod.label = "Invalid Method"

        let result = await delegate.paymentAuthorizationController(
            PKPaymentAuthorizationController(),
            didSelectShippingMethod: invalidMethod
        )
        XCTAssertNotNil(result, "Should handle invalid method with fallback logic")
    }

    // MARK: - Shipping Contact Update Logic Tests

    func test_didSelectShippingContact_shouldClearShippingMethodsAndUpdateAddress() async throws {
        let contact = PKContact()
        contact.postalAddress = createPostalAddress()

        let result = await delegate.paymentAuthorizationController(
            PKPaymentAuthorizationController(),
            didSelectShippingContact: contact
        )

        XCTAssertNotNil(result, "Should return a result for shipping contact selection")
        XCTAssertNotNil(result.shippingMethods, "Should have shipping methods array")
    }

    func test_didSelectShippingContact_withCartStatePreservation_shouldHandleStateCorrectly() async throws {
        let contact = PKContact()
        contact.postalAddress = createPostalAddress()

        let result = await delegate.paymentAuthorizationController(
            PKPaymentAuthorizationController(),
            didSelectShippingContact: contact
        )

        XCTAssertNotNil(mockController.cart, "Cart should still exist after contact selection")
        XCTAssertNotNil(result)
    }

    // MARK: - upsertShippingAddress Strategy Tests

    func test_upsertShippingAddress_withExistingAddressID_shouldFollowRemoveThenAddStrategy() async throws {
        let address = StorefrontAPI.Address(
            address1: "123 New Street",
            city: "New City",
            country: "US",
            province: "CA",
            zip: "90210"
        )

        let existingAddressID = GraphQLScalars.ID("existing-address-123")
        delegate.selectedShippingAddressID = existingAddressID

        let result = try await delegate.upsertShippingAddress(to: address)
        XCTAssertNotNil(result)
        XCTAssertEqual(delegate.selectedShippingAddressID, GraphQLScalars.ID("gid://shopify/CartSelectableAddress/1"))
        XCTAssertNotNil(MockURLProtocol.lastOperation)
    }

    func test_upsertShippingAddress_withNoExistingAddressID_shouldOnlyAdd() async throws {
        let address = StorefrontAPI.Address(
            address1: "123 New Street",
            city: "New City",
            country: "US",
            province: "CA",
            zip: "90210"
        )

        delegate.selectedShippingAddressID = nil

        let result = try await delegate.upsertShippingAddress(to: address)
        XCTAssertNotNil(result)
        XCTAssertEqual(delegate.selectedShippingAddressID, GraphQLScalars.ID("gid://shopify/CartSelectableAddress/1"))
        XCTAssertNotNil(MockURLProtocol.lastOperation)
    }

    func test_upsertShippingAddress_errorHandlingStrategy_shouldHandleRemoveFailures() async throws {
        let address = StorefrontAPI.Address(
            address1: "123 Test Street",
            city: "Test City",
            country: "US",
            province: "CA",
            zip: "12345"
        )

        delegate.selectedShippingAddressID = GraphQLScalars.ID("test-address-id")

        MockURLProtocol.failRemove = true
        MockURLProtocol.lastOperation = nil
        _ = try? await delegate.upsertShippingAddress(to: address)
        XCTAssertEqual(delegate.selectedShippingAddressID, GraphQLScalars.ID("gid://shopify/CartSelectableAddress/1"))
        XCTAssertNotNil(MockURLProtocol.lastOperation)
        MockURLProtocol.failRemove = false
    }

    // MARK: - Shipping Method Selection – Delegate Validation

    private class TestPKDecoder: PKDecoder {
        var stubbedShippingMethods: [PKShippingMethod] = []
        override var shippingMethods: [PKShippingMethod] {
            stubbedShippingMethods
        }
    }

    private func makeStubDecoder(methods: [PKShippingMethod]) -> TestPKDecoder {
        let decoder = TestPKDecoder(configuration: configuration, cart: { [weak self] in self?.mockController.cart })
        decoder.stubbedShippingMethods = methods
        return decoder
    }

    func test_didSelectShippingMethod_whenMethodIsValid_shouldRetainSelection() async throws {
        let valid = PKShippingMethod()
        valid.identifier = "valid-method"
        let other = PKShippingMethod()
        other.identifier = "other-method"

        delegate.pkDecoder = makeStubDecoder(methods: [valid, other])
        MockURLProtocol.lastOperation = nil

        _ = await delegate.paymentAuthorizationController(
            PKPaymentAuthorizationController(),
            didSelectShippingMethod: valid
        )

        XCTAssertEqual(delegate.pkEncoder.selectedShippingMethod?.identifier, "valid-method")
        XCTAssertFalse(delegate.pkDecoder.paymentSummaryItems.isEmpty)
    }

    func test_didSelectShippingMethod_whenMethodIsInvalid_shouldFallbackToFirstAvailable() async throws {
        let firstAvailable = PKShippingMethod()
        firstAvailable.identifier = "first-available"

        let selected = PKShippingMethod()
        selected.identifier = "invalid-method"

        delegate.pkDecoder = makeStubDecoder(methods: [firstAvailable])
        MockURLProtocol.lastOperation = nil

        _ = await delegate.paymentAuthorizationController(
            PKPaymentAuthorizationController(),
            didSelectShippingMethod: selected
        )

        XCTAssertEqual(delegate.pkEncoder.selectedShippingMethod?.identifier, "first-available")
    }

    func test_didSelectShippingMethod_whenNoMethodsAvailable_shouldKeepOriginal() async throws {
        let selected = PKShippingMethod()
        selected.identifier = "only-method"

        delegate.pkDecoder = makeStubDecoder(methods: [])
        MockURLProtocol.lastOperation = nil

        _ = await delegate.paymentAuthorizationController(
            PKPaymentAuthorizationController(),
            didSelectShippingMethod: selected
        )

        XCTAssertEqual(delegate.pkEncoder.selectedShippingMethod?.identifier, "only-method")
    }

    // MARK: - Helper Methods

    private func createPostalAddress() -> CNPostalAddress {
        let address = CNMutablePostalAddress()
        address.street = "123 Test Street"
        address.city = "Test City"
        address.state = "CA"
        address.postalCode = "12345"
        address.country = "US"
        return address
    }

    // MARK: - Mock Classes

    private class MockPayController: PayController {
        var cart: StorefrontAPI.Types.Cart?
        var storefront: StorefrontAPI
        var storefrontJulyRelease: StorefrontAPI

        init() {
            let cfg = ShopifyAcceleratedCheckouts.Configuration.testConfiguration
            storefront = StorefrontAPI(storefrontDomain: cfg.storefrontDomain, storefrontAccessToken: cfg.storefrontAccessToken)
            storefrontJulyRelease = storefront
        }

        func present(url _: URL) async throws {}
    }

    // MARK: - Network Stubbing

    class MockURLProtocol: URLProtocol {
        static let mockCartResponse: String = "{" +
            "\"id\":\"gid://shopify/Cart/test\"," +
            "\"checkoutUrl\":\"https://stub/checkout\"," +
            "\"totalQuantity\":0," +
            "\"buyerIdentity\":null," +
            "\"deliveryGroups\":{\"nodes\":[]}," +
            "\"delivery\":null," +
            "\"lines\":{\"nodes\":[]}," +
            "\"cost\":{\"totalAmount\":{\"amount\":\"0.00\",\"currencyCode\":\"USD\"}}," +
            "\"discountCodes\":[],\"discountAllocations\":[]}"

        static let mockCartWithAddressResponse: String = "{" +
            "\"id\":\"gid://shopify/Cart/test\"," +
            "\"checkoutUrl\":\"https://stub/checkout\"," +
            "\"totalQuantity\":0," +
            "\"buyerIdentity\":null," +
            "\"deliveryGroups\":{\"nodes\":[]}," +
            "\"delivery\":{\"addresses\":[{\"id\":\"gid://shopify/CartSelectableAddress/1\",\"selected\":true,\"address\":{\"countryCode\":\"US\"}}]}," +
            "\"lines\":{\"nodes\":[]}," +
            "\"cost\":{\"totalAmount\":{\"amount\":\"0.00\",\"currencyCode\":\"USD\"}}," +
            "\"discountCodes\":[],\"discountAllocations\":[]}"

        static var failRemove = false
        static var failAdd = false
        static var lastOperation: String?

        static func response(for op: String) -> Data {
            if op == "cartPrepareForCompletion" {
                let json = "{" +
                    "\"data\":{\"cartPrepareForCompletion\":{\"result\":{\"__typename\":\"CartStatusReady\",\"cart\":" + mockCartResponse + "},\"userErrors\":[]}}}"
                return Data(json.utf8)
            } else if op == "cartDeliveryAddressesAdd" {
                let json = "{" +
                    "\"data\":{\"cartDeliveryAddressesAdd\":{\"cart\":" + mockCartWithAddressResponse + ",\"userErrors\":[]}}}"
                return Data(json.utf8)
            } else {
                let json = "{" +
                    "\"data\":{\"" + op + "\":{\"cart\":" + mockCartResponse + ",\"userErrors\":[]}}}"
                return Data(json.utf8)
            }
        }

        override class func canInit(with _: URLRequest) -> Bool { true }
        override class func canonicalRequest(for req: URLRequest) -> URLRequest { req }
        override func startLoading() {
            let bodyStr = request.httpBody.flatMap { String(data: $0, encoding: .utf8) } ?? ""
            let ops = ["cartDeliveryAddressesAdd", "cartDeliveryAddressesRemove", "cartSelectedDeliveryOptionsUpdate", "cartPrepareForCompletion"]
            let op = ops.first { bodyStr.contains($0) } ?? "cartDeliveryAddressesAdd"
            Self.lastOperation = op
            if (op == "cartDeliveryAddressesRemove" && Self.failRemove) || (op == "cartDeliveryAddressesAdd" && Self.failAdd) {
                let errorJSON = "{\"data\":{\"\(op)\":{\"cart\":null,\"userErrors\":[{\"message\":\"fail\"}]}}}"
                let data = Data(errorJSON.utf8)
                let resp = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                client?.urlProtocol(self, didReceive: resp, cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: data)
            } else {
                let data = Self.response(for: op)
                let resp = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                client?.urlProtocol(self, didReceive: resp, cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: data)
            }
            client?.urlProtocolDidFinishLoading(self)
        }

        override func stopLoading() {}
        static func reset() { lastOperation = nil; failRemove = false; failAdd = false }
    }
}
