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
            PKPaymentAuthorizationController(paymentRequest: .testPaymentRequest),
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
            PKPaymentAuthorizationController(paymentRequest: .testPaymentRequest),
            didSelectShippingMethod: invalidMethod
        )
        XCTAssertNotNil(result, "Should handle invalid method with fallback logic")
    }

    func test_didSelectShippingMethod_withCartIDError_shouldReturnFailureStatus() async throws {
        // Add the shipping method to available methods so it passes validation
        let shippingMethod = PKShippingMethod()
        shippingMethod.identifier = "standard-shipping"
        shippingMethod.label = "Standard Shipping"

        delegate.pkDecoder = makeStubDecoder(methods: [shippingMethod])

        // Now set cart to nil to cause cartID.get() to fail
        try delegate.setCart(to: nil)

        let result = await delegate.paymentAuthorizationController(
            PKPaymentAuthorizationController(paymentRequest: .testPaymentRequest),
            didSelectShippingMethod: shippingMethod
        )

        XCTAssertEqual(result.status, .failure, "Should return failure status when cartID cannot be retrieved")
        XCTAssertNotNil(result.paymentSummaryItems, "Should still return payment summary items")
    }

    // MARK: - Shipping Contact Update Logic Tests

    func test_didSelectShippingContact_shouldClearShippingMethodsAndUpdateAddress() async throws {
        let contact = PKContact()
        contact.postalAddress = createPostalAddress()

        let result = await delegate.paymentAuthorizationController(
            PKPaymentAuthorizationController(paymentRequest: .testPaymentRequest),
            didSelectShippingContact: contact
        )

        XCTAssertNotNil(result, "Should return a result for shipping contact selection")
        XCTAssertNotNil(result.shippingMethods, "Should have shipping methods array")
    }

    func test_didSelectShippingContact_withCartStatePreservation_shouldHandleStateCorrectly() async throws {
        let contact = PKContact()
        contact.postalAddress = createPostalAddress()

        let result = await delegate.paymentAuthorizationController(
            PKPaymentAuthorizationController(paymentRequest: .testPaymentRequest),
            didSelectShippingContact: contact
        )

        XCTAssertNotNil(mockController.cart, "Cart should still exist after contact selection")
        XCTAssertNotNil(result)
    }

    func test_didSelectShippingContact_withUnsupportedCountry_shouldReturnError() async throws {
        // Configure with only US as supported country
        let applePayConfig = ShopifyAcceleratedCheckouts.ApplePayConfiguration.testConfiguration(supportedShippingCountries: ["US"])
        let configWithRestriction = ApplePayConfigurationWrapper.testConfiguration(applePay: applePayConfig)
        delegate = ApplePayAuthorizationDelegate(
            configuration: configWithRestriction,
            controller: mockController,
            clock: MockClock()
        )
        try delegate.setCart(to: mockController.cart)

        // Create contact with France (FR) as the country
        let contact = PKContact()
        let address = CNMutablePostalAddress()
        address.street = "123 Rue de Test"
        address.city = "Paris"
        address.state = ""
        address.postalCode = "75001"
        address.isoCountryCode = "FR"
        contact.postalAddress = address

        let result = await delegate.paymentAuthorizationController(
            PKPaymentAuthorizationController(paymentRequest: .testPaymentRequest),
            didSelectShippingContact: contact
        )

        XCTAssertNotNil(result, "Should return a result for unsupported country")
        XCTAssertNotNil(result.errors, "Should have errors for unsupported country")
        XCTAssertFalse(result.errors?.isEmpty ?? true, "Should have at least one error")
        // PKPaymentError errors maintain success status to keep the sheet open for user correction
        XCTAssertEqual(result.status, .success, "Should return success status with PKPaymentError for user correction")

        // Verify the error is specifically about country validation
        if let firstError = result.errors?.first as? NSError {
            XCTAssertEqual(firstError.domain, PKPaymentErrorDomain, "Error should be a PKPaymentError")
            // The error code for shipping address invalid is 2 (PKPaymentError.Code.shippingContactInvalidError)
            XCTAssertEqual(firstError.code, PKPaymentError.Code.shippingContactInvalidError.rawValue, "Should be shipping contact invalid error")
        } else {
            XCTFail("Expected to find an error in the result, but errors array was empty or nil")
        }
    }

    func test_didSelectShippingContact_withSupportedCountry_shouldProceed() async throws {
        // Configure with US and CA as supported countries
        let applePayConfig = ShopifyAcceleratedCheckouts.ApplePayConfiguration.testConfiguration(supportedShippingCountries: ["US", "CA"])
        let configWithRestriction = ApplePayConfigurationWrapper.testConfiguration(applePay: applePayConfig)
        delegate = ApplePayAuthorizationDelegate(
            configuration: configWithRestriction,
            controller: mockController,
            clock: MockClock()
        )
        try delegate.setCart(to: mockController.cart)

        // Create contact with US as the country (which is in the supported list)
        let contact = PKContact()
        let address = CNMutablePostalAddress()
        address.street = "123 Main Street"
        address.city = "San Francisco"
        address.state = "CA"
        address.postalCode = "94102"
        address.isoCountryCode = "US"
        contact.postalAddress = address

        let result = await delegate.paymentAuthorizationController(
            PKPaymentAuthorizationController(paymentRequest: .testPaymentRequest),
            didSelectShippingContact: contact
        )

        XCTAssertNotNil(result, "Should return a result for supported country")
        if let errors = result.errors, !errors.isEmpty {
            // Verify we don't have the country not supported error
            let errorMessages = errors.compactMap { ($0 as NSError).localizedDescription }
            XCTAssertFalse(
                errorMessages.contains { $0.contains("country") || $0.contains("Country") },
                "Should not have country-related errors for supported country"
            )
        }
        XCTAssertNotNil(result.shippingMethods, "Should have shipping methods")
    }

    func test_didSelectShippingContact_withNoRestrictions_shouldAllowAll() async throws {
        // Configure without country restrictions (nil or empty array)
        let configNoRestrictions = ApplePayConfigurationWrapper.testConfiguration()
        delegate = ApplePayAuthorizationDelegate(
            configuration: configNoRestrictions,
            controller: mockController,
            clock: MockClock()
        )
        try delegate.setCart(to: mockController.cart)

        // Create contact with any country (e.g., Japan/JP)
        let contact = PKContact()
        let address = CNMutablePostalAddress()
        address.street = "1-1 Shibuya"
        address.city = "Tokyo"
        address.state = "Tokyo"
        address.postalCode = "150-0002"
        address.isoCountryCode = "JP"
        contact.postalAddress = address

        let result = await delegate.paymentAuthorizationController(
            PKPaymentAuthorizationController(paymentRequest: .testPaymentRequest),
            didSelectShippingContact: contact
        )

        XCTAssertNotNil(result, "Should return a result when no restrictions")
        if let errors = result.errors, !errors.isEmpty {
            // Verify we don't have the country not supported error
            let errorMessages = errors.compactMap { ($0 as NSError).localizedDescription }
            XCTAssertFalse(
                errorMessages.contains { $0.contains("country") || $0.contains("Country") },
                "Should not have country-related errors when no restrictions"
            )
        }
        XCTAssertNotNil(result.shippingMethods, "Should have shipping methods")
    }

    // MARK: - Country List Error Message Tests

    func test_shippingCountryNotSupported_withShortList_shouldShowFullList() async throws {
        // Configure with a small set of countries that fits in 128 chars
        let supportedCountries = Set(["US", "CA", "GB", "FR"])
        let applePayConfig = ShopifyAcceleratedCheckouts.ApplePayConfiguration.testConfiguration(supportedShippingCountries: supportedCountries)
        let config = ApplePayConfigurationWrapper.testConfiguration(applePay: applePayConfig)
        delegate = ApplePayAuthorizationDelegate(
            configuration: config,
            controller: mockController,
            clock: MockClock()
        )
        try delegate.setCart(to: mockController.cart)

        // Create contact with unsupported country
        let contact = PKContact()
        let address = CNMutablePostalAddress()
        address.isoCountryCode = "JP"
        contact.postalAddress = address

        let result = await delegate.paymentAuthorizationController(
            PKPaymentAuthorizationController(paymentRequest: .testPaymentRequest),
            didSelectShippingContact: contact
        )

        // Verify error message contains full list
        if let firstError = result.errors?.first as? NSError {
            let message = firstError.localizedDescription
            XCTAssertTrue(message.contains("CA"), "Should include CA in list")
            XCTAssertTrue(message.contains("FR"), "Should include FR in list")
            XCTAssertTrue(message.contains("GB"), "Should include GB in list")
            XCTAssertTrue(message.contains("US"), "Should include US in list")
            XCTAssertFalse(message.contains("and others"), "Should not truncate short list")
            XCTAssertLessThanOrEqual(message.count, 128, "Message should respect 128 char guideline")
        } else {
            XCTFail("Expected error for unsupported country")
        }
    }

    func test_shippingCountryNotSupported_withLongList_shouldTruncateWithOthers() async throws {
        // Configure with many countries that exceed 128 chars
        let supportedCountries = Set([
            "US", "CA", "GB", "FR", "DE", "IT", "ES", "PT", "NL", "BE",
            "CH", "AT", "SE", "NO", "DK", "FI", "PL", "CZ", "HU", "RO",
            "BG", "HR", "SI", "SK", "EE", "LV", "LT", "IE", "LU", "MT"
        ])
        let applePayConfig = ShopifyAcceleratedCheckouts.ApplePayConfiguration.testConfiguration(supportedShippingCountries: supportedCountries)
        let config = ApplePayConfigurationWrapper.testConfiguration(applePay: applePayConfig)
        delegate = ApplePayAuthorizationDelegate(
            configuration: config,
            controller: mockController,
            clock: MockClock()
        )
        try delegate.setCart(to: mockController.cart)

        // Create contact with unsupported country
        let contact = PKContact()
        let address = CNMutablePostalAddress()
        address.isoCountryCode = "JP"
        contact.postalAddress = address

        let result = await delegate.paymentAuthorizationController(
            PKPaymentAuthorizationController(paymentRequest: .testPaymentRequest),
            didSelectShippingContact: contact
        )

        // Verify error message is truncated with "and others"
        if let firstError = result.errors?.first as? NSError {
            let message = firstError.localizedDescription
            XCTAssertTrue(message.contains("and others"), "Should truncate long list with 'and others'")
            XCTAssertLessThanOrEqual(message.count, 128, "Message should respect 128 char guideline")
            // Should include at least some countries (alphabetically first ones)
            XCTAssertTrue(message.contains("AT") || message.contains("BE"), "Should include some countries")
            // Should NOT include all countries
            XCTAssertFalse(message.contains("MT") && message.contains("SK") && message.contains("SI"), "Should not include all countries")
        } else {
            XCTFail("Expected error for unsupported country")
        }
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
            PKPaymentAuthorizationController(paymentRequest: .testPaymentRequest),
            didSelectShippingMethod: valid
        )

        XCTAssertEqual(delegate.pkEncoder.selectedShippingMethod?.identifier, "valid-method")
        XCTAssertFalse(delegate.pkDecoder.paymentSummaryItems.isEmpty)
    }

    func test_didSelectShippingMethod_whenMethodIsInvalid_shouldNotSetShippingMethod() async throws {
        let firstAvailable = PKShippingMethod()
        firstAvailable.identifier = "first-available"

        let selected = PKShippingMethod()
        selected.identifier = "invalid-method"

        delegate.pkDecoder = makeStubDecoder(methods: [firstAvailable])
        MockURLProtocol.lastOperation = nil

        let result = await delegate.paymentAuthorizationController(
            PKPaymentAuthorizationController(paymentRequest: .testPaymentRequest),
            didSelectShippingMethod: selected
        )

        XCTAssertNil(delegate.pkEncoder.selectedShippingMethod, "Should not set invalid shipping method")
        XCTAssertEqual(result.status, .failure, "Should return failure status for invalid method")
    }

    func test_didSelectShippingMethod_whenNoMethodsAvailable_shouldNotSetShippingMethod() async throws {
        let selected = PKShippingMethod()
        selected.identifier = "only-method"

        delegate.pkDecoder = makeStubDecoder(methods: [])
        MockURLProtocol.lastOperation = nil

        let result = await delegate.paymentAuthorizationController(
            PKPaymentAuthorizationController(paymentRequest: .testPaymentRequest),
            didSelectShippingMethod: selected
        )

        XCTAssertNil(delegate.pkEncoder.selectedShippingMethod, "Should not set shipping method when no methods available")
        XCTAssertEqual(result.status, .failure, "Should return failure status when no methods available")
    }

    func test_didSelectShippingMethod_withSelectedDeliveryOptionHandleError_shouldReturnFailureStatus() async throws {
        let shippingMethod = PKShippingMethod()
        shippingMethod.identifier = nil
        shippingMethod.label = "Method Without ID"

        let result = await delegate.paymentAuthorizationController(
            PKPaymentAuthorizationController(paymentRequest: .testPaymentRequest),
            didSelectShippingMethod: shippingMethod
        )

        XCTAssertEqual(result.status, .failure, "Should return failure status when selectedDeliveryOptionHandle.get() throws")
        XCTAssertNotNil(result.paymentSummaryItems, "Should still return payment summary items")
    }

    func test_didSelectShippingMethod_withDeliveryGroupIDError_shouldReturnFailureStatus() async throws {
        let shippingMethod = PKShippingMethod()
        shippingMethod.identifier = "nonexistent-delivery-group"
        shippingMethod.label = "Invalid Delivery Group Method"

        let result = await delegate.paymentAuthorizationController(
            PKPaymentAuthorizationController(paymentRequest: .testPaymentRequest),
            didSelectShippingMethod: shippingMethod
        )

        XCTAssertEqual(result.status, .failure, "Should return failure status when deliveryGroupID.get() throws")
        XCTAssertNotNil(result.paymentSummaryItems, "Should still return payment summary items")
    }

    func test_didSelectShippingMethod_withCartSelectedDeliveryOptionsUpdateError_shouldReturnFailureStatus() async throws {
        let shippingMethod = PKShippingMethod()
        shippingMethod.identifier = "standard-shipping"
        shippingMethod.label = "Standard Shipping"

        MockURLProtocol.failDeliveryUpdate = true
        defer { MockURLProtocol.failDeliveryUpdate = false }

        let result = await delegate.paymentAuthorizationController(
            PKPaymentAuthorizationController(paymentRequest: .testPaymentRequest),
            didSelectShippingMethod: shippingMethod
        )

        XCTAssertEqual(result.status, .failure, "Should return failure status when cartSelectedDeliveryOptionsUpdate throws")
        XCTAssertNotNil(result.paymentSummaryItems, "Should still return payment summary items")
    }

    func test_didSelectShippingMethod_withCartPrepareForCompletionError_shouldReturnFailureStatus() async throws {
        let shippingMethod = PKShippingMethod()
        shippingMethod.identifier = "standard-shipping"
        shippingMethod.label = "Standard Shipping"

        MockURLProtocol.failPrepareForCompletion = true
        defer { MockURLProtocol.failPrepareForCompletion = false }

        let result = await delegate.paymentAuthorizationController(
            PKPaymentAuthorizationController(paymentRequest: .testPaymentRequest),
            didSelectShippingMethod: shippingMethod
        )

        XCTAssertEqual(result.status, .failure, "Should return failure status when cartPrepareForCompletion throws")
        XCTAssertNotNil(result.paymentSummaryItems, "Should still return payment summary items")
    }

    func test_didSelectShippingMethod_withMappableCartUserError_shouldMaintainSuccessStatus() async throws {
        let shippingMethod = PKShippingMethod()
        shippingMethod.identifier = "standard-shipping"
        shippingMethod.label = "Standard Shipping"

        // This tests that CartUserError(ADDRESS_FIELD_IS_REQUIRED, addresses.0.address.deliveryAddress.firstName)
        // maps to ValidationErrors.nameInvalid (PKPaymentError) which maintains success status
        MockURLProtocol.returnMappableCartUserError = true
        defer { MockURLProtocol.returnMappableCartUserError = false }

        let result = await delegate.paymentAuthorizationController(
            PKPaymentAuthorizationController(paymentRequest: .testPaymentRequest),
            didSelectShippingMethod: shippingMethod
        )

        XCTAssertEqual(result.status, .success, "Should maintain success status when CartUserError maps to PKPaymentError")
        XCTAssertNotNil(result.paymentSummaryItems, "Should return payment summary items")
        XCTAssertTrue(result.errors.isEmpty, "Should not errors")
    }

    func test_didSelectShippingMethod_withSetCartError_shouldReturnFailureStatus() async throws {
        let shippingMethod = PKShippingMethod()
        shippingMethod.identifier = "standard-shipping"
        shippingMethod.label = "Standard Shipping"

        MockURLProtocol.returnInvalidCart = true
        defer { MockURLProtocol.returnInvalidCart = false }

        let result = await delegate.paymentAuthorizationController(
            PKPaymentAuthorizationController(paymentRequest: .testPaymentRequest),
            didSelectShippingMethod: shippingMethod
        )

        XCTAssertEqual(result.status, .failure, "Should return failure status when setCart throws")
        XCTAssertNotNil(result.paymentSummaryItems, "Should still return payment summary items")
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
        var storefront: StorefrontAPIProtocol
        var storefrontJulyRelease: StorefrontAPIProtocol

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
            "\"deliveryGroups\":{\"nodes\":[{" +
            "\"id\":\"gid://shopify/CartDeliveryGroup/1\"," +
            "\"groupType\":\"ONE_TIME_PURCHASE\"," +
            "\"deliveryOptions\":[{" +
            "\"handle\":\"standard-shipping\"," +
            "\"title\":\"Standard Shipping\"," +
            "\"code\":\"STANDARD\"," +
            "\"deliveryMethodType\":\"SHIPPING\"," +
            "\"description\":\"5-7 business days\"," +
            "\"estimatedCost\":{\"amount\":\"5.00\",\"currencyCode\":\"USD\"}" +
            "}]," +
            "\"selectedDeliveryOption\":null" +
            "}]}," +
            "\"delivery\":null," +
            "\"lines\":{\"nodes\":[]}," +
            "\"cost\":{\"totalAmount\":{\"amount\":\"0.00\",\"currencyCode\":\"USD\"}}," +
            "\"discountCodes\":[],\"discountAllocations\":[]}"

        static let mockCartWithAddressResponse: String = "{" +
            "\"id\":\"gid://shopify/Cart/test\"," +
            "\"checkoutUrl\":\"https://stub/checkout\"," +
            "\"totalQuantity\":0," +
            "\"buyerIdentity\":null," +
            "\"deliveryGroups\":{\"nodes\":[{" +
            "\"id\":\"gid://shopify/CartDeliveryGroup/1\"," +
            "\"groupType\":\"ONE_TIME_PURCHASE\"," +
            "\"deliveryOptions\":[{" +
            "\"handle\":\"standard-shipping\"," +
            "\"title\":\"Standard Shipping\"," +
            "\"code\":\"STANDARD\"," +
            "\"deliveryMethodType\":\"SHIPPING\"," +
            "\"description\":\"5-7 business days\"," +
            "\"estimatedCost\":{\"amount\":\"5.00\",\"currencyCode\":\"USD\"}" +
            "}]," +
            "\"selectedDeliveryOption\":null" +
            "}]}," +
            "\"delivery\":{\"addresses\":[{\"id\":\"gid://shopify/CartSelectableAddress/1\",\"selected\":true,\"address\":{\"countryCode\":\"US\"}}]}," +
            "\"lines\":{\"nodes\":[]}," +
            "\"cost\":{\"totalAmount\":{\"amount\":\"0.00\",\"currencyCode\":\"USD\"}}," +
            "\"discountCodes\":[],\"discountAllocations\":[]}"

        static var failRemove = false
        static var failAdd = false
        static var failDeliveryUpdate = false
        static var failPrepareForCompletion = false
        static var returnMappableCartUserError = false
        static var returnInvalidCart = false
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
            let op = ops.first { bodyStr.contains($0) } ?? {
                // Fallback: if returnMappableCartUserError is true, assume it's cartSelectedDeliveryOptionsUpdate
                if Self.returnMappableCartUserError {
                    return "cartSelectedDeliveryOptionsUpdate"
                }
                return "cartDeliveryAddressesAdd"
            }()
            Self.lastOperation = op

            let shouldFail = (op == "cartDeliveryAddressesRemove" && Self.failRemove) ||
                (op == "cartDeliveryAddressesAdd" && Self.failAdd) ||
                (op == "cartSelectedDeliveryOptionsUpdate" && Self.failDeliveryUpdate) ||
                (op == "cartPrepareForCompletion" && Self.failPrepareForCompletion)
            let data: Data
            if shouldFail {
                let errorJSON = "{\"data\":{\"\(op)\":{\"cart\":null,\"userErrors\":[{\"message\":\"fail\"}]}}}"
                data = Data(errorJSON.utf8)
            } else if Self.returnMappableCartUserError, op == "cartSelectedDeliveryOptionsUpdate" {
                data = Self.responseWithCartUserError(operation: op, errorCode: "INVALID")
            } else if Self.returnInvalidCart {
                let invalidCartJSON = "{\"data\":{\"\(op)\":{\"cart\":{\"invalid\":\"structure\"},\"userErrors\":[]}}}"
                data = Data(invalidCartJSON.utf8)
            } else {
                data = Self.response(for: op)
            }
            let resp = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            client?.urlProtocol(self, didReceive: resp, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        }

        override func stopLoading() {}
        static func reset() {
            lastOperation = nil
            failRemove = false
            failAdd = false
            failDeliveryUpdate = false
            failPrepareForCompletion = false
            returnMappableCartUserError = false
            returnInvalidCart = false
        }

        static func responseWithCartUserError(operation: String, errorCode _: String) -> Data {
            let json = "{" +
                "\"data\":{\"" + operation + "\":{\"cart\": " + mockCartResponse + "," +
                "\"userErrors\":[{\"field\":[\"addresses\",\"0\",\"address\",\"deliveryAddress\",\"firstName\"],\"message\":\"First name is invalid\",\"code\":\"ADDRESS_FIELD_IS_REQUIRED\"}]}}}"
            return Data(json.utf8)
        }
    }
}
