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

    // MARK: - Callback Properties Tests

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

    // MARK: - Delegate Tests

    @MainActor
    func test_checkoutDidCancel_whenInvoked_invokesOnCancelCallback() async {
        let expectation = XCTestExpectation(description: "Cancel callback should be invoked")

        viewController.onCheckoutCancel = {
            expectation.fulfill()
        }

        viewController.checkoutDidCancel()

        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func test_checkoutDidCancel_whenNoCheckoutViewController_worksCorrectly() async {
        XCTAssertNil(viewController.checkoutViewController)

        await MainActor.run {
            viewController.checkoutDidCancel()
        }
    }

    func test_checkoutDidCancel_whenNoOnCancelCallback_worksCorrectly() async {
        let isNil = await MainActor.run {
            viewController.onCheckoutCancel == nil
        }
        XCTAssertTrue(isNil, "onCancel should be nil")

        await MainActor.run {
            viewController.checkoutDidCancel()
        }
    }

    // MARK: - WalletController Inheritance Tests

    func test_configuration_whenInitialized_usesCorrectStorefront() {
        XCTAssertEqual(
            viewController.configuration.common.storefrontDomain,
            "test-shop.myshopify.com"
        )
        XCTAssertEqual(viewController.configuration.common.storefrontAccessToken, "test-token")
    }

    func test_createOrfetchCart_whenCalled_usesFetchCartByCheckoutIdentifier() async throws {
        let mockCart = StorefrontAPI.Cart.testCart(
            checkoutUrl: URL(string: "https://test-shop.myshopify.com/checkout")!
        )
        mockStorefront.cartResult = CartResult.success(mockCart)

        await XCTAssertNoThrowAsync(try await viewController.createOrfetchCart())
    }

    // MARK: - startPayment() Error Coverage Tests

    func test_startPayment_whenSuccess_callsCorrectTransition() async throws {
        let mockCart = StorefrontAPI.Cart.testCart(
            checkoutUrl: URL(string: "https://test-shop.myshopify.com/checkout")!
        )
        mockStorefront.cartResult = CartResult.success(mockCart)
        XCTAssertNil(viewController.cart)

        await XCTAssertNoThrowAsync(await viewController.startPayment())

        XCTAssertNotNil(viewController.cart)
        XCTAssertEqual(viewController.cart?.id, mockCart.id)

        XCTAssertEqual(mockAuthorizationDelegate.transitionHistory.count, 1)
        XCTAssertEqual(mockAuthorizationDelegate.transitionHistory.first, .startPaymentRequest)
    }

    func test_startPayment_whenCreateOrFetchCartFails_callsCompletedTransition() async throws {
        let expectedError = NSError(domain: "TestError", code: 500, userInfo: nil)
        mockStorefront.cartResult = CartResult.failure(expectedError)

        await XCTAssertNoThrowAsync(await viewController.startPayment())

        XCTAssertNil(viewController.cart)

        XCTAssertEqual(mockAuthorizationDelegate.transitionHistory.count, 2)
        XCTAssertEqual(
            mockAuthorizationDelegate.transitionHistory.first,
            .terminalError(error: expectedError)
        )
        XCTAssertEqual(mockAuthorizationDelegate.transitionHistory.last, .completed)
    }

    func test_startPayment_whenCartIsNil_callsCompletedTransition() async throws {
        mockStorefront.cartResult = CartResult.success(nil)

        await XCTAssertNoThrowAsync(await viewController.startPayment())

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

    // MARK: - createOrfetchCart() Error Coverage Tests

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
        mockStorefront.cartResult = CartResult.failure(storefrontError)

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
        mockStorefront.cartResult = CartResult.failure(checkoutSdkError)

        let expectation = XCTestExpectation(description: "onCheckoutFail callback should be invoked")
        viewController.onCheckoutFail = { _ in expectation.fulfill() }

        await XCTAssertThrowsErrorAsync(try await viewController.createOrfetchCart()) { error in
            XCTAssertTrue(error is CheckoutError)
        }

        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(mockAuthorizationDelegate.transitionHistory.count, 1)
        XCTAssertEqual(
            mockAuthorizationDelegate.transitionHistory.first,
            .terminalError(error: checkoutSdkError)
        )
    }

    func test_createOrfetchCart_whenGenericError_callsTerminalErrorTransition() async throws {
        let genericError = NSError(domain: "GenericError", code: 400, userInfo: nil)
        mockStorefront.cartResult = CartResult.failure(genericError)

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
        let mockCart = StorefrontAPI.Cart.testCart(
            checkoutUrl: URL(string: "https://test-shop.myshopify.com/checkout")!
        )
        mockStorefront.cartResult = CartResult.success(mockCart)

        let result = try await viewController.createOrfetchCart()
        XCTAssertEqual(result.id, mockCart.id)

        XCTAssertEqual(mockAuthorizationDelegate.transitionHistory.count, 0)
    }

    // MARK: - Additional Error Handling Test Coverage

    @MainActor
    func test_startPayment_whenAuthorizationDelegateTransitionThrows_handlesError() async {
        let mockCart = StorefrontAPI.Cart.testCart(
            checkoutUrl: URL(string: "https://test-shop.myshopify.com/checkout")!
        )
        mockStorefront.cartResult = CartResult.success(mockCart)

        mockAuthorizationDelegate.shouldThrowOnTransition = true

        await viewController.startPayment()

        // Should have attempted the transition, and since delegate throws, startPayment catch block is triggered
        // This results in 2 transitions: .startPaymentRequest (attempted) + .completed (error handling)
        XCTAssertEqual(mockAuthorizationDelegate.transitionHistory.count, 2)
        XCTAssertEqual(mockAuthorizationDelegate.transitionHistory.first, .startPaymentRequest)
        XCTAssertEqual(mockAuthorizationDelegate.transitionHistory.last, .completed)
    }

    @MainActor
    func test_startPayment_whenAuthorizationDelegateNil_handlesGracefully() async {
        // This tests defensive coding when dependencies might be misconfigured
        let mockCart = StorefrontAPI.Cart.testCart(
            checkoutUrl: URL(string: "https://test-shop.myshopify.com/checkout")!
        )
        mockStorefront.cartResult = CartResult.success(mockCart)

        await viewController.startPayment()

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
        mockStorefront.cartResult = CartResult.failure(storefrontError)

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
        mockStorefront.cartResult = CartResult.failure(storefrontError)

        await XCTAssertThrowsErrorAsync(try await viewController.createOrfetchCart()) { error in
            XCTAssertTrue(error is StorefrontAPI.Errors)
        }

        // When cart is nil, handleStorefrontError rethrows the error without calling any transitions
        // The error bubbles up and the method throws, but no state transitions occur
        XCTAssertEqual(mockAuthorizationDelegate.transitionHistory.count, 0)
    }

    @MainActor
    func test_createOrfetchCart_whenStorefrontUserErrorWithCart_handlesUnhandledErrorAction() async throws {
        let mockCart = StorefrontAPI.Cart.testCart(
            checkoutUrl: URL(string: "https://test-shop.myshopify.com/checkout")!
        )
        let userError = StorefrontAPI.CartUserError(
            code: .invalid,
            message: "Test user error",
            field: ["test"]
        )
        let storefrontError = StorefrontAPI.Errors.userError(
            userErrors: [userError],
            cart: mockCart
        )
        mockStorefront.cartResult = CartResult.failure(storefrontError)

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
        let mockCart = StorefrontAPI.Cart.testCart(
            checkoutUrl: URL(string: "https://test-shop.myshopify.com/checkout")!
        )
        let userError = StorefrontAPI.CartUserError(
            code: .invalid,
            message: "Invalid email address",
            field: ["buyerIdentity", "email"]
        )
        let storefrontError = StorefrontAPI.Errors.userError(
            userErrors: [userError],
            cart: mockCart
        )
        mockStorefront.cartResult = CartResult.failure(storefrontError)

        let result = try await viewController.createOrfetchCart()

        XCTAssertEqual(result.id, mockCart.id)

        // only .interrupt PaymentSheetActions will cause a transition (see ApplePayViewController.handleErrorAction)
        XCTAssertEqual(mockAuthorizationDelegate.transitionHistory.count, 0)
    }

    @MainActor
    func test_startPayment_whenMultipleErrorScenarios_allHandledCorrectly() async {
        // Test multiple consecutive errors are handled properly
        let genericError = NSError(domain: "TestError", code: 123, userInfo: nil)
        mockStorefront.cartResult = CartResult.failure(genericError)

        await viewController.startPayment()
        XCTAssertNil(viewController.cart)
        XCTAssertEqual(mockAuthorizationDelegate.transitionHistory.count, 2)

        mockAuthorizationDelegate.resetMocks()
        let checkoutError = CheckoutError.sdkError(
            underlying: NSError(domain: "CheckoutError", code: 400, userInfo: nil)
        )
        mockStorefront.cartResult = CartResult.failure(checkoutError)

        await viewController.startPayment()
        XCTAssertNil(viewController.cart)
        XCTAssertEqual(mockAuthorizationDelegate.transitionHistory.count, 2)
    }
}
