@testable import ShopifyCheckoutSheetKit
import WebKit
import XCTest

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

    private let recoverableError = CheckoutError.checkoutUnavailable(message: "Test recoverable", code: .httpError(statusCode: 500), recoverable: true)
    private let nonRecoverableError = CheckoutError.checkoutExpired(message: "Test non-recoverable", code: .cartExpired, recoverable: false)

    func test_init_withNilEntryPoint_shouldSetCorrectUserAgent() {
        let viewController = CheckoutWebViewController(checkoutURL: url, entryPoint: nil)

        let expectedUserAgent = CheckoutBridge.applicationName(entryPoint: nil)

        XCTAssertEqual(viewController.checkoutView.configuration.applicationNameForUserAgent, expectedUserAgent)
    }

    func test_init_withAcceleratedCheckoutsEntryPoint_shouldSetCorrectUserAgent() {
        let viewController = CheckoutWebViewController(checkoutURL: url, entryPoint: .acceleratedCheckouts)

        let expectedUserAgent = CheckoutBridge.applicationName(entryPoint: .acceleratedCheckouts)

        XCTAssertEqual(viewController.checkoutView.configuration.applicationNameForUserAgent, expectedUserAgent)
    }

    func test_checkoutViewDidFailWithError_incrementsErrorCount() {
        var failCalled = false
        let viewController = CheckoutWebViewController(checkoutURL: url, entryPoint: nil)
        viewController.onFail = { _ in failCalled = true }

        XCTAssertEqual(viewController.checkoutViewDidFailWithErrorCount, 0)

        viewController.checkoutViewDidFailWithError(error: nonRecoverableError)

        XCTAssertEqual(viewController.checkoutViewDidFailWithErrorCount, 1)
        XCTAssertTrue(failCalled)
    }

    func test_checkoutViewDidFailWithError_attemptsRecoveryWhenRecoverable() {
        let viewController = TestableCheckoutWebViewController(checkoutURL: url, entryPoint: nil)

        viewController.checkoutViewDidFailWithError(error: recoverableError)

        XCTAssertEqual(viewController.checkoutViewDidFailWithErrorCount, 1)
        XCTAssertTrue(viewController.presentFallbackViewControllerCalled)
        XCTAssertEqual(viewController.presentFallbackViewControllerURL, url)
        XCTAssertFalse(viewController.dismissCalled)
    }

    func test_checkoutViewDidFailWithError_doesNotAttemptRecoveryWhenCountReachesTwo() {
        let viewController = TestableCheckoutWebViewController(checkoutURL: url, entryPoint: nil)

        viewController.checkoutViewDidFailWithError(error: recoverableError)

        XCTAssertTrue(viewController.presentFallbackViewControllerCalled)
        XCTAssertFalse(viewController.dismissCalled)

        viewController.checkoutViewDidFailWithError(error: recoverableError)

        XCTAssertEqual(viewController.checkoutViewDidFailWithErrorCount, 2)
        XCTAssertTrue(viewController.dismissCalled)
        XCTAssertTrue(viewController.dismissAnimated)
    }

    func test_checkoutViewDidFailWithError_doesNotAttemptRecoveryWhenErrorIsNotRecoverable() {
        let viewController = TestableCheckoutWebViewController(checkoutURL: url, entryPoint: nil)

        viewController.checkoutViewDidFailWithError(error: nonRecoverableError)

        XCTAssertEqual(viewController.checkoutViewDidFailWithErrorCount, 1)
        XCTAssertTrue(viewController.dismissCalled)
        XCTAssertTrue(viewController.dismissAnimated)
        XCTAssertFalse(viewController.presentFallbackViewControllerCalled)
    }

    func test_checkoutViewDidFailWithError_doesNotAttemptRecoveryForMultipassURL() {
        let viewController = TestableCheckoutWebViewController(checkoutURL: multipassURL, entryPoint: nil)

        viewController.checkoutViewDidFailWithError(error: recoverableError)

        XCTAssertEqual(viewController.checkoutViewDidFailWithErrorCount, 1)
        XCTAssertTrue(viewController.dismissCalled)
        XCTAssertTrue(viewController.dismissAnimated)
        XCTAssertFalse(viewController.presentFallbackViewControllerCalled)
    }

    func test_checkoutViewDidFailWithError_attemptsRecoveryForFirstFailureThenDismisses() {
        let viewController = TestableCheckoutWebViewController(checkoutURL: url, entryPoint: nil)

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
            let viewController = TestableCheckoutWebViewController(checkoutURL: url, entryPoint: nil)

            viewController.checkoutViewDidFailWithError(error: testCase.error)

            if testCase.expectedRecoverable {
                XCTAssertTrue(viewController.presentFallbackViewControllerCalled, "Failed for \(testCase.name): should attempt recovery")
                XCTAssertFalse(viewController.dismissCalled, "Failed for \(testCase.name): should not dismiss")
            } else {
                XCTAssertFalse(viewController.presentFallbackViewControllerCalled, "Failed for \(testCase.name): should not attempt recovery")
                XCTAssertTrue(viewController.dismissCalled, "Failed for \(testCase.name): should dismiss")
            }

            XCTAssertEqual(testCase.error.isRecoverable, testCase.expectedRecoverable, "Failed for \(testCase.name): isRecoverable mismatch")
        }
    }
}
