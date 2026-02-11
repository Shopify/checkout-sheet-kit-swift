@testable import ShopifyCheckoutSheetKit
import WebKit
import XCTest

class CheckoutViewDelegateTests: XCTestCase {
    private var customTitle: String?
    private let checkoutURL = URL(string: "https://checkout-sdk.myshopify.com")!
    private var viewController: MockCheckoutWebViewController!
    private var navigationController: UINavigationController!

    override func setUp() {
        ShopifyCheckoutSheetKit.configure {
            $0.preloading.enabled = true
            $0.title = customTitle ?? "Checkout"
        }
        viewController = MockCheckoutWebViewController(
            checkoutURL: checkoutURL
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

    func testDoesNotInstantiateRecoveryForMultipassURL() throws {
        let controller = try MockCheckoutWebViewController(
            checkoutURL: XCTUnwrap(URL(string: "https://checkout-sdk.myshopify.com/account/login/multipass/token"))
        )

        controller.checkoutViewDidFailWithError(
            error:
            .checkoutUnavailable(message: "error", code: CheckoutUnavailable.httpError(statusCode: 500), recoverable: true)
        )

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

    func testPresentationControllerDidDismissInvalidatesViewCache() throws {
        let one = CheckoutWebView.for(checkout: checkoutURL)
        let two = CheckoutWebView.for(checkout: checkoutURL)
        XCTAssertEqual(one, two)

        let presentationController = try XCTUnwrap(UIViewController().presentationController)
        viewController.presentationControllerDidDismiss(presentationController)

        let three = CheckoutWebView.for(checkout: checkoutURL)
        XCTAssertNotEqual(two, three)
    }

    func testPresentationControllerDidDismissSavesCacheWhenActivatedByClient() throws {
        CheckoutWebView.preloadingActivatedByClient = true
        let one = CheckoutWebView.for(checkout: checkoutURL)
        let two = CheckoutWebView.for(checkout: checkoutURL)
        XCTAssertEqual(one, two)

        let presentationController = try XCTUnwrap(UIViewController().presentationController)
        viewController.presentationControllerDidDismiss(presentationController)

        let three = CheckoutWebView.for(checkout: checkoutURL)
        XCTAssertEqual(one, three)
    }

    func testCheckoutViewDidStartNavigationShowsProgressBar() {
        XCTAssertFalse(viewController.progressBar.isHidden)
        XCTAssertTrue(viewController.initialNavigation)
        XCTAssertFalse(viewController.checkoutView.checkoutDidLoad)

        viewController.checkoutViewDidStartNavigation()
        viewController.checkoutViewDidFinishNavigation()
        XCTAssertFalse(viewController.progressBar.isHidden)
    }

    func testCloseButtonUsesSystemDefaultWhenTintColorIsNil() {
        ShopifyCheckoutSheetKit.configuration.closeButtonTintColor = nil
        let controller = MockCheckoutWebViewController(checkoutURL: checkoutURL)

        let closeButton = controller.navigationItem.rightBarButtonItem
        XCTAssertNotNil(closeButton)
        XCTAssertEqual(closeButton?.style, .plain)
        XCTAssertNil(closeButton?.image)
    }

    func testCloseButtonUsesCustomImageAndTintWhenColorIsSet() {
        let customColor = UIColor.red
        ShopifyCheckoutSheetKit.configuration.closeButtonTintColor = customColor
        let controller = MockCheckoutWebViewController(checkoutURL: checkoutURL)

        let closeButton = controller.navigationItem.rightBarButtonItem
        XCTAssertNotNil(closeButton)
        XCTAssertEqual(closeButton?.style, .plain)
        XCTAssertNotNil(closeButton?.image)
        XCTAssertEqual(closeButton?.tintColor, customColor)
    }

    func testCloseButtonImageIsXMarkCircleFill() {
        ShopifyCheckoutSheetKit.configuration.closeButtonTintColor = .blue
        let controller = MockCheckoutWebViewController(checkoutURL: checkoutURL)

        let closeButton = controller.navigationItem.rightBarButtonItem
        XCTAssertNotNil(closeButton?.image)
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
