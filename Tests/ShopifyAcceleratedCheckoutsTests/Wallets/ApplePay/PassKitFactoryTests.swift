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

import XCTest

@testable import ShopifyAcceleratedCheckouts

class PassKitFactoryTests: XCTestCase {
    var oneTimePurchaseDeliveryGroup: StorefrontAPI.CartDeliveryGroup!
    var subscriptionDeliveryGroup: StorefrontAPI.CartDeliveryGroup!

    override func setUp() {
        super.setUp()

        // Create delivery options for one-time purchase
        let standardShipping = StorefrontAPI.CartDeliveryOption(
            handle: "1234",
            title: "Standard Shipping",
            code: nil,
            deliveryMethodType: .shipping,
            description: "2 to 3 days",
            estimatedCost: StorefrontAPI.MoneyV2(amount: 10.00, currencyCode: "CAD")
        )

        let expressShipping = StorefrontAPI.CartDeliveryOption(
            handle: "12345",
            title: "Express Shipping",
            code: nil,
            deliveryMethodType: .shipping,
            description: "1 to 2 days",
            estimatedCost: StorefrontAPI.MoneyV2(amount: 20.99, currencyCode: "CAD")
        )

        oneTimePurchaseDeliveryGroup = StorefrontAPI.CartDeliveryGroup(
            id: GraphQLScalars.ID("test-one-time-group"),
            groupType: .oneTimePurchase,
            deliveryOptions: [standardShipping, expressShipping],
            selectedDeliveryOption: nil
        )

        // Create delivery options for subscription
        let subscriptionShipping = StorefrontAPI.CartDeliveryOption(
            handle: "4321",
            title: "Subscription Shipping",
            code: nil,
            deliveryMethodType: .shipping,
            description: "5 to 7 days",
            estimatedCost: StorefrontAPI.MoneyV2(amount: 5.00, currencyCode: "CAD")
        )

        subscriptionDeliveryGroup = StorefrontAPI.CartDeliveryGroup(
            id: GraphQLScalars.ID("test-subscription-group"),
            groupType: .subscription,
            deliveryOptions: [subscriptionShipping],
            selectedDeliveryOption: nil
        )
    }

    override func tearDown() {
        oneTimePurchaseDeliveryGroup = nil
        subscriptionDeliveryGroup = nil
        super.tearDown()
    }

    func testCreateShippingMethodsWithOneTimePurchaseGroup() {
        let result = PassKitFactory.shared.createShippingMethods(
            deliveryGroups: [oneTimePurchaseDeliveryGroup]
        )

        XCTAssertEqual(result.count, 2)

        let firstMethod = result[0]
        XCTAssertEqual(firstMethod.label, "Standard Shipping")
        XCTAssertEqual(firstMethod.amount, NSDecimalNumber(decimal: 10.00))
        XCTAssertEqual(firstMethod.identifier, "1234")
        XCTAssertEqual(firstMethod.detail, "2 to 3 days")

        let secondMethod = result[1]
        XCTAssertEqual(secondMethod.label, "Express Shipping")
        XCTAssertEqual(secondMethod.amount, NSDecimalNumber(decimal: 20.99))
        XCTAssertEqual(secondMethod.identifier, "12345")
        XCTAssertEqual(secondMethod.detail, "1 to 2 days")
    }

    func testCreateShippingMethodsWithEmptyDeliveryGroups() {
        let result = PassKitFactory.shared.createShippingMethods(deliveryGroups: [])
        XCTAssertTrue(result.isEmpty)
    }

    func testCreateShippingMethodsWithNilDeliveryGroups() {
        let result = PassKitFactory.shared.createShippingMethods(deliveryGroups: nil)
        XCTAssertTrue(result.isEmpty)
    }

    func testCreateShippingMethodsWithCombinedGroups() {
        let result = PassKitFactory.shared.createShippingMethods(
            deliveryGroups: [oneTimePurchaseDeliveryGroup, subscriptionDeliveryGroup]
        )

        XCTAssertEqual(result.count, 2)

        let firstCombination = result.first { $0.identifier == "1234,4321" }
        XCTAssertNotNil(firstCombination)
        XCTAssertEqual(firstCombination?.label, "Standard Shipping and Subscription Shipping")
        XCTAssertEqual(firstCombination?.amount, NSDecimalNumber(decimal: 15.00))
        XCTAssertEqual(firstCombination?.detail, "2 to 3 days and 5 to 7 days")

        let secondCombination = result.first { $0.identifier == "12345,4321" }
        XCTAssertNotNil(secondCombination)
        XCTAssertEqual(secondCombination?.label, "Express Shipping and Subscription Shipping")
        XCTAssertEqual(secondCombination?.amount, NSDecimalNumber(decimal: 25.99))
        XCTAssertEqual(secondCombination?.detail, "1 to 2 days and 5 to 7 days")
    }
}
