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

@available(iOS 16.0, *)
final class WalletControllerTests: XCTestCase {
    var mockStorefront: TestStorefrontAPI!
    var controller: MockWalletController!
    var mockDelegate: MockCheckoutDelegate!

    override func setUp() {
        super.setUp()
        mockStorefront = TestStorefrontAPI()
        mockDelegate = MockCheckoutDelegate()
    }

    override func tearDown() {
        mockStorefront = nil
        controller = nil
        mockDelegate = nil
        super.tearDown()
    }

    class MockWalletController: WalletController {
        var mockTopViewController: UIViewController?

        override func getTopViewController() -> UIViewController? {
            return mockTopViewController
        }
    }

    class MockCheckoutDelegate: CheckoutDelegate {
        func checkoutDidComplete(event _: CheckoutCompletedEvent) {}
        func checkoutDidFail(error _: CheckoutError) {}
        func checkoutDidCancel() {}
        func shouldRecoverFromError(error: CheckoutError) -> Bool { return error.isRecoverable }
        func checkoutDidClickLink(url _: URL) {}
        func checkoutDidEmitWebPixelEvent(event _: PixelEvent) {}
    }

    // MARK: - fetchCartByCheckoutIdentifier Tests - Cart Identifier

    func test_fetchCartByCheckoutIdentifier_withCartIdentifier_shouldSucceed() async throws {
        let expectedCart = StorefrontAPI.Cart.testCart
        mockStorefront.cartResult = .success(expectedCart)

        controller = MockWalletController(
            identifier: .cart(cartID: "gid://Shopify/Cart/test-cart-id"),
            storefront: mockStorefront
        )

        let result = try await controller.fetchCartByCheckoutIdentifier()
        XCTAssertEqual(result.id, expectedCart.id)
    }

    func test_fetchCartByCheckoutIdentifier_withCartIdentifierReturningNil_shouldThrowError() async throws {
        mockStorefront.cartResult = .success(nil)

        controller = MockWalletController(
            identifier: .cart(cartID: "gid://Shopify/Cart/test-cart-id"),
            storefront: mockStorefront
        )

        await XCTAssertThrowsErrorAsync(try await controller.fetchCartByCheckoutIdentifier()) { error in
            guard case let ShopifyAcceleratedCheckouts.Error.cartAcquisition(identifier) = error else {
                XCTFail("Expected cartAcquisition error, got: \(error)")
                return
            }

            if case let .cart(cartID) = identifier {
                XCTAssertEqual(cartID, "gid://Shopify/Cart/test-cart-id")
            } else {
                XCTFail("Expected cart identifier, got: \(identifier)")
            }
        }
    }

    func test_fetchCartByCheckoutIdentifier_withCartIdentifierStorefrontError_shouldThrowError() async throws {
        let storefrontError = NSError(domain: "StorefrontError", code: 500, userInfo: nil)
        mockStorefront.cartResult = .failure(storefrontError)

        controller = MockWalletController(
            identifier: .cart(cartID: "gid://Shopify/Cart/test-cart-id"),
            storefront: mockStorefront
        )

        await XCTAssertThrowsErrorAsync(try await controller.fetchCartByCheckoutIdentifier()) { error in
            XCTAssertEqual((error as NSError).domain, "StorefrontError")
            XCTAssertEqual((error as NSError).code, 500)
        }
    }

    // MARK: - fetchCartByCheckoutIdentifier Tests - Variant Identifier

    func test_fetchCartByCheckoutIdentifier_withVariantIdentifier_shouldSucceed() async throws {
        let expectedCart = StorefrontAPI.Cart.testCart
        mockStorefront.cartCreateResult = Result<StorefrontAPI.Cart, Error>.success(expectedCart)

        controller = MockWalletController(
            identifier: .variant(variantID: "gid://Shopify/ProductVariant/test-variant-id", quantity: 2),
            storefront: mockStorefront
        )

        let result = try await controller.fetchCartByCheckoutIdentifier()
        XCTAssertEqual(result.id, expectedCart.id)
    }

    func test_fetchCartByCheckoutIdentifier_withVariantIdentifierZeroQuantity_shouldSucceed() async throws {
        let expectedCart = StorefrontAPI.Cart.testCart
        mockStorefront.cartCreateResult = Result<StorefrontAPI.Cart, Error>.success(expectedCart)

        controller = MockWalletController(
            identifier: .variant(variantID: "gid://Shopify/ProductVariant/test-variant-id", quantity: 0),
            storefront: mockStorefront
        )

        let result = try await controller.fetchCartByCheckoutIdentifier()
        XCTAssertEqual(result.id, expectedCart.id)
    }

    func test_fetchCartByCheckoutIdentifier_withVariantIdentifierCartCreateFails_shouldThrowError() async throws {
        let cartCreateError = NSError(domain: "CartCreateError", code: 400, userInfo: nil)
        mockStorefront.cartCreateResult = Result<StorefrontAPI.Cart, Error>.failure(cartCreateError)

        controller = MockWalletController(
            identifier: .variant(variantID: "gid://Shopify/ProductVariant/test-variant-id", quantity: 2),
            storefront: mockStorefront
        )

        await XCTAssertThrowsErrorAsync(try await controller.fetchCartByCheckoutIdentifier()) { error in
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "CartCreateError")
            XCTAssertEqual(nsError.code, 400)
        }
    }

    // MARK: - fetchCartByCheckoutIdentifier Tests - Invariant Identifier

    func test_fetchCartByCheckoutIdentifier_withInvariantIdentifier_shouldThrowError() async throws {
        controller = MockWalletController(
            identifier: .invariant(reason: "Invalid identifier"),
            storefront: mockStorefront
        )

        await XCTAssertThrowsErrorAsync(try await controller.fetchCartByCheckoutIdentifier()) { error in
            guard case let ShopifyAcceleratedCheckouts.Error.cartAcquisition(identifier) = error else {
                XCTFail("Expected cartAcquisition error, got: \(error)")
                return
            }

            if case let .invariant(reason) = identifier {
                XCTAssertEqual(reason, "Invalid identifier")
            } else {
                XCTFail("Expected invariant identifier, got: \(identifier)")
            }
        }
    }

    // MARK: - present Tests

    func test_present_withValidParameters_shouldSucceed() async throws {
        controller = MockWalletController(
            identifier: .cart(cartID: "gid://Shopify/Cart/test-cart-id"),
            storefront: mockStorefront
        )

        // Mock the top view controller
        let mockViewController = await MainActor.run { UIViewController() }
        controller.mockTopViewController = mockViewController

        let testURL = URL(string: "https://test.myshopify.com/checkout")!

        try await controller.present(url: testURL, delegate: mockDelegate)

        XCTAssertNotNil(controller.checkoutViewController)
    }
}
