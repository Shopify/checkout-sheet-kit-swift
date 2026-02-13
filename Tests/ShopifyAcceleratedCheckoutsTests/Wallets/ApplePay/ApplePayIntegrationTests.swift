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
        await MainActor.run {
            let view = AcceleratedCheckoutButtons(cartID: "gid://Shopify/Cart/test-cart")
                .wallets([.applePay])
                .environmentObject(mockCommonConfiguration)
                .environmentObject(mockApplePayConfiguration)
                .environmentObject(mockShopSettings)

            let hostingController = UIHostingController(rootView: view)

            _ = hostingController.view

            XCTAssertNotNil(hostingController.view, "View should be created")

            XCTAssertNotNil(hostingController.rootView, "Root view should exist")
        }
    }

    func testViewModifierWithButtonIntegrationIncludingCancel() async {
        let failExpectation = expectation(description: "Fail callback")
        failExpectation.isInverted = true
        let cancelExpectation = expectation(description: "Cancel callback")
        cancelExpectation.isInverted = true

        await MainActor.run {
            let view = AcceleratedCheckoutButtons(cartID: "gid://Shopify/Cart/test-cart")
                .wallets([.applePay])
                .onFail { _ in
                    failExpectation.fulfill()
                }
                .onCancel {
                    cancelExpectation.fulfill()
                }
                .environmentObject(mockCommonConfiguration)
                .environmentObject(mockApplePayConfiguration)
                .environmentObject(mockShopSettings)

            let hostingController = UIHostingController(rootView: view)

            _ = hostingController.view

            XCTAssertNotNil(hostingController.view, "View should be created with all callbacks")
            XCTAssertNotNil(hostingController.rootView, "Root view should exist")
        }

        await fulfillment(of: [failExpectation, cancelExpectation], timeout: 0.2)
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
        var failCount = 0
        let failHandler = { (_: CheckoutError) in
            failCount += 1
        }

        let button = await ApplePayButton(
            identifier: .cart(cartID: "gid://Shopify/Cart/test-cart"),
            eventHandlers: EventHandlers(checkoutDidFail: failHandler),
            cornerRadius: nil
        )

        let modifiedView = AnyView(
            button
                .id(UUID())
        )

        XCTAssertNotNil(button, "Button should still exist after modifications")
        XCTAssertNotNil(modifiedView, "Modified view should exist")
    }

    // MARK: - Delegate Tests

    @MainActor
    func testCheckoutDelegateCancelCallback() async {
        var cancelCallbackInvoked = false

        let viewController = ApplePayViewController(
            identifier: .cart(cartID: "gid://Shopify/Cart/test-cart"),
            configuration: mockConfiguration
        )

        viewController.onCheckoutCancel = {
            cancelCallbackInvoked = true
        }

        viewController.onCheckoutCancel?()

        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertTrue(cancelCallbackInvoked, "Cancel callback should be invoked when onCheckoutCancel is called")
    }
}
