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
import ShopifyCheckoutSheetKit
import UIKit
import XCTest

@available(iOS 17.0, *)
class ApplePayViewControllerTests: XCTestCase {
    var viewController: ApplePayViewController!
    var mockConfiguration: ApplePayConfigurationWrapper!
    var mockStorefront: TestStorefrontAPI!

    override func setUp() {
        super.setUp()

        // Create mock shop settings
        let paymentSettings = PaymentSettings(countryCode: "US", acceptedCardBrands: [.visa, .mastercard])
        let primaryDomain = Domain(host: "test-shop.myshopify.com", url: "https://test-shop.myshopify.com")
        let shopSettings = ShopSettings(
            name: "Test Shop",
            primaryDomain: primaryDomain,
            paymentSettings: paymentSettings
        )

        // Create common configuration
        let commonConfig = ShopifyAcceleratedCheckouts.Configuration(
            storefrontDomain: "test-shop.myshopify.com",
            storefrontAccessToken: "test-token"
        )

        // Create Apple Pay configuration
        let applePayConfig = ShopifyAcceleratedCheckouts.ApplePayConfiguration(
            merchantIdentifier: "test.merchant",
            contactFields: []
        )

        // Create configuration wrapper
        mockConfiguration = ApplePayConfigurationWrapper(
            common: commonConfig,
            applePay: applePayConfig,
            shopSettings: shopSettings
        )

        // Create mock storefront
        mockStorefront = TestStorefrontAPI()

        // Create system under test
        let identifier = CheckoutIdentifier.cart(cartID: "gid://Shopify/Cart/test-cart-id")
        viewController = ApplePayViewController(
            identifier: identifier,
            configuration: mockConfiguration
        )

        // Inject mock storefront to prevent real HTTP requests
        viewController.storefront = mockStorefront
    }

    override func tearDown() {
        viewController = nil
        mockConfiguration = nil
        mockStorefront = nil
        super.tearDown()
    }

    // MARK: - Callback Properties Tests

    func testOnCheckoutSuccessCallback_defaultsToNil() async {
        await MainActor.run {
            XCTAssertNil(viewController.onCheckoutComplete)
        }
    }

    func testOnCheckoutErrorCallback_defaultsToNil() async {
        await MainActor.run {
            XCTAssertNil(viewController.onCheckoutFail)
        }
    }

    func testOnCheckoutCancelCallback_defaultsToNil() async {
        await MainActor.run {
            XCTAssertNil(viewController.onCheckoutCancel)
        }
    }

    // MARK: - Delegate Tests

    @MainActor
    func testCheckoutDidCancel_invokesOnCancelCallback() async {
        var cancelCallbackInvoked = false
        let expectation = XCTestExpectation(description: "Cancel callback should be invoked")

        viewController.onCheckoutCancel = {
            cancelCallbackInvoked = true
            expectation.fulfill()
        }

        viewController.checkoutDidCancel()

        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(cancelCallbackInvoked, "Cancel callback should be invoked when checkoutDidCancel is called")
    }

    func testCheckoutDidCancel_worksWithoutCheckoutViewController() async {
        XCTAssertNil(viewController.checkoutViewController)

        await MainActor.run {
            viewController.checkoutDidCancel()
        }
    }

    func testCheckoutDidCancel_worksWithoutOnCancelCallback() async {
        let isNil = await MainActor.run {
            viewController.onCheckoutCancel == nil
        }
        XCTAssertTrue(isNil, "onCancel should be nil")

        await MainActor.run {
            viewController.checkoutDidCancel()
        }
    }

    // MARK: - WalletController Inheritance Tests

    func testUsesCorrectStorefrontConfiguration() {
        XCTAssertEqual(viewController.configuration.common.storefrontDomain, "test-shop.myshopify.com")
        XCTAssertEqual(viewController.configuration.common.storefrontAccessToken, "test-token")
    }

    func testCreateOrFetchCart_UsesFetchCartByCheckoutIdentifier() async throws {
        let mockCart = StorefrontAPI.Cart.testCart(
            checkoutUrl: URL(string: "https://test-shop.myshopify.com/checkout")!
        )
        mockStorefront.cartResult = Result<StorefrontAPI.Cart?, Error>.success(mockCart)

        await XCTAssertNoThrowAsync(try await viewController.createOrfetchCart())
    }
}
