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

class CheckoutViewDelegateTests: XCTestCase {
    private var customTitle: String?
    private let checkoutURL = URL(string: "https://checkout-sdk.myshopify.com")!
    private var viewController: MockCheckoutWebViewController!
    private var navigationController: UINavigationController!
    private var delegate = ExampleDelegate()

    override func setUp() {
        ShopifyCheckoutSheetKit.configure {
            $0.preloading.enabled = true
            $0.title = customTitle ?? "Checkout"
        }
        viewController = MockCheckoutWebViewController(
            checkoutURL: checkoutURL, delegate: delegate
        )

        navigationController = UINavigationController(rootViewController: viewController)
    }

    override func tearDown() {
        customTitle = nil
        super.tearDown()
    }

    func testTitleIsSetToCheckout() {
        XCTAssertEqual(viewController.title, "Checkout")
    }

    func testTitleCanBeCustomized() {
        customTitle = "Custom title"
        setUp()
        XCTAssertEqual(viewController.title, "Custom title")
    }

    func testCheckoutViewDidCompleteCheckoutInvalidatesViewCache() {
        let one = CheckoutWebView.for(checkout: checkoutURL)
        let two = CheckoutWebView.for(checkout: checkoutURL)
        XCTAssertEqual(one, two)

        viewController.checkoutViewDidCompleteCheckout(event: createEmptyCheckoutCompletedEvent())

        let three = CheckoutWebView.for(checkout: checkoutURL)
        XCTAssertNotEqual(two, three)
    }

    func testCheckoutViewDidFailWithErrorInvalidatesViewCache() {
        let one = CheckoutWebView.for(checkout: checkoutURL)
        let two = CheckoutWebView.for(checkout: checkoutURL)
        XCTAssertEqual(one, two)

        viewController.checkoutViewDidFailWithError(error: .checkoutUnavailable(message: "error", code: CheckoutUnavailable.httpError(statusCode: 500), recoverable: false))

        let three = CheckoutWebView.for(checkout: checkoutURL)
        XCTAssertNotEqual(two, three)
        XCTAssertFalse(viewController.checkoutView.isRecovery)
        XCTAssertTrue(viewController.dismissCalled)
    }

    func testInstantiatesRecoveryWebviewOnRecoverableError() {
        let view = CheckoutWebView.for(checkout: checkoutURL)

        viewController.checkoutViewDidFailWithError(error: .checkoutUnavailable(message: "error", code: CheckoutUnavailable.httpError(statusCode: 500), recoverable: true))

        XCTAssertNotEqual(view, viewController.checkoutView)
        XCTAssertTrue(viewController.checkoutView.isRecovery)
        XCTAssertFalse(viewController.checkoutView.isBridgeAttached)
        XCTAssertFalse(viewController.checkoutView.isPreloadingAvailable)
        XCTAssertFalse(viewController.dismissCalled)

        XCTAssertFalse(viewController.checkoutView.translatesAutoresizingMaskIntoConstraints)
        XCTAssertEqual(viewController.checkoutView.scrollView.contentInsetAdjustmentBehavior, .never)
    }

    func testDoesNotInstantiateRecoveryWebviewOnNonRecoverableError() {
        _ = CheckoutWebView.for(checkout: checkoutURL)

        viewController.checkoutViewDidFailWithError(error: .checkoutUnavailable(message: "error", code: CheckoutUnavailable.httpError(statusCode: 500), recoverable: false))

        XCTAssertFalse(viewController.checkoutView.isRecovery)
    }

    func testDoesNotInstantiateRecoveryForMultipassURL() {
        let controller = MockCheckoutWebViewController(
            checkoutURL: URL(string: "https://checkout-sdk.myshopify.com/account/login/multipass/token")!, delegate: delegate
        )

        controller.checkoutViewDidFailWithError(error:
            .checkoutUnavailable(message: "error", code: CheckoutUnavailable.httpError(statusCode: 500), recoverable: true))

        XCTAssertFalse(controller.checkoutView.isRecovery)
    }

    func testFailWithErrorDisablesPreloadingActivtedByClient() {
        CheckoutWebView.preloadingActivatedByClient = true

        _ = CheckoutWebView.for(checkout: checkoutURL)

        viewController.checkoutViewDidFailWithError(error: .checkoutUnavailable(message: "error", code: CheckoutUnavailable.httpError(statusCode: 500), recoverable: false))

        XCTAssertEqual(false, CheckoutWebView.preloadingActivatedByClient)
    }

    func testCloseInvalidatesViewCache() {
        let one = CheckoutWebView.for(checkout: checkoutURL)
        let two = CheckoutWebView.for(checkout: checkoutURL)
        XCTAssertEqual(one, two)

        viewController.close()

        let three = CheckoutWebView.for(checkout: checkoutURL)
        XCTAssertNotEqual(two, three)
    }

    func testCloseDoesNotInvalidateViewCacheWhenPreloadingIsCalledByClient() {
        ShopifyCheckoutSheetKit.preload(checkout: checkoutURL)

        let one = CheckoutWebView.for(checkout: checkoutURL)
        let two = CheckoutWebView.for(checkout: checkoutURL)
        XCTAssertEqual(one, two)

        viewController.close()

        let three = CheckoutWebView.for(checkout: checkoutURL)
        XCTAssertEqual(one, three)
    }

    func testPresentationControllerDidDismissInvalidatesViewCache() {
        let one = CheckoutWebView.for(checkout: checkoutURL)
        let two = CheckoutWebView.for(checkout: checkoutURL)
        XCTAssertEqual(one, two)

        let presentationController = UIViewController().presentationController!
        viewController.presentationControllerDidDismiss(presentationController)

        let three = CheckoutWebView.for(checkout: checkoutURL)
        XCTAssertNotEqual(two, three)
    }

    func testPresentationControllerDidDismissSavesCacheWhenActivatedByClient() {
        CheckoutWebView.preloadingActivatedByClient = true
        let one = CheckoutWebView.for(checkout: checkoutURL)
        let two = CheckoutWebView.for(checkout: checkoutURL)
        XCTAssertEqual(one, two)

        let presentationController = UIViewController().presentationController!
        viewController.presentationControllerDidDismiss(presentationController)

        let three = CheckoutWebView.for(checkout: checkoutURL)
        XCTAssertEqual(one, three)
    }

    func testCheckoutViewDidClickLinkDoesNotInvalidateViewCache() {
        let one = CheckoutWebView.for(checkout: checkoutURL)
        let two = CheckoutWebView.for(checkout: checkoutURL)
        XCTAssertEqual(one, two)

        viewController.checkoutViewDidClickLink(url: URL(string: "https://shopify.com/anything")!)

        let three = CheckoutWebView.for(checkout: checkoutURL)
        XCTAssertEqual(two, three)
    }

    func testCheckoutViewDidToggleModalAddsAndRemovesNavigationBar() {
        XCTAssertFalse(viewController.navigationController!.isNavigationBarHidden)

        viewController.checkoutViewDidToggleModal(modalVisible: true)
        XCTAssertTrue(viewController.navigationController!.isNavigationBarHidden)

        viewController.checkoutViewDidToggleModal(modalVisible: false)
        XCTAssertFalse(viewController.navigationController!.isNavigationBarHidden)
    }

    func testCheckoutViewDidStartNavigationShowsProgressBar() {
        XCTAssertFalse(viewController.progressBar.isHidden)
        XCTAssertTrue(viewController.initialNavigation)
        XCTAssertFalse(viewController.checkoutView.checkoutDidLoad)

        viewController.checkoutViewDidStartNavigation()
        viewController.checkoutViewDidFinishNavigation()
        XCTAssertFalse(viewController.progressBar.isHidden)
    }
}

protocol Dismissible: AnyObject {
    func dismiss(animated flag: Bool, completion: (() -> Void)?)
}

extension CheckoutWebViewController: Dismissible {}

class MockCheckoutWebViewController: CheckoutWebViewController {
    private(set) var dismissCalled = false

    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        dismissCalled = true
        super.dismiss(animated: flag, completion: completion)
    }
}
