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

class DefaultCheckoutDelegate: CheckoutDelegate {
    func checkoutDidFail(error _: CheckoutError) {}
    func checkoutDidCancel() {}
    func checkoutDidComplete(event _: CheckoutCompletedEvent) {}
    func checkoutDidClickLink(url _: URL) {}
    func checkoutDidEmitWebPixelEvent(event _: PixelEvent) {}

    func shouldRecoverFromError(error: CheckoutError) -> Bool {
        return error.isRecoverable
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

    private let recoverableError = CheckoutError.checkoutUnavailable(message: "Test recoverable", code: .clientError(code: .unknown), recoverable: true)
    private let nonRecoverableError = CheckoutError.checkoutExpired(message: "Test non-recoverable", code: .cartExpired, recoverable: false)

    func test_checkoutViewDidFailWithError_incrementsErrorCount() {
        let mockDelegate = MockCheckoutDelegate()
        let viewController = CheckoutWebViewController(checkoutURL: url, delegate: mockDelegate, entryPoint: nil)

        XCTAssertEqual(viewController.checkoutViewDidFailWithErrorCount, 0)

        viewController.checkoutViewDidFailWithError(error: nonRecoverableError)

        XCTAssertEqual(viewController.checkoutViewDidFailWithErrorCount, 1)
        XCTAssertTrue(mockDelegate.checkoutDidFailCalled)
    }

    func test_checkoutViewDidFailWithError_attemptsRecoveryWhenCountLessThanTwoAndDelegateAllows() {
        let defaultDelegate = DefaultCheckoutDelegate()
        let viewController = TestableCheckoutWebViewController(checkoutURL: url, delegate: defaultDelegate, entryPoint: nil)

        viewController.checkoutViewDidFailWithError(error: recoverableError)

        XCTAssertEqual(viewController.checkoutViewDidFailWithErrorCount, 1)
        XCTAssertTrue(viewController.presentFallbackViewControllerCalled)
        XCTAssertEqual(viewController.presentFallbackViewControllerURL, url)
        XCTAssertFalse(viewController.dismissCalled)
    }

    func test_checkoutViewDidFailWithError_doesNotAttemptRecoveryWhenCountReachesTwo() {
        let defaultDelegate = DefaultCheckoutDelegate()
        let viewController = TestableCheckoutWebViewController(checkoutURL: url, delegate: defaultDelegate, entryPoint: nil)

        viewController.checkoutViewDidFailWithError(error: recoverableError)

        XCTAssertTrue(viewController.presentFallbackViewControllerCalled)
        XCTAssertFalse(viewController.dismissCalled)

        viewController.checkoutViewDidFailWithError(error: recoverableError)

        XCTAssertEqual(viewController.checkoutViewDidFailWithErrorCount, 2)
        XCTAssertTrue(viewController.dismissCalled)
        XCTAssertTrue(viewController.dismissAnimated)
    }

    func test_checkoutViewDidFailWithError_doesNotAttemptRecoveryWhenErrorIsNotRecoverable() {
        let defaultDelegate = DefaultCheckoutDelegate()
        let viewController = TestableCheckoutWebViewController(checkoutURL: url, delegate: defaultDelegate, entryPoint: nil)

        viewController.checkoutViewDidFailWithError(error: nonRecoverableError)

        XCTAssertEqual(viewController.checkoutViewDidFailWithErrorCount, 1)
        XCTAssertTrue(viewController.dismissCalled)
        XCTAssertTrue(viewController.dismissAnimated)
        XCTAssertFalse(viewController.presentFallbackViewControllerCalled)
    }

    func test_checkoutViewDidFailWithError_doesNotAttemptRecoveryForMultipassURL() {
        let defaultDelegate = DefaultCheckoutDelegate()
        let viewController = TestableCheckoutWebViewController(checkoutURL: multipassURL, delegate: defaultDelegate, entryPoint: nil)

        viewController.checkoutViewDidFailWithError(error: recoverableError)

        XCTAssertEqual(viewController.checkoutViewDidFailWithErrorCount, 1)
        XCTAssertTrue(viewController.dismissCalled)
        XCTAssertTrue(viewController.dismissAnimated)
        XCTAssertFalse(viewController.presentFallbackViewControllerCalled)
    }

    func test_checkoutViewDidFailWithError_attemptsRecoveryForFirstFailureThenDismisses() {
        let defaultDelegate = DefaultCheckoutDelegate()
        let viewController = TestableCheckoutWebViewController(checkoutURL: url, delegate: defaultDelegate, entryPoint: nil)

        viewController.checkoutViewDidFailWithError(error: recoverableError)
        XCTAssertEqual(viewController.checkoutViewDidFailWithErrorCount, 1)
        XCTAssertTrue(viewController.presentFallbackViewControllerCalled)
        XCTAssertFalse(viewController.dismissCalled)

        viewController.presentFallbackViewControllerCalled = false

        viewController.checkoutViewDidFailWithError(error: recoverableError)
        XCTAssertEqual(viewController.checkoutViewDidFailWithErrorCount, 2)
        XCTAssertFalse(viewController.presentFallbackViewControllerCalled)
        XCTAssertTrue(viewController.dismissCalled)
        XCTAssertTrue(viewController.dismissAnimated)
    }

    func test_checkoutViewDidFailWithError_respectsErrorRecoverableProperty() {
        struct TestCase {
            let name: String
            let error: CheckoutError
            let expectedRecoverable: Bool
        }

        let testCases: [TestCase] = [
            TestCase(
                name: "sdkError recoverable=true",
                error: .sdkError(underlying: NSError(domain: "test", code: 1), recoverable: true),
                expectedRecoverable: true
            ),
            TestCase(
                name: "sdkError recoverable=false",
                error: .sdkError(underlying: NSError(domain: "test", code: 1), recoverable: false),
                expectedRecoverable: false
            ),
            TestCase(
                name: "configurationError recoverable=true",
                error: .configurationError(message: "Test config", code: .unknown, recoverable: true),
                expectedRecoverable: true
            ),
            TestCase(
                name: "configurationError recoverable=false",
                error: .configurationError(message: "Test config", code: .unknown, recoverable: false),
                expectedRecoverable: false
            ),
            TestCase(
                name: "checkoutUnavailable recoverable=true",
                error: .checkoutUnavailable(message: "Test unavailable", code: .httpError(statusCode: 500), recoverable: true),
                expectedRecoverable: true
            ),
            TestCase(
                name: "checkoutUnavailable recoverable=false",
                error: .checkoutUnavailable(message: "Test unavailable", code: .httpError(statusCode: 500), recoverable: false),
                expectedRecoverable: false
            ),
            TestCase(
                name: "checkoutExpired recoverable=true",
                error: .checkoutExpired(message: "Test expired", code: .cartExpired, recoverable: true),
                expectedRecoverable: true
            ),
            TestCase(
                name: "checkoutExpired recoverable=false",
                error: .checkoutExpired(message: "Test expired", code: .cartExpired, recoverable: false),
                expectedRecoverable: false
            )
        ]

        for testCase in testCases {
            let defaultDelegate = DefaultCheckoutDelegate()
            let viewController = TestableCheckoutWebViewController(checkoutURL: url, delegate: defaultDelegate, entryPoint: nil)

            viewController.checkoutViewDidFailWithError(error: testCase.error)

            if testCase.expectedRecoverable {
                XCTAssertTrue(viewController.presentFallbackViewControllerCalled, "Failed for \(testCase.name): should attempt recovery")
                XCTAssertFalse(viewController.dismissCalled, "Failed for \(testCase.name): should not dismiss")
            } else {
                XCTAssertFalse(viewController.presentFallbackViewControllerCalled, "Failed for \(testCase.name): should not attempt recovery")
                XCTAssertTrue(viewController.dismissCalled, "Failed for \(testCase.name): should dismiss")
            }

            // Verify the error's isRecoverable property matches expectation
            XCTAssertEqual(testCase.error.isRecoverable, testCase.expectedRecoverable, "Failed for \(testCase.name): isRecoverable mismatch")
        }
    }
}
