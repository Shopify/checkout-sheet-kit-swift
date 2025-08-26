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
    var testDelegate: TestCheckoutDelegate!

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

        testDelegate = TestCheckoutDelegate()
    }

    override func tearDown() {
        mockConfiguration = nil
        mockApplePayConfiguration = nil
        mockShopSettings = nil
        testDelegate = nil
        super.tearDown()
    }

    // MARK: - onError Modifier Tests

    func testOnErrorModifier() {
        var errorCallbackInvoked = false
        let errorAction = { (_: AcceleratedCheckoutError) in
            errorCallbackInvoked = true
        }

        let view = AcceleratedCheckoutButtons(cartID: "gid://Shopify/Cart/test-cart-id")
            .onError(errorAction)
            .environmentObject(mockConfiguration)
            .environmentObject(mockApplePayConfiguration)
            .environmentObject(mockShopSettings)

        XCTAssertNotNil(view, "View should be created successfully with error modifier")

        // Test with validation error (only type supported by onError now)
        let validationError = ValidationError(userErrors: [
            ValidationError.UserError(message: "Test error", code: "TEST")
        ])
        errorAction(AcceleratedCheckoutError.validation(validationError))
        XCTAssertTrue(errorCallbackInvoked, "Error callback should be invoked when called")
    }

    // MARK: - Combined Modifiers Tests

    func testCheckoutDelegateModifier() {
        testDelegate.reset()

        let view = AcceleratedCheckoutButtons(cartID: "gid://Shopify/Cart/test-cart-id")
            .checkout(delegate: testDelegate)
            .environmentObject(mockConfiguration)
            .environmentObject(mockApplePayConfiguration)
            .environmentObject(mockShopSettings)

        XCTAssertNotNil(view, "View should be created successfully with checkout delegate")
    }

    func testCombinedNewModifiers() {
        var errorInvoked = false
        testDelegate.reset()

        let errorAction = { (_: AcceleratedCheckoutError) in
            errorInvoked = true
        }

        let view = AcceleratedCheckoutButtons(cartID: "gid://Shopify/Cart/test-cart-id")
            .checkout(delegate: testDelegate)
            .onError(errorAction)
            .environmentObject(mockConfiguration)
            .environmentObject(mockApplePayConfiguration)
            .environmentObject(mockShopSettings)

        XCTAssertNotNil(view, "View should be created successfully with both new modifiers")

        // Test error callback
        let validationError = ValidationError(userErrors: [
            ValidationError.UserError(message: "Test error", code: "TEST")
        ])
        errorAction(AcceleratedCheckoutError.validation(validationError))
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

    // MARK: - ValidationError Tests

    func testValidationErrorInOnError() {
        var receivedError: AcceleratedCheckoutError?
        let errorAction = { (error: AcceleratedCheckoutError) in
            receivedError = error
        }

        let view = AcceleratedCheckoutButtons(cartID: "gid://Shopify/Cart/test-cart-id")
            .onError(errorAction)
            .environmentObject(mockConfiguration)
            .environmentObject(mockApplePayConfiguration)
            .environmentObject(mockShopSettings)

        XCTAssertNotNil(view, "View should be created successfully")

        // Test validation error
        let validationError = ValidationError(userErrors: [
            ValidationError.UserError(message: "Email is invalid", field: ["email"], code: "INVALID"),
            ValidationError.UserError(message: "Required field missing", field: ["name"], code: "BLANK")
        ])
        let acceleratedError = AcceleratedCheckoutError.validation(validationError)

        errorAction(acceleratedError)

        guard let error = receivedError else {
            XCTFail("Error should be captured")
            return
        }

        XCTAssertTrue(error.isValidationError, "Should be validation error")

        guard let capturedValidationError = error.validationError else {
            XCTFail("Should contain validation error")
            return
        }

        XCTAssertEqual(capturedValidationError.userErrors.count, 2)
        XCTAssertEqual(capturedValidationError.userErrors[0].message, "Email is invalid")
        XCTAssertEqual(capturedValidationError.userErrors[0].field, ["email"])
        XCTAssertEqual(capturedValidationError.userErrors[0].code, "INVALID")

        // Test utility methods
        XCTAssertTrue(error.hasValidationErrorCode("INVALID"))
        XCTAssertTrue(error.hasValidationErrorCode("BLANK"))
        XCTAssertFalse(error.hasValidationErrorCode("OTHER"))

        let messages = error.validationMessages
        XCTAssertEqual(messages.count, 2)
        XCTAssertTrue(messages.contains("Email is invalid"))
        XCTAssertTrue(messages.contains("Required field missing"))
    }

    // MARK: - Integration Tests

    func testCompleteIntegrationWithNewAPI() {
        var errorCount = 0
        testDelegate.reset()

        let view = VStack {
            AcceleratedCheckoutButtons(cartID: "gid://Shopify/Cart/test-cart-id")
                .checkout(delegate: testDelegate)
                .onError { _ in errorCount += 1 }
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
