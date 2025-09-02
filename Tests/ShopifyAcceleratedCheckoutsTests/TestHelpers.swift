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

import Foundation
@testable import ShopifyAcceleratedCheckouts
import ShopifyCheckoutSheetKit
import XCTest

// MARK: - Configuration Helpers

func XCTAssertThrowsErrorAsync(
    _ expression: @autoclosure () async throws -> some Any,
    _ errorHandler: (Error) -> Void,
    _ message: @autoclosure () -> String = "Expected error to be thrown",
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    do {
        _ = try await expression()
        XCTFail(message(), file: file, line: line)
    } catch {
        errorHandler(error)
    }
}

@available(iOS 16.0, *)
extension ShopifyAcceleratedCheckouts.Configuration {
    static var testConfiguration: ShopifyAcceleratedCheckouts.Configuration {
        return ShopifyAcceleratedCheckouts.Configuration(
            storefrontDomain: "test-shop.myshopify.com",
            storefrontAccessToken: "test-token",
            customer: ShopifyAcceleratedCheckouts.Customer.testCustomer
        )
    }

    static func testConfiguration(
        storefrontDomain: String = "test-shop.myshopify.com",
        storefrontAccessToken: String = "test-token",
        customer: ShopifyAcceleratedCheckouts.Customer? = nil
    ) -> ShopifyAcceleratedCheckouts.Configuration {
        return ShopifyAcceleratedCheckouts.Configuration(
            storefrontDomain: storefrontDomain,
            storefrontAccessToken: storefrontAccessToken,
            customer: customer
        )
    }
}

@available(iOS 16.0, *)
extension ShopifyAcceleratedCheckouts.Customer {
    static var testCustomer: ShopifyAcceleratedCheckouts.Customer {
        return ShopifyAcceleratedCheckouts.Customer(
            email: "test@shopify.com", phoneNumber: "+447777777777"
        )
    }

    static func testCustomer(email: String? = "test@shopify.com")
        -> ShopifyAcceleratedCheckouts.Customer
    {
        return ShopifyAcceleratedCheckouts.Customer(email: email, phoneNumber: "+447777777777")
    }
}

@available(iOS 16.0, *)
extension ShopSettings {
    static var testShopSettings: ShopSettings {
        return ShopSettings(
            name: "Test Shop",
            primaryDomain: Domain(
                host: "test-shop.myshopify.com",
                url: "https://test-shop.myshopify.com"
            ),
            paymentSettings: PaymentSettings(
                countryCode: "US",
                acceptedCardBrands: [.visa, .mastercard, .americanExpress, .discover]
            )
        )
    }

    static func testShopSettings(
        name: String = "Test Shop",
        primaryDomain: Domain = Domain(
            host: "test-shop.myshopify.com",
            url: "https://test-shop.myshopify.com"
        ),
        paymentSettings: PaymentSettings = PaymentSettings(
            countryCode: "US",
            acceptedCardBrands: [.visa, .mastercard, .americanExpress, .discover]
        )
    ) -> ShopSettings {
        return ShopSettings(
            name: name,
            primaryDomain: primaryDomain,
            paymentSettings: paymentSettings
        )
    }
}

@available(iOS 16.0, *)
extension ShopifyAcceleratedCheckouts.ApplePayConfiguration {
    static var testConfiguration: ShopifyAcceleratedCheckouts.ApplePayConfiguration {
        return ShopifyAcceleratedCheckouts.ApplePayConfiguration(
            merchantIdentifier: "merchant.test.id",
            contactFields: [.email, .phone]
        )
    }

    static func testConfiguration(
        merchantIdentifier: String = "merchant.test.id"
    ) -> ShopifyAcceleratedCheckouts.ApplePayConfiguration {
        return ShopifyAcceleratedCheckouts.ApplePayConfiguration(
            merchantIdentifier: merchantIdentifier,
            contactFields: [.email, .phone]
        )
    }
}

@available(iOS 16.0, *)
extension ApplePayConfigurationWrapper {
    static var testConfiguration: ApplePayConfigurationWrapper {
        return ApplePayConfigurationWrapper(
            common: ShopifyAcceleratedCheckouts.Configuration.testConfiguration,
            applePay: ShopifyAcceleratedCheckouts.ApplePayConfiguration.testConfiguration,
            shopSettings: ShopSettings.testShopSettings
        )
    }

    static func testConfiguration(
        common: ShopifyAcceleratedCheckouts.Configuration = .testConfiguration,
        applePay: ShopifyAcceleratedCheckouts.ApplePayConfiguration = .testConfiguration,
        shopSettings: ShopSettings = .testShopSettings
    ) -> ApplePayConfigurationWrapper {
        return ApplePayConfigurationWrapper(
            common: common,
            applePay: applePay,
            shopSettings: shopSettings
        )
    }
}

// MARK: - StorefrontAPI.Cart Helpers

@available(iOS 16.0, *)
extension StorefrontAPI.Cart {
    static var testCart: StorefrontAPI.Cart {
        let checkoutURL = URL(string: "https://test-shop.myshopify.com/checkout")!
        return StorefrontAPI.Cart(
            id: GraphQLScalars.ID("gid://Shopify/Cart/test-cart-id"),
            checkoutUrl: GraphQLScalars.URL(checkoutURL),
            totalQuantity: 1,
            buyerIdentity: nil,
            deliveryGroups: StorefrontAPI.CartDeliveryGroupConnection(nodes: []),
            delivery: nil,
            lines: StorefrontAPI.BaseCartLineConnection(nodes: []),
            cost: StorefrontAPI.CartCost(
                totalAmount: StorefrontAPI.MoneyV2(amount: Decimal(100.0), currencyCode: "USD"),
                subtotalAmount: nil,
                totalTaxAmount: nil,
                totalDutyAmount: nil
            ),
            discountCodes: [],
            discountAllocations: []
        )
    }

    static func testCart(
        id: String = "gid://Shopify/Cart/test-cart-id",
        checkoutUrl: URL? = nil,
        totalQuantity: Int = 1,
        totalAmount: Double = 100.0,
        currencyCode: String = "USD"
    ) -> StorefrontAPI.Cart {
        let url = checkoutUrl ?? URL(string: "https://test-shop.myshopify.com/checkout")!
        return StorefrontAPI.Cart(
            id: GraphQLScalars.ID(id),
            checkoutUrl: GraphQLScalars.URL(url),
            totalQuantity: totalQuantity,
            buyerIdentity: nil,
            deliveryGroups: StorefrontAPI.CartDeliveryGroupConnection(nodes: []),
            delivery: nil,
            lines: StorefrontAPI.BaseCartLineConnection(nodes: []),
            cost: StorefrontAPI.CartCost(
                totalAmount: StorefrontAPI.MoneyV2(
                    amount: Decimal(totalAmount), currencyCode: currencyCode
                ),
                subtotalAmount: nil,
                totalTaxAmount: nil,
                totalDutyAmount: nil
            ),
            discountCodes: [],
            discountAllocations: []
        )
    }
}

// MARK: - StorefrontAPI Mock

/// This class conforms to StorefrontAPIProtocol with not implemented errors
/// Extend this class and override only the methods you need, per test file
@available(iOS 16.0, *)
class MockStorefrontAPI: StorefrontAPIProtocol {
    func cart(by _: GraphQLScalars.ID) async throws -> StorefrontAPI.Cart? {
        fatalError("cart(by:) not implemented in test. Override this method in your test class.")
    }

    func shop() async throws -> StorefrontAPI.Shop {
        fatalError("shop() not implemented in test. Override this method in your test class.")
    }

    func cartCreate(with _: [GraphQLScalars.ID], customer _: ShopifyAcceleratedCheckouts.Customer?)
        async throws -> StorefrontAPI.Cart
    {
        fatalError(
            "cartCreate(with:customer:) not implemented in test. Override this method in your test class."
        )
    }

    @discardableResult func cartBuyerIdentityUpdate(
        id _: GraphQLScalars.ID, input _: StorefrontAPI.CartBuyerIdentityUpdateInput
    ) async throws -> StorefrontAPI.Cart {
        fatalError(
            "cartBuyerIdentityUpdate(id:input:) not implemented in test. Override this method in your test class."
        )
    }

    func cartDeliveryAddressesAdd(
        id _: GraphQLScalars.ID, address _: StorefrontAPI.Address, validate _: Bool
    ) async throws -> StorefrontAPI.Cart {
        fatalError(
            "cartDeliveryAddressesAdd(id:address:validate:) not implemented in test. Override this method in your test class."
        )
    }

    func cartDeliveryAddressesUpdate(
        id _: GraphQLScalars.ID, addressId _: GraphQLScalars.ID, address _: StorefrontAPI.Address,
        validate _: Bool
    ) async throws -> StorefrontAPI.Cart {
        fatalError(
            "cartDeliveryAddressesUpdate(id:addressId:address:validate:) not implemented in test. Override this method in your test class."
        )
    }

    func cartDeliveryAddressesRemove(id _: GraphQLScalars.ID, addressId _: GraphQLScalars.ID)
        async throws -> StorefrontAPI.Cart
    {
        fatalError(
            "cartDeliveryAddressesRemove(id:addressId:) not implemented in test. Override this method in your test class."
        )
    }

    func cartSelectedDeliveryOptionsUpdate(
        id _: GraphQLScalars.ID, deliveryGroupId _: GraphQLScalars.ID,
        deliveryOptionHandle _: String
    ) async throws -> StorefrontAPI.Cart {
        fatalError(
            "cartSelectedDeliveryOptionsUpdate(id:deliveryGroupId:deliveryOptionHandle:) not implemented in test. Override this method in your test class."
        )
    }

    @discardableResult func cartPaymentUpdate(
        id _: GraphQLScalars.ID, totalAmount _: StorefrontAPI.MoneyV2,
        applePayPayment _: StorefrontAPI.ApplePayPayment
    ) async throws -> StorefrontAPI.Cart {
        fatalError(
            "cartPaymentUpdate(id:totalAmount:applePayPayment:) not implemented in test. Override this method in your test class."
        )
    }

    @discardableResult func cartBillingAddressUpdate(
        id _: GraphQLScalars.ID, billingAddress _: StorefrontAPI.Address
    ) async throws -> StorefrontAPI.Cart {
        fatalError(
            "cartBillingAddressUpdate(id:billingAddress:) not implemented in test. Override this method in your test class."
        )
    }

    func cartRemovePersonalData(id _: GraphQLScalars.ID) async throws {
        fatalError(
            "cartRemovePersonalData(id:) not implemented in test. Override this method in your test class."
        )
    }

    func cartPrepareForCompletion(id _: GraphQLScalars.ID) async throws
        -> StorefrontAPI.CartStatusReady
    {
        fatalError(
            "cartPrepareForCompletion(id:) not implemented in test. Override this method in your test class."
        )
    }

    func cartSubmitForCompletion(id _: GraphQLScalars.ID) async throws
        -> StorefrontAPI.SubmitSuccess
    {
        fatalError(
            "cartSubmitForCompletion(id:) not implemented in test. Override this method in your test class."
        )
    }
}

// MARK: - Test StorefrontAPI

@available(iOS 16.0, *)
typealias CartResult = Result<StorefrontAPI.Cart?, Error>

@available(iOS 16.0, *)
class TestStorefrontAPI: MockStorefrontAPI {
    var cartResult: CartResult?

    override func cart(by _: GraphQLScalars.ID) async throws -> StorefrontAPI.Cart? {
        guard let result = cartResult else {
            fatalError("cartResult not configured for TestStorefrontAPI")
        }
        return try result.get()
    }

    var cartCreateResult: Result<StorefrontAPI.Cart, Error>?
    override func cartCreate(with _: [GraphQLScalars.ID], customer _: ShopifyAcceleratedCheckouts.Customer?) async throws -> StorefrontAPI.Cart {
        guard let result = cartCreateResult else {
            fatalError("cartCreateResult not configured for TestStorefrontAPI")
        }
        return try result.get()
    }
}

// MARK: - WalletController Mock

@available(iOS 16.0, *)
class MockWalletController: WalletController {
    var mockTopViewController: UIViewController?

    override func getTopViewController() -> UIViewController? {
        return mockTopViewController
    }
}

// MARK: - ShopPayViewController Mock

@available(iOS 16.0, *)
class MockShopPayViewController: ShopPayViewController {
    var mockTopViewController: UIViewController?

    override func getTopViewController() -> UIViewController? {
        return mockTopViewController
    }
}

// MARK: - ApplePayAuthorizationDelegate Mock

@available(iOS 16.0, *)
class MockApplePayAuthorizationDelegate: ApplePayAuthorizationDelegate {
    var transitionHistory: [ApplePayState] = []
    var setCartCalls: [StorefrontAPI.Types.Cart] = []
    var shouldThrowOnTransition = false
    var shouldThrowOnSetCart = false

    override func transition(to state: ApplePayState) async throws {
        transitionHistory.append(state)
        if shouldThrowOnTransition {
            throw NSError(domain: "MockError", code: 1, userInfo: nil)
        }
        // Don't call super to avoid actual state machine logic
    }

    override func setCart(to cart: StorefrontAPI.Types.Cart?) throws {
        if let cart {
            setCartCalls.append(cart)
        }
        if shouldThrowOnSetCart {
            throw NSError(domain: "MockError", code: 1, userInfo: nil)
        }
        // Don't call super to avoid actual cart setting logic
    }

    func resetMocks() {
        transitionHistory.removeAll()
        setCartCalls.removeAll()
        shouldThrowOnTransition = false
        shouldThrowOnSetCart = false
    }
}

// MARK: - ApplePayViewController Mock

@available(iOS 17.0, *)
class MockApplePayViewController: ApplePayViewController {
    var mockAuthorizationDelegate: MockApplePayAuthorizationDelegate!
    var mockTopViewController: UIViewController?

    override var authorizationDelegate: ApplePayAuthorizationDelegate {
        return mockAuthorizationDelegate
    }

    override func getTopViewController() -> UIViewController? {
        return mockTopViewController
    }

    // Helper methods for test setup
    func setMockAuthorizationDelegate(_ mock: MockApplePayAuthorizationDelegate) {
        mockAuthorizationDelegate = mock
    }
}

// MARK: - CheckoutDelegate Mock

@available(iOS 16.0, *)
class MockCheckoutDelegate: CheckoutDelegate {
    func checkoutDidComplete(event _: CheckoutCompletedEvent) {}
    func checkoutDidFail(error _: CheckoutError) {}
    func checkoutDidCancel() {}
    func shouldRecoverFromError(error _: CheckoutError) -> Bool { return false }
    func checkoutDidClickLink(url _: URL) {}
    func checkoutDidEmitWebPixelEvent(event _: PixelEvent) {}
}
