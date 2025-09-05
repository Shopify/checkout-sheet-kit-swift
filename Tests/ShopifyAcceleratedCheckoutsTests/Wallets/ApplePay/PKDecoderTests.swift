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
import XCTest

@available(iOS 17.0, *)
class PKDecoderTests: XCTestCase {
    private var cart: () -> StorefrontAPI.Types.Cart? = { nil }

    private var decoder: PKDecoder {
        return PKDecoder(configuration: ApplePayConfigurationWrapper.testConfiguration, cart: { self.cart() })
    }

    // MARK: - Initialization Tests

    func testInitializesDecoderCorrectly() {
        let testDecoder = decoder
        XCTAssertNil(testDecoder.cart())
        XCTAssertNil(testDecoder.selectedShippingMethod)
    }

    func testDecoderStorefrontConfiguration() {
        let testDecoder = decoder
        // Can't directly test private storefront property, but we can test the decoder initializes properly
        XCTAssertNil(testDecoder.cart())
        XCTAssertNil(testDecoder.selectedShippingMethod)
    }

    // MARK: - paymentSummaryItems Tests

    func testReturnsEmptyPaymentSummaryWhenCartIsNil() {
        let testDecoder = decoder
        testDecoder.cart = { nil }

        let summaryItems = testDecoder.paymentSummaryItems
        XCTAssertTrue(summaryItems.isEmpty)
    }

    func testReturnsEmptyPaymentSummaryWhenCartHasNoLines() {
        let testDecoder = decoder
        // Don't set cart - it remains nil

        let summaryItems = testDecoder.paymentSummaryItems
        XCTAssertTrue(summaryItems.isEmpty)
    }

    func testPaymentSummaryItemsWithShippingMethodButNilCart() {
        let testDecoder = decoder
        let shippingMethod = PKShippingMethod(
            label: "Express", amount: NSDecimalNumber(decimal: 5.00)
        )
        testDecoder.selectedShippingMethod = shippingMethod
        testDecoder.cart = { nil }

        let summaryItems = testDecoder.paymentSummaryItems
        XCTAssertTrue(summaryItems.isEmpty)
    }

    // MARK: - shippingMethods Tests

    func testReturnsEmptyShippingMethodsWhenCartIsNil() {
        let testDecoder = decoder
        testDecoder.cart = { nil }

        let shippingMethods = testDecoder.shippingMethods
        XCTAssertTrue(shippingMethods.isEmpty)
    }

    func testReturnsEmptyShippingMethodsWhenNoDeliveryGroups() {
        let testDecoder = decoder
        // Don't set cart - it remains nil

        let shippingMethods = testDecoder.shippingMethods
        XCTAssertTrue(shippingMethods.isEmpty)
    }

    func testShippingMethodsWithNilCartReturnsEmpty() {
        let testDecoder = decoder
        testDecoder.cart = { nil }

        let shippingMethods = testDecoder.shippingMethods
        XCTAssertTrue(shippingMethods.isEmpty)
    }

    // MARK: - selectedShippingMethod Tests

    func testSelectedShippingMethodCanBeSetAndRetrieved() {
        let testDecoder = decoder
        let shippingMethod = PKShippingMethod(
            label: "Express", amount: NSDecimalNumber(decimal: 5.00)
        )
        shippingMethod.detail = "1-2 business days"
        shippingMethod.identifier = "express"

        testDecoder.selectedShippingMethod = shippingMethod

        XCTAssertNotNil(testDecoder.selectedShippingMethod)
        XCTAssertEqual(testDecoder.selectedShippingMethod?.label, "Express")
        XCTAssertEqual(
            testDecoder.selectedShippingMethod?.amount, NSDecimalNumber(decimal: 5.00)
        )
        XCTAssertEqual(testDecoder.selectedShippingMethod?.detail, "1-2 business days")
        XCTAssertEqual(testDecoder.selectedShippingMethod?.identifier, "express")
    }

    // MARK: - requiredContactFields Tests

    func testRequiredContactFieldsReturnsEmptyWhenNoFieldsRequested() {
        let configuration = ApplePayConfigurationWrapper.testConfiguration(
            applePay: ShopifyAcceleratedCheckouts.ApplePayConfiguration(
                merchantIdentifier: "merchant.test.id",
                contactFields: []
            )
        )
        let testDecoder = PKDecoder(
            configuration: configuration,
            cart: { nil }
        )

        let fields = testDecoder.requiredContactFields
        XCTAssertTrue(fields.isEmpty)
    }

    func testRequiredContactFieldsIncludesEmailWhenRequestedAndNotInBuyerIdentity() {
        let configuration = ApplePayConfigurationWrapper.testConfiguration(
            applePay: ShopifyAcceleratedCheckouts.ApplePayConfiguration(
                merchantIdentifier: "merchant.test.id",
                contactFields: [.email]
            )
        )
        let testDecoder = PKDecoder(
            configuration: configuration,
            cart: { nil }
        )

        let fields = testDecoder.requiredContactFields
        XCTAssertEqual(fields, [.emailAddress])
    }

    func testRequiredContactFieldsIncludesPhoneWhenRequestedAndNotInBuyerIdentity() {
        let configuration = ApplePayConfigurationWrapper.testConfiguration(
            applePay: ShopifyAcceleratedCheckouts.ApplePayConfiguration(
                merchantIdentifier: "merchant.test.id",
                contactFields: [.phone]
            )
        )
        let testDecoder = PKDecoder(
            configuration: configuration,
            cart: { nil }
        )

        let fields = testDecoder.requiredContactFields
        XCTAssertEqual(fields, [.phoneNumber])
    }

    func testRequiredContactFieldsExcludesEmailWhenAlreadyInBuyerIdentity() {
        let configuration = ApplePayConfigurationWrapper.testConfiguration(
            applePay: ShopifyAcceleratedCheckouts.ApplePayConfiguration(
                merchantIdentifier: "merchant.test.id",
                contactFields: [.email, .phone]
            )
        )

        let cartWithBuyerEmail = StorefrontAPI.Cart(
            id: GraphQLScalars.ID("gid://Shopify/Cart/test-cart-id"),
            checkoutUrl: GraphQLScalars.URL(URL(string: "https://test-shop.myshopify.com/checkout")!),
            totalQuantity: 1,
            buyerIdentity: StorefrontAPI.CartBuyerIdentity(
                email: "test@example.com",
                phone: nil
            ),
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

        let testDecoder = PKDecoder(
            configuration: configuration,
            cart: { cartWithBuyerEmail }
        )

        let fields = testDecoder.requiredContactFields
        // Email should not be requested since it's already in buyerIdentity
        // Only phone should be requested
        XCTAssertEqual(fields, [.phoneNumber])
    }

    func testRequiredContactFieldsExcludesPhoneWhenAlreadyInBuyerIdentity() {
        let configuration = ApplePayConfigurationWrapper.testConfiguration(
            applePay: ShopifyAcceleratedCheckouts.ApplePayConfiguration(
                merchantIdentifier: "merchant.test.id",
                contactFields: [.email, .phone]
            )
        )

        let cartWithBuyerPhone = StorefrontAPI.Cart(
            id: GraphQLScalars.ID("gid://Shopify/Cart/test-cart-id"),
            checkoutUrl: GraphQLScalars.URL(URL(string: "https://test-shop.myshopify.com/checkout")!),
            totalQuantity: 1,
            buyerIdentity: StorefrontAPI.CartBuyerIdentity(
                email: nil,
                phone: "+1234567890"
            ),
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

        let testDecoder = PKDecoder(
            configuration: configuration,
            cart: { cartWithBuyerPhone }
        )

        let fields = testDecoder.requiredContactFields
        // Phone should not be requested since it's already in buyerIdentity
        // Only email should be requested
        XCTAssertEqual(fields, [.emailAddress])
    }

    func testRequiredContactFieldsExcludesBothWhenBothAlreadyInBuyerIdentity() {
        let configuration = ApplePayConfigurationWrapper.testConfiguration(
            applePay: ShopifyAcceleratedCheckouts.ApplePayConfiguration(
                merchantIdentifier: "merchant.test.id",
                contactFields: [.email, .phone]
            )
        )

        let cartWithFullBuyerIdentity = StorefrontAPI.Cart(
            id: GraphQLScalars.ID("gid://Shopify/Cart/test-cart-id"),
            checkoutUrl: GraphQLScalars.URL(URL(string: "https://test-shop.myshopify.com/checkout")!),
            totalQuantity: 1,
            buyerIdentity: StorefrontAPI.CartBuyerIdentity(
                email: "test@example.com",
                phone: "+1234567890"
            ),
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

        let testDecoder = PKDecoder(
            configuration: configuration,
            cart: { cartWithFullBuyerIdentity }
        )

        let fields = testDecoder.requiredContactFields
        // Neither email nor phone should be requested since both are in buyerIdentity
        XCTAssertTrue(fields.isEmpty)
    }

    func testRequiredContactFieldsTreatsEmptyStringsAsNotPresent() {
        let configuration = ApplePayConfigurationWrapper.testConfiguration(
            applePay: ShopifyAcceleratedCheckouts.ApplePayConfiguration(
                merchantIdentifier: "merchant.test.id",
                contactFields: [.email, .phone]
            )
        )

        let cartWithEmptyBuyerIdentity = StorefrontAPI.Cart(
            id: GraphQLScalars.ID("gid://Shopify/Cart/test-cart-id"),
            checkoutUrl: GraphQLScalars.URL(URL(string: "https://test-shop.myshopify.com/checkout")!),
            totalQuantity: 1,
            buyerIdentity: StorefrontAPI.CartBuyerIdentity(
                email: "", // Empty string should be treated as not present
                phone: "" // Empty string should be treated as not present
            ),
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

        let testDecoder = PKDecoder(
            configuration: configuration,
            cart: { cartWithEmptyBuyerIdentity }
        )

        let fields = testDecoder.requiredContactFields
        // Both email and phone should be requested since empty strings are treated as not present
        XCTAssertEqual(fields, [.emailAddress, .phoneNumber])
    }

    func testRequiredContactFieldsRequestsBothWhenBothNilInBuyerIdentity() {
        let configuration = ApplePayConfigurationWrapper.testConfiguration(
            applePay: ShopifyAcceleratedCheckouts.ApplePayConfiguration(
                merchantIdentifier: "merchant.test.id",
                contactFields: [.email, .phone]
            )
        )

        let cartWithNilBuyerIdentity = StorefrontAPI.Cart(
            id: GraphQLScalars.ID("gid://Shopify/Cart/test-cart-id"),
            checkoutUrl: GraphQLScalars.URL(URL(string: "https://test-shop.myshopify.com/checkout")!),
            totalQuantity: 1,
            buyerIdentity: StorefrontAPI.CartBuyerIdentity(
                email: nil,
                phone: nil
            ),
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

        let testDecoder = PKDecoder(
            configuration: configuration,
            cart: { cartWithNilBuyerIdentity }
        )

        let fields = testDecoder.requiredContactFields
        // Both email and phone should be requested since they are nil in buyerIdentity
        XCTAssertEqual(fields, [.emailAddress, .phoneNumber])
    }

    func testRequiredContactFieldsRequestsBothWhenBuyerIdentityIsNil() {
        let configuration = ApplePayConfigurationWrapper.testConfiguration(
            applePay: ShopifyAcceleratedCheckouts.ApplePayConfiguration(
                merchantIdentifier: "merchant.test.id",
                contactFields: [.email, .phone]
            )
        )

        let cartWithoutBuyerIdentity = StorefrontAPI.Cart(
            id: GraphQLScalars.ID("gid://Shopify/Cart/test-cart-id"),
            checkoutUrl: GraphQLScalars.URL(URL(string: "https://test-shop.myshopify.com/checkout")!),
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

        let testDecoder = PKDecoder(
            configuration: configuration,
            cart: { cartWithoutBuyerIdentity }
        )

        let fields = testDecoder.requiredContactFields
        // Both email and phone should be requested since buyerIdentity is nil
        XCTAssertEqual(fields, [.emailAddress, .phoneNumber])
    }
}
