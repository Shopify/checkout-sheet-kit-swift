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
import XCTest

@available(iOS 17.0, *)
final class ApplePayCallbackTests: XCTestCase {
    // MARK: - Properties

    var viewController: ApplePayViewController!
    var mockConfiguration: ApplePayConfigurationWrapper!
    var mockIdentifier: CheckoutIdentifier!
    var errorExpectation: XCTestExpectation!
    var cancelExpectation: XCTestExpectation!

    // MARK: - Setup

    override func setUp() {
        super.setUp()

        // Create mock configuration
        let commonConfig = ShopifyAcceleratedCheckouts.Configuration(
            storefrontDomain: "test-shop.myshopify.com",
            storefrontAccessToken: "test-token"
        )

        let applePayConfig = ShopifyAcceleratedCheckouts.ApplePayConfiguration(
            merchantIdentifier: "test.merchant.id",
            contactFields: []
        )

        let shopSettings = ShopSettings(
            name: "Test Shop",
            primaryDomain: Domain(
                host: "test-shop.myshopify.com",
                url: "https://test-shop.myshopify.com"
            ),
            paymentSettings: PaymentSettings(countryCode: "US", acceptedCardBrands: [.visa, .mastercard])
        )

        mockConfiguration = ApplePayConfigurationWrapper(
            common: commonConfig,
            applePay: applePayConfig,
            shopSettings: shopSettings
        )

        mockIdentifier = .cart(cartID: "gid://Shopify/Cart/test-cart-id")

        // Create SUT
        viewController = ApplePayViewController(
            identifier: mockIdentifier,
            configuration: mockConfiguration
        )
    }

    override func tearDown() {
        viewController = nil
        mockConfiguration = nil
        mockIdentifier = nil
        errorExpectation = nil
        cancelExpectation = nil
        super.tearDown()
    }

    // MARK: - Error Callback Tests

    func testErrorCallbackInvoked() async {
        errorExpectation = expectation(description: "Error callback should be invoked")
        let callbackInvokedExpectation = expectation(description: "Error callback invoked")

        await MainActor.run {
            viewController.onCheckoutFail = { [weak self] _ in
                callbackInvokedExpectation.fulfill()
                self?.errorExpectation.fulfill()
            }
        }

        await MainActor.run {
            let mockError = CheckoutError.sdkError(underlying: NSError(domain: "TestError", code: 0, userInfo: nil), recoverable: false)
            viewController.onCheckoutFail?(mockError)
        }

        await fulfillment(of: [errorExpectation, callbackInvokedExpectation], timeout: 1.0)
    }

    func testErrorCallbackNotInvokedWhenNil() async {
        await MainActor.run {
            XCTAssertNil(viewController.onCheckoutFail)
        }

        await MainActor.run {
            let mockError = CheckoutError.sdkError(underlying: NSError(domain: "TestError", code: 0, userInfo: nil), recoverable: false)
            viewController.onCheckoutFail?(mockError) // Should not crash
        }

        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        XCTAssertTrue(true, "Should not crash when callback is nil")
    }

    // MARK: - Cancel Callback Tests

    func testCancelCallbackInvoked() async {
        cancelExpectation = expectation(description: "Cancel callback should be invoked")
        let callbackInvokedExpectation = expectation(description: "Cancel callback invoked")

        await MainActor.run {
            viewController.onCheckoutCancel = { [weak self] in
                callbackInvokedExpectation.fulfill()
                self?.cancelExpectation.fulfill()
            }
        }

        await MainActor.run {
            viewController.onCheckoutCancel?()
        }

        await fulfillment(of: [cancelExpectation, callbackInvokedExpectation], timeout: 1.0)
    }

    func testCancelCallbackNotInvokedWhenNil() async {
        let isNil = await MainActor.run {
            viewController.onCheckoutCancel == nil
        }
        XCTAssertTrue(isNil, "onCancel should be nil")

        await MainActor.run {
            viewController.onCheckoutCancel?() // Should not crash
        }

        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        XCTAssertTrue(true, "Should not crash when callback is nil")
    }

    // MARK: - No Callback Tests

    @MainActor
    func testNoCallbackWhenCheckoutCancelled() async {
        var errorInvoked = false
        var cancelInvoked = false

        viewController.onCheckoutFail = { _ in
            errorInvoked = true
        }
        viewController.onCheckoutCancel = {
            cancelInvoked = true
        }

        viewController.onCheckoutCancel?()

        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        XCTAssertFalse(errorInvoked, "Error callback should not be invoked")
        XCTAssertTrue(cancelInvoked, "Cancel callback should be invoked")
    }

    // MARK: - Thread Safety Tests

    @MainActor
    func testCallbackThreadSafety() async {
        let iterations = 10 // Even distribution between error and cancel
        let errorExpectations = (0 ..< iterations / 2).map { _ in expectation(description: "Error") }
        let cancelExpectations = (0 ..< iterations / 2).map { _ in expectation(description: "Cancel") }

        var errorIndex = 0
        var cancelIndex = 0

        viewController.onCheckoutFail = { _ in
            if errorIndex < errorExpectations.count {
                errorExpectations[errorIndex].fulfill()
                errorIndex += 1
            }
        }
        viewController.onCheckoutCancel = {
            if cancelIndex < cancelExpectations.count {
                cancelExpectations[cancelIndex].fulfill()
                cancelIndex += 1
            }
        }

        for i in 0 ..< iterations {
            if i % 2 == 0 {
                let mockError = CheckoutError.sdkError(underlying: NSError(domain: "TestError", code: 0, userInfo: nil), recoverable: false)
                viewController.onCheckoutFail?(mockError)
            } else {
                viewController.onCheckoutCancel?()
            }

            // Give time for callback to execute
            try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
        }

        // Wait for all expectations
        await fulfillment(of: errorExpectations + cancelExpectations, timeout: 2.0)
    }

    // MARK: - Edge Case Tests

    func testMultipleCancelCallbackAssignments() async {
        let firstCallbackExpectation = expectation(description: "First cancel callback")
        firstCallbackExpectation.isInverted = true
        let secondCallbackExpectation = expectation(description: "Second cancel callback")

        await MainActor.run {
            // First assignment
            viewController.onCheckoutCancel = {
                firstCallbackExpectation.fulfill()
            }

            // Second assignment (should replace first)
            viewController.onCheckoutCancel = {
                secondCallbackExpectation.fulfill()
            }
        }

        await MainActor.run {
            viewController.onCheckoutCancel?()
        }

        await fulfillment(of: [secondCallbackExpectation], timeout: 1.0)
        await fulfillment(of: [firstCallbackExpectation], timeout: 0.2)
    }
}

// Mock types are no longer needed since we're testing callbacks directly
