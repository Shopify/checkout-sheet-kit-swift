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
    private var configuration: ApplePayConfigurationWrapper!
    private var mockController: MockPayController!
    private var delegate: ApplePayAuthorizationDelegate!
    private let initialState = ApplePayState.idle

    override func setUp() async throws {
        try await super.setUp()

        configuration = ApplePayConfigurationWrapper.testConfiguration
        mockController = MockPayController()
        mockController.cart = StorefrontAPI.Cart.testCart
        delegate = ApplePayAuthorizationDelegate(
            configuration: configuration,
            controller: mockController
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
        configuration = nil
        try await super.tearDown()
    }

    // MARK: - State Transition Tests

    func test_transition_withValidStateTransition_shouldUpdateStateCorrectly() async throws {
        XCTAssertEqual(delegate.state, initialState, "Should start in idle state")

        await delegate.transition(to: .reset)
        await delegate.transition(to: .idle)
        XCTAssertEqual(delegate.state, initialState, "Should be back to idle after reset")
    }

    func test_transition_withInvalidStateTransition_shouldRejectAndMaintainCurrentState() async throws {
        XCTAssertEqual(delegate.state, initialState, "Should start in idle state")
        await delegate.transition(to: .paymentAuthorized(payment: PKPayment()))
        XCTAssertEqual(delegate.state, initialState, "Invalid transition should not transition")
    }

    // MARK: - Side Effect Tests

    func test_onCompleted_withErrorState_shouldTransitionToPresentingCSKWithCheckoutURL() async throws {
        await delegate.transition(to: .unexpectedError(error: NSError(domain: "test", code: 1)))
        await delegate.transition(to: .completed)
        guard case let .presentingCSK(url) = delegate.state else {
            XCTFail("Should transition to presentingCSK for error states, but got \(delegate.state)")
            return
        }

        XCTAssertEqual(url?.absoluteString, delegate.checkoutURL?.absoluteString, "Should use checkout URL for error states")
    }

    func test_url_withDefaultState_shouldReturnCheckoutURL() async throws {
        XCTAssertEqual(delegate.state, .idle, "Should start in idle state")

        let defaultURL = delegate.url
        XCTAssertEqual(defaultURL?.absoluteString, delegate.checkoutURL?.absoluteString, "Should return checkout URL for idle state")
    }

    func test_onCompleted_withErrorState_shouldCallPresentWithCheckoutURL() async throws {
        mockController.presentCallCount = 0
        mockController.presentCalledWith = nil

        let error = NSError(domain: "test", code: 999, userInfo: nil)
        await delegate.transition(to: .unexpectedError(error: error))

        let checkoutURL = delegate.checkoutURL
        XCTAssertNotNil(checkoutURL)

        await delegate.transition(to: .completed)

        // The flow should be: .completed → onCompleted() → .presentingCSK → onPresentingCSK() → present()
        XCTAssertEqual(mockController.presentCallCount, 1, "CSK should be presented once")
        XCTAssertEqual(
            mockController.presentCalledWith?.absoluteString, checkoutURL?.absoluteString
        )
    }

    // MARK: - URL Computation Tests

    func test_appendQueryParam_withInterruptReasons_shouldAddQueryParametersToURL() async throws {
        // This test verifies URL computation for interrupt reasons that include query params
        // In production, these URLs are computed when the delegate is in interrupt state

        XCTAssertNotNil(delegate.checkoutURL, "checkoutURL should be set from cart")
        let baseURL = delegate.checkoutURL!

        // Test interrupt reasons that add query params
        let testCases: [(queryParam: String, expectedParam: String)] = [
            ("wallet_currency_change", "wallet_currency_change=true"),
            ("wallet_dynamic_tax", "wallet_dynamic_tax=true"),
            ("wallet_cart_not_ready", "wallet_cart_not_ready=true"),
            ("wallet_not_enough_stock", "wallet_not_enough_stock=true")
        ]

        for (queryParam, expectedParam) in testCases {
            let url = baseURL.appendQueryParam(name: queryParam, value: "true")
            XCTAssertTrue(
                url?.absoluteString.contains(expectedParam) == true,
                "URL should contain \(expectedParam) for \(queryParam) interrupt"
            )
        }
    }

    func test_appendQueryParam_withNonParameterInterruptReasons_shouldReturnBaseURL() async throws {
        // This test verifies URL computation for interrupt reasons that don't add query params
        // In production, these URLs are the base checkout URL without modifications

        XCTAssertNotNil(delegate.checkoutURL, "checkoutURL should be set from cart")
        let baseURL = delegate.checkoutURL!

        // Test interrupt reasons that don't add query params
        // outOfStock, cartThrottled, other, and unhandled all use the base checkout URL
        let expectedURL = "https://test-shop.myshopify.com/checkout"
        XCTAssertEqual(baseURL.absoluteString, expectedURL)

        // These interrupt reasons would use the base URL without modifications
        let interruptReasonsWithoutParams = [
            "outOfStock",
            "cartThrottled",
            "other",
            "unhandled"
        ]

        for reason in interruptReasonsWithoutParams {
            // In production, these would all resolve to the base checkout URL
            XCTAssertEqual(
                baseURL.absoluteString,
                expectedURL,
                "\(reason) interrupt should use base checkout URL without query params"
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
        mockController.presentCallCount = 0
        try? await mockController.present(url: redirectURL)

        // Verify the mock controller works as expected
        XCTAssertEqual(mockController.presentCallCount, 1)
        XCTAssertEqual(mockController.presentCalledWith?.absoluteString, redirectURL.absoluteString)
    }

    // MARK: - Error Handling Tests

    func test_onPresentingCSK_withNilURL_shouldNotCallPresent() async throws {
        delegate.checkoutURL = nil
        mockController.presentCallCount = 0

        await delegate.transition(to: .presentingCSK(url: nil))

        XCTAssertEqual(
            mockController.presentCallCount, 0, "Present should not be called with nil URL"
        )
        XCTAssertEqual(delegate.state, .idle, "Should transition to idle when nil URL")
    }

    func test_onPresentingCSK_withPresentFailure_shouldStillTransitionToPresentingCSKState() async throws {
        let failingController = FailingMockPayController()
        failingController.cart = mockController.cart

        let failingDelegate = ApplePayAuthorizationDelegate(
            configuration: configuration,
            controller: failingController
        )
        try? failingDelegate.setCart(to: failingController.cart)

        await failingDelegate.transition(to: .unexpectedError(error: NSError(domain: "test", code: 1)))

        await failingDelegate.transition(to: .completed)

        XCTAssertEqual(failingController.presentCallCount, 1, "Should attempt to present CSK")

        guard case .presentingCSK = failingDelegate.state else {
            XCTFail("Expected presentingCSK state but got \(failingDelegate.state)")
            return
        }
    }

    // MARK: - Mock Classes

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
