import PassKit
@testable import ShopifyAcceleratedCheckouts
import ShopifyCheckoutSheetKit
import UIKit
import XCTest

@available(iOS 17.0, *)
class ApplePayViewControllerTests: XCTestCase {
    var viewController: ApplePayViewController!
    var mockConfiguration: ApplePayConfigurationWrapper!

    override func setUp() {
        super.setUp()

        // Create mock shop settings
        let paymentSettings = PaymentSettings(countryCode: "US")
        let primaryDomain = Domain(host: "test-shop.myshopify.com", url: "https://test-shop.myshopify.com")
        let shopSettings = ShopSettings(
            name: "Test Shop",
            primaryDomain: primaryDomain,
            paymentSettings: paymentSettings
        )

        // Create common configuration
        let commonConfig = ShopifyAcceleratedCheckouts.Configuration(
            shopDomain: "test-shop.myshopify.com",
            storefrontAccessToken: "test-token"
        )

        // Create Apple Pay configuration
        let applePayConfig = ShopifyAcceleratedCheckouts.ApplePayConfiguration(
            merchantIdentifier: "test.merchant",
            supportedNetworks: [.visa, .masterCard],
            contactFields: []
        )

        // Create configuration wrapper
        mockConfiguration = ApplePayConfigurationWrapper(
            common: commonConfig,
            applePay: applePayConfig,
            shopSettings: shopSettings
        )

        // Create system under test
        let identifier = CheckoutIdentifier.cart(cartID: "gid://Shopify/Cart/test-cart-id")
        viewController = ApplePayViewController(
            identifier: identifier,
            configuration: mockConfiguration
        )
    }

    override func tearDown() {
        viewController = nil
        mockConfiguration = nil
        super.tearDown()
    }

    func testOnCheckoutSuccessCallback_defaultsToNil() async {
        await MainActor.run {
            XCTAssertNil(viewController.onComplete)
        }
    }

    func testOnCheckoutErrorCallback_defaultsToNil() async {
        await MainActor.run {
            XCTAssertNil(viewController.onFail)
        }
    }

    func testOnCheckoutCancelCallback_defaultsToNil() async {
        await MainActor.run {
            XCTAssertNil(viewController.onCancel)
        }
    }

    func testCheckoutDidCancel_invokesOnCancelCallback() async {
        var cancelCallbackInvoked = false
        let expectation = XCTestExpectation(description: "Cancel callback should be invoked")

        await MainActor.run {
            viewController.onCancel = {
                cancelCallbackInvoked = true
                expectation.fulfill()
            }
        }

        let delegate = viewController.authorizationDelegate

        delegate.checkoutDidCancel()

        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(cancelCallbackInvoked, "Cancel callback should be invoked when checkoutDidCancel is called")
    }

    func testCheckoutDidCancel_worksWithoutCheckoutViewController() {
        let delegate = viewController.authorizationDelegate
        XCTAssertNil(delegate.checkoutViewController)

        delegate.checkoutDidCancel()
    }

    func testCheckoutDidCancel_worksWithoutOnCancelCallback() async {
        let delegate = viewController.authorizationDelegate
        let isNil = await MainActor.run {
            viewController.onCancel == nil
        }
        XCTAssertTrue(isNil, "onCancel should be nil")

        delegate.checkoutDidCancel()
    }
}
