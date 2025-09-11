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

    // MARK: - Helper Factory Methods

    private func makeCart(
        email: String? = nil,
        phone: String? = nil,
        customerEmail: String? = nil,
        customerPhone: String? = nil
    ) -> StorefrontAPI.Cart {
        let customer: StorefrontAPI.CartCustomer? = (customerEmail != nil || customerPhone != nil) ?
            StorefrontAPI.CartCustomer(email: customerEmail, phone: customerPhone) : nil

        let buyerIdentity: StorefrontAPI.CartBuyerIdentity? = (email != nil || phone != nil || customer != nil) ?
            StorefrontAPI.CartBuyerIdentity(email: email, phone: phone, customer: customer) : nil

        return StorefrontAPI.Cart(
            id: GraphQLScalars.ID("gid://Shopify/Cart/test-cart-id"),
            checkoutUrl: GraphQLScalars.URL(URL(string: "https://test-shop.myshopify.com/checkout")!),
            totalQuantity: 1,
            buyerIdentity: buyerIdentity,
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

    private func makeConfiguration(
        customerEmail: String? = nil,
        customerPhone: String? = nil,
        contactFields: [ShopifyAcceleratedCheckouts.RequiredContactFields] = []
    ) -> ApplePayConfigurationWrapper {
        let customer = (customerEmail != nil || customerPhone != nil) ?
            ShopifyAcceleratedCheckouts.Customer(email: customerEmail, phoneNumber: customerPhone) : nil

        let config = ShopifyAcceleratedCheckouts.Configuration.testConfiguration(customer: customer)

        return ApplePayConfigurationWrapper.testConfiguration(
            common: config,
            applePay: ShopifyAcceleratedCheckouts.ApplePayConfiguration(
                merchantIdentifier: "merchant.test.id",
                contactFields: contactFields
            )
        )
    }

    private func makeDecoder(
        configuration: ApplePayConfigurationWrapper? = nil,
        cart: StorefrontAPI.Cart? = nil
    ) -> PKDecoder {
        let config = configuration ?? makeConfiguration()
        return PKDecoder(configuration: config, cart: { cart })
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
        let testDecoder = makeDecoder(cart: nil)
        XCTAssertTrue(testDecoder.paymentSummaryItems.isEmpty)
    }

    func testReturnsEmptyPaymentSummaryWhenCartHasNoLines() {
        // Don't set cart - it remains nil
        let testDecoder = makeDecoder(cart: nil)
        XCTAssertTrue(testDecoder.paymentSummaryItems.isEmpty)
    }

    func testPaymentSummaryItemsWithShippingMethodButNilCart() {
        let testDecoder = makeDecoder(cart: nil)
        let shippingMethod = PKShippingMethod(label: "Express", amount: NSDecimalNumber(decimal: 5.00))
        testDecoder.selectedShippingMethod = shippingMethod

        XCTAssertTrue(testDecoder.paymentSummaryItems.isEmpty)
    }

    // MARK: - shippingMethods Tests

    func testReturnsEmptyShippingMethodsWhenCartIsNil() {
        let testDecoder = makeDecoder(cart: nil)
        XCTAssertTrue(testDecoder.shippingMethods.isEmpty)
    }

    func testReturnsEmptyShippingMethodsWhenNoDeliveryGroups() {
        // Don't set cart - it remains nil
        let testDecoder = makeDecoder(cart: nil)
        XCTAssertTrue(testDecoder.shippingMethods.isEmpty)
    }

    func testShippingMethodsWithNilCartReturnsEmpty() {
        let testDecoder = makeDecoder(cart: nil)
        XCTAssertTrue(testDecoder.shippingMethods.isEmpty)
    }

    // MARK: - selectedShippingMethod Tests

    func testSelectedShippingMethodCanBeSetAndRetrieved() {
        let testDecoder = makeDecoder()
        let shippingMethod = PKShippingMethod(label: "Express", amount: NSDecimalNumber(decimal: 5.00))
        shippingMethod.detail = "1-2 business days"
        shippingMethod.identifier = "express"

        testDecoder.selectedShippingMethod = shippingMethod

        XCTAssertNotNil(testDecoder.selectedShippingMethod)
        XCTAssertEqual(testDecoder.selectedShippingMethod?.label, "Express")
        XCTAssertEqual(testDecoder.selectedShippingMethod?.amount, NSDecimalNumber(decimal: 5.00))
        XCTAssertEqual(testDecoder.selectedShippingMethod?.detail, "1-2 business days")
        XCTAssertEqual(testDecoder.selectedShippingMethod?.identifier, "express")
    }

    // MARK: - requiredContactFields Tests

    func testRequiredContactFieldsDefaultsToEmailWhenNoFieldsConfigured() {
        let configuration = makeConfiguration(contactFields: [])
        let testDecoder = makeDecoder(configuration: configuration, cart: nil)

        XCTAssertEqual(testDecoder.requiredContactFields, [PKContactField.emailAddress])
    }

    func testRequiredContactFieldsIncludesEmailWhenRequestedAndNotInBuyerIdentity() {
        let configuration = makeConfiguration(contactFields: [ShopifyAcceleratedCheckouts.RequiredContactFields.email])
        let testDecoder = makeDecoder(configuration: configuration, cart: nil)

        XCTAssertEqual(testDecoder.requiredContactFields, [PKContactField.emailAddress])
    }

    func testRequiredContactFieldsIncludesPhoneWhenRequestedAndNotInBuyerIdentity() {
        let configuration = makeConfiguration(contactFields: [ShopifyAcceleratedCheckouts.RequiredContactFields.phone])
        let testDecoder = makeDecoder(configuration: configuration, cart: nil)

        XCTAssertEqual(testDecoder.requiredContactFields, [.phoneNumber])
    }

    func testRequiredContactFieldsExcludesEmailWhenAlreadyInBuyerIdentity() {
        let configuration = makeConfiguration(contactFields: [ShopifyAcceleratedCheckouts.RequiredContactFields.email, ShopifyAcceleratedCheckouts.RequiredContactFields.phone])
        let cart = makeCart(email: "test@example.com")
        let testDecoder = makeDecoder(configuration: configuration, cart: cart)

        XCTAssertEqual(testDecoder.requiredContactFields, [.phoneNumber])
    }

    func testRequiredContactFieldsExcludesPhoneWhenAlreadyInBuyerIdentity() {
        let configuration = makeConfiguration(contactFields: [ShopifyAcceleratedCheckouts.RequiredContactFields.email, ShopifyAcceleratedCheckouts.RequiredContactFields.phone])
        let cart = makeCart(phone: "+1234567890")
        let testDecoder = makeDecoder(configuration: configuration, cart: cart)

        XCTAssertEqual(testDecoder.requiredContactFields, [PKContactField.emailAddress])
    }

    func testRequiredContactFieldsExcludesBothWhenBothAlreadyInBuyerIdentity() {
        let configuration = makeConfiguration(contactFields: [ShopifyAcceleratedCheckouts.RequiredContactFields.email, ShopifyAcceleratedCheckouts.RequiredContactFields.phone])
        let cart = makeCart(email: "test@example.com", phone: "+1234567890")
        let testDecoder = makeDecoder(configuration: configuration, cart: cart)

        XCTAssertTrue(testDecoder.requiredContactFields.isEmpty)
    }

    func testRequiredContactFieldsTreatsEmptyStringsAsNotPresent() {
        let configuration = makeConfiguration(contactFields: [ShopifyAcceleratedCheckouts.RequiredContactFields.email, ShopifyAcceleratedCheckouts.RequiredContactFields.phone])
        let cart = makeCart(email: "", phone: "")
        let testDecoder = makeDecoder(configuration: configuration, cart: cart)

        XCTAssertEqual(testDecoder.requiredContactFields, Set([PKContactField.emailAddress, PKContactField.phoneNumber]))
    }

    func testRequiredContactFieldsRequestsBothWhenBothNilInBuyerIdentity() {
        let configuration = makeConfiguration(contactFields: [ShopifyAcceleratedCheckouts.RequiredContactFields.email, ShopifyAcceleratedCheckouts.RequiredContactFields.phone])
        let cart = makeCart(email: nil, phone: nil)
        let testDecoder = makeDecoder(configuration: configuration, cart: cart)

        XCTAssertEqual(testDecoder.requiredContactFields, Set([PKContactField.emailAddress, PKContactField.phoneNumber]))
    }

    func testRequiredContactFieldsRequestsBothWhenBuyerIdentityIsNil() {
        let configuration = makeConfiguration(contactFields: [ShopifyAcceleratedCheckouts.RequiredContactFields.email, ShopifyAcceleratedCheckouts.RequiredContactFields.phone])
        let cart = makeCart()
        let testDecoder = makeDecoder(configuration: configuration, cart: cart)

        XCTAssertEqual(testDecoder.requiredContactFields, Set([PKContactField.emailAddress, PKContactField.phoneNumber]))
    }

    // MARK: - Minimum Required Field Tests

    func testRequiredContactFieldsDefaultsToEmailWhenNoFieldsAndNoBuyerIdentity() {
        let configuration = makeConfiguration(contactFields: [])
        let cart = makeCart()
        let testDecoder = makeDecoder(configuration: configuration, cart: cart)

        XCTAssertEqual(testDecoder.requiredContactFields, [PKContactField.emailAddress])
    }

    func testRequiredContactFieldsRespectsExistingEmailInBuyerIdentityEvenWithNoConfig() {
        let configuration = makeConfiguration(contactFields: [])
        let cart = makeCart(email: "test@example.com")
        let testDecoder = makeDecoder(configuration: configuration, cart: cart)

        XCTAssertTrue(testDecoder.requiredContactFields.isEmpty)
    }

    func testRequiredContactFieldsRespectsExistingPhoneInBuyerIdentityEvenWithNoConfig() {
        let configuration = makeConfiguration(contactFields: [])
        let cart = makeCart(phone: "+1234567890")
        let testDecoder = makeDecoder(configuration: configuration, cart: cart)

        XCTAssertTrue(testDecoder.requiredContactFields.isEmpty)
    }

    func testRequiredContactFieldsDefaultsToEmailWithEmptyBuyerIdentityStrings() {
        let configuration = makeConfiguration(contactFields: [])
        let cart = makeCart(email: "", phone: "")
        let testDecoder = makeDecoder(configuration: configuration, cart: cart)

        XCTAssertEqual(testDecoder.requiredContactFields, [PKContactField.emailAddress])
    }

    func testRequiredContactFieldsWithCustomerEmailAndPhone() {
        let configuration = makeConfiguration(contactFields: [ShopifyAcceleratedCheckouts.RequiredContactFields.email, ShopifyAcceleratedCheckouts.RequiredContactFields.phone])
        let cart = makeCart(customerEmail: "customer@example.com", customerPhone: "+9876543210")
        let testDecoder = makeDecoder(configuration: configuration, cart: cart)

        XCTAssertTrue(testDecoder.requiredContactFields.isEmpty)
    }

    func testRequiredContactFieldsWithCustomerEmailOnly() {
        let configuration = makeConfiguration(contactFields: [ShopifyAcceleratedCheckouts.RequiredContactFields.email, ShopifyAcceleratedCheckouts.RequiredContactFields.phone])
        let cart = makeCart(customerEmail: "customer@example.com")
        let testDecoder = makeDecoder(configuration: configuration, cart: cart)

        XCTAssertEqual(testDecoder.requiredContactFields, [.phoneNumber])
    }

    func testRequiredContactFieldsWithCustomerPhoneOnly() {
        let configuration = makeConfiguration(contactFields: [ShopifyAcceleratedCheckouts.RequiredContactFields.email, ShopifyAcceleratedCheckouts.RequiredContactFields.phone])
        let cart = makeCart(customerPhone: "+9876543210")
        let testDecoder = makeDecoder(configuration: configuration, cart: cart)

        XCTAssertEqual(testDecoder.requiredContactFields, [PKContactField.emailAddress])
    }

    func testRequiredContactFieldsFallbackToBuyerIdentityWhenCustomerIsNil() {
        let configuration = makeConfiguration(contactFields: [ShopifyAcceleratedCheckouts.RequiredContactFields.email, ShopifyAcceleratedCheckouts.RequiredContactFields.phone])
        let cart = makeCart(email: "buyer@example.com", phone: "+1234567890")
        let testDecoder = makeDecoder(configuration: configuration, cart: cart)

        XCTAssertTrue(testDecoder.requiredContactFields.isEmpty)
    }

    func testRequiredContactFieldsCustomerTakesPrecedenceOverBuyerIdentity() {
        let configuration = makeConfiguration(contactFields: [ShopifyAcceleratedCheckouts.RequiredContactFields.email, ShopifyAcceleratedCheckouts.RequiredContactFields.phone])
        let cart = makeCart(
            email: "buyer@example.com",
            phone: nil,
            customerEmail: "customer@example.com",
            customerPhone: "+9876543210"
        )
        let testDecoder = makeDecoder(configuration: configuration, cart: cart)

        XCTAssertTrue(testDecoder.requiredContactFields.isEmpty)
    }

    // MARK: - Customer Configuration Priority Tests

    func testRequiredContactFieldsUsesCustomerConfigurationEmailOverBuyerIdentity() {
        let configuration = makeConfiguration(customerEmail: "config@example.com", contactFields: [ShopifyAcceleratedCheckouts.RequiredContactFields.email, ShopifyAcceleratedCheckouts.RequiredContactFields.phone])
        let cart = makeCart(email: "buyer@example.com")
        let testDecoder = makeDecoder(configuration: configuration, cart: cart)

        XCTAssertEqual(testDecoder.requiredContactFields, [.phoneNumber])
    }

    func testRequiredContactFieldsUsesCustomerConfigurationPhoneOverBuyerIdentity() {
        let configuration = makeConfiguration(customerPhone: "+1234567890", contactFields: [ShopifyAcceleratedCheckouts.RequiredContactFields.email, ShopifyAcceleratedCheckouts.RequiredContactFields.phone])
        let cart = makeCart(phone: "+9876543210")
        let testDecoder = makeDecoder(configuration: configuration, cart: cart)

        XCTAssertEqual(testDecoder.requiredContactFields, [.emailAddress])
    }

    // MARK: - Customer Configuration With Email Tests

    func testRequiredContactFieldsExcludesEmailWhenInCustomerConfiguration() {
        let configuration = makeConfiguration(customerEmail: "config@example.com", contactFields: [ShopifyAcceleratedCheckouts.RequiredContactFields.email])
        let testDecoder = makeDecoder(configuration: configuration, cart: nil)

        XCTAssertTrue(testDecoder.requiredContactFields.isEmpty)
    }

    func testRequiredContactFieldsTreatsEmptyCustomerEmailAsNotPresent() {
        let configuration = makeConfiguration(customerEmail: "", contactFields: [ShopifyAcceleratedCheckouts.RequiredContactFields.email])
        let testDecoder = makeDecoder(configuration: configuration, cart: nil)

        XCTAssertEqual(testDecoder.requiredContactFields, [.emailAddress])
    }

    // MARK: - Customer Configuration With Phone Tests

    func testRequiredContactFieldsExcludesPhoneWhenInCustomerConfiguration() {
        let configuration = makeConfiguration(customerPhone: "+1234567890", contactFields: [ShopifyAcceleratedCheckouts.RequiredContactFields.phone])
        let testDecoder = makeDecoder(configuration: configuration, cart: nil)

        XCTAssertTrue(testDecoder.requiredContactFields.isEmpty)
    }

    func testRequiredContactFieldsTreatsEmptyCustomerPhoneAsNotPresent() {
        let configuration = makeConfiguration(customerPhone: "", contactFields: [ShopifyAcceleratedCheckouts.RequiredContactFields.phone])
        let testDecoder = makeDecoder(configuration: configuration, cart: nil)

        XCTAssertEqual(testDecoder.requiredContactFields, [.phoneNumber])
    }

    // MARK: - Customer Configuration With Both Email and Phone Tests

    func testRequiredContactFieldsExcludesBothWhenBothInCustomerConfiguration() {
        let configuration = makeConfiguration(
            customerEmail: "config@example.com",
            customerPhone: "+1234567890",
            contactFields: [ShopifyAcceleratedCheckouts.RequiredContactFields.email, ShopifyAcceleratedCheckouts.RequiredContactFields.phone]
        )
        let testDecoder = makeDecoder(configuration: configuration, cart: nil)

        XCTAssertTrue(testDecoder.requiredContactFields.isEmpty)
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
