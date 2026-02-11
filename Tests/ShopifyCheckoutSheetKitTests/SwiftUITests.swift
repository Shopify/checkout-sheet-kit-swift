@testable import ShopifyCheckoutSheetKit
import XCTest

class CheckoutViewControllerTests: XCTestCase {
    var checkoutURL: URL!
    var checkoutViewController: CheckoutViewController!

    override func setUp() {
        super.setUp()
        checkoutURL = URL(string: "https://www.shopify.com")
        checkoutViewController = CheckoutViewController(checkout: checkoutURL)
    }

    func testInit() {
        XCTAssertNotNil(checkoutViewController)
    }
}

class CheckoutSheetTests: XCTestCase {
    var checkoutURL: URL!
    var checkoutSheet: CheckoutSheet!

    override func setUp() {
        super.setUp()
        checkoutURL = URL(string: "https://www.shopify.com")
        checkoutSheet = CheckoutSheet(checkout: checkoutURL)
    }

    func testOnCancel() {
        var cancelActionCalled = false

        let sheet = checkoutSheet.onCancel {
            cancelActionCalled = true
        }
        sheet.onCancelAction?()
        XCTAssertTrue(cancelActionCalled)
    }

    func testOnFail() {
        var actionCalled = false
        var actionData: CheckoutError?
        let error: CheckoutError = .checkoutUnavailable(message: "error", code: CheckoutUnavailable.httpError(statusCode: 500), recoverable: false)

        let sheet = checkoutSheet.onFail { failure in
            actionCalled = true
            actionData = failure
        }

        sheet.onFailAction?(error)
        XCTAssertTrue(actionCalled)
        XCTAssertNotNil(actionData)
    }

    func testConnect() {
        let handler = MockBridgeHandler()
        let sheet = checkoutSheet.connect(handler)
        XCTAssertNotNil(sheet.bridgeHandler)
    }
}

class CheckoutConfigurableTests: XCTestCase {
    var checkoutURL: URL!
    var checkoutSheet: CheckoutSheet!

    override func setUp() {
        super.setUp()
        checkoutURL = URL(string: "https://www.shopify.com")
        checkoutSheet = CheckoutSheet(checkout: checkoutURL)
    }

    func testBackgroundColor() {
        let color = UIColor.red
        checkoutSheet.backgroundColor(color)
        XCTAssertEqual(ShopifyCheckoutSheetKit.configuration.backgroundColor, color)
    }

    func testColorScheme() {
        let colorScheme = ShopifyCheckoutSheetKit.Configuration.ColorScheme.light
        checkoutSheet.colorScheme(colorScheme)
        XCTAssertEqual(ShopifyCheckoutSheetKit.configuration.colorScheme, colorScheme)
    }

    func testTintColor() {
        let color = UIColor.blue
        checkoutSheet.tintColor(color)
        XCTAssertEqual(ShopifyCheckoutSheetKit.configuration.tintColor, color)
    }

    func testTitle() {
        let title = "Test Title"
        checkoutSheet.title(title)
        XCTAssertEqual(ShopifyCheckoutSheetKit.configuration.title, title)
    }

    func testCloseButtonTintColor() {
        let color = UIColor.green
        checkoutSheet.closeButtonTintColor(color)
        XCTAssertEqual(ShopifyCheckoutSheetKit.configuration.closeButtonTintColor, color)
    }

    func testCloseButtonTintColorNil() {
        checkoutSheet.closeButtonTintColor(nil)
        XCTAssertNil(ShopifyCheckoutSheetKit.configuration.closeButtonTintColor)
    }
}
