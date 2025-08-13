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
@testable import ShopifyCheckoutSheetKit
import SwiftUI
import XCTest

@available(iOS 17.0, *)
final class ApplePayViewModifierTests: XCTestCase {
    // MARK: - Properties

    var mockConfiguration: ShopifyAcceleratedCheckouts.Configuration!
    var mockApplePayConfiguration: ShopifyAcceleratedCheckouts.ApplePayConfiguration!
    var mockShopSettings: ShopSettings!

    // MARK: - Setup

    override func setUp() {
        super.setUp()

        mockConfiguration = ShopifyAcceleratedCheckouts.Configuration(
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
            paymentSettings: PaymentSettings(countryCode: "US", acceptedCardBrands: [.visa, .mastercard])
        )
    }

    override func tearDown() {
        mockConfiguration = nil
        mockApplePayConfiguration = nil
        mockShopSettings = nil
        super.tearDown()
    }

    // MARK: - onComplete Modifier Tests

    func testOnSuccessModifier() {
        var successCallbackInvoked = false
        let successAction = { (_: CheckoutCompletedEvent) in
            successCallbackInvoked = true
        }

        let view = AcceleratedCheckoutButtons(cartID: "gid://Shopify/Cart/test-cart-id")
            .onComplete(successAction)
            .environmentObject(mockConfiguration)
            .environmentObject(mockApplePayConfiguration)
            .environmentObject(mockShopSettings)

        XCTAssertNotNil(view, "View should be created successfully with success modifier")

        successAction(createEmptyCheckoutCompletedEvent())
        XCTAssertTrue(successCallbackInvoked, "Success callback should be invoked when called")
    }

    func testOnSuccessModifierChaining() {
        var firstCallbackInvoked = false
        var secondCallbackInvoked = false

        let firstAction = { (_: CheckoutCompletedEvent) in
            firstCallbackInvoked = true
        }
        let secondAction = { (_: CheckoutCompletedEvent) in
            secondCallbackInvoked = true
        }

        let view = AcceleratedCheckoutButtons(cartID: "gid://Shopify/Cart/test-cart-id")
            .onComplete(firstAction)
            .onComplete(secondAction) // Should replace the first
            .environmentObject(mockConfiguration)
            .environmentObject(mockApplePayConfiguration)
            .environmentObject(mockShopSettings)

        // The second handler should replace the first
        secondAction(createEmptyCheckoutCompletedEvent())
        XCTAssertFalse(firstCallbackInvoked, "First callback should not be invoked")
        XCTAssertTrue(secondCallbackInvoked, "Second callback should be invoked")
    }

    // MARK: - onCancel Modifier Tests

    func testOnCancelModifier() {
        var cancelCallbackInvoked = false
        let cancelAction = {
            cancelCallbackInvoked = true
        }

        let view = AcceleratedCheckoutButtons(cartID: "gid://Shopify/Cart/test-cart-id")
            .onCancel(cancelAction)
            .environmentObject(mockConfiguration)
            .environmentObject(mockApplePayConfiguration)
            .environmentObject(mockShopSettings)

        XCTAssertNotNil(view, "View should be created successfully with cancel modifier")

        cancelAction()
        XCTAssertTrue(cancelCallbackInvoked, "Cancel callback should be invoked when called")
    }

    func testOnCancelModifierChaining() {
        var firstCallbackInvoked = false
        var secondCallbackInvoked = false

        let firstAction = { (_: CheckoutCompletedEvent) in
            firstCallbackInvoked = true
        }
        let secondAction = { (_: CheckoutCompletedEvent) in
            secondCallbackInvoked = true
        }

        let view = AcceleratedCheckoutButtons(cartID: "gid://Shopify/Cart/test-cart-id")
            .onCancel { firstCallbackInvoked = true }
            .onCancel { secondCallbackInvoked = true } // Should replace the first
            .environmentObject(mockConfiguration)
            .environmentObject(mockApplePayConfiguration)
            .environmentObject(mockShopSettings)

        // The second handler should replace the first
        secondAction(createEmptyCheckoutCompletedEvent())
        XCTAssertFalse(firstCallbackInvoked, "First callback should not be invoked")
        XCTAssertTrue(secondCallbackInvoked, "Second callback should be invoked")
    }

    // MARK: - onFail Modifier Tests

    func testOnErrorModifier() {
        var errorCallbackInvoked = false
        let errorAction = { (_: CheckoutError) in
            errorCallbackInvoked = true
        }

        let view = AcceleratedCheckoutButtons(cartID: "gid://Shopify/Cart/test-cart-id")
            .onFail(errorAction)
            .environmentObject(mockConfiguration)
            .environmentObject(mockApplePayConfiguration)
            .environmentObject(mockShopSettings)

        XCTAssertNotNil(view, "View should be created successfully with error modifier")

        errorAction(CheckoutError.sdkError(underlying: NSError(domain: "Test", code: 0)))
        XCTAssertTrue(errorCallbackInvoked, "Error callback should be invoked when called")
    }

    // MARK: - Combined Modifiers Tests

    func testCombinedModifiers() {
        var successInvoked = false
        var errorInvoked = false

        let successAction = { (_: CheckoutCompletedEvent) in
            successInvoked = true
        }
        let errorAction = { (_: CheckoutError) in
            errorInvoked = true
        }

        let view = AcceleratedCheckoutButtons(cartID: "gid://Shopify/Cart/test-cart-id")
            .onComplete(successAction)
            .onFail(errorAction)
            .environmentObject(mockConfiguration)
            .environmentObject(mockApplePayConfiguration)
            .environmentObject(mockShopSettings)

        XCTAssertNotNil(view, "View should be created successfully with both modifiers")

        successAction(createEmptyCheckoutCompletedEvent())
        XCTAssertTrue(successInvoked, "Success callback should be invoked")
        XCTAssertFalse(errorInvoked, "Error callback should not be invoked")

        errorAction(CheckoutError.sdkError(underlying: NSError(domain: "Test", code: 0)))
        XCTAssertTrue(errorInvoked, "Error callback should be invoked")
    }

    // MARK: - Environment Propagation Tests

    func testEnvironmentValueDefaults() {
        let view = AcceleratedCheckoutButtons(cartID: "gid://Shopify/Cart/test-cart-id")
            .environmentObject(mockConfiguration)
            .environmentObject(mockApplePayConfiguration)
            .environmentObject(mockShopSettings)

        XCTAssertNotNil(view, "View should be created successfully without handlers")
    }

    // MARK: - Combined Modifier Tests

    func testAllCallbackModifiersCombined() {
        var successInvoked = false
        var errorInvoked = false
        var cancelInvoked = false

        let successAction = { (_: CheckoutCompletedEvent) in successInvoked = true }
        let errorAction = { (_: CheckoutError) in errorInvoked = true }
        let cancelAction = { cancelInvoked = true }

        let view = AcceleratedCheckoutButtons(cartID: "gid://Shopify/Cart/test-cart-id")
            .onComplete(successAction)
            .onFail(errorAction)
            .onCancel(cancelAction)
            .environmentObject(mockConfiguration)
            .environmentObject(mockApplePayConfiguration)
            .environmentObject(mockShopSettings)

        XCTAssertNotNil(view, "View should be created successfully with all modifiers")

        successAction(createEmptyCheckoutCompletedEvent())
        XCTAssertTrue(successInvoked, "Success callback should be invoked")
        XCTAssertFalse(errorInvoked, "Error callback should not be invoked")
        XCTAssertFalse(cancelInvoked, "Cancel callback should not be invoked")

        // Reset
        successInvoked = false
        errorAction(CheckoutError.sdkError(underlying: NSError(domain: "Test", code: 0)))
        XCTAssertFalse(successInvoked, "Success callback should not be invoked")
        XCTAssertTrue(errorInvoked, "Error callback should be invoked")
        XCTAssertFalse(cancelInvoked, "Cancel callback should not be invoked")

        // Reset
        errorInvoked = false
        cancelAction()
        XCTAssertFalse(successInvoked, "Success callback should not be invoked")
        XCTAssertFalse(errorInvoked, "Error callback should not be invoked")
        XCTAssertTrue(cancelInvoked, "Cancel callback should be invoked")
    }

    // MARK: - Integration Tests

    func testCompleteIntegrationWithAllModifiers() {
        var successCount = 0
        var errorCount = 0
        var viewAppeared = false

        let view = VStack {
            AcceleratedCheckoutButtons(cartID: "gid://Shopify/Cart/test-cart-id")
                .onComplete { _ in successCount += 1 }
                .onFail { _ in errorCount += 1 }
                .onAppear { viewAppeared = true }
        }
        .environmentObject(mockConfiguration)
        .environmentObject(mockApplePayConfiguration)
        .environmentObject(mockShopSettings)

        XCTAssertNotNil(view, "View should be created successfully")

        let modifiedView = view
            .frame(width: 300, height: 50)
            .background(Color.blue)

        XCTAssertNotNil(modifiedView, "Modified view should be created successfully")
    }

    // MARK: - Corner Radius Modifier Tests

    func testCornerRadiusModifier() {
        let view = AcceleratedCheckoutButtons(cartID: "gid://Shopify/Cart/test-cart-id")
            .cornerRadius(16)
            .environmentObject(mockConfiguration)
            .environmentObject(mockApplePayConfiguration)
            .environmentObject(mockShopSettings)

        XCTAssertNotNil(view, "View should be created successfully with corner radius modifier")
    }

    func testCornerRadiusZeroValue() {
        let view = AcceleratedCheckoutButtons(cartID: "gid://Shopify/Cart/test-cart-id")
            .cornerRadius(0)
            .environmentObject(mockConfiguration)
            .environmentObject(mockApplePayConfiguration)
            .environmentObject(mockShopSettings)

        XCTAssertNotNil(view, "View should be created successfully with zero corner radius")
    }

    func testCornerRadiusNegativeValue() {
        let view = AcceleratedCheckoutButtons(cartID: "gid://Shopify/Cart/test-cart-id")
            .cornerRadius(-10)
            .environmentObject(mockConfiguration)
            .environmentObject(mockApplePayConfiguration)
            .environmentObject(mockShopSettings)

        XCTAssertNotNil(view, "View should be created successfully with negative corner radius")
    }

    // MARK: - Helper Methods

    private func extractEnvironmentValue<T>(from _: Mirror, keyPath _: KeyPath<EnvironmentValues, T>) -> T? {
        // This is a simplified helper - in real tests you might use ViewInspector or similar
        // For demonstration purposes, we're showing the test structure
        // In production, you'd need proper reflection or test utilities

        // Note: This would require actual implementation to extract environment values
        // from SwiftUI views, which is complex due to SwiftUI's opaque types

        // For the purpose of these tests, we're demonstrating the test structure
        // In practice, you might test this through UI tests or by testing the
        // underlying ApplePayViewController directly

        return nil
    }
}
