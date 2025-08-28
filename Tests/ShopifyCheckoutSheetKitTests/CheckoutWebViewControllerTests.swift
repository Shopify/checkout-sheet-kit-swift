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

@testable import ShopifyCheckoutSheetKit
import WebKit
import XCTest

class MockCheckoutDelegate: CheckoutDelegate {
    var shouldRecoverFromErrorResult: Bool = false
    var checkoutDidFailCalled = false
    var checkoutDidCancelCalled = false
    var checkoutDidCompleteCalled = false
    var checkoutDidClickLinkCalled = false
    var checkoutDidEmitWebPixelEventCalled = false

    func checkoutDidFail(error _: CheckoutError) {
        checkoutDidFailCalled = true
    }

    func checkoutDidCancel() {
        checkoutDidCancelCalled = true
    }

    func checkoutDidComplete(event _: CheckoutCompletedEvent) {
        checkoutDidCompleteCalled = true
    }

    func checkoutDidClickLink(url _: URL) {
        checkoutDidClickLinkCalled = true
    }

    func checkoutDidEmitWebPixelEvent(event _: PixelEvent) {
        checkoutDidEmitWebPixelEventCalled = true
    }

    func shouldRecoverFromError(error _: CheckoutError) -> Bool {
        return shouldRecoverFromErrorResult
    }
}

class TestableCheckoutWebViewController: CheckoutWebViewController {
    var presentFallbackViewControllerCalled = false
    var dismissCalled = false
    var presentFallbackViewControllerURL: URL?
    var dismissAnimated: Bool = false

    override func presentFallbackViewController(url: URL) {
        presentFallbackViewControllerCalled = true
        presentFallbackViewControllerURL = url
    }

    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        dismissCalled = true
        dismissAnimated = flag
        completion?()
    }
}

class CheckoutWebViewControllerTests: XCTestCase {
    private let url = URL(string: "http://shopify1.shopify.com/checkouts/cn/123")!
    private let multipassURL = URL(string: "http://shopify1.shopify.com/checkouts/cn/123?multipass=token")!

    func test_init_withNilEntryPoint_shouldSetCorrectUserAgent() {
        let viewController = CheckoutWebViewController(checkoutURL: url, delegate: nil, entryPoint: nil)

        let expectedUserAgent = CheckoutBridge.applicationName(entryPoint: nil)

        XCTAssertEqual(viewController.checkoutView.configuration.applicationNameForUserAgent, expectedUserAgent)
    }

    func test_init_withAcceleratedCheckoutsEntryPoint_shouldSetCorrectUserAgent() {
        let viewController = CheckoutWebViewController(checkoutURL: url, delegate: nil, entryPoint: .acceleratedCheckouts)

        let expectedUserAgent = CheckoutBridge.applicationName(entryPoint: .acceleratedCheckouts)

        XCTAssertEqual(viewController.checkoutView.configuration.applicationNameForUserAgent, expectedUserAgent)
    }

    func test_checkoutViewDidFailWithError_incrementsErrorCount() {
        let mockDelegate = MockCheckoutDelegate()
        let viewController = CheckoutWebViewController(checkoutURL: url, delegate: mockDelegate, entryPoint: nil)
        let error = CheckoutError.checkoutExpired(message: "Test expired", code: .cartExpired, recoverable: false)

        XCTAssertEqual(viewController.checkoutViewDidFailWithErrorCount, 0)

        viewController.checkoutViewDidFailWithError(error: error)

        XCTAssertEqual(viewController.checkoutViewDidFailWithErrorCount, 1)
        XCTAssertTrue(mockDelegate.checkoutDidFailCalled)
    }

    func test_checkoutViewDidFailWithError_attemptsRecoveryWhenCountLessThanThreeAndDelegateAllows() {
        let mockDelegate = MockCheckoutDelegate()
        mockDelegate.shouldRecoverFromErrorResult = true
        let viewController = TestableCheckoutWebViewController(checkoutURL: url, delegate: mockDelegate, entryPoint: nil)
        let error = CheckoutError.checkoutUnavailable(message: "Test unavailable", code: .clientError(code: .unknown), recoverable: true)

        viewController.checkoutViewDidFailWithError(error: error)

        XCTAssertEqual(viewController.checkoutViewDidFailWithErrorCount, 1)
        XCTAssertTrue(viewController.presentFallbackViewControllerCalled)
        XCTAssertEqual(viewController.presentFallbackViewControllerURL, url)
        XCTAssertFalse(viewController.dismissCalled)
    }

    func test_checkoutViewDidFailWithError_doesNotAttemptRecoveryWhenCountReachesThree() {
        let mockDelegate = MockCheckoutDelegate()
        mockDelegate.shouldRecoverFromErrorResult = true
        let viewController = TestableCheckoutWebViewController(checkoutURL: url, delegate: mockDelegate, entryPoint: nil)

        let error = CheckoutError.checkoutUnavailable(message: "Test unavailable", code: .clientError(code: .unknown), recoverable: true)

        viewController.checkoutViewDidFailWithError(error: error)
        viewController.checkoutViewDidFailWithError(error: error)

        XCTAssertTrue(viewController.presentFallbackViewControllerCalled)
        XCTAssertFalse(viewController.dismissCalled)

        viewController.checkoutViewDidFailWithError(error: error)

        XCTAssertEqual(viewController.checkoutViewDidFailWithErrorCount, 3)
        XCTAssertTrue(viewController.dismissCalled)
        XCTAssertTrue(viewController.dismissAnimated)
    }

    func test_checkoutViewDidFailWithError_doesNotAttemptRecoveryWhenDelegateDeclines() {
        let mockDelegate = MockCheckoutDelegate()
        mockDelegate.shouldRecoverFromErrorResult = false
        let viewController = TestableCheckoutWebViewController(checkoutURL: url, delegate: mockDelegate, entryPoint: nil)

        let error = CheckoutError.checkoutUnavailable(message: "Test unavailable", code: .clientError(code: .unknown), recoverable: true)
        viewController.checkoutViewDidFailWithError(error: error)

        XCTAssertEqual(viewController.checkoutViewDidFailWithErrorCount, 1)
        XCTAssertTrue(mockDelegate.checkoutDidFailCalled)
        XCTAssertTrue(viewController.dismissCalled)
        XCTAssertTrue(viewController.dismissAnimated)
        XCTAssertFalse(viewController.presentFallbackViewControllerCalled)
    }

    func test_checkoutViewDidFailWithError_doesNotAttemptRecoveryForMultipassURL() {
        let mockDelegate = MockCheckoutDelegate()
        mockDelegate.shouldRecoverFromErrorResult = true
        let viewController = TestableCheckoutWebViewController(checkoutURL: multipassURL, delegate: mockDelegate, entryPoint: nil)

        let error = CheckoutError.checkoutUnavailable(message: "Test unavailable", code: .clientError(code: .unknown), recoverable: true)
        viewController.checkoutViewDidFailWithError(error: error)

        XCTAssertEqual(viewController.checkoutViewDidFailWithErrorCount, 1)
        XCTAssertTrue(mockDelegate.checkoutDidFailCalled)
        XCTAssertTrue(viewController.dismissCalled)
        XCTAssertTrue(viewController.dismissAnimated)
        XCTAssertFalse(viewController.presentFallbackViewControllerCalled)
    }

    func test_checkoutViewDidFailWithError_attemptsRecoveryForFirstTwoFailuresThenDismisses() {
        let mockDelegate = MockCheckoutDelegate()
        mockDelegate.shouldRecoverFromErrorResult = true
        let viewController = TestableCheckoutWebViewController(checkoutURL: url, delegate: mockDelegate, entryPoint: nil)

        let error = CheckoutError.checkoutUnavailable(message: "Test unavailable", code: .clientError(code: .unknown), recoverable: true)

        viewController.checkoutViewDidFailWithError(error: error)
        XCTAssertEqual(viewController.checkoutViewDidFailWithErrorCount, 1)
        XCTAssertTrue(viewController.presentFallbackViewControllerCalled)
        XCTAssertFalse(viewController.dismissCalled)

        viewController.presentFallbackViewControllerCalled = false

        viewController.checkoutViewDidFailWithError(error: error)
        XCTAssertEqual(viewController.checkoutViewDidFailWithErrorCount, 2)
        XCTAssertTrue(viewController.presentFallbackViewControllerCalled)
        XCTAssertFalse(viewController.dismissCalled)

        viewController.presentFallbackViewControllerCalled = false

        viewController.checkoutViewDidFailWithError(error: error)
        XCTAssertEqual(viewController.checkoutViewDidFailWithErrorCount, 3)
        XCTAssertFalse(viewController.presentFallbackViewControllerCalled)
        XCTAssertTrue(viewController.dismissCalled)
        XCTAssertTrue(viewController.dismissAnimated)
    }
}
