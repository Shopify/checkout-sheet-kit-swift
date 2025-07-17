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
    var successExpectation: XCTestExpectation!
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
        successExpectation = nil
        errorExpectation = nil
        cancelExpectation = nil
        super.tearDown()
    }

    // MARK: - Success Callback Tests

    func testSuccessCallbackInvoked() async {
        successExpectation = expectation(description: "Success callback should be invoked")
        let callbackInvokedExpectation = expectation(description: "Callback invoked")

        await MainActor.run {
            viewController.onCheckoutComplete = { [weak self] _ in
                callbackInvokedExpectation.fulfill()
                self?.successExpectation.fulfill()
            }
        }

        await MainActor.run {
            let mockEvent = createEmptyCheckoutCompletedEvent(id: "test-order-123")
            viewController.onCheckoutComplete?(mockEvent)
        }

        await fulfillment(of: [successExpectation, callbackInvokedExpectation], timeout: 1.0)
    }

    func testSuccessCallbackNotInvokedWhenNil() async {
        await MainActor.run {
            XCTAssertNil(viewController.onCheckoutComplete)
        }

        await MainActor.run {
            let mockEvent = createEmptyCheckoutCompletedEvent(id: "test-order-123")
            viewController.onCheckoutComplete?(mockEvent) // Should not crash
        }

        // Wait a moment to ensure no crash occurs
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        XCTAssertTrue(true, "Should not crash when callback is nil")
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
        var successInvoked = false
        var errorInvoked = false
        var cancelInvoked = false

        viewController.onCheckoutComplete = { _ in
            successInvoked = true
        }
        viewController.onCheckoutFail = { _ in
            errorInvoked = true
        }
        viewController.onCheckoutCancel = {
            cancelInvoked = true
        }

        viewController.onCheckoutCancel?()

        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        XCTAssertFalse(successInvoked, "Success callback should not be invoked")
        XCTAssertFalse(errorInvoked, "Error callback should not be invoked")
        XCTAssertTrue(cancelInvoked, "Cancel callback should be invoked")
    }

    // MARK: - Thread Safety Tests

    @MainActor
    func testCallbackThreadSafety() async {
        let iterations = 12 // Multiple of 3 for even distribution
        let successExpectations = (0 ..< iterations / 3).map { _ in expectation(description: "Success") }
        let errorExpectations = (0 ..< iterations / 3).map { _ in expectation(description: "Error") }
        let cancelExpectations = (0 ..< iterations / 3).map { _ in expectation(description: "Cancel") }

        var successIndex = 0
        var errorIndex = 0
        var cancelIndex = 0

        viewController.onCheckoutComplete = { _ in
            if successIndex < successExpectations.count {
                successExpectations[successIndex].fulfill()
                successIndex += 1
            }
        }
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
            if i % 3 == 0 {
                let mockEvent = createEmptyCheckoutCompletedEvent(id: "test-order-123")
                viewController.onCheckoutComplete?(mockEvent)
            } else if i % 3 == 1 {
                let mockError = CheckoutError.sdkError(underlying: NSError(domain: "TestError", code: 0, userInfo: nil), recoverable: false)
                viewController.onCheckoutFail?(mockError)
            } else {
                viewController.onCheckoutCancel?()
            }

            // Give time for callback to execute
            try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
        }

        // Wait for all expectations
        await fulfillment(of: successExpectations + errorExpectations + cancelExpectations, timeout: 2.0)
    }

    // MARK: - Edge Case Tests

    func testMultipleCallbackAssignments() async {
        let firstCallbackExpectation = expectation(description: "First callback")
        firstCallbackExpectation.isInverted = true
        let secondCallbackExpectation = expectation(description: "Second callback")

        await MainActor.run {
            // First assignment
            viewController.onCheckoutComplete = { _ in
                firstCallbackExpectation.fulfill()
            }

            // Second assignment (should replace first)
            viewController.onCheckoutComplete = { _ in
                secondCallbackExpectation.fulfill()
            }
        }

        await MainActor.run {
            let mockEvent = createEmptyCheckoutCompletedEvent(id: "test-order-123")
            viewController.onCheckoutComplete?(mockEvent)
        }

        await fulfillment(of: [secondCallbackExpectation], timeout: 1.0)
        await fulfillment(of: [firstCallbackExpectation], timeout: 0.2)
    }

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

    // MARK: - shouldRecoverFromError Callback Tests

    @MainActor
    func testShouldRecoverFromErrorCallbackInvoked() async {
        let expectation = expectation(description: "shouldRecoverFromError callback should be invoked")

        let testError = ShopifyCheckoutSheetKit.CheckoutError.checkoutUnavailable(message: "Test error", code: .clientError(code: .unknown), recoverable: true)
        var capturedError: ShopifyCheckoutSheetKit.CheckoutError?

        viewController.onShouldRecoverFromError = { error in
            capturedError = error
            expectation.fulfill()
            return true
        }

        let result = viewController.shouldRecoverFromError(error: testError)

        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertNotNil(capturedError, "Error should be passed to callback")
        XCTAssertTrue(result, "Should return true as returned by callback")
    }

    func testShouldRecoverFromErrorCallbackReturnsCorrectValue() async {
        let callbackExpectation = expectation(description: "Callback invoked")

        await MainActor.run {
            viewController.onShouldRecoverFromError = { _ in
                callbackExpectation.fulfill()
                return true
            }
        }

        let testError = ShopifyCheckoutSheetKit.CheckoutError.checkoutUnavailable(message: "Test", code: .clientError(code: .unknown), recoverable: true)
        let result = await MainActor.run {
            viewController.shouldRecoverFromError(error: testError)
        }

        await fulfillment(of: [callbackExpectation], timeout: 1.0)
        XCTAssertTrue(result, "Should return true as specified by callback")
    }

    // MARK: - checkoutDidClickLink Callback Tests

    @MainActor
    func testCheckoutDidClickLinkCallbackInvoked() async {
        let expectation = expectation(description: "checkoutDidClickLink callback should be invoked")
        let testURL = URL(string: "https://test-shop.myshopify.com/products/test")!
        var capturedURL: URL?

        viewController.onCheckoutClickLink = { url in
            capturedURL = url
            expectation.fulfill()
        }

        viewController.checkoutDidClickLink(url: testURL)

        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(capturedURL, testURL, "URL should be passed to callback")
    }

    func testCheckoutDidClickLinkCallbackNotInvokedWhenNil() async {
        await MainActor.run {
            XCTAssertNil(viewController.onCheckoutClickLink)
        }

        let testURL = URL(string: "https://test-shop.myshopify.com")!
        await MainActor.run {
            viewController.checkoutDidClickLink(url: testURL) // Should not crash
        }

        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        XCTAssertTrue(true, "Should not crash when callback is nil")
    }

    @MainActor
    func testCheckoutDidClickLinkWithVariousURLs() async {
        let testURLs = [
            URL(string: "https://test-shop.myshopify.com/products/test")!,
            URL(string: "https://external-site.com/page")!,
            URL(string: "mailto:test@example.com")!,
            URL(string: "tel:+1234567890")!
        ]

        let expectations = testURLs.map { _ in
            expectation(description: "URL callback")
        }

        var capturedURLs: [URL] = []
        var currentIndex = 0

        viewController.onCheckoutClickLink = { url in
            capturedURLs.append(url)
            if currentIndex < expectations.count {
                expectations[currentIndex].fulfill()
                currentIndex += 1
            }
        }

        for url in testURLs {
            viewController.checkoutDidClickLink(url: url)
        }

        await fulfillment(of: expectations, timeout: 1.0)
        XCTAssertEqual(capturedURLs, testURLs, "URLs should be captured in order")
    }

    // MARK: - checkoutDidEmitWebPixelEvent Callback Tests

    // MARK: - Thread Safety Tests for New Callbacks
}

// Mock types are no longer needed since we're testing callbacks directly
