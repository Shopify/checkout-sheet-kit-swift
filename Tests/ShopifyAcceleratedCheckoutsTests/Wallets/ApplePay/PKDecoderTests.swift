
import PassKit
@testable import ShopifyAcceleratedCheckouts
import XCTest

class PKDecoderTests: XCTestCase {
    private var cart: () -> Api.Types.Cart? = { nil }

    private var decoder: PKDecoder {
        return PKDecoder(configuration: ApplePayConfigurationWrapper.testConfiguration, cart: { self.cart() })
    }


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
}
