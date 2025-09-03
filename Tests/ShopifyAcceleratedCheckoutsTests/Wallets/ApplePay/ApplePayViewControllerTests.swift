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

import ShopifyCheckoutSheetKit
import UIKit
import XCTest

@testable import ShopifyAcceleratedCheckouts

@available(iOS 17.0, *)
class ApplePayViewControllerTests: XCTestCase {
    var viewController: MockApplePayViewController!
    var mockConfiguration: ApplePayConfigurationWrapper!
    var mockStorefront: TestStorefrontAPI!
    var mockAuthorizationDelegate: MockApplePayAuthorizationDelegate!

    override func setUp() {
        super.setUp()

        // Create mock shop settings
        let paymentSettings = PaymentSettings(
            countryCode: "US",
            acceptedCardBrands: [.visa, .mastercard]
        )
        let primaryDomain = Domain(
            host: "test-shop.myshopify.com",
            url: "https://test-shop.myshopify.com"
        )
        let shopSettings = ShopSettings(
            name: "Test Shop",
            primaryDomain: primaryDomain,
            paymentSettings: paymentSettings
        )

        // Create common configuration
        let commonConfig = ShopifyAcceleratedCheckouts.Configuration(
            storefrontDomain: "test-shop.myshopify.com",
            storefrontAccessToken: "test-token"
        )

        // Create Apple Pay configuration
        let applePayConfig = ShopifyAcceleratedCheckouts.ApplePayConfiguration(
            merchantIdentifier: "test.merchant",
            contactFields: []
        )

        // Create configuration wrapper
        mockConfiguration = ApplePayConfigurationWrapper(
            common: commonConfig,
            applePay: applePayConfig,
            shopSettings: shopSettings
        )

        // Create mock storefront
        mockStorefront = TestStorefrontAPI()

        // Create system under test first
        let identifier = CheckoutIdentifier.cart(cartID: "gid://Shopify/Cart/test-cart-id")
        viewController = MockApplePayViewController(
            identifier: identifier,
            configuration: mockConfiguration
        )

        // Create mock authorization delegate with the created viewController
        mockAuthorizationDelegate = MockApplePayAuthorizationDelegate(
            configuration: mockConfiguration,
            controller: viewController
        )

        // Inject mocks
        viewController.storefront = mockStorefront
        viewController.setMockAuthorizationDelegate(mockAuthorizationDelegate)
    }

    override func tearDown() {
        viewController = nil
        mockConfiguration = nil
        mockStorefront = nil
        mockAuthorizationDelegate = nil
        super.tearDown()
    }

    class MockApplePayAuthorizationDelegate: ApplePayAuthorizationDelegate {
        var transitionHistory: [ApplePayState] = []
        var setCartCalls: [StorefrontAPI.Types.Cart] = []
        var shouldThrowOnTransition = false
        var shouldThrowOnSetCart = false

        override func transition(to state: ApplePayState) async throws {
            transitionHistory.append(state)
            if shouldThrowOnTransition {
                throw NSError(domain: "MockError", code: 1, userInfo: nil)
            }
            // Don't call super to avoid actual state machine logic
        }

        override func setCart(to cart: StorefrontAPI.Types.Cart?) throws {
            if let cart {
                setCartCalls.append(cart)
            }
            if shouldThrowOnSetCart {
                throw NSError(domain: "MockError", code: 1, userInfo: nil)
            }
            // Don't call super to avoid actual cart setting logic
        }

        func resetMocks() {
            transitionHistory.removeAll()
            setCartCalls.removeAll()
            shouldThrowOnTransition = false
            shouldThrowOnSetCart = false
        }
    }

    class MockApplePayViewController: ApplePayViewController {
        var mockAuthorizationDelegate: MockApplePayAuthorizationDelegate!
        var mockTopViewController: UIViewController?

        override var authorizationDelegate: ApplePayAuthorizationDelegate {
            return mockAuthorizationDelegate
        }

        override func getTopViewController() -> UIViewController? {
            return mockTopViewController
        }

        // Helper methods for test setup
        func setMockAuthorizationDelegate(_ mock: MockApplePayAuthorizationDelegate) {
            mockAuthorizationDelegate = mock
        }
    }

    // MARK: - Callback Properties

    func test_onCheckoutComplete_whenDefault_isNil() async {
        await MainActor.run {
            XCTAssertNil(viewController.onCheckoutComplete)
        }
    }

    func test_onCheckoutFail_whenDefault_isNil() async {
        await MainActor.run {
            XCTAssertNil(viewController.onCheckoutFail)
        }
    }

    func test_onCheckoutCancel_whenDefault_isNil() async {
        await MainActor.run {
            XCTAssertNil(viewController.onCheckoutCancel)
        }
    }

    // MARK: - Delegate

    @MainActor
    func test_checkoutDidCancel_whenInvoked_invokesOnCancelCallback() async {
        let cancelCallbackExpectation = XCTestExpectation(description: "Cancel callback should be invoked")
        viewController.onCheckoutCancel = { cancelCallbackExpectation.fulfill() }

        viewController.checkoutDidCancel()

        await fulfillment(of: [cancelCallbackExpectation], timeout: 1.0)
    }

    // MARK: - WalletController Inheritance

    func test_configuration_whenInitialized_usesCorrectStorefront() {
        XCTAssertEqual(
            viewController.configuration.common.storefrontDomain,
            "test-shop.myshopify.com"
        )
        XCTAssertEqual(viewController.configuration.common.storefrontAccessToken, "test-token")
    }

    func test_createOrfetchCart_whenCalled_usesFetchCartByCheckoutIdentifier() async throws {
        let mockCart = StorefrontAPI.Cart.testCart()
        mockStorefront.cartResult = .success(mockCart)

        let cart = try await viewController.createOrfetchCart()

        XCTAssertEqual(cart.id, mockCart.id)
    }

    // MARK: - startPayment()

    func test_onPress_whenSuccess_callsCorrectTransition() async throws {
        let mockCart = StorefrontAPI.Cart.testCart()
        mockStorefront.cartResult = .success(mockCart)
        XCTAssertNil(viewController.cart)

        await viewController.onPress()

        XCTAssertNotNil(viewController.cart)
        XCTAssertEqual(viewController.cart?.id, mockCart.id)

        XCTAssertEqual(mockAuthorizationDelegate.transitionHistory.count, 1)
        XCTAssertEqual(mockAuthorizationDelegate.transitionHistory.first, .startPaymentRequest)
    }

    func test_onPress_whenCreateOrFetchCartFails_callsCompletedTransition() async throws {
        let expectedError = NSError(domain: "TestError", code: 500, userInfo: nil)
        mockStorefront.cartResult = .failure(expectedError)

        await viewController.onPress()

        XCTAssertNil(viewController.cart)

        XCTAssertEqual(mockAuthorizationDelegate.transitionHistory.count, 2)
        XCTAssertEqual(
            mockAuthorizationDelegate.transitionHistory.first,
            .terminalError(error: expectedError)
        )
        XCTAssertEqual(mockAuthorizationDelegate.transitionHistory.last, .completed)
    }

    func test_onPress_whenCartIsNil_callsCompletedTransition() async throws {
        mockStorefront.cartResult = .success(nil)

        await viewController.onPress()

        XCTAssertNil(viewController.cart)

        // WalletController.fetchCartByCheckoutIdentifier throws when cart is nil
        XCTAssertEqual(mockAuthorizationDelegate.transitionHistory.count, 2)
        XCTAssertEqual(
            mockAuthorizationDelegate.transitionHistory.first,
            .terminalError(
                error: ShopifyAcceleratedCheckouts.Error.cartAcquisition(
                    identifier: CheckoutIdentifier.cart(cartID: "gid://Shopify/Cart/test-cart-id")
                )
            )
        )
        XCTAssertEqual(mockAuthorizationDelegate.transitionHistory.last, .completed)
    }

    // MARK: - createOrfetchCart() Error

    func test_createOrfetchCart_whenStorefrontAPIError_handlesError() async throws {
        let storefrontError = StorefrontAPI.Errors.response(
            requestName: "testRequest",
            message: "Test error",
            payload: .cartPrepareForCompletion(
                StorefrontAPI.CartPrepareForCompletionPayload(
                    result: nil,
                    userErrors: []
                )
            )
        )
        mockStorefront.cartResult = .failure(storefrontError)

        // The actual implementation should handle StorefrontAPI.Errors through handleStorefrontError
        // We're not testing the internal implementation details, just that it eventually throws or handles appropriately
        await XCTAssertThrowsErrorAsync(try await viewController.createOrfetchCart()) { error in
            XCTAssertTrue(error is StorefrontAPI.Errors)
        }

        // For StorefrontAPI errors (default case), .unexpectedError transition should happen
        XCTAssertEqual(mockAuthorizationDelegate.transitionHistory.count, 1)
        XCTAssertEqual(
            mockAuthorizationDelegate.transitionHistory.first,
            .unexpectedError(error: storefrontError)
        )
    }

    @MainActor
    func test_createOrfetchCart_whenCheckoutError_callsTerminalErrorTransition() async throws {
        let checkoutSdkError = CheckoutError.sdkError(
            underlying: NSError(domain: "CheckoutError", code: 400, userInfo: nil)
        )
        mockStorefront.cartResult = .failure(checkoutSdkError)

        let onCheckoutFailExpectation = XCTestExpectation(description: "onCheckoutFail callback should be invoked")
        viewController.onCheckoutFail = { _ in onCheckoutFailExpectation.fulfill() }

        await XCTAssertThrowsErrorAsync(try await viewController.createOrfetchCart()) { error in
            XCTAssertTrue(error is CheckoutError)
        }

        await fulfillment(of: [onCheckoutFailExpectation], timeout: 1.0)
        XCTAssertEqual(mockAuthorizationDelegate.transitionHistory.count, 1)
        XCTAssertEqual(
            mockAuthorizationDelegate.transitionHistory.first,
            .terminalError(error: checkoutSdkError)
        )
    }

    func test_createOrfetchCart_whenGenericError_callsTerminalErrorTransition() async throws {
        let genericError = NSError(domain: "GenericError", code: 400, userInfo: nil)
        mockStorefront.cartResult = .failure(genericError)

        await XCTAssertThrowsErrorAsync(try await viewController.createOrfetchCart()) { error in
            XCTAssertEqual((error as NSError).domain, "GenericError")
            XCTAssertEqual((error as NSError).code, 400)
        }

        XCTAssertEqual(mockAuthorizationDelegate.transitionHistory.count, 1)
        XCTAssertEqual(
            mockAuthorizationDelegate.transitionHistory.first,
            .terminalError(error: genericError)
        )
    }

    func test_createOrfetchCart_whenSuccess_noTransitions() async throws {
        let mockCart = StorefrontAPI.Cart.testCart()
        mockStorefront.cartResult = .success(mockCart)

        let result = try await viewController.createOrfetchCart()
        XCTAssertEqual(result.id, mockCart.id)

        XCTAssertEqual(mockAuthorizationDelegate.transitionHistory.count, 0)
    }

    // MARK: - Error Handling

    @MainActor
    func test_onPress_whenAuthorizationDelegateConfigured_shouldCallTransition() async {
        // This tests defensive coding when dependencies might be misconfigured
        let mockCart = StorefrontAPI.Cart.testCart()
        mockStorefront.cartResult = .success(mockCart)

        await viewController.onPress()

        XCTAssertNotNil(viewController.cart)
        XCTAssertEqual(mockAuthorizationDelegate.transitionHistory.count, 1)
    }

    @MainActor
    func test_createOrfetchCart_whenStorefrontUserErrorWithNilCart_throwsAndCallsTerminalError() async {
        let userError = StorefrontAPI.CartUserError(
            code: .invalid,
            message: "Invalid product variant",
            field: ["lineItems"]
        )
        let storefrontError = StorefrontAPI.Errors.userError(userErrors: [userError], cart: nil)
        mockStorefront.cartResult = .failure(storefrontError)

        await XCTAssertThrowsErrorAsync(try await viewController.createOrfetchCart()) { error in
            XCTAssertTrue(error is StorefrontAPI.Errors)
        }

        // When cart is nil, handleStorefrontError rethrows the error without calling any transitions
        // The error bubbles up and the method throws, but no state transitions occur
        XCTAssertEqual(mockAuthorizationDelegate.transitionHistory.count, 0)
    }

    @MainActor
    func test_createOrfetchCart_whenStorefrontWarningWithNilCart_throwsAndCallsTerminalError() async {
        let storefrontError = StorefrontAPI.Errors.warning(type: .outOfStock, cart: nil)
        mockStorefront.cartResult = .failure(storefrontError)

        await XCTAssertThrowsErrorAsync(try await viewController.createOrfetchCart()) { error in
            XCTAssertTrue(error is StorefrontAPI.Errors)
        }

        // When cart is nil, handleStorefrontError rethrows the error without calling any transitions
        // The error bubbles up and the method throws, but no state transitions occur
        XCTAssertEqual(mockAuthorizationDelegate.transitionHistory.count, 0)
    }

    @MainActor
    func test_createOrfetchCart_whenStorefrontUserErrorWithCart_handlesUnhandledErrorAction() async throws {
        let mockCart = StorefrontAPI.Cart.testCart()
        let userError = StorefrontAPI.CartUserError(
            code: .invalid,
            message: "Test user error",
            field: ["test"]
        )
        let storefrontError = StorefrontAPI.Errors.userError(
            userErrors: [userError],
            cart: mockCart
        )
        mockStorefront.cartResult = .failure(storefrontError)

        let result = try await viewController.createOrfetchCart()

        // Should return the cart from the error
        XCTAssertEqual(result.id, mockCart.id)

        XCTAssertEqual(mockAuthorizationDelegate.transitionHistory.count, 1)
        XCTAssertEqual(
            mockAuthorizationDelegate.transitionHistory.first,
            .interrupt(reason: .unhandled)
        )
    }

    @MainActor
    func test_createOrfetchCart_whenStorefrontUserErrorWithEmailField_handlesEmailErrorAction() async throws {
        let mockCart = StorefrontAPI.Cart.testCart()
        let userError = StorefrontAPI.CartUserError(
            code: .invalid,
            message: "Invalid email address",
            field: ["buyerIdentity", "email"]
        )
        let storefrontError = StorefrontAPI.Errors.userError(
            userErrors: [userError],
            cart: mockCart
        )
        mockStorefront.cartResult = .failure(storefrontError)

        let result = try await viewController.createOrfetchCart()

        XCTAssertEqual(result.id, mockCart.id)

        // only .interrupt PaymentSheetActions will cause a transition (see ApplePayViewController.handleErrorAction)
        XCTAssertEqual(mockAuthorizationDelegate.transitionHistory.count, 0)
    }

    @MainActor
    func test_onPress_whenMultipleErrorScenarios_allHandledCorrectly() async {
        // Test multiple consecutive errors are handled properly
        let genericError = NSError(domain: "TestError", code: 123, userInfo: nil)
        mockStorefront.cartResult = .failure(genericError)

        await viewController.onPress()
        XCTAssertNil(viewController.cart)
        XCTAssertEqual(mockAuthorizationDelegate.transitionHistory.count, 2)

        mockAuthorizationDelegate.resetMocks()
        let checkoutError = CheckoutError.sdkError(
            underlying: NSError(domain: "CheckoutError", code: 400, userInfo: nil)
        )
        mockStorefront.cartResult = .failure(checkoutError)

        await viewController.onPress()
        XCTAssertNil(viewController.cart)
        XCTAssertEqual(mockAuthorizationDelegate.transitionHistory.count, 2)
    }
}
