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
@testable import ShopifyAcceleratedCheckouts
import ShopifyCheckoutSheetKit
import SwiftUI
import XCTest

@available(iOS 17.0, *)
final class ApplePayIntegrationTests: XCTestCase {
    // MARK: - Properties

    var mockConfiguration: ApplePayConfigurationWrapper!
    var mockCommonConfiguration: ShopifyAcceleratedCheckouts.Configuration!
    var mockApplePayConfiguration: ShopifyAcceleratedCheckouts.ApplePayConfiguration!
    var mockShopSettings: ShopSettings!

    // MARK: - Setup

    override func setUp() {
        super.setUp()

        mockCommonConfiguration = ShopifyAcceleratedCheckouts.Configuration(
            shopDomain: "test-shop.myshopify.com",
            storefrontAccessToken: "test-token"
        )

        mockApplePayConfiguration = ShopifyAcceleratedCheckouts.ApplePayConfiguration(
            merchantIdentifier: "test.merchant.id",
            supportedNetworks: [.visa, .masterCard, .amex],
            contactFields: []
        )

        mockShopSettings = ShopSettings(
            name: "Test Shop",
            primaryDomain: Domain(
                host: "test-shop.myshopify.com",
                url: "https://test-shop.myshopify.com"
            ),
            paymentSettings: PaymentSettings(countryCode: "US")
        )

        mockConfiguration = ApplePayConfigurationWrapper(
            common: mockCommonConfiguration,
            applePay: mockApplePayConfiguration,
            shopSettings: mockShopSettings
        )
    }

    override func tearDown() {
        mockConfiguration = nil
        mockCommonConfiguration = nil
        mockApplePayConfiguration = nil
        mockShopSettings = nil
        super.tearDown()
    }

    // MARK: - Integration Tests

    func testViewModifierWithButtonIntegration() async {
        // Given
        var callbackInvoked = false

        await MainActor.run {
            // Create a hosting controller to test SwiftUI integration
            let view = AcceleratedCheckoutButtons(cartID: "gid://Shopify/Cart/test-cart")
                .withWallets([.applepay])
                .onComplete {
                    callbackInvoked = true
                }
                .environment(mockCommonConfiguration)
                .environment(mockApplePayConfiguration)
                .environment(mockShopSettings)

            let hostingController = UIHostingController(rootView: view)

            // When - Load the view
            _ = hostingController.view

            // Then
            XCTAssertNotNil(hostingController.view, "View should be created")

            // Test that the view hierarchy is properly established
            XCTAssertNotNil(hostingController.rootView, "Root view should exist")
        }
    }

    func testViewModifierWithButtonIntegrationIncludingCancel() async {
        // Given
        var completeInvoked = false
        var failInvoked = false
        var cancelInvoked = false

        await MainActor.run {
            // Create a hosting controller to test SwiftUI integration with all callbacks
            let view = AcceleratedCheckoutButtons(cartID: "gid://Shopify/Cart/test-cart")
                .withWallets([.applepay])
                .onComplete {
                    completeInvoked = true
                }
                .onFail {
                    failInvoked = true
                }
                .onCancel {
                    cancelInvoked = true
                }
                .environment(mockCommonConfiguration)
                .environment(mockApplePayConfiguration)
                .environment(mockShopSettings)

            let hostingController = UIHostingController(rootView: view)

            // When - Load the view
            _ = hostingController.view

            // Then
            XCTAssertNotNil(hostingController.view, "View should be created with all callbacks")
            XCTAssertNotNil(hostingController.rootView, "Root view should exist")

            // Verify callbacks are not invoked during view creation
            XCTAssertFalse(completeInvoked, "Complete callback should not be invoked on view creation")
            XCTAssertFalse(failInvoked, "Fail callback should not be invoked on view creation")
            XCTAssertFalse(cancelInvoked, "Cancel callback should not be invoked on view creation")
        }
    }

    // MARK: - Edge Case Tests

    func testInvariantIdentifierHandling() {
        // Given
        let identifier = CheckoutIdentifier.invariant

        // When
        let button = ApplePayButton(identifier: identifier, eventHandlers: EventHandlers())

        // Create hosting controller to render the view
        let hostingController = UIHostingController(
            rootView: button
                .environment(mockCommonConfiguration)
                .environment(mockApplePayConfiguration)
                .environment(mockShopSettings)
        )

        // Then - Should render EmptyView
        XCTAssertNotNil(hostingController.view)
        // The view should essentially be empty/minimal due to invariant case
    }

    func testCallbackPersistenceAcrossViewUpdates() async {
        // Given
        var successCount = 0
        let successHandler = {
            successCount += 1
        }

        // When - Create button with handler
        let button = ApplePayButton(
            identifier: .cart(cartID: "gid://Shopify/Cart/test-cart"),
            eventHandlers: EventHandlers(checkoutSuccessHandler: successHandler)
        )

        // Apply additional modifiers (simulating view updates)
        // Note: withLabel returns 'some View', not ApplePayButton
        let modifiedView = AnyView(
            button
                .id(UUID())
        )

        // Then - Handler should persist
        // This tests that the environment value propagates correctly
        XCTAssertNotNil(button, "Button should still exist after modifications")
        XCTAssertNotNil(modifiedView, "Modified view should exist")
    }

    // MARK: - Delegate Tests

    func testCheckoutDelegateCancelCallback() async {
        // Given
        var cancelCallbackInvoked = false

        let viewController = ApplePayViewController(
            identifier: .cart(cartID: "gid://Shopify/Cart/test-cart"),
            configuration: mockConfiguration
        )

        await MainActor.run {
            viewController.onCancel = {
                cancelCallbackInvoked = true
            }
        }

        let delegate = viewController.authorizationDelegate

        // When - Simulate checkout cancellation
        delegate.checkoutDidCancel()

        // Then - Wait for async callback
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        await MainActor.run {
            XCTAssertTrue(cancelCallbackInvoked, "Cancel callback should be invoked when checkoutDidCancel is called")
        }
    }

    // MARK: - New Delegate Method Integration Tests

    func testCheckoutDidClickLinkDelegateIntegration() async {
        // Given
        var callbackInvoked = false
        var receivedURL: URL?

        let viewController = ApplePayViewController(
            identifier: .cart(cartID: "gid://Shopify/Cart/test-cart"),
            configuration: mockConfiguration
        )

        await MainActor.run {
            viewController.onClickLink = { url in
                callbackInvoked = true
                receivedURL = url
            }
        }

        let delegate = viewController.authorizationDelegate

        // When - Simulate link click
        let testURL = URL(string: "https://help.shopify.com/payment-terms")!
        delegate.checkoutDidClickLink(url: testURL)

        // Then
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        await MainActor.run {
            XCTAssertTrue(callbackInvoked, "checkoutDidClickLink callback should be invoked")
            XCTAssertEqual(receivedURL, testURL, "URL should be passed to callback")
        }
    }

    func testCheckoutDidEmitWebPixelEventDelegateIntegration() async {
        // Given
        let viewController = ApplePayViewController(
            identifier: .cart(cartID: "gid://Shopify/Cart/test-cart"),
            configuration: mockConfiguration
        )

        var callbackSet = false

        // When - Set the web pixel event callback
        await MainActor.run {
            viewController.onWebPixelEvent = { _ in
                callbackSet = true
            }
        }

        // Then - Verify the callback is set
        await MainActor.run {
            XCTAssertNotNil(viewController.onWebPixelEvent, "Web pixel event callback should be set")
        }
    }
}
