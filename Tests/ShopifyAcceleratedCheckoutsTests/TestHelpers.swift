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

import PassKit
@testable import ShopifyAcceleratedCheckouts

// MARK: - Configuration Helpers

@available(iOS 17.0, *)
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

@available(iOS 17.0, *)
extension ShopifyAcceleratedCheckouts.Customer {
    static var testCustomer: ShopifyAcceleratedCheckouts.Customer {
        return ShopifyAcceleratedCheckouts.Customer(email: "test@shopify.com", phoneNumber: "+447777777777")
    }

    static func testCustomer(email: String? = "test@shopify.com") -> ShopifyAcceleratedCheckouts.Customer {
        return ShopifyAcceleratedCheckouts.Customer(email: email, phoneNumber: "+447777777777")
    }
}

@available(iOS 17.0, *)
extension ShopSettings {
    static var testShopSettings: ShopSettings {
        return ShopSettings(
            name: "Test Shop",
            primaryDomain: Domain(
                host: "test-shop.myshopify.com",
                url: "https://test-shop.myshopify.com"
            ),
            paymentSettings: PaymentSettings(
                countryCode: "US"
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
            countryCode: "US"
        )
    ) -> ShopSettings {
        return ShopSettings(
            name: name,
            primaryDomain: primaryDomain,
            paymentSettings: paymentSettings
        )
    }
}

@available(iOS 17.0, *)
extension ShopifyAcceleratedCheckouts.ApplePayConfiguration {
    static var testConfiguration: ShopifyAcceleratedCheckouts.ApplePayConfiguration {
        return ShopifyAcceleratedCheckouts.ApplePayConfiguration(
            merchantIdentifier: "merchant.test.id",
            supportedNetworks: [.visa],
            contactFields: [.email, .phone]
        )
    }

    static func testConfiguration(
        merchantIdentifier: String = "merchant.test.id",
        supportedNetworks: [PKPaymentNetwork] = [.visa]
    ) -> ShopifyAcceleratedCheckouts.ApplePayConfiguration {
        return ShopifyAcceleratedCheckouts.ApplePayConfiguration(
            merchantIdentifier: merchantIdentifier,
            supportedNetworks: supportedNetworks,
            contactFields: [.email, .phone]
        )
    }
}

@available(iOS 17.0, *)
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

@available(iOS 17.0, *)
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
                totalAmount: StorefrontAPI.MoneyV2(amount: Decimal(totalAmount), currencyCode: currencyCode),
                subtotalAmount: nil,
                totalTaxAmount: nil,
                totalDutyAmount: nil
            ),
            discountCodes: [],
            discountAllocations: []
        )
    }
}
