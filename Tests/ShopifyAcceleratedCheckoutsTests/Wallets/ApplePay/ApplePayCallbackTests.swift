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
    }

    override func tearDown() {
        viewController = nil
        mockConfiguration = nil
        mockIdentifier = nil
        super.tearDown()
    }

    // MARK: - CheckoutDelegate Tests

    @MainActor
    func testCheckoutDidComplete_invokesDelegateMethod() async {
        class TestDelegate: CheckoutDelegate {
            var completeCallbackInvoked = false
            let expectation: XCTestExpectation

            init(expectation: XCTestExpectation) {
                self.expectation = expectation
            }

            func checkoutDidComplete(event _: CheckoutCompletedEvent) {
                completeCallbackInvoked = true
                expectation.fulfill()
            }

            func checkoutDidFail(error _: CheckoutError) {}
            func checkoutDidCancel() {}
            func checkoutDidClickLink(url _: URL) {}
            func checkoutDidEmitWebPixelEvent(event _: PixelEvent) {}
        }

        let expectation = XCTestExpectation(description: "Complete delegate method should be invoked")
        let delegate = TestDelegate(expectation: expectation)

        // Create view controller with delegate
        viewController = ApplePayViewController(
            identifier: mockIdentifier,
            configuration: mockConfiguration,
            checkoutDelegate: delegate
        )

        let completedEvent = createEmptyCheckoutCompletedEvent(id: "test-order")
        viewController.checkoutDidComplete(event: completedEvent)

        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(delegate.completeCallbackInvoked, "Complete delegate method should be invoked")
    }

    @MainActor
    func testCheckoutDidFail_invokesDelegateMethod() async {
        class TestDelegate: CheckoutDelegate {
            var failCallbackInvoked = false
            let expectation: XCTestExpectation

            init(expectation: XCTestExpectation) {
                self.expectation = expectation
            }

            func checkoutDidComplete(event _: CheckoutCompletedEvent) {}

            func checkoutDidFail(error _: CheckoutError) {
                failCallbackInvoked = true
                expectation.fulfill()
            }

            func checkoutDidCancel() {}
            func checkoutDidClickLink(url _: URL) {}
            func checkoutDidEmitWebPixelEvent(event _: PixelEvent) {}
        }

        let expectation = XCTestExpectation(description: "Fail delegate method should be invoked")
        let delegate = TestDelegate(expectation: expectation)

        viewController = ApplePayViewController(
            identifier: mockIdentifier,
            configuration: mockConfiguration,
            checkoutDelegate: delegate
        )

        let checkoutError = CheckoutError.sdkError(
            underlying: NSError(domain: "TestError", code: 0, userInfo: nil),
            recoverable: false
        )
        viewController.checkoutDidFail(error: checkoutError)

        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(delegate.failCallbackInvoked, "Fail delegate method should be invoked")
    }

    @MainActor
    func testCheckoutDidCancel_invokesDelegateMethod() async {
        class TestDelegate: CheckoutDelegate {
            var cancelCallbackInvoked = false
            let expectation: XCTestExpectation

            init(expectation: XCTestExpectation) {
                self.expectation = expectation
            }

            func checkoutDidComplete(event _: CheckoutCompletedEvent) {}
            func checkoutDidFail(error _: CheckoutError) {}

            func checkoutDidCancel() {
                cancelCallbackInvoked = true
                expectation.fulfill()
            }

            func checkoutDidClickLink(url _: URL) {}
            func checkoutDidEmitWebPixelEvent(event _: PixelEvent) {}
        }

        let expectation = XCTestExpectation(description: "Cancel delegate method should be invoked")
        let delegate = TestDelegate(expectation: expectation)

        viewController = ApplePayViewController(
            identifier: mockIdentifier,
            configuration: mockConfiguration,
            checkoutDelegate: delegate
        )

        viewController.checkoutDidCancel()

        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(delegate.cancelCallbackInvoked, "Cancel delegate method should be invoked")
    }

    @MainActor
    func testCheckoutDidClickLink_invokesDelegateMethod() async {
        class TestDelegate: CheckoutDelegate {
            var linkCallbackInvoked = false
            var receivedURL: URL?
            let expectation: XCTestExpectation

            init(expectation: XCTestExpectation) {
                self.expectation = expectation
            }

            func checkoutDidComplete(event _: CheckoutCompletedEvent) {}
            func checkoutDidFail(error _: CheckoutError) {}
            func checkoutDidCancel() {}

            func checkoutDidClickLink(url: URL) {
                linkCallbackInvoked = true
                receivedURL = url
                expectation.fulfill()
            }

            func checkoutDidEmitWebPixelEvent(event _: PixelEvent) {}
        }

        let expectation = XCTestExpectation(description: "Link click delegate method should be invoked")
        let delegate = TestDelegate(expectation: expectation)

        viewController = ApplePayViewController(
            identifier: mockIdentifier,
            configuration: mockConfiguration,
            checkoutDelegate: delegate
        )

        let testURL = URL(string: "https://test-shop.myshopify.com/products/test")!
        viewController.checkoutDidClickLink(url: testURL)

        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(delegate.linkCallbackInvoked, "Link click delegate method should be invoked")
        XCTAssertEqual(delegate.receivedURL, testURL, "URL should be passed to delegate")
    }

    @MainActor
    func testCheckoutDidEmitWebPixelEvent_invokesDelegateMethod() async {
        class TestDelegate: CheckoutDelegate {
            var webPixelCallbackInvoked = false
            var receivedEvent: PixelEvent?
            let expectation: XCTestExpectation

            init(expectation: XCTestExpectation) {
                self.expectation = expectation
            }

            func checkoutDidComplete(event _: CheckoutCompletedEvent) {}
            func checkoutDidFail(error _: CheckoutError) {}
            func checkoutDidCancel() {}
            func checkoutDidClickLink(url _: URL) {}

            func checkoutDidEmitWebPixelEvent(event: PixelEvent) {
                webPixelCallbackInvoked = true
                receivedEvent = event
                expectation.fulfill()
            }
        }

        let expectation = XCTestExpectation(description: "Web pixel delegate method should be invoked")
        let delegate = TestDelegate(expectation: expectation)

        viewController = ApplePayViewController(
            identifier: mockIdentifier,
            configuration: mockConfiguration,
            checkoutDelegate: delegate
        )

        let customEvent = CustomEvent(context: nil, customData: nil, id: "test-id", name: "page_viewed", timestamp: nil)
        let testEvent = PixelEvent.customEvent(customEvent)
        viewController.checkoutDidEmitWebPixelEvent(event: testEvent)

        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(delegate.webPixelCallbackInvoked, "Web pixel delegate method should be invoked")
        // Extract name from the PixelEvent enum
        let expectedName: String?
        switch testEvent {
        case let .customEvent(customEvent):
            expectedName = customEvent.name
        case let .standardEvent(standardEvent):
            expectedName = standardEvent.name
        }

        let receivedName: String?
        if let receivedEvent = delegate.receivedEvent {
            switch receivedEvent {
            case let .customEvent(customEvent):
                receivedName = customEvent.name
            case let .standardEvent(standardEvent):
                receivedName = standardEvent.name
            }
        } else {
            receivedName = nil
        }

        XCTAssertEqual(receivedName, expectedName, "Event should be passed to delegate")
    }

    @MainActor
    func testShouldRecoverFromError() async {
        class TestDelegate: CheckoutDelegate {
            var recoveryDecision = true
            var errorRecoveryAsked = false
            let expectation: XCTestExpectation

            init(expectation: XCTestExpectation, recoveryDecision: Bool = true) {
                self.expectation = expectation
                self.recoveryDecision = recoveryDecision
            }

            func checkoutDidComplete(event _: CheckoutCompletedEvent) {}
            func checkoutDidFail(error _: CheckoutError) {}
            func checkoutDidCancel() {}
            func checkoutDidClickLink(url _: URL) {}
            func checkoutDidEmitWebPixelEvent(event _: PixelEvent) {}

            func shouldRecoverFromError(error _: CheckoutError) -> Bool {
                errorRecoveryAsked = true
                expectation.fulfill()
                return recoveryDecision
            }
        }

        let expectation = XCTestExpectation(description: "Should recovery delegate method should be invoked")
        let delegate = TestDelegate(expectation: expectation, recoveryDecision: false)

        viewController = ApplePayViewController(
            identifier: mockIdentifier,
            configuration: mockConfiguration,
            checkoutDelegate: delegate
        )

        let checkoutError = CheckoutError.sdkError(
            underlying: NSError(domain: "TestError", code: 0, userInfo: nil),
            recoverable: true
        )
        let shouldRecover = viewController.shouldRecoverFromError(error: checkoutError)

        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(delegate.errorRecoveryAsked, "Error recovery delegate method should be invoked")
        XCTAssertFalse(shouldRecover, "Should return delegate's decision")
    }

    // MARK: - No Delegate Tests

    @MainActor
    func testDelegateMethodsWorkWithoutDelegate() async {
        // Create view controller without delegate
        viewController = ApplePayViewController(
            identifier: mockIdentifier,
            configuration: mockConfiguration
        )

        // These should not crash when called without a delegate
        let completedEvent = createEmptyCheckoutCompletedEvent(id: "test-order")
        viewController.checkoutDidComplete(event: completedEvent)

        let checkoutError = CheckoutError.sdkError(
            underlying: NSError(domain: "TestError", code: 0, userInfo: nil),
            recoverable: false
        )
        viewController.checkoutDidFail(error: checkoutError)

        viewController.checkoutDidCancel()

        let testURL = URL(string: "https://test-shop.myshopify.com")!
        viewController.checkoutDidClickLink(url: testURL)

        let customEvent = CustomEvent(context: nil, customData: nil, id: "test-id", name: "test_event", timestamp: nil)
        let testEvent = PixelEvent.customEvent(customEvent)
        viewController.checkoutDidEmitWebPixelEvent(event: testEvent)

        // Wait a moment to ensure no crash occurs
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        XCTAssertTrue(true, "Should not crash when delegate is nil")
    }

    // MARK: - Multiple Event Tests

    @MainActor
    func testMultipleEventsWithSameDelegate() async {
        class TestDelegate: CheckoutDelegate {
            var completeCount = 0
            var failCount = 0
            var cancelCount = 0
            var linkCount = 0
            var webPixelCount = 0

            let completeExpectations: [XCTestExpectation]
            let failExpectations: [XCTestExpectation]
            let cancelExpectations: [XCTestExpectation]

            init(
                completeExpectations: [XCTestExpectation],
                failExpectations: [XCTestExpectation],
                cancelExpectations: [XCTestExpectation]
            ) {
                self.completeExpectations = completeExpectations
                self.failExpectations = failExpectations
                self.cancelExpectations = cancelExpectations
            }

            func checkoutDidComplete(event _: CheckoutCompletedEvent) {
                if completeCount < completeExpectations.count {
                    completeExpectations[completeCount].fulfill()
                }
                completeCount += 1
            }

            func checkoutDidFail(error _: CheckoutError) {
                if failCount < failExpectations.count {
                    failExpectations[failCount].fulfill()
                }
                failCount += 1
            }

            func checkoutDidCancel() {
                if cancelCount < cancelExpectations.count {
                    cancelExpectations[cancelCount].fulfill()
                }
                cancelCount += 1
            }

            func checkoutDidClickLink(url _: URL) {
                linkCount += 1
            }

            func checkoutDidEmitWebPixelEvent(event _: PixelEvent) {
                webPixelCount += 1
            }
        }

        let completeExpectations = [XCTestExpectation(description: "Complete 1"), XCTestExpectation(description: "Complete 2")]
        let failExpectations = [XCTestExpectation(description: "Fail 1"), XCTestExpectation(description: "Fail 2")]
        let cancelExpectations = [XCTestExpectation(description: "Cancel 1"), XCTestExpectation(description: "Cancel 2")]

        let delegate = TestDelegate(
            completeExpectations: completeExpectations,
            failExpectations: failExpectations,
            cancelExpectations: cancelExpectations
        )

        viewController = ApplePayViewController(
            identifier: mockIdentifier,
            configuration: mockConfiguration,
            checkoutDelegate: delegate
        )

        // Trigger multiple events
        for _ in 0 ..< 2 {
            let completedEvent = createEmptyCheckoutCompletedEvent(id: "test-order")
            viewController.checkoutDidComplete(event: completedEvent)

            let checkoutError = CheckoutError.sdkError(
                underlying: NSError(domain: "TestError", code: 0, userInfo: nil),
                recoverable: false
            )
            viewController.checkoutDidFail(error: checkoutError)

            viewController.checkoutDidCancel()

            let testURL = URL(string: "https://test-shop.myshopify.com")!
            viewController.checkoutDidClickLink(url: testURL)

            let customEvent = CustomEvent(context: nil, customData: nil, id: "test-id", name: "test_event", timestamp: nil)
            let testEvent = PixelEvent.customEvent(customEvent)
            viewController.checkoutDidEmitWebPixelEvent(event: testEvent)
        }

        await fulfillment(of: completeExpectations + failExpectations + cancelExpectations, timeout: 2.0)

        XCTAssertEqual(delegate.completeCount, 2, "Should have received 2 complete events")
        XCTAssertEqual(delegate.failCount, 2, "Should have received 2 fail events")
        XCTAssertEqual(delegate.cancelCount, 2, "Should have received 2 cancel events")
        XCTAssertEqual(delegate.linkCount, 2, "Should have received 2 link events")
        XCTAssertEqual(delegate.webPixelCount, 2, "Should have received 2 web pixel events")
    }

    // MARK: - URL Variation Tests

    @MainActor
    func testCheckoutDidClickLinkWithVariousURLs() async {
        class TestDelegate: CheckoutDelegate {
            var receivedURLs: [URL] = []
            var expectations: [XCTestExpectation]
            var currentIndex = 0

            init(expectations: [XCTestExpectation]) {
                self.expectations = expectations
            }

            func checkoutDidComplete(event _: CheckoutCompletedEvent) {}
            func checkoutDidFail(error _: CheckoutError) {}
            func checkoutDidCancel() {}

            func checkoutDidClickLink(url: URL) {
                receivedURLs.append(url)
                if currentIndex < expectations.count {
                    expectations[currentIndex].fulfill()
                    currentIndex += 1
                }
            }

            func checkoutDidEmitWebPixelEvent(event _: PixelEvent) {}
        }

        let testURLs = [
            URL(string: "https://test-shop.myshopify.com/products/test")!,
            URL(string: "https://external-site.com/page")!,
            URL(string: "mailto:test@example.com")!,
            URL(string: "tel:+1234567890")!
        ]

        let expectations = testURLs.map { _ in
            expectation(description: "URL callback")
        }

        let delegate = TestDelegate(expectations: expectations)

        viewController = ApplePayViewController(
            identifier: mockIdentifier,
            configuration: mockConfiguration,
            checkoutDelegate: delegate
        )

        for url in testURLs {
            viewController.checkoutDidClickLink(url: url)
        }

        await fulfillment(of: expectations, timeout: 1.0)
        XCTAssertEqual(delegate.receivedURLs, testURLs, "URLs should be captured in order")
    }
}
