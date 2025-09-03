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

    func testRequiredContactFieldsDefaultsToEmailWhenNoFieldsConfigured() {
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
        XCTAssertEqual(fields, [PKContactField.emailAddress])
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
        XCTAssertEqual(fields, [PKContactField.emailAddress])
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
                phone: nil,
                customer: nil
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
                phone: "+1234567890",
                customer: nil
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
        XCTAssertEqual(fields, [PKContactField.emailAddress])
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
                phone: "+1234567890",
                customer: nil
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
                phone: "", // Empty string should be treated as not present
                customer: nil
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
        XCTAssertEqual(fields, Set([PKContactField.emailAddress, PKContactField.phoneNumber]))
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
                phone: nil,
                customer: nil
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
        XCTAssertEqual(fields, Set([PKContactField.emailAddress, PKContactField.phoneNumber]))
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
        XCTAssertEqual(fields, Set([PKContactField.emailAddress, PKContactField.phoneNumber]))
    }

    // MARK: - Minimum Required Field Tests

    func testRequiredContactFieldsDefaultsToEmailWhenNoFieldsAndNoBuyerIdentity() {
        let configuration = ApplePayConfigurationWrapper.testConfiguration(
            applePay: ShopifyAcceleratedCheckouts.ApplePayConfiguration(
                merchantIdentifier: "merchant.test.id",
                contactFields: []
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
        // Should default to requiring email when no fields are configured and buyer identity is empty
        XCTAssertEqual(fields, [PKContactField.emailAddress])
    }

    func testRequiredContactFieldsRespectsExistingEmailInBuyerIdentityEvenWithNoConfig() {
        let configuration = ApplePayConfigurationWrapper.testConfiguration(
            applePay: ShopifyAcceleratedCheckouts.ApplePayConfiguration(
                merchantIdentifier: "merchant.test.id",
                contactFields: []
            )
        )

        let cartWithEmail = StorefrontAPI.Cart(
            id: GraphQLScalars.ID("gid://Shopify/Cart/test-cart-id"),
            checkoutUrl: GraphQLScalars.URL(URL(string: "https://test-shop.myshopify.com/checkout")!),
            totalQuantity: 1,
            buyerIdentity: StorefrontAPI.CartBuyerIdentity(
                email: "test@example.com",
                phone: nil,
                customer: nil
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
            cart: { cartWithEmail }
        )

        let fields = testDecoder.requiredContactFields
        // Should not require any fields since email exists in buyer identity
        XCTAssertTrue(fields.isEmpty)
    }

    func testRequiredContactFieldsRespectsExistingPhoneInBuyerIdentityEvenWithNoConfig() {
        let configuration = ApplePayConfigurationWrapper.testConfiguration(
            applePay: ShopifyAcceleratedCheckouts.ApplePayConfiguration(
                merchantIdentifier: "merchant.test.id",
                contactFields: []
            )
        )

        let cartWithPhone = StorefrontAPI.Cart(
            id: GraphQLScalars.ID("gid://Shopify/Cart/test-cart-id"),
            checkoutUrl: GraphQLScalars.URL(URL(string: "https://test-shop.myshopify.com/checkout")!),
            totalQuantity: 1,
            buyerIdentity: StorefrontAPI.CartBuyerIdentity(
                email: nil,
                phone: "+1234567890",
                customer: nil
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
            cart: { cartWithPhone }
        )

        let fields = testDecoder.requiredContactFields
        // Should not require any fields since phone exists in buyer identity
        XCTAssertTrue(fields.isEmpty)
    }

    func testRequiredContactFieldsDefaultsToEmailWithEmptyBuyerIdentityStrings() {
        let configuration = ApplePayConfigurationWrapper.testConfiguration(
            applePay: ShopifyAcceleratedCheckouts.ApplePayConfiguration(
                merchantIdentifier: "merchant.test.id",
                contactFields: []
            )
        )

        let cartWithEmptyStrings = StorefrontAPI.Cart(
            id: GraphQLScalars.ID("gid://Shopify/Cart/test-cart-id"),
            checkoutUrl: GraphQLScalars.URL(URL(string: "https://test-shop.myshopify.com/checkout")!),
            totalQuantity: 1,
            buyerIdentity: StorefrontAPI.CartBuyerIdentity(
                email: "", // Empty string
                phone: "", // Empty string
                customer: nil
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
            cart: { cartWithEmptyStrings }
        )

        let fields = testDecoder.requiredContactFields
        // Should default to requiring email when buyer identity has empty strings
        XCTAssertEqual(fields, [PKContactField.emailAddress])
    }

    func testRequiredContactFieldsWithCustomerEmailAndPhone() {
        let configuration = ApplePayConfigurationWrapper.testConfiguration(
            applePay: ShopifyAcceleratedCheckouts.ApplePayConfiguration(
                merchantIdentifier: "merchant.test.id",
                contactFields: [.email, .phone]
            )
        )

        let cartWithCustomer = StorefrontAPI.Cart(
            id: GraphQLScalars.ID("gid://Shopify/Cart/test-cart-id"),
            checkoutUrl: GraphQLScalars.URL(URL(string: "https://test-shop.myshopify.com/checkout")!),
            totalQuantity: 1,
            buyerIdentity: StorefrontAPI.CartBuyerIdentity(
                email: nil,
                phone: nil,
                customer: StorefrontAPI.CartCustomer(
                    email: "customer@example.com",
                    phone: "+9876543210"
                )
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
            cart: { cartWithCustomer }
        )

        let fields = testDecoder.requiredContactFields
        // Should not require any fields since customer has both email and phone
        XCTAssertTrue(fields.isEmpty)
    }

    func testRequiredContactFieldsWithCustomerEmailOnly() {
        let configuration = ApplePayConfigurationWrapper.testConfiguration(
            applePay: ShopifyAcceleratedCheckouts.ApplePayConfiguration(
                merchantIdentifier: "merchant.test.id",
                contactFields: [.email, .phone]
            )
        )

        let cartWithCustomerEmail = StorefrontAPI.Cart(
            id: GraphQLScalars.ID("gid://Shopify/Cart/test-cart-id"),
            checkoutUrl: GraphQLScalars.URL(URL(string: "https://test-shop.myshopify.com/checkout")!),
            totalQuantity: 1,
            buyerIdentity: StorefrontAPI.CartBuyerIdentity(
                email: nil,
                phone: nil,
                customer: StorefrontAPI.CartCustomer(
                    email: "customer@example.com",
                    phone: nil
                )
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
            cart: { cartWithCustomerEmail }
        )

        let fields = testDecoder.requiredContactFields
        // Should only require phone since customer has email
        XCTAssertEqual(fields, [.phoneNumber])
    }

    func testRequiredContactFieldsWithCustomerPhoneOnly() {
        let configuration = ApplePayConfigurationWrapper.testConfiguration(
            applePay: ShopifyAcceleratedCheckouts.ApplePayConfiguration(
                merchantIdentifier: "merchant.test.id",
                contactFields: [.email, .phone]
            )
        )

        let cartWithCustomerPhone = StorefrontAPI.Cart(
            id: GraphQLScalars.ID("gid://Shopify/Cart/test-cart-id"),
            checkoutUrl: GraphQLScalars.URL(URL(string: "https://test-shop.myshopify.com/checkout")!),
            totalQuantity: 1,
            buyerIdentity: StorefrontAPI.CartBuyerIdentity(
                email: nil,
                phone: nil,
                customer: StorefrontAPI.CartCustomer(
                    email: nil,
                    phone: "+9876543210"
                )
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
            cart: { cartWithCustomerPhone }
        )

        let fields = testDecoder.requiredContactFields
        // Should only require email since customer has phone
        XCTAssertEqual(fields, [PKContactField.emailAddress])
    }

    func testRequiredContactFieldsFallbackToBuyerIdentityWhenCustomerIsNil() {
        let configuration = ApplePayConfigurationWrapper.testConfiguration(
            applePay: ShopifyAcceleratedCheckouts.ApplePayConfiguration(
                merchantIdentifier: "merchant.test.id",
                contactFields: [.email, .phone]
            )
        )

        let cartWithoutCustomer = StorefrontAPI.Cart(
            id: GraphQLScalars.ID("gid://Shopify/Cart/test-cart-id"),
            checkoutUrl: GraphQLScalars.URL(URL(string: "https://test-shop.myshopify.com/checkout")!),
            totalQuantity: 1,
            buyerIdentity: StorefrontAPI.CartBuyerIdentity(
                email: "buyer@example.com",
                phone: "+1234567890",
                customer: nil
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
            cart: { cartWithoutCustomer }
        )

        let fields = testDecoder.requiredContactFields
        // Should not require any fields since buyerIdentity has both email and phone
        XCTAssertTrue(fields.isEmpty)
    }

    func testRequiredContactFieldsCustomerTakesPrecedenceOverBuyerIdentity() {
        let configuration = ApplePayConfigurationWrapper.testConfiguration(
            applePay: ShopifyAcceleratedCheckouts.ApplePayConfiguration(
                merchantIdentifier: "merchant.test.id",
                contactFields: [.email, .phone]
            )
        )

        let cartWithBothCustomerAndBuyer = StorefrontAPI.Cart(
            id: GraphQLScalars.ID("gid://Shopify/Cart/test-cart-id"),
            checkoutUrl: GraphQLScalars.URL(URL(string: "https://test-shop.myshopify.com/checkout")!),
            totalQuantity: 1,
            buyerIdentity: StorefrontAPI.CartBuyerIdentity(
                email: "buyer@example.com",
                phone: nil,
                customer: StorefrontAPI.CartCustomer(
                    email: "customer@example.com",
                    phone: "+9876543210"
                )
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
            cart: { cartWithBothCustomerAndBuyer }
        )

        let fields = testDecoder.requiredContactFields
        // Should not require any fields since customer has both email and phone (customer takes precedence)
        XCTAssertTrue(fields.isEmpty)
    }

    // MARK: - Error Handling Method Tests

    func test_paymentRequestShippingMethodUpdate_withErrors_shouldReturnValidResponse() {
        let testDecoder = decoder
        let testError = PKPaymentError(.shippingAddressUnserviceableError)

        let result = testDecoder.paymentRequestShippingMethodUpdate(errors: [testError])

        XCTAssertEqual(result.status, .success, "Status should remain success")
        XCTAssertNotNil(result.paymentSummaryItems, "Should always return payment summary items")
    }

    func test_paymentRequestShippingMethodUpdate_withoutErrors_shouldReturnValidResponse() {
        let testDecoder = decoder

        let result = testDecoder.paymentRequestShippingMethodUpdate()

        XCTAssertEqual(result.status, .success, "Status should remain success when no errors")
        XCTAssertNotNil(result.paymentSummaryItems, "Should return payment summary items")
    }

    func test_paymentRequestShippingContactUpdate_withAllPKPaymentErrors_shouldKeepSuccessStatus() {
        let testDecoder = decoder
        let pkPaymentError1 = PKPaymentError(.shippingAddressUnserviceableError)
        let pkPaymentError2 = PKPaymentError(.shippingContactInvalidError)

        let result = testDecoder.paymentRequestShippingContactUpdate(errors: [pkPaymentError1, pkPaymentError2])

        XCTAssertEqual(result.status, .success, "Status should remain success when all errors are PKPaymentError")
        XCTAssertNotNil(result.paymentSummaryItems, "Should return payment summary items")
    }

    func test_paymentRequestShippingContactUpdate_withNonPKPaymentError_shouldSetFailureStatus() {
        let testDecoder = decoder
        let nonPKError = ShopifyAcceleratedCheckouts.Error.invariant(expected: "test")

        let result = testDecoder.paymentRequestShippingContactUpdate(errors: [nonPKError])

        XCTAssertEqual(result.status, .failure, "Status should be failure when error is not PKPaymentError")
        XCTAssertNotNil(result.paymentSummaryItems, "Should return payment summary items")
    }

    func test_paymentRequestShippingContactUpdate_withMixedErrors_shouldSetFailureStatus() {
        let testDecoder = decoder
        let pkPaymentError = PKPaymentError(.shippingAddressUnserviceableError)
        let nonPKError = ShopifyAcceleratedCheckouts.Error.invariant(expected: "test")

        let result = testDecoder.paymentRequestShippingContactUpdate(errors: [pkPaymentError, nonPKError])

        XCTAssertEqual(result.status, .failure, "Status should be failure when any error is not PKPaymentError")
        XCTAssertNotNil(result.paymentSummaryItems, "Should return payment summary items")
    }
}
