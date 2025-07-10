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
            supportedNetworks: [.visa, .masterCard],
            contactFields: []
        )

        let shopSettings = ShopSettings(
            name: "Test Shop",
            primaryDomain: Domain(
                host: "test-shop.myshopify.com",
                url: "https://test-shop.myshopify.com"
            ),
            paymentSettings: PaymentSettings(countryCode: "US")
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
        var callbackInvoked = false

        await MainActor.run {
            viewController.onComplete = { [weak self] in
                callbackInvoked = true
                self?.successExpectation.fulfill()
            }
        }

        await MainActor.run {
            viewController.onComplete?()
        }

        await fulfillment(of: [successExpectation], timeout: 1.0)
        XCTAssertTrue(callbackInvoked, "Success callback should have been invoked")
    }

    func testSuccessCallbackNotInvokedWhenNil() async {
        await MainActor.run {
            XCTAssertNil(viewController.onComplete)
        }

        await MainActor.run {
            viewController.onComplete?() // Should not crash
        }

        // Wait a moment to ensure no crash occurs
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        XCTAssertTrue(true, "Should not crash when callback is nil")
    }

    // MARK: - Error Callback Tests

    func testErrorCallbackInvoked() async {
        errorExpectation = expectation(description: "Error callback should be invoked")
        var callbackInvoked = false

        await MainActor.run {
            viewController.onFail = { [weak self] in
                callbackInvoked = true
                self?.errorExpectation.fulfill()
            }
        }

        await MainActor.run {
            viewController.onFail?()
        }

        await fulfillment(of: [errorExpectation], timeout: 1.0)
        XCTAssertTrue(callbackInvoked, "Error callback should have been invoked")
    }

    func testErrorCallbackNotInvokedWhenNil() async {
        await MainActor.run {
            XCTAssertNil(viewController.onFail)
        }

        await MainActor.run {
            viewController.onFail?() // Should not crash
        }

        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        XCTAssertTrue(true, "Should not crash when callback is nil")
    }

    // MARK: - Cancel Callback Tests

    func testCancelCallbackInvoked() async {
        cancelExpectation = expectation(description: "Cancel callback should be invoked")
        var callbackInvoked = false

        await MainActor.run {
            viewController.onCancel = { [weak self] in
                callbackInvoked = true
                self?.cancelExpectation.fulfill()
            }
        }

        await MainActor.run {
            viewController.onCancel?()
        }

        await fulfillment(of: [cancelExpectation], timeout: 1.0)
        XCTAssertTrue(callbackInvoked, "Cancel callback should have been invoked")
    }

    func testCancelCallbackNotInvokedWhenNil() async {
        let isNil = await MainActor.run {
            viewController.onCancel == nil
        }
        XCTAssertTrue(isNil, "onCancel should be nil")

        await MainActor.run {
            viewController.onCancel?() // Should not crash
        }

        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        XCTAssertTrue(true, "Should not crash when callback is nil")
    }

    // MARK: - No Callback Tests

    func testNoCallbackWhenCheckoutCancelled() async {
        var successInvoked = false
        var errorInvoked = false
        var cancelInvoked = false

        await MainActor.run {
            viewController.onComplete = {
                successInvoked = true
            }
            viewController.onFail = {
                errorInvoked = true
            }
            viewController.onCancel = {
                cancelInvoked = true
            }
        }

        await MainActor.run {
            viewController.onCancel?()
        }

        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        XCTAssertFalse(successInvoked, "Success callback should not be invoked")
        XCTAssertFalse(errorInvoked, "Error callback should not be invoked")
        XCTAssertTrue(cancelInvoked, "Cancel callback should be invoked")
    }

    // MARK: - Thread Safety Tests

    func testCallbackThreadSafety() async {
        let iterations = 12 // Multiple of 3 for even distribution
        var successCount = 0
        var errorCount = 0
        var cancelCount = 0
        let lock = NSLock()

        await MainActor.run {
            viewController.onComplete = {
                lock.lock()
                successCount += 1
                lock.unlock()
            }
            viewController.onFail = {
                lock.lock()
                errorCount += 1
                lock.unlock()
            }
            viewController.onCancel = {
                lock.lock()
                cancelCount += 1
                lock.unlock()
            }
        }

        for i in 0 ..< iterations {
            await MainActor.run {
                if i % 3 == 0 {
                    viewController.onComplete?()
                } else if i % 3 == 1 {
                    viewController.onFail?()
                } else {
                    viewController.onCancel?()
                }
            }

            // Give time for callback to execute
            try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
        }

        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds

        // Verify counts
        XCTAssertEqual(successCount, iterations / 3, "Success callback should be invoked correct number of times")
        XCTAssertEqual(errorCount, iterations / 3, "Error callback should be invoked correct number of times")
        XCTAssertEqual(cancelCount, iterations / 3, "Cancel callback should be invoked correct number of times")
    }

    // MARK: - Edge Case Tests

    func testMultipleCallbackAssignments() async {
        var firstCallbackInvoked = false
        var secondCallbackInvoked = false

        await MainActor.run {
            // First assignment
            viewController.onComplete = {
                firstCallbackInvoked = true
            }

            // Second assignment (should replace first)
            viewController.onComplete = {
                secondCallbackInvoked = true
            }
        }

        await MainActor.run {
            viewController.onComplete?()
        }

        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        XCTAssertFalse(firstCallbackInvoked, "First callback should not be invoked")
        XCTAssertTrue(secondCallbackInvoked, "Second callback should be invoked")
    }

    func testMultipleCancelCallbackAssignments() async {
        var firstCallbackInvoked = false
        var secondCallbackInvoked = false

        await MainActor.run {
            // First assignment
            viewController.onCancel = {
                firstCallbackInvoked = true
            }

            // Second assignment (should replace first)
            viewController.onCancel = {
                secondCallbackInvoked = true
            }
        }

        await MainActor.run {
            viewController.onCancel?()
        }

        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        XCTAssertFalse(firstCallbackInvoked, "First callback should not be invoked")
        XCTAssertTrue(secondCallbackInvoked, "Second callback should be invoked")
    }

    // MARK: - shouldRecoverFromError Callback Tests

    func testShouldRecoverFromErrorCallbackInvoked() async {
        let expectation = expectation(description: "shouldRecoverFromError callback should be invoked")
        var passedError: ShopifyCheckoutSheetKit.CheckoutError?

        await MainActor.run {
            viewController.onShouldRecoverFromError = { error in
                passedError = error
                expectation.fulfill()
                return true
            }
        }

        let testError = ShopifyCheckoutSheetKit.CheckoutError.checkoutUnavailable(message: "Test error", code: .clientError(code: .unknown), recoverable: true)
        let result = await MainActor.run {
            viewController.shouldRecoverFromError(error: testError)
        }

        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertNotNil(passedError, "Error should be passed to callback")
        XCTAssertTrue(result, "Should return true as returned by callback")
    }

    func testShouldRecoverFromErrorCallbackReturnsCorrectValue() async {
        var callbackInvoked = false

        await MainActor.run {
            viewController.onShouldRecoverFromError = { _ in
                callbackInvoked = true
                return true
            }
        }

        let testError = ShopifyCheckoutSheetKit.CheckoutError.checkoutUnavailable(message: "Test", code: .clientError(code: .unknown), recoverable: true)
        let result = await MainActor.run {
            viewController.shouldRecoverFromError(error: testError)
        }

        XCTAssertTrue(callbackInvoked, "Callback should be invoked")
        XCTAssertTrue(result, "Should return true as specified by callback")
    }

    // MARK: - checkoutDidClickLink Callback Tests

    func testCheckoutDidClickLinkCallbackInvoked() async {
        let expectation = expectation(description: "checkoutDidClickLink callback should be invoked")
        var passedURL: URL?

        await MainActor.run {
            viewController.onClickLink = { url in
                passedURL = url
                expectation.fulfill()
            }
        }

        let testURL = URL(string: "https://test-shop.myshopify.com/products/test")!
        await MainActor.run {
            viewController.checkoutDidClickLink(url: testURL)
        }

        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(passedURL, testURL, "URL should be passed to callback")
    }

    func testCheckoutDidClickLinkCallbackNotInvokedWhenNil() async {
        await MainActor.run {
            XCTAssertNil(viewController.onClickLink)
        }

        let testURL = URL(string: "https://test-shop.myshopify.com")!
        await MainActor.run {
            viewController.checkoutDidClickLink(url: testURL) // Should not crash
        }

        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        XCTAssertTrue(true, "Should not crash when callback is nil")
    }

    func testCheckoutDidClickLinkWithVariousURLs() async {
        var capturedURLs: [URL] = []
        let testURLs = [
            URL(string: "https://test-shop.myshopify.com/products/test")!,
            URL(string: "https://external-site.com/page")!,
            URL(string: "mailto:test@example.com")!,
            URL(string: "tel:+1234567890")!
        ]

        await MainActor.run {
            viewController.onClickLink = { url in
                capturedURLs.append(url)
            }
        }

        await MainActor.run {
            for url in testURLs {
                viewController.checkoutDidClickLink(url: url)
            }
        }

        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        XCTAssertEqual(capturedURLs.count, testURLs.count, "All URLs should be captured")
        XCTAssertEqual(capturedURLs, testURLs, "URLs should be captured in order")
    }

    // MARK: - checkoutDidEmitWebPixelEvent Callback Tests

    // MARK: - Thread Safety Tests for New Callbacks
}

// Mock types are no longer needed since we're testing callbacks directly
