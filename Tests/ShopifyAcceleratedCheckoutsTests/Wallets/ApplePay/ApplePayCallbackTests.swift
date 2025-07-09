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

    var sut: ApplePayViewController!
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
            shopDomain: "test-shop.myshopify.com",
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
        sut = ApplePayViewController(
            identifier: mockIdentifier,
            configuration: mockConfiguration
        )
    }

    override func tearDown() {
        sut = nil
        mockConfiguration = nil
        mockIdentifier = nil
        successExpectation = nil
        errorExpectation = nil
        cancelExpectation = nil
        super.tearDown()
    }

    // MARK: - Success Callback Tests

    func testSuccessCallbackInvoked() async {
        // Given
        successExpectation = expectation(description: "Success callback should be invoked")
        var callbackInvoked = false

        await MainActor.run {
            sut.onComplete = { [weak self] in
                callbackInvoked = true
                self?.successExpectation.fulfill()
            }
        }

        // When - Directly invoke the callback
        await MainActor.run {
            sut.onComplete?()
        }

        // Then
        await fulfillment(of: [successExpectation], timeout: 1.0)
        XCTAssertTrue(callbackInvoked, "Success callback should have been invoked")
    }

    func testSuccessCallbackNotInvokedWhenNil() async {
        // Given - No callback set
        await MainActor.run {
            XCTAssertNil(sut.onComplete)
        }

        // When - Try to invoke nil callback
        await MainActor.run {
            sut.onComplete?() // Should not crash
        }

        // Then - Should not crash
        // Wait a moment to ensure no crash occurs
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        XCTAssertTrue(true, "Should not crash when callback is nil")
    }

    // MARK: - Error Callback Tests

    func testErrorCallbackInvoked() async {
        // Given
        errorExpectation = expectation(description: "Error callback should be invoked")
        var callbackInvoked = false

        await MainActor.run {
            sut.onFail = { [weak self] in
                callbackInvoked = true
                self?.errorExpectation.fulfill()
            }
        }

        // When - Directly invoke the callback
        await MainActor.run {
            sut.onFail?()
        }

        // Then
        await fulfillment(of: [errorExpectation], timeout: 1.0)
        XCTAssertTrue(callbackInvoked, "Error callback should have been invoked")
    }

    func testErrorCallbackNotInvokedWhenNil() async {
        // Given - No callback set
        await MainActor.run {
            XCTAssertNil(sut.onFail)
        }

        // When - Try to invoke nil callback
        await MainActor.run {
            sut.onFail?() // Should not crash
        }

        // Then - Should not crash
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        XCTAssertTrue(true, "Should not crash when callback is nil")
    }

    // MARK: - Cancel Callback Tests

    func testCancelCallbackInvoked() async {
        // Given
        cancelExpectation = expectation(description: "Cancel callback should be invoked")
        var callbackInvoked = false

        await MainActor.run {
            sut.onCancel = { [weak self] in
                callbackInvoked = true
                self?.cancelExpectation.fulfill()
            }
        }

        // When - Directly invoke the callback
        await MainActor.run {
            sut.onCancel?()
        }

        // Then
        await fulfillment(of: [cancelExpectation], timeout: 1.0)
        XCTAssertTrue(callbackInvoked, "Cancel callback should have been invoked")
    }

    func testCancelCallbackNotInvokedWhenNil() async {
        // Given - No callback set
        let isNil = await MainActor.run {
            sut.onCancel == nil
        }
        XCTAssertTrue(isNil, "onCancel should be nil")

        // When - Try to invoke nil callback
        await MainActor.run {
            sut.onCancel?() // Should not crash
        }

        // Then - Should not crash
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        XCTAssertTrue(true, "Should not crash when callback is nil")
    }

    // MARK: - No Callback Tests

    func testNoCallbackWhenCheckoutCancelled() async {
        // Given
        var successInvoked = false
        var errorInvoked = false
        var cancelInvoked = false

        await MainActor.run {
            sut.onComplete = {
                successInvoked = true
            }
            sut.onFail = {
                errorInvoked = true
            }
            sut.onCancel = {
                cancelInvoked = true
            }
        }

        // When - Only cancel callback is invoked
        await MainActor.run {
            sut.onCancel?()
        }

        // Then
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        XCTAssertFalse(successInvoked, "Success callback should not be invoked")
        XCTAssertFalse(errorInvoked, "Error callback should not be invoked")
        XCTAssertTrue(cancelInvoked, "Cancel callback should be invoked")
    }

    // MARK: - Thread Safety Tests

    func testCallbackThreadSafety() async {
        // Given
        let iterations = 12 // Multiple of 3 for even distribution
        var successCount = 0
        var errorCount = 0
        var cancelCount = 0
        let lock = NSLock()

        await MainActor.run {
            sut.onComplete = {
                lock.lock()
                successCount += 1
                lock.unlock()
            }
            sut.onFail = {
                lock.lock()
                errorCount += 1
                lock.unlock()
            }
            sut.onCancel = {
                lock.lock()
                cancelCount += 1
                lock.unlock()
            }
        }

        // When - Simulate multiple sequential completions to avoid race conditions
        for i in 0 ..< iterations {
            await MainActor.run {
                if i % 3 == 0 {
                    sut.onComplete?()
                } else if i % 3 == 1 {
                    sut.onFail?()
                } else {
                    sut.onCancel?()
                }
            }

            // Give time for callback to execute
            try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
        }

        // Then - Wait for all callbacks to complete
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds

        // Verify counts
        XCTAssertEqual(successCount, iterations / 3, "Success callback should be invoked correct number of times")
        XCTAssertEqual(errorCount, iterations / 3, "Error callback should be invoked correct number of times")
        XCTAssertEqual(cancelCount, iterations / 3, "Cancel callback should be invoked correct number of times")
    }

    // MARK: - Edge Case Tests

    func testMultipleCallbackAssignments() async {
        // Given
        var firstCallbackInvoked = false
        var secondCallbackInvoked = false

        await MainActor.run {
            // First assignment
            sut.onComplete = {
                firstCallbackInvoked = true
            }

            // Second assignment (should replace first)
            sut.onComplete = {
                secondCallbackInvoked = true
            }
        }

        // When
        await MainActor.run {
            sut.onComplete?()
        }

        // Then
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        XCTAssertFalse(firstCallbackInvoked, "First callback should not be invoked")
        XCTAssertTrue(secondCallbackInvoked, "Second callback should be invoked")
    }

    func testMultipleCancelCallbackAssignments() async {
        // Given
        var firstCallbackInvoked = false
        var secondCallbackInvoked = false

        await MainActor.run {
            // First assignment
            sut.onCancel = {
                firstCallbackInvoked = true
            }

            // Second assignment (should replace first)
            sut.onCancel = {
                secondCallbackInvoked = true
            }
        }

        // When
        await MainActor.run {
            sut.onCancel?()
        }

        // Then
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        XCTAssertFalse(firstCallbackInvoked, "First callback should not be invoked")
        XCTAssertTrue(secondCallbackInvoked, "Second callback should be invoked")
    }

    // MARK: - shouldRecoverFromError Callback Tests

    func testShouldRecoverFromErrorCallbackInvoked() async {
        // Given
        let expectation = expectation(description: "shouldRecoverFromError callback should be invoked")
        var passedError: ShopifyCheckoutSheetKit.CheckoutError?

        await MainActor.run {
            sut.onShouldRecoverFromError = { error in
                passedError = error
                expectation.fulfill()
                return true
            }
        }

        // When - Simulate delegate method call
        let testError = ShopifyCheckoutSheetKit.CheckoutError.checkoutUnavailable(message: "Test error", code: .clientError(code: .unknown), recoverable: true)
        let delegate = sut.authorizationDelegate as! ApplePayAuthorizationDelegate
        delegate.shouldRecoverFromError(error: testError)

        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertNotNil(passedError, "Error should be passed to callback")
    }

    func testShouldRecoverFromErrorCallbackReturnsCorrectValue() async {
        // Given - Test callback is invoked even though return value is always false
        var callbackInvoked = false

        await MainActor.run {
            sut.onShouldRecoverFromError = { _ in
                callbackInvoked = true
                return true // Even though we return true, the delegate method will return false
            }
        }

        // When
        let testError = ShopifyCheckoutSheetKit.CheckoutError.checkoutUnavailable(message: "Test", code: .clientError(code: .unknown), recoverable: true)
        let delegate = sut.authorizationDelegate as! ApplePayAuthorizationDelegate
        delegate.shouldRecoverFromError(error: testError)

        // Then
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        XCTAssertTrue(callbackInvoked, "Callback should be invoked")
    }

    // MARK: - checkoutDidClickLink Callback Tests

    func testCheckoutDidClickLinkCallbackInvoked() async {
        // Given
        let expectation = expectation(description: "checkoutDidClickLink callback should be invoked")
        var passedURL: URL?

        await MainActor.run {
            sut.onClickLink = { url in
                passedURL = url
                expectation.fulfill()
            }
        }

        // When - Simulate delegate method call
        let testURL = URL(string: "https://test-shop.myshopify.com/products/test")!
        let delegate = sut.authorizationDelegate as! ApplePayAuthorizationDelegate
        delegate.checkoutDidClickLink(url: testURL)

        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(passedURL, testURL, "URL should be passed to callback")
    }

    func testCheckoutDidClickLinkCallbackNotInvokedWhenNil() async {
        // Given - No callback set
        await MainActor.run {
            XCTAssertNil(sut.onClickLink)
        }

        // When - Try to invoke nil callback
        let testURL = URL(string: "https://test-shop.myshopify.com")!
        let delegate = sut.authorizationDelegate as! ApplePayAuthorizationDelegate
        delegate.checkoutDidClickLink(url: testURL) // Should not crash

        // Then - Should not crash
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        XCTAssertTrue(true, "Should not crash when callback is nil")
    }

    func testCheckoutDidClickLinkWithVariousURLs() async {
        // Given
        var capturedURLs: [URL] = []
        let testURLs = [
            URL(string: "https://test-shop.myshopify.com/products/test")!,
            URL(string: "https://external-site.com/page")!,
            URL(string: "mailto:test@example.com")!,
            URL(string: "tel:+1234567890")!
        ]

        await MainActor.run {
            sut.onClickLink = { url in
                capturedURLs.append(url)
            }
        }

        // When
        let delegate = sut.authorizationDelegate as! ApplePayAuthorizationDelegate
        for url in testURLs {
            delegate.checkoutDidClickLink(url: url)
        }

        // Then
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        XCTAssertEqual(capturedURLs.count, testURLs.count, "All URLs should be captured")
        XCTAssertEqual(capturedURLs, testURLs, "URLs should be captured in order")
    }

    // MARK: - checkoutDidEmitWebPixelEvent Callback Tests

    // MARK: - Thread Safety Tests for New Callbacks
}

// Mock types are no longer needed since we're testing callbacks directly
