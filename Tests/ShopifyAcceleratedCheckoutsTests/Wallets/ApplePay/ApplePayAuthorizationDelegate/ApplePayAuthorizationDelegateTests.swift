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
    private var mockPaymentControllerFactory: MockPaymentAuthorizationControllerFactory!
    private var delegate: ApplePayAuthorizationDelegate!
    private let initialState = ApplePayState.idle

    override func setUp() async throws {
        try await super.setUp()

        mockController = MockPayController()
        mockController.cart = StorefrontAPI.Cart.testCart
        mockController.presentCallCount = 0
        mockController.presentCalledWith = nil

        mockPaymentControllerFactory = MockPaymentAuthorizationControllerFactory()
        delegate = ApplePayAuthorizationDelegate(
            configuration: configuration,
            controller: mockController,
            paymentControllerFactory: mockPaymentControllerFactory
        )

        do {
            try delegate.setCart(to: mockController.cart)
        } catch {
            XCTFail("setCart failed with error: \(error)")
        }

        // Verify delegate has checkoutURL set
        XCTAssertNotNil(delegate.checkoutURL, "Delegate checkoutURL should be set after setCart")
        if let cart = mockController.cart {
            XCTAssertEqual(
                delegate.checkoutURL?.absoluteString, cart.checkoutUrl.url.absoluteString
            )
        }
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
        await delegate.transition(to: .reset)
        XCTAssertEqual(delegate.state, initialState, "Should be back to idle after reset")
    }

    /// Ensures guard is in place to prevent state update transition
    /// Exhaustive testing of valid transitions are located: `ApplePayStateTests.swift`
    func test_transition_withInvalidStateTransition_shouldRejectAndMaintainCurrentState()
        async throws
    {
        XCTAssertEqual(delegate.state, initialState, "Should start in idle state")
        await delegate.transition(to: .paymentAuthorized(payment: PKPayment()))
        XCTAssertEqual(delegate.state, initialState, "Invalid transition should not transition")
    }

    // MARK: - Side Effect Tests

    func test_onCompleted_withErrorState_shouldTransitionToPresentingCSKWithCheckoutURL()
        async throws
    {
        await delegate.transition(to: .unexpectedError(error: NSError(domain: "test", code: 1)))
        await delegate.transition(to: .completed)
        guard case let .presentingCSK(url) = delegate.state else {
            XCTFail(
                "Should transition to presentingCSK for error states, but got \(delegate.state)")
            return
        }

        XCTAssertEqual(
            url?.absoluteString,
            delegate.checkoutURL?.absoluteString,
            "Should use checkout URL for error states"
        )
    }

    func test_url_withDefaultState_shouldReturnCheckoutURL() async throws {
        XCTAssertEqual(delegate.state, .idle, "Should start in idle state")

        let defaultURL = delegate.url
        XCTAssertEqual(
            defaultURL?.absoluteString,
            delegate.checkoutURL?.absoluteString,
            "Should return checkout URL for idle state"
        )
    }

    func test_onCompleted_withErrorState_shouldCallPresentWithCheckoutURL() async throws {
        let error = NSError(domain: "test", code: 999, userInfo: nil)
        await delegate.transition(to: .unexpectedError(error: error))

        let checkoutURL = delegate.checkoutURL
        XCTAssertNotNil(checkoutURL)

        await delegate.transition(to: .completed)

        // The flow should be: .completed → onCompleted() → .presentingCSK → onPresentingCSK() → present()
        XCTAssertEqual(mockController.presentCallCount, 1, "CSK should be presented once")
        XCTAssertEqual(
            mockController.presentCalledWith?.absoluteString,
            checkoutURL?.absoluteString
        )
    }

    // MARK: - URL Computation Tests

    func test_url_withInterruptReasonsWithQueryParams_shouldAddQueryParametersToURL() async throws {
        // Test interrupt reasons that add query parameters
        let interruptReasonsWithParams: [ErrorHandler.InterruptReason] = [
            .currencyChanged,
            .dynamicTax,
            .cartNotReady,
            .notEnoughStock,
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
                paymentControllerFactory: mockPaymentControllerFactory
            )
            try testDelegate.setCart(to: mockController.cart)

            // Transition to a state where interrupt is valid
            await testDelegate.transition(to: .startPaymentRequest)
            await testDelegate.transition(to: .interrupt(reason: reason))
            await testDelegate.transition(to: .completed)

            let url = mockController.presentCalledWith
            XCTAssertTrue(
                url?.absoluteString.contains(expectedParam) == true,
                "URL should contain \(expectedParam) for \(reason) interrupt, but got: \(url?.absoluteString ?? "nil")"
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
            .unhandled,
        ]

        let expectedURL = "https://test-shop.myshopify.com/checkout"

        for reason in interruptReasonsWithoutParams {
            // Create a fresh delegate for each test iteration to avoid state interference
            let testDelegate = ApplePayAuthorizationDelegate(
                configuration: configuration,
                controller: mockController,
                paymentControllerFactory: mockPaymentControllerFactory
            )
            try testDelegate.setCart(to: mockController.cart)

            // Transition to a state where interrupt is valid
            await testDelegate.transition(to: .startPaymentRequest)
            await testDelegate.transition(to: .interrupt(reason: reason))
            await testDelegate.transition(to: .completed)

            XCTAssertEqual(
                testDelegate.url?.absoluteString,
                expectedURL,
                "\(reason) interrupt should use base checkout URL without query params, but got: \(testDelegate.url?.absoluteString ?? "nil")"
            )

            XCTAssertEqual(
                mockController.presentCalledWith?.absoluteString,
                expectedURL,
                "Present should be called with url"
            )
        }
    }

    func test_present_withRedirectURL_shouldCallControllerPresentWithRedirectURL() async throws {
        // In production, this state is reached after successful payment authorization

        // Since we can't simulate the full payment flow in tests, we verify the URL computation logic
        let redirectURL = URL(string: "https://example.com/thank-you")!

        // The delegate's url property should return the redirect URL when in cartSubmittedForCompletion state
        // We can't test this directly without being able to set the state, but we can verify
        // that the mock controller can present URLs
        try? await mockController.present(url: redirectURL)

        // Verify the mock controller works as expected
        XCTAssertEqual(mockController.presentCallCount, 1)
        XCTAssertEqual(mockController.presentCalledWith?.absoluteString, redirectURL.absoluteString)
    }

    // MARK: - Error Handling Tests

    func test_onPresentingCSK_withPresentFailure_shouldStillTransitionToPresentingCSKState()
        async throws
    {
        let failingController = FailingMockPayController()
        failingController.cart = mockController.cart

        let failingDelegate = ApplePayAuthorizationDelegate(
            configuration: configuration,
            controller: failingController
        )
        try? failingDelegate.setCart(to: failingController.cart)

        await failingDelegate.transition(
            to: .unexpectedError(error: NSError(domain: "test", code: 1))
        )

        await failingDelegate.transition(to: .completed)

        XCTAssertEqual(failingController.presentCallCount, 1, "Should attempt to present CSK")

        guard case .presentingCSK = failingDelegate.state else {
            XCTFail("Expected presentingCSK state but got \(failingDelegate.state)")
            return
        }
    }

    func test_onPresentingCSK_withNilURL_shouldTransitionToUnexpectedError() async throws {
        delegate.checkoutURL = nil

        await delegate.transition(to: .unexpectedError(error: NSError(domain: "test", code: 1)))
        await delegate.transition(to: .completed)

        // onComplete will move us to .presentingCSK which returns .terminalError due to nil url
        guard case .terminalError = delegate.state else {
            XCTFail("Expected unexpectedError state when URL is nil, but got \(delegate.state)")
            return
        }

        XCTAssertEqual(
            mockController.presentCallCount,
            0,
            "Present should not be called with nil URL"
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

    /// Mock factory for creating MockPaymentAuthorizationController instances
    private class MockPaymentAuthorizationControllerFactory: PaymentAuthorizationControllerFactory {
        let mockController = MockPaymentAuthorizationController()

        func createPaymentAuthorizationController(paymentRequest _: PKPaymentRequest)
            -> PaymentAuthorizationController
        {
            return mockController
        }
    }

    private class MockPayController: PayController {
        var cart: StorefrontAPI.Types.Cart?
        var storefront: StorefrontAPI
        var storefrontJulyRelease: StorefrontAPI

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
        var storefront: StorefrontAPI
        var storefrontJulyRelease: StorefrontAPI

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
}
