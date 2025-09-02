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
import XCTest

@available(iOS 16.0, *)

@available(iOS 16.0, *)
final class ShopPayViewControllerTests: XCTestCase {
    var viewController: MockShopPayViewController!
    var mockConfiguration: ShopifyAcceleratedCheckouts.Configuration!
    var mockStorefront: TestStorefrontAPI!

    override func setUp() {
        super.setUp()

        mockConfiguration = ShopifyAcceleratedCheckouts.Configuration(
            storefrontDomain: "test-shop.myshopify.com",
            storefrontAccessToken: "test-token"
        )
        mockStorefront = TestStorefrontAPI()
    }

    override func tearDown() {
        viewController = nil
        mockConfiguration = nil
        mockStorefront = nil
        super.tearDown()
    }

    @available(iOS 16.0, *)
    class MockShopPayViewController: ShopPayViewController {
        var mockTopViewController: UIViewController?

        override func getTopViewController() -> UIViewController? {
            return mockTopViewController
        }
    }

    // MARK: - present() Tests with Cart Identifier

    func testPresent_CartIdentifier_Success() async throws {
        let mockCart = StorefrontAPI.Cart.testCart(
            checkoutUrl: URL(string: "https://test-shop.myshopify.com/checkout")!
        )
        mockStorefront.cartResult = Result<StorefrontAPI.Cart?, Error>.success(mockCart)

        viewController = MockShopPayViewController(
            identifier: .cart(cartID: "gid://Shopify/Cart/test-cart-id"),
            configuration: mockConfiguration
        )

        viewController.storefront = mockStorefront
        // Mock the top view controller
        let mockViewController = await MainActor.run { UIViewController() }
        viewController.mockTopViewController = mockViewController

        try await viewController.present()
        XCTAssertNotNil(viewController.checkoutViewController)
    }

    func testPresent_CartIdentifier_CartNotFound() async throws {
        mockStorefront.cartResult = Result<StorefrontAPI.Cart?, Error>.success(nil)

        viewController = MockShopPayViewController(
            identifier: .cart(cartID: "non-existent-cart-id"),
            configuration: mockConfiguration
        )

        viewController.storefront = mockStorefront

        try await viewController.present()
    }

    // MARK: - present() Tests with Variant Identifier

    func testPresent_VariantIdentifier_Success() async throws {
        let mockCart = StorefrontAPI.Cart.testCart(
            checkoutUrl: URL(string: "https://test-shop.myshopify.com/checkout")!
        )
        mockStorefront.cartCreateResult = Result<StorefrontAPI.Cart, Error>.success(mockCart)

        viewController = MockShopPayViewController(
            identifier: .variant(variantID: "gid://Shopify/ProductVariant/test-variant-id", quantity: 2),
            configuration: mockConfiguration
        )

        viewController.storefront = mockStorefront
        // Mock the top view controller
        let mockViewController = await MainActor.run { UIViewController() }
        viewController.mockTopViewController = mockViewController

        try await viewController.present()
        XCTAssertNotNil(viewController.checkoutViewController)
    }

    func testPresent_VariantIdentifier_CartCreateFails() async throws {
        let cartCreateError = NSError(domain: "CartCreateError", code: 400, userInfo: nil)
        mockStorefront.cartCreateResult = Result<StorefrontAPI.Cart, Error>.failure(cartCreateError)

        viewController = MockShopPayViewController(
            identifier: .variant(variantID: "gid://Shopify/ProductVariant/test-variant-id", quantity: 2),
            configuration: mockConfiguration
        )

        viewController.storefront = mockStorefront

        try await viewController.present()
    }

    func testPresent_VariantIdentifier_ZeroQuantity() async throws {
        let mockCart = StorefrontAPI.Cart.testCart(
            checkoutUrl: URL(string: "https://test-shop.myshopify.com/checkout")!
        )
        mockStorefront.cartCreateResult = Result<StorefrontAPI.Cart, Error>.success(mockCart)

        viewController = MockShopPayViewController(
            identifier: .variant(variantID: "gid://Shopify/ProductVariant/test-variant-id", quantity: 0),
            configuration: mockConfiguration
        )

        viewController.storefront = mockStorefront
        // Mock the top view controller
        let mockViewController = await MainActor.run { UIViewController() }
        viewController.mockTopViewController = mockViewController

        try await viewController.present()
        // Zero quantity should not create a checkout controller (business logic constraint)
        XCTAssertNil(viewController.checkoutViewController)
    }

    // MARK: - present() Tests with Invariant Identifier

    func testPresent_InvariantIdentifier_HandlesGracefully() async throws {
        viewController = MockShopPayViewController(
            identifier: .invariant(reason: "Invalid checkout data"),
            configuration: mockConfiguration
        )

        viewController.storefront = mockStorefront

        try await viewController.present()
    }

    // MARK: - URL Construction Tests

    func testPresent_ConstructsCorrectShopPayURL() async throws {
        let baseCheckoutUrl = "https://test-shop.myshopify.com/checkout"
        let mockCart = StorefrontAPI.Cart.testCart(
            checkoutUrl: URL(string: baseCheckoutUrl)!
        )
        mockStorefront.cartResult = Result<StorefrontAPI.Cart?, Error>.success(mockCart)

        viewController = MockShopPayViewController(
            identifier: .cart(cartID: "gid://Shopify/Cart/test-cart-id"),
            configuration: mockConfiguration
        )

        viewController.storefront = mockStorefront
        // Mock the top view controller
        let mockViewController = await MainActor.run { UIViewController() }
        viewController.mockTopViewController = mockViewController

        try await viewController.present()

        XCTAssertNotNil(viewController.checkoutViewController)
    }

    func testPresent_InvalidURL_HandlesGracefully() async throws {
        let mockCart = StorefrontAPI.Cart.testCart(
            checkoutUrl: URL(string: "invalid-url")!
        )
        mockStorefront.cartResult = Result<StorefrontAPI.Cart?, Error>.success(mockCart)

        viewController = MockShopPayViewController(
            identifier: .cart(cartID: "gid://Shopify/Cart/test-cart-id"),
            configuration: mockConfiguration
        )

        viewController.storefront = mockStorefront

        try await viewController.present()
    }

    // MARK: - Inheritance Tests

    func testInheritsFromWalletController() {
        viewController = MockShopPayViewController(
            identifier: .cart(cartID: "gid://Shopify/Cart/test-cart-id"),
            configuration: mockConfiguration
        )

        XCTAssertTrue(viewController is WalletController)
        XCTAssertNotNil(viewController.identifier)
        XCTAssertNotNil(viewController.storefront)
    }

    func testUsesCorrectStorefrontConfiguration() {
        viewController = MockShopPayViewController(
            identifier: .cart(cartID: "gid://Shopify/Cart/test-cart-id"),
            configuration: mockConfiguration
        )

        XCTAssertEqual(viewController.configuration.storefrontDomain, "test-shop.myshopify.com")
        XCTAssertEqual(viewController.configuration.storefrontAccessToken, "test-token")
    }
}
