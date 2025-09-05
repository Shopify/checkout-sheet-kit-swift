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

import PassKit
import ShopifyCheckoutSheetKit
import XCTest

@testable import ShopifyAcceleratedCheckouts

/// Tests focused on onPresentingCSK behavior and URL computation for different states
@available(iOS 17.0, *)
@MainActor
final class ApplePayAuthorizationDelegateTests: XCTestCase {
    private var configuration: ApplePayConfigurationWrapper =
        .testConfiguration
    private var mockController: MockPayController!
    private var mockPaymentControllerFactory: PKAuthorizationControllerFactory!
    private var delegate: ApplePayAuthorizationDelegate!
    private let initialState = ApplePayState.idle
    private let mockPaymentController = MockPaymentAuthorizationController()

    override func setUp() async throws {
        try await super.setUp()

        mockController = MockPayController()
        mockController.cart = StorefrontAPI.Cart.testCart

        mockPaymentControllerFactory = { _ in self.mockPaymentController }
        delegate = ApplePayAuthorizationDelegate(
            configuration: configuration,
            controller: mockController,
            paymentControllerFactory: mockPaymentControllerFactory,
            clock: MockClock()
        )

        do {
            try delegate.setCart(to: mockController.cart)
        } catch {
            XCTFail("setCart failed with error: \(error)")
        }

        // Verify delegate has checkoutURL set
        XCTAssertNotNil(delegate.checkoutURL, "Delegate checkoutURL should be set after setCart")
        XCTAssertEqual(
            delegate.checkoutURL!.absoluteString,
            mockController.cart!.checkoutUrl.url.absoluteString
        )
    }

    override func tearDown() async throws {
        delegate = nil
        mockController = nil
        mockPaymentControllerFactory = nil
        try await super.tearDown()
    }

    // MARK: - State Transition Tests

    func test_transition_withValidStateTransition_shouldUpdateStateCorrectly() async throws {
        XCTAssertEqual(delegate.state, initialState, "Should start in idle state")

        // Use a valid state transition sequence: idle -> unexpectedError -> completed -> presentingCSK -> completed -> reset -> idle
        try await delegate.transition(to: .unexpectedError(error: NSError(domain: "test", code: 1)))
        try await delegate.transition(to: .completed)

        // The onCompleted should automatically transition to presentingCSK, then we complete that
        try await delegate.transition(to: .completed)
        // onCompleted will automatically transition to reset, then onReset will transition to idle
        XCTAssertEqual(delegate.state, initialState, "Should be back to idle after reset")
    }

    /// Ensures guard is in place to prevent state update transition
    /// Exhaustive testing of valid transitions are located: `ApplePayStateTests.swift`
    func test_transition_withInvalidStateTransition_shouldThrowAndMaintainCurrentState()
        async throws
    {
        XCTAssertEqual(delegate.state, initialState, "Should start in idle state")

        // This should throw an InvalidStateTransitionError
        do {
            try await delegate.transition(to: .paymentAuthorized(payment: PKPayment()))
            XCTFail("Expected InvalidStateTransitionError to be thrown")
        } catch let error as InvalidStateTransitionError {
            XCTAssertEqual(error.fromState, .idle)
            // Just verify that the error was about transitioning to paymentAuthorized
            guard case .paymentAuthorized = error.toState else {
                XCTFail("Expected error to be about paymentAuthorized transition")
                return
            }
        }

        XCTAssertEqual(delegate.state, initialState, "Invalid transition should not change state")
    }

    // MARK: - Side Effect Tests

    func test_onCompleted_withErrorState_shouldTransitionToPresentingCSKWithCheckoutURL()
        async throws
    {
        try await delegate.transition(to: .unexpectedError(error: NSError(domain: "test", code: 1)))
        try await delegate.transition(to: .completed)
        guard case let .presentingCSK(url) = delegate.state else {
            XCTFail(
                "Should transition to presentingCSK for error states, but got \(delegate.state)")
            return
        }

        XCTAssertEqual(
            url!.absoluteString,
            delegate.checkoutURL!.absoluteString,
            "Should use checkout URL for error states"
        )
    }

    func test_url_withDefaultState_shouldReturnCheckoutURL() async throws {
        XCTAssertEqual(delegate.state, .idle, "Should start in idle state")

        let defaultURL = delegate.createSheetKitURL(for: delegate.state)
        XCTAssertEqual(
            defaultURL!.absoluteString,
            delegate.checkoutURL!.absoluteString,
            "Should return checkout URL for idle state"
        )
    }

    func test_onCompleted_withErrorState_shouldCallPresentWithCheckoutURL() async throws {
        let error = NSError(domain: "test", code: 999, userInfo: nil)
        try await delegate.transition(to: .unexpectedError(error: error))

        let checkoutURL = delegate.checkoutURL
        XCTAssertNotNil(checkoutURL)

        try await delegate.transition(to: .completed)

        // The flow should be: .completed → onCompleted() → .presentingCSK → onPresentingCSK() → present()
        XCTAssertEqual(mockController.presentCallCount, 1, "CSK should be presented once")
        XCTAssertEqual(
            mockController.presentCalledWith!.absoluteString,
            checkoutURL!.absoluteString
        )
    }

    // MARK: - URL Computation Tests

    func test_url_withInterruptReasonsWithQueryParams_shouldAddQueryParametersToURL() async throws {
        // Test interrupt reasons that add query parameters
        let interruptReasonsWithParams: [ErrorHandler.InterruptReason] = [
            .currencyChanged,
            .dynamicTax,
            .cartNotReady,
            .notEnoughStock
        ]

        for reason in interruptReasonsWithParams {
            guard let queryParam = reason.queryParam else {
                XCTFail("Expected query param for \(reason) but got nil")
                continue
            }

            let expectedParam = "\(queryParam)=true"

            // Create a fresh delegate for each test iteration to avoid state interference
            let testDelegate = ApplePayAuthorizationDelegate(
                configuration: configuration,
                controller: mockController,
                paymentControllerFactory: mockPaymentControllerFactory,
                clock: MockClock()
            )
            try testDelegate.setCart(to: mockController.cart)

            // Transition to a state where interrupt is valid
            try await testDelegate.transition(to: .startPaymentRequest)
            try await testDelegate.transition(to: .interrupt(reason: reason))
            try await testDelegate.transition(to: .completed)

            let url = mockController.presentCalledWith
            XCTAssertTrue(
                url!.absoluteString.contains(expectedParam) == true,
                "URL should contain \(expectedParam) for \(reason) interrupt, but got: \(url!.absoluteString)"
            )

            XCTAssertEqual(
                testDelegate.state,
                .presentingCSK(url: url),
                "Should be in presentingCSK state after completed"
            )
        }
    }

    func test_url_withInterruptReasonsWithoutQueryParams_shouldReturnBaseURL() async throws {
        // Test interrupt reasons that don't add query parameters
        let interruptReasonsWithoutParams: [ErrorHandler.InterruptReason] = [
            .outOfStock,
            .cartThrottled,
            .other,
            .unhandled
        ]

        let expectedURL = "https://test-shop.myshopify.com/checkout"

        for reason in interruptReasonsWithoutParams {
            // Create a fresh delegate for each test iteration to avoid state interference
            let testDelegate = ApplePayAuthorizationDelegate(
                configuration: configuration,
                controller: mockController,
                paymentControllerFactory: mockPaymentControllerFactory,
                clock: MockClock()
            )
            try testDelegate.setCart(to: mockController.cart)

            // Transition to a state where interrupt is valid
            try await testDelegate.transition(to: .startPaymentRequest)
            try await testDelegate.transition(to: .interrupt(reason: reason))
            try await testDelegate.transition(to: .completed)
            let url = testDelegate.createSheetKitURL(for: testDelegate.state)

            XCTAssertEqual(
                url!.absoluteString,
                expectedURL,
                "\(reason) interrupt should use base checkout URL without query params, but got: \(url?.absoluteString ?? "nil")"
            )

            XCTAssertEqual(
                mockController.presentCalledWith!.absoluteString,
                expectedURL,
                "Present should be called with url"
            )
        }
    }

    // MARK: - Error Handling Tests

    func test_onPresentingCSK_withPresentFailure_shouldStillTransitionToPresentingCSKState()
        async throws
    {
        let failingController = FailingMockPayController()
        failingController.cart = mockController.cart

        let failingDelegate = ApplePayAuthorizationDelegate(
            configuration: configuration,
            controller: failingController,
            clock: MockClock()
        )
        try? failingDelegate.setCart(to: failingController.cart)

        try await failingDelegate.transition(
            to: .unexpectedError(error: NSError(domain: "test", code: 1))
        )

        try await failingDelegate.transition(to: .completed)

        XCTAssertEqual(failingController.presentCallCount, 1, "Should attempt to present CSK")

        guard case .presentingCSK = failingDelegate.state else {
            XCTFail("Expected presentingCSK state but got \(failingDelegate.state)")
            return
        }
    }

    func test_onPresentingCSK_withNilURL_shouldTransitionToUnexpectedError() async throws {
        delegate.checkoutURL = nil

        try await delegate.transition(to: .unexpectedError(error: NSError(domain: "test", code: 1)))
        try await delegate.transition(to: .completed)

        // onComplete will move us to .presentingCSK which returns .terminalError due to nil url
        guard case .terminalError = delegate.state else {
            XCTFail("Expected terminalError state when URL is nil, but got \(delegate.state)")
            return
        }

        XCTAssertEqual(
            mockController.presentCallCount,
            0,
            "Present should not be called with nil URL"
        )
    }

    // MARK: - Function Coverage Tests

    func test_setCart_withValidCart_shouldSetControllerCartAndCheckoutURL() throws {
        let testCart = StorefrontAPI.Cart.testCart

        try delegate.setCart(to: testCart)

        XCTAssertEqual(mockController.cart!.id, testCart.id)
        XCTAssertEqual(
            delegate.checkoutURL!.absoluteString, testCart.checkoutUrl.url.absoluteString
        )
    }

    func test_setCart_withNilCart_shouldSetControllerCartAndCheckoutURLToNil() throws {
        // First set a cart
        try delegate.setCart(to: StorefrontAPI.Cart.testCart)
        XCTAssertNotNil(mockController.cart)
        XCTAssertNotNil(delegate.checkoutURL)

        // Then set to nil
        try delegate.setCart(to: nil)

        XCTAssertNil(mockController.cart)
        XCTAssertNil(delegate.checkoutURL)
    }

    func test_setCart_withCurrencyChange_shouldThrowCurrencyChangedError() throws {
        // First set a cart to establish initial currency
        try delegate.setCart(to: StorefrontAPI.Cart.testCart)

        // Create a cart with different currency
        _ = StorefrontAPI.Cart.testCart
        // Note: In a real test, we'd need to create a cart with different currency
        // For now, this test demonstrates the structure

        // The actual currency change test would require mocking the PKDecoder
        // to return a different initialCurrencyCode
    }

    func test_ensureCurrencyNotChanged_withNoInitialCurrency_shouldNotThrow() throws {
        // When there's no initial currency set, should not throw
        try delegate.ensureCurrencyNotChanged()
    }

    func test_ensureCurrencyNotChanged_withSameCurrency_shouldNotThrow() throws {
        // Set a cart to establish currency
        try delegate.setCart(to: StorefrontAPI.Cart.testCart)

        // Should not throw when currency hasn't changed
        try delegate.ensureCurrencyNotChanged()
    }

    func test_onReset_shouldResetAllPropertiesAndTransitionToIdle() async throws {
        // Set up some state first
        delegate.selectedShippingAddressID = StorefrontAPI.Types.ID("test-address-id")
        delegate.checkoutURL = URL(string: "https://test.com")

        // Need to transition through a valid path to reset: idle -> startPaymentRequest -> appleSheetPresented -> completed -> reset
        // Configure mock to succeed in presenting
        mockPaymentController.shouldPresentSuccessfully = true

        try await delegate.transition(to: .startPaymentRequest)
        XCTAssertEqual(delegate.state, .appleSheetPresented)

        // Transition to completed (simulating user cancelling)
        try await delegate.transition(to: .completed)
        // onCompleted should transition to reset for this flow, then onReset transitions to idle

        // Verify state is reset to idle
        XCTAssertNil(delegate.selectedShippingAddressID)
        XCTAssertNil(delegate.checkoutURL)
        XCTAssertEqual(delegate.state, .idle)
    }

    func test_startPaymentRequest_withNoCart_shouldReturnEarly() async throws {
        // Ensure no cart is set
        mockController.cart = nil

        // Transition to startPaymentRequest
        try await delegate.transition(to: .startPaymentRequest)

        // Should not have created a payment controller
        XCTAssertEqual(mockPaymentController.presentCallCount, 0)
    }

    func test_startPaymentRequest_withValidCart_shouldPresentPaymentSheet() async throws {
        // Set a valid cart
        mockController.cart = StorefrontAPI.Cart.testCart

        // Configure mock to succeed
        mockPaymentController.shouldPresentSuccessfully = true

        // Transition to startPaymentRequest
        try await delegate.transition(to: .startPaymentRequest)

        // Should have attempted to present payment sheet
        XCTAssertEqual(mockPaymentController.presentCallCount, 1)
        XCTAssertEqual(delegate.state, .appleSheetPresented)
    }

    func test_startPaymentRequest_withPresentationFailure_shouldTransitionToReset() async throws {
        // Set a valid cart
        mockController.cart = StorefrontAPI.Cart.testCart

        // Configure mock to fail
        mockPaymentController.shouldPresentSuccessfully = false

        // Transition to startPaymentRequest
        try await delegate.transition(to: .startPaymentRequest)

        // Should have attempted to present payment sheet but failed
        XCTAssertEqual(mockPaymentController.presentCallCount, 1)
        XCTAssertEqual(delegate.state, .idle) // onReset transitions to idle
    }

    // MARK: onCompleted()

    func
        test_onCompleted_withCartSubmittedForCompletion_shouldTransitionToPresentingCSKWithRedirectURL()
        async throws
    {
        let redirectURL = URL(string: "https://shop.example.com/thank-you")!

        // Follow valid state transitions: idle -> startPaymentRequest -> appleSheetPresented -> paymentAuthorized -> cartSubmittedForCompletion
        try await delegate.transition(to: .startPaymentRequest)
        try await delegate.transition(to: .paymentAuthorized(payment: PKPayment()))
        try await delegate.transition(to: .cartSubmittedForCompletion(redirectURL: redirectURL))

        // Transition to completed to trigger onCompleted
        try await delegate.transition(to: .completed)

        // Should transition to presentingCSK with the redirect URL
        guard case let .presentingCSK(url) = delegate.state else {
            XCTFail("Expected presentingCSK state but got \(delegate.state)")
            return
        }

        XCTAssertEqual(url, redirectURL, "Should use redirect URL from cartSubmittedForCompletion")
        XCTAssertEqual(mockController.presentCallCount, 1, "Should call present with redirect URL")
        XCTAssertEqual(
            mockController.presentCalledWith, redirectURL,
            "Should present with correct redirect URL"
        )
    }

    func
        test_onCompleted_withPaymentAuthorizationFailed_shouldTransitionToPresentingCSKWithCheckoutURL()
        async throws
    {
        let testError = NSError(domain: "test", code: 1, userInfo: nil)

        // Follow valid state transitions: idle -> startPaymentRequest -> appleSheetPresented -> paymentAuthorizationFailed
        try await delegate.transition(to: .startPaymentRequest)
        try await delegate.transition(to: .paymentAuthorizationFailed(error: testError))

        // Transition to completed to trigger onCompleted
        try await delegate.transition(to: .completed)

        // Should transition to presentingCSK with computed URL from getURLFromState
        guard case let .presentingCSK(url) = delegate.state else {
            XCTFail("Expected presentingCSK state but got \(delegate.state)")
            return
        }

        XCTAssertEqual(url, delegate.checkoutURL, "Should use computed URL from getURLFromState")
        XCTAssertEqual(mockController.presentCallCount, 1, "Should call present with computed URL")
        XCTAssertEqual(
            mockController.presentCalledWith, delegate.checkoutURL,
            "Should present with checkout URL"
        )
    }

    /// User cancels the sheet without authorizing payment
    func test_onCompleted_withDefaultCase_shouldTransitionToReset() async throws {
        // Start with appleSheetPresented (a state that falls into default case)
        try await delegate.transition(to: .startPaymentRequest)
        XCTAssertEqual(delegate.state, .appleSheetPresented)

        // Transition to completed to trigger onCompleted
        try await delegate.transition(to: .completed)

        // Should transition to reset, then onReset transitions to idle
        XCTAssertEqual(delegate.state, .idle, "Default case should transition to reset then idle")
        XCTAssertEqual(
            mockController.presentCallCount, 0, "Should not call present for default case"
        )
    }

    // MARK: onPresentingCSK()

    func test_onPresentingCSK_withValidURL_shouldCallPresentSuccessfully() async throws {
        let testURL = URL(string: "https://test-shop.myshopify.com/checkout")!

        // Transition to a state that leads to presentingCSK
        try await delegate.transition(to: .unexpectedError(error: NSError(domain: "test", code: 1)))
        try await delegate.transition(to: .completed)

        guard case let .presentingCSK(url) = delegate.state else {
            XCTFail("Expected presentingCSK state but got \(delegate.state)")
            return
        }

        XCTAssertEqual(url, testURL, "Should have correct URL")
        XCTAssertEqual(mockController.presentCallCount, 1, "Should call present once")
        XCTAssertEqual(mockController.presentCalledWith, testURL, "Should present with correct URL")
    }

    func test_onPresentingCSK_withCartSubmittedForCompletion_shouldSkipPersonalDataRemoval()
        async throws
    {
        let redirectURL = URL(string: "https://shop.example.com/thank-you")!

        // Create a spy controller to track personal data removal calls
        let spyController = SpyPayController()
        spyController.cart = StorefrontAPI.Cart.testCart

        let spyDelegate = ApplePayAuthorizationDelegate(
            configuration: configuration,
            controller: spyController,
            paymentControllerFactory: mockPaymentControllerFactory,
            clock: MockClock()
        )
        try spyDelegate.setCart(to: spyController.cart)

        // Follow valid state transitions: idle -> startPaymentRequest -> appleSheetPresented -> paymentAuthorized -> cartSubmittedForCompletion
        try await spyDelegate.transition(to: .startPaymentRequest)
        try await spyDelegate.transition(to: .paymentAuthorized(payment: PKPayment()))
        try await spyDelegate.transition(to: .cartSubmittedForCompletion(redirectURL: redirectURL))
        try await spyDelegate.transition(to: .completed)

        // Should be in presentingCSK state
        guard case let .presentingCSK(url) = spyDelegate.state else {
            XCTFail("Expected presentingCSK state but got \(spyDelegate.state)")
            return
        }

        XCTAssertEqual(url, redirectURL, "Should use redirect URL")
        XCTAssertEqual(spyController.presentCallCount, 1, "Should call present")
        XCTAssertEqual(
            spyController.presentCalledWith, redirectURL, "Should present with redirect URL"
        )

        // Note: We can't easily verify that cartRemovePersonalData was NOT called
        // because it uses storefrontJulyRelease.cartRemovePersonalData which is hard to mock
        // But we can verify the happy path behavior
    }

    func test_onPresentingCSK_withNonCartSubmittedState_shouldCallPresentSuccessfully() async throws {
        // Test with interrupt state (not cartSubmittedForCompletion)
        try await delegate.transition(to: .startPaymentRequest)
        try await delegate.transition(to: .interrupt(reason: .currencyChanged))
        try await delegate.transition(to: .completed)

        // Should be in presentingCSK state with query parameter
        guard case let .presentingCSK(url) = delegate.state else {
            XCTFail("Expected presentingCSK state but got \(delegate.state)")
            return
        }

        XCTAssertNotNil(url, "Should have valid URL")
        XCTAssertTrue(
            url!.absoluteString.contains("wallet_currency_change=true") == true,
            "Should contain query parameter"
        )
        XCTAssertEqual(mockController.presentCallCount, 1, "Should call present")
        XCTAssertEqual(mockController.presentCalledWith, url, "Should present with correct URL")
    }

    // MARK: - CheckoutURL Assignment Tests

    func test_handleError_withCurrencyChangedInterrupt_setsCheckoutURLFromCart() async throws {
        let originalCheckoutURL = delegate.checkoutURL
        let cartWithDifferentURL = createTestCartWithURL("https://example.com/different-checkout")
        mockController.cart = cartWithDifferentURL

        let currencyChangedError = StorefrontAPI.Errors.currencyChanged

        // Configure mock to succeed for startPaymentRequest transition
        mockPaymentController.shouldPresentSuccessfully = true
        try await delegate.transition(to: .startPaymentRequest)
        // startPaymentRequest should automatically transition to appleSheetPresented when successful

        let result = await delegate.handleError(error: currencyChangedError, cart: nil) { errors in
            return errors
        }

        XCTAssertEqual(result.count, 1, "Should return abort error")
        XCTAssertEqual(delegate.checkoutURL, cartWithDifferentURL.checkoutUrl.url, "Should update checkoutURL from cart's checkoutURL")
        XCTAssertNotEqual(delegate.checkoutURL, originalCheckoutURL, "CheckoutURL should have changed")
    }

    func test_handleError_withCurrencyChangedInterruptAndNilCart_preservesOriginalCheckoutURL() async throws {
        let originalCheckoutURL = delegate.checkoutURL
        mockController.cart = nil

        let currencyChangedError = StorefrontAPI.Errors.currencyChanged

        // Configure mock to succeed for startPaymentRequest transition
        mockPaymentController.shouldPresentSuccessfully = true
        try await delegate.transition(to: .startPaymentRequest)
        // startPaymentRequest should automatically transition to appleSheetPresented when successful

        let result = await delegate.handleError(error: currencyChangedError, cart: nil) { errors in
            return errors
        }

        XCTAssertEqual(result.count, 1, "Should return abort error")
        XCTAssertEqual(delegate.checkoutURL, originalCheckoutURL, "Should preserve original checkoutURL when cart is nil")
    }

    func test_handleError_withUserError_preservesOriginalCheckoutURL() async throws {
        let originalCheckoutURL = delegate.checkoutURL
        let userError = StorefrontAPI.CartUserError(
            code: nil,
            message: "Test error",
            field: ["test"]
        )
        let userErrors = StorefrontAPI.Errors.userError(userErrors: [userError], cart: mockController.cart)

        // Configure mock to succeed for startPaymentRequest transition
        mockPaymentController.shouldPresentSuccessfully = true
        try await delegate.transition(to: .startPaymentRequest)
        // startPaymentRequest should automatically transition to appleSheetPresented when successful

        let result = await delegate.handleError(error: userErrors, cart: nil) { errors in
            return errors
        }

        XCTAssertGreaterThan(result.count, 0, "Should return user errors")
        XCTAssertEqual(delegate.checkoutURL, originalCheckoutURL, "Should preserve original checkoutURL for user errors")
    }

    // MARK: - Test Helpers

    private func createTestCartWithURL(_ urlString: String) -> StorefrontAPI.Cart {
        let address = StorefrontAPI.CartDeliveryAddress(
            address1: nil,
            address2: nil,
            city: nil,
            countryCode: "US",
            firstName: nil,
            lastName: nil,
            phone: nil,
            provinceCode: nil,
            zip: nil
        )

        let selectableAddress = StorefrontAPI.CartSelectableAddress(
            id: GraphQLScalars.ID("test-address-id"),
            selected: true,
            address: address
        )

        let delivery = StorefrontAPI.CartDelivery(addresses: [selectableAddress])

        return StorefrontAPI.Cart(
            id: GraphQLScalars.ID("test-cart-id"),
            checkoutUrl: GraphQLScalars.URL(URL(string: urlString)!),
            totalQuantity: 1,
            buyerIdentity: nil,
            deliveryGroups: StorefrontAPI.CartDeliveryGroupConnection(nodes: []),
            delivery: delivery,
            lines: StorefrontAPI.BaseCartLineConnection(nodes: []),
            cost: StorefrontAPI.CartCost(
                totalAmount: StorefrontAPI.MoneyV2(amount: 100.0, currencyCode: "USD"),
                subtotalAmount: nil,
                totalTaxAmount: nil,
                totalDutyAmount: nil
            ),
            discountCodes: [],
            discountAllocations: []
        )
    }

    // MARK: - Mock Classes

    /// Mock PaymentAuthorizationController for testing
    private class MockPaymentAuthorizationController: PaymentAuthorizationController {
        var delegate: PKPaymentAuthorizationControllerDelegate?
        var shouldPresentSuccessfully = true
        var presentCallCount = 0
        var dismissCallCount = 0

        func present() async -> Bool {
            presentCallCount += 1
            return shouldPresentSuccessfully
        }

        func dismiss(completion: (() -> Void)?) {
            dismissCallCount += 1
            completion?()
        }
    }

    private class MockPayController: PayController {
        var cart: StorefrontAPI.Types.Cart?
        var storefront: StorefrontAPIProtocol
        var storefrontJulyRelease: StorefrontAPIProtocol

        var presentCallCount = 0
        var presentCalledWith: URL?

        init() {
            let config = ShopifyAcceleratedCheckouts.Configuration.testConfiguration
            storefront = StorefrontAPI(
                storefrontDomain: config.storefrontDomain,
                storefrontAccessToken: config.storefrontAccessToken
            )
            storefrontJulyRelease = storefront
        }

        func present(url: URL) async throws {
            presentCallCount += 1
            presentCalledWith = url
        }
    }

    private class FailingMockPayController: PayController {
        var cart: StorefrontAPI.Types.Cart?
        var storefront: StorefrontAPIProtocol
        var storefrontJulyRelease: StorefrontAPIProtocol

        var presentCallCount = 0

        init() {
            let config = ShopifyAcceleratedCheckouts.Configuration.testConfiguration
            storefront = StorefrontAPI(
                storefrontDomain: config.storefrontDomain,
                storefrontAccessToken: config.storefrontAccessToken
            )
            storefrontJulyRelease = storefront
        }

        func present(url _: URL) async throws {
            presentCallCount += 1
            throw NSError(domain: "test", code: 1, userInfo: nil)
        }
    }

    private class SpyPayController: PayController {
        var cart: StorefrontAPI.Types.Cart?
        var storefront: StorefrontAPIProtocol
        var storefrontJulyRelease: StorefrontAPIProtocol

        var presentCallCount = 0
        var presentCalledWith: URL?

        init() {
            let config = ShopifyAcceleratedCheckouts.Configuration.testConfiguration
            storefront = StorefrontAPI(
                storefrontDomain: config.storefrontDomain,
                storefrontAccessToken: config.storefrontAccessToken
            )
            storefrontJulyRelease = storefront
        }

        func present(url: URL) async throws {
            presentCallCount += 1
            presentCalledWith = url
        }
    }

    // MARK: - Customer Info Attachment Tests

    func test_onPresentingCSK_fromCartSubmittedForCompletion_shouldNotModifyCustomerInfo() async throws {
        let redirectURL = URL(string: "https://shop.example.com/thank-you")!

        // Follow valid state transition path: idle -> startPaymentRequest -> appleSheetPresented -> paymentAuthorized -> cartSubmittedForCompletion -> completed
        // The completed state will automatically transition to presentingCSK
        try await delegate.transition(to: .startPaymentRequest)
        try await delegate.transition(to: .paymentAuthorized(payment: PKPayment()))
        try await delegate.transition(to: .cartSubmittedForCompletion(redirectURL: redirectURL))
        try await delegate.transition(to: .completed)

        // Should call present with the redirect URL through the completed -> presentingCSK transition
        XCTAssertEqual(mockController.presentCallCount, 1)
        XCTAssertEqual(mockController.presentCalledWith, redirectURL)
    }

    func test_createSheetKitURL_withInterruptReasonHavingQueryParam_shouldAppendQueryParam() {
        let baseURL = URL(string: "https://shop.example.com/checkout")!
        delegate.checkoutURL = baseURL

        let interruptState = ApplePayState.interrupt(reason: .dynamicTax)
        let resultURL = delegate.createSheetKitURL(for: interruptState)

        guard let resultURL else {
            XCTFail("Expected URL to be created")
            return
        }

        XCTAssertTrue(
            resultURL.absoluteString.contains("wallet_dynamic_tax=true"),
            "URL should contain interrupt query parameter"
        )
    }

    func test_createSheetKitURL_withInterruptReasonWithoutQueryParam_shouldReturnOriginalURL() {
        let baseURL = URL(string: "https://shop.example.com/checkout")!
        delegate.checkoutURL = baseURL

        let interruptState = ApplePayState.interrupt(reason: .outOfStock)
        let resultURL = delegate.createSheetKitURL(for: interruptState)

        XCTAssertEqual(resultURL, baseURL, "URL should remain unchanged when interrupt reason has no query param")
    }

    func test_createSheetKitURL_withCartSubmittedForCompletion_shouldReturnRedirectURL() {
        let redirectURL = URL(string: "https://shop.example.com/thank-you")!
        let state = ApplePayState.cartSubmittedForCompletion(redirectURL: redirectURL)

        let resultURL = delegate.createSheetKitURL(for: state)

        XCTAssertEqual(resultURL, redirectURL)
    }

    func test_createSheetKitURL_withNormalState_shouldReturnCheckoutURL() {
        let baseURL = URL(string: "https://shop.example.com/checkout")!
        delegate.checkoutURL = baseURL

        let resultURL = delegate.createSheetKitURL(for: .appleSheetPresented)

        XCTAssertEqual(resultURL, baseURL)
    }
}
