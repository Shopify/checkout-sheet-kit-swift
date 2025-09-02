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

import ShopifyCheckoutSheetKit
import XCTest

@testable import ShopifyAcceleratedCheckouts

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
        var mockStorefront: TestStorefrontAPI
        var presentCalls: [(url: URL, delegate: CheckoutDelegate)] = []

        override func getTopViewController() -> UIViewController? {
            return mockTopViewController
        }

        /// Mocks the calls to ShopifyCheckoutSheetKit
        @MainActor
        override func present(url: URL, delegate: CheckoutDelegate) async throws {
            presentCalls.append((url: url, delegate: delegate))
        }

        init(
            identifier: CheckoutIdentifier,
            configuration: ShopifyAcceleratedCheckouts.Configuration,
            eventHandlers: EventHandlers = EventHandlers(),
            storefront: TestStorefrontAPI = TestStorefrontAPI()
        ) {
            mockStorefront = storefront
            super.init(
                identifier: identifier,
                configuration: configuration,
                eventHandlers: eventHandlers
            )
            self.storefront = storefront
        }
    }

    // MARK: - onPress() Tests with Cart Identifier

    func test_onPress_withCartIdentifier_shouldCallPresentWithShopPayURL() async throws {
        let mockCart = StorefrontAPI.Cart.testCart()

        viewController = MockShopPayViewController(
            identifier: .cart(cartID: "gid://Shopify/Cart/test-cart-id"),
            configuration: mockConfiguration,
            storefront: mockStorefront
        )
        viewController.mockStorefront.cartResult = .success(mockCart)

        await viewController.onPress()

        XCTAssertEqual(viewController.presentCalls.count, 1)
        XCTAssertEqual(
            viewController.presentCalls[0].url.absoluteString,
            "https://test-shop.myshopify.com/checkout?payment=shop_pay"
        )
    }

    func test_onPress_withCartIdentifierCartNotFound_shouldNotCallPresent() async throws {
        viewController = MockShopPayViewController(
            identifier: .cart(cartID: "non-existent-cart-id"),
            configuration: mockConfiguration,
            storefront: mockStorefront
        )
        viewController.mockStorefront.cartResult = .success(nil)

        await viewController.onPress()

        XCTAssertTrue(viewController.presentCalls.isEmpty)
    }

    // MARK: - onPress() Tests with Variant Identifier

    func test_onPress_withVariantIdentifier_shouldCallPresent() async throws {
        let mockCart = StorefrontAPI.Cart.testCart()

        viewController = MockShopPayViewController(
            identifier: .variant(
                variantID: "gid://Shopify/ProductVariant/test-variant-id",
                quantity: 2
            ),
            configuration: mockConfiguration,
            storefront: mockStorefront
        )
        viewController.mockStorefront.cartCreateResult = .success(mockCart)

        await viewController.onPress()

        XCTAssertEqual(viewController.presentCalls.count, 1)
        XCTAssertEqual(
            viewController.presentCalls[0].url.absoluteString,
            "https://test-shop.myshopify.com/checkout?payment=shop_pay"
        )
    }

    func test_onPress_withVariantIdentifier_whenCartCreateFails_shouldNotCallPresent()
        async throws
    {
        let cartCreateError = NSError(domain: "CartCreateError", code: 400, userInfo: nil)

        viewController = MockShopPayViewController(
            identifier: .variant(
                variantID: "gid://Shopify/ProductVariant/test-variant-id",
                quantity: 2
            ),
            configuration: mockConfiguration,
            storefront: mockStorefront
        )
        viewController.mockStorefront.cartCreateResult = .failure(cartCreateError)

        await viewController.onPress()

        XCTAssertTrue(viewController.presentCalls.isEmpty)
    }

    func test_onPress_withInvalidZeroQuantityVariantIdentifier_shouldNotCreateCheckoutController()
        async throws
    {
        let mockCart = StorefrontAPI.Cart.testCart()

        viewController = MockShopPayViewController(
            identifier: .variant(
                variantID: "gid://Shopify/ProductVariant/test-variant-id",
                quantity: 0
            ),
            configuration: mockConfiguration,
            storefront: mockStorefront
        )
        viewController.mockStorefront.cartCreateResult = .success(mockCart)

        await viewController.onPress()

        XCTAssertNil(viewController.checkoutViewController)
        XCTAssertTrue(viewController.presentCalls.isEmpty)
    }

    // MARK: - onPress() Tests with Invariant Identifier

    func test_onPress_withInvariantIdentifier_shouldNotCallPresent() async throws {
        viewController = MockShopPayViewController(
            identifier: .invariant(reason: "Invalid checkout data"),
            configuration: mockConfiguration,
            storefront: mockStorefront
        )

        await viewController.onPress()

        XCTAssertTrue(viewController.presentCalls.isEmpty)
    }

    // MARK: - Error Handling Tests

    func test_onPress_withCartNotFound_shouldCallCheckoutDidFail() async throws {
        let checkoutDidFailExpectation = XCTestExpectation(
            description: "checkoutDidFail should be called"
        )

        viewController = MockShopPayViewController(
            identifier: .cart(cartID: "non-existent-cart-id"),
            configuration: mockConfiguration,
            eventHandlers: EventHandlers(
                checkoutDidFail: { _ in checkoutDidFailExpectation.fulfill() }
            ),
            storefront: mockStorefront
        )
        viewController.mockStorefront.cartResult = .success(nil)

        await viewController.onPress()

        await fulfillment(of: [checkoutDidFailExpectation], timeout: 1.0)
    }

    func test_onPress_withVariantIdentifierCartCreateFails_shouldCallCheckoutDidFail() async throws {
        let checkoutDidFailExpectation = XCTestExpectation(
            description: "checkoutDidFail should be called"
        )
        let identifier = CheckoutIdentifier.variant(
            variantID: "gid://Shopify/ProductVariant/test-variant-id",
            quantity: 2
        )
        var underlyingError: Error?

        viewController = MockShopPayViewController(
            identifier: identifier,
            configuration: mockConfiguration,
            eventHandlers: EventHandlers(
                checkoutDidFail: { error in
                    if case let .sdkError(underlying, _) = error {
                        underlyingError = underlying
                        checkoutDidFailExpectation.fulfill()
                    } else {
                        XCTFail("Expected sdkError")
                    }
                }
            ),
            storefront: mockStorefront
        )
        // Exact failure doesn't matter - just need fetchCartByCheckoutIdentifier to throw .cartAcquisition
        viewController.mockStorefront.cartCreateResult = .failure(
            NSError(domain: "CartCreateError", code: 400, userInfo: nil)
        )

        await viewController.onPress()

        await fulfillment(of: [checkoutDidFailExpectation], timeout: 1.0)

        XCTAssertEqual(
            underlyingError?.localizedDescription,
            ShopifyAcceleratedCheckouts.Error
                .cartAcquisition(identifier: identifier).localizedDescription
        )
    }

    func test_onPress_withInvariantIdentifier_shouldCallCheckoutDidFail() async throws {
        let checkoutDidFailExpectation = XCTestExpectation(
            description: "checkoutDidFail should be called"
        )

        viewController = MockShopPayViewController(
            identifier: .invariant(reason: "Invalid checkout data"),
            configuration: mockConfiguration,
            eventHandlers: EventHandlers(
                checkoutDidFail: { _ in checkoutDidFailExpectation.fulfill() }
            ),
            storefront: mockStorefront
        )

        await viewController.onPress()

        await fulfillment(of: [checkoutDidFailExpectation], timeout: 1.0)
    }

    // MARK: - URL Construction Tests

    func test_onPress_withInvalidURL_shouldCallPresentWithModifiedURL() async throws {
        let mockCart = StorefrontAPI.Cart.testCart(
            checkoutUrl: URL(string: "invalid-url")!
        )

        viewController = MockShopPayViewController(
            identifier: .cart(cartID: "gid://Shopify/Cart/test-cart-id"),
            configuration: mockConfiguration,
            storefront: mockStorefront
        )
        viewController.mockStorefront.cartResult = .success(mockCart)

        await viewController.onPress()

        // An invalid URL still gets processed, so we should check it was called with the modified URL
        XCTAssertEqual(
            viewController.presentCalls[0].url.absoluteString,
            "invalid-url?payment=shop_pay"
        )
    }
}
