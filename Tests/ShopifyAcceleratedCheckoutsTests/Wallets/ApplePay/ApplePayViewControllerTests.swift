import PassKit
@testable import ShopifyAcceleratedCheckouts
import ShopifyCheckoutSheetKit
import UIKit
import XCTest

@available(iOS 17.0, *)
class ApplePayViewControllerTests: XCTestCase {
    var sut: ApplePayViewController!
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
        sut = ApplePayViewController(
            identifier: identifier,
            configuration: mockConfiguration
        )
    }

    override func tearDown() {
        sut = nil
        mockConfiguration = nil
        super.tearDown()
    }

    // MARK: - Callback Properties Tests

    func testOnCheckoutSuccessCallback_defaultsToNil() async {
        await MainActor.run {
            XCTAssertNil(sut.onComplete)
        }
    }

    func testOnCheckoutErrorCallback_defaultsToNil() async {
        await MainActor.run {
            XCTAssertNil(sut.onFail)
        }
    }

    func testOnCheckoutCancelCallback_defaultsToNil() async {
        await MainActor.run {
            XCTAssertNil(sut.onCancel)
        }
    }

    // MARK: - Delegate Tests

    func testCheckoutDidCancel_invokesOnCancelCallback() async {
        // Given
        var cancelCallbackInvoked = false
        let expectation = XCTestExpectation(description: "Cancel callback should be invoked")

        await MainActor.run {
            sut.onCancel = {
                cancelCallbackInvoked = true
                expectation.fulfill()
            }
        }

        let delegate = sut.authorizationDelegate

        // When
        delegate.checkoutDidCancel()

        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(cancelCallbackInvoked, "Cancel callback should be invoked when checkoutDidCancel is called")
    }

    func testCheckoutDidCancel_worksWithoutCheckoutViewController() {
        // Given
        let delegate = sut.authorizationDelegate
        XCTAssertNil(delegate.checkoutViewController)

        // When/Then - Should not crash
        delegate.checkoutDidCancel()
    }

    func testCheckoutDidCancel_worksWithoutOnCancelCallback() async {
        // Given
        let delegate = sut.authorizationDelegate
        let isNil = await MainActor.run {
            sut.onCancel == nil
        }
        XCTAssertTrue(isNil, "onCancel should be nil")

        // When/Then - Should not crash
        delegate.checkoutDidCancel()
    }
}
