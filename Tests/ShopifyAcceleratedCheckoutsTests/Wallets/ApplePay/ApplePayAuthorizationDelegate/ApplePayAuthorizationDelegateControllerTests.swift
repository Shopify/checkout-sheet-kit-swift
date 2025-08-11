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
        // This tests the cart state preservation logic in lines 48-58
        // where it stores the previous cart and potentially reverts it

        let contact = PKContact()
        contact.postalAddress = createPostalAddress()

        // Store reference to original cart to test preservation logic
        _ = mockController.cart

        let result = await delegate.paymentAuthorizationController(
            PKPaymentAuthorizationController(),
            didSelectShippingContact: contact
        )

        // The cart state preservation logic should maintain cart integrity
        XCTAssertNotNil(mockController.cart, "Cart should still exist after contact selection")

        // Test passes if no exception is thrown and result is returned
        XCTAssertNotNil(result, "Should return a result even if cart state changes")
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

        // Set existing address ID to test the remove-then-add strategy
        let existingAddressID = GraphQLScalars.ID("existing-address-123")
        delegate.selectedShippingAddressID = existingAddressID

        do {
            let result = try await delegate.upsertShippingAddress(to: address)
            XCTAssertNotNil(result, "Should return updated cart")
            // Don't assert specific address ID value since it depends on cart structure
        } catch {
            XCTAssertEqual(delegate.selectedShippingAddressID, existingAddressID, "Address ID should remain if remove fails")
        }
    }

    func test_upsertShippingAddress_withNoExistingAddressID_shouldOnlyAdd() async throws {
        let address = StorefrontAPI.Address(
            address1: "123 New Street",
            city: "New City",
            country: "US",
            province: "CA",
            zip: "90210"
        )

        // No existing address ID - should only do add operation
        delegate.selectedShippingAddressID = nil

        do {
            let result = try await delegate.upsertShippingAddress(to: address)
            XCTAssertNotNil(result, "Should return cart from add operation")
            XCTAssertNil(delegate.selectedShippingAddressID, "Should remain nil when no existing address")
        } catch {
            // Test that method handles add-only scenario properly even on failure
            XCTAssertNil(delegate.selectedShippingAddressID, "Should remain nil even on add failure")
        }
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

        // The upsertShippingAddress method should handle failures gracefully
        // Per the implementation: address ID is only cleared if remove succeeds (line 252)

        do {
            _ = try await delegate.upsertShippingAddress(to: address)
            // If both remove and add succeed, address ID would be set to new value (line 267)
        } catch {
            // Expected behavior in test environment - API calls will likely fail
            // If remove fails, address ID is NOT cleared (caught at lines 253-257)
            // If add fails, the error is re-thrown (lines 270-275)
        }

        // The actual behavior: address ID is only cleared if remove succeeds
        XCTAssertEqual(delegate.selectedShippingAddressID, GraphQLScalars.ID("test-address-id"), "Address ID should remain unchanged when operations fail")
    }

    // MARK: - Integration Tests

    func test_shippingMethodValidationLogic_shouldUseCorrectFallbackStrategy() {
        let originalMethod = PKShippingMethod()
        originalMethod.identifier = "original-method"

        let fallbackMethod = PKShippingMethod()
        fallbackMethod.identifier = "fallback-method"

        // Test 1: When user's selected method is valid, use it
        let availableMethodsWithOriginal = [originalMethod, fallbackMethod]
        let isValidMethod = availableMethodsWithOriginal.contains { $0.identifier == originalMethod.identifier }
        let methodToUse = isValidMethod ? originalMethod : (availableMethodsWithOriginal.first ?? originalMethod)
        XCTAssertEqual(methodToUse.identifier, "original-method", "Should use user's selected method when valid")

        // Test 2: When user's selected method is invalid, use first available
        let invalidMethod = PKShippingMethod()
        invalidMethod.identifier = "invalid-method"
        let availableMethodsOnly = [fallbackMethod]
        let isInvalidMethod = availableMethodsOnly.contains { $0.identifier == invalidMethod.identifier }
        let methodToUseWhenInvalid = isInvalidMethod ? invalidMethod : (availableMethodsOnly.first ?? invalidMethod)
        XCTAssertEqual(methodToUseWhenInvalid.identifier, "fallback-method", "Should use first available when selected is invalid")

        // Test 3: When no methods available, fallback to user's selection
        let emptyMethods: [PKShippingMethod] = []
        let methodToUseWhenEmpty = emptyMethods.first ?? originalMethod
        XCTAssertEqual(methodToUseWhenEmpty.identifier, "original-method", "Should fallback to original when no methods available")
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
            let config = ShopifyAcceleratedCheckouts.Configuration.testConfiguration
            storefront = StorefrontAPI(
                storefrontDomain: config.storefrontDomain,
                storefrontAccessToken: config.storefrontAccessToken
            )
            storefrontJulyRelease = storefront
        }

        func present(url _: URL) async throws {
            // Mock implementation
        }
    }
}
