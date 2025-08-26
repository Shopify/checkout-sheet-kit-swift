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
    var testDelegate: TestCheckoutDelegate!

    // MARK: - Setup

    override func setUp() {
        super.setUp()

        mockCommonConfiguration = ShopifyAcceleratedCheckouts.Configuration(
            storefrontDomain: "test-shop.myshopify.com",
            storefrontAccessToken: "test-token"
        )

        mockApplePayConfiguration = ShopifyAcceleratedCheckouts.ApplePayConfiguration(
            merchantIdentifier: "test.merchant.id",
            contactFields: []
        )

        mockShopSettings = ShopSettings(
            name: "Test Shop",
            primaryDomain: Domain(
                host: "test-shop.myshopify.com",
                url: "https://test-shop.myshopify.com"
            ),
            paymentSettings: PaymentSettings(
                countryCode: "US",
                acceptedCardBrands: [.visa, .mastercard, .americanExpress]
            )
        )

        mockConfiguration = ApplePayConfigurationWrapper(
            common: mockCommonConfiguration,
            applePay: mockApplePayConfiguration,
            shopSettings: mockShopSettings
        )

        testDelegate = TestCheckoutDelegate()
    }

    override func tearDown() {
        mockConfiguration = nil
        mockCommonConfiguration = nil
        mockApplePayConfiguration = nil
        mockShopSettings = nil
        testDelegate = nil
        super.tearDown()
    }

    // MARK: - Integration Tests

    func testViewModifierWithButtonIntegration() async {
        await MainActor.run {
            testDelegate.reset()

            // Create a hosting controller to test SwiftUI integration
            let view = AcceleratedCheckoutButtons(cartID: "gid://Shopify/Cart/test-cart")
                .wallets([.applePay])
                .checkout(delegate: testDelegate)
                .environmentObject(mockCommonConfiguration)
                .environmentObject(mockApplePayConfiguration)
                .environmentObject(mockShopSettings)

            let hostingController = UIHostingController(rootView: view)

            _ = hostingController.view

            XCTAssertNotNil(hostingController.view, "View should be created")

            // Test that the view hierarchy is properly established
            XCTAssertNotNil(hostingController.rootView, "Root view should exist")
        }
    }

    func testViewModifierWithButtonIntegrationWithNewAPI() async {
        let completeExpectation = expectation(description: "Complete callback")
        completeExpectation.isInverted = true
        let failExpectation = expectation(description: "Fail callback")
        failExpectation.isInverted = true
        let cancelExpectation = expectation(description: "Cancel callback")
        cancelExpectation.isInverted = true
        let errorExpectation = expectation(description: "Error callback")
        errorExpectation.isInverted = true

        await MainActor.run {
            testDelegate.reset()
            testDelegate.completeExpectations = [completeExpectation]
            testDelegate.failExpectations = [failExpectation]
            testDelegate.cancelExpectations = [cancelExpectation]

            // Create a hosting controller to test SwiftUI integration with new API
            let view = AcceleratedCheckoutButtons(cartID: "gid://Shopify/Cart/test-cart")
                .wallets([.applePay])
                .checkout(delegate: testDelegate)
                .onError { _ in
                    errorExpectation.fulfill()
                }
                .environmentObject(mockCommonConfiguration)
                .environmentObject(mockApplePayConfiguration)
                .environmentObject(mockShopSettings)

            let hostingController = UIHostingController(rootView: view)

            _ = hostingController.view

            XCTAssertNotNil(hostingController.view, "View should be created with new API")
            XCTAssertNotNil(hostingController.rootView, "Root view should exist")
        }

        // Verify callbacks are not invoked during view creation
        await fulfillment(of: [completeExpectation, failExpectation, cancelExpectation, errorExpectation], timeout: 0.2)
    }

    // MARK: - Edge Case Tests

    func testInvariantIdentifierHandling() {
        let identifier = CheckoutIdentifier.invariant(reason: "Test invariant")

        let button = ApplePayButton(identifier: identifier, eventHandlers: EventHandlers(), cornerRadius: nil)

        // Create hosting controller to render the view
        let hostingController = UIHostingController(
            rootView: button
                .environmentObject(mockCommonConfiguration)
                .environmentObject(mockApplePayConfiguration)
                .environmentObject(mockShopSettings)
        )

        XCTAssertNotNil(hostingController.view)
        // The view should essentially be empty/minimal due to invariant case
    }

    func testCallbackPersistenceAcrossViewUpdates() async {
        testDelegate.reset()

        let button = await ApplePayButton(
            identifier: .cart(cartID: "gid://Shopify/Cart/test-cart"),
            eventHandlers: EventHandlers(),
            checkoutDelegate: testDelegate,
            cornerRadius: nil
        )

        // Apply additional modifiers (simulating view updates)
        // Note: withLabel returns 'some View', not ApplePayButton
        let modifiedView = AnyView(
            button
                .id(UUID())
        )

        // This tests that the environment value propagates correctly
        XCTAssertNotNil(button, "Button should still exist after modifications")
        XCTAssertNotNil(modifiedView, "Modified view should exist")
        XCTAssertEqual(testDelegate.completeCount, 0, "Success count should start at 0")
    }

    // MARK: - CheckoutDelegate Integration Tests

    @MainActor
    func testCheckoutDelegateIntegration() async {
        testDelegate.reset()

        let viewController = ApplePayViewController(
            identifier: .cart(cartID: "gid://Shopify/Cart/test-cart"),
            configuration: mockConfiguration,
            checkoutDelegate: testDelegate
        )

        // Test cancel delegation
        viewController.checkoutDidCancel()
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        XCTAssertTrue(testDelegate.cancelCallbackInvoked, "Cancel callback should be delegated")

        // Test link click delegation
        let testURL = URL(string: "https://help.shopify.com/payment-terms")!
        viewController.checkoutDidClickLink(url: testURL)
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        XCTAssertTrue(testDelegate.linkCallbackInvoked, "Link click callback should be delegated")
        XCTAssertEqual(testDelegate.receivedURL, testURL, "URL should be passed to delegate")
    }
}
