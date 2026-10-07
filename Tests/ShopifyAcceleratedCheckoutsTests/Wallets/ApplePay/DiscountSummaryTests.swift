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
final class DiscountSummaryTests: XCTestCase {
    func testFixedOrderDiscountIsCountedOnceAcrossMultipleLines() throws {
        let cart = try makeCart(
            subtotals: [40, 60],
            lineTotals: [36, 54],
            applications: [application(amount: 10, code: "SAVE10")],
            total: 90
        )

        let summary = PassKitFactory.shared.mapToApplePayLineItems(cart: cart, merchantName: "Test Store")

        XCTAssertEqual(summary.count, 3)
        XCTAssertEqual(summary.first?.amount.decimalValue, 100)
        XCTAssertEqual(summary.first { $0.label == "SAVE10" }?.amount.decimalValue, -10)
        assertBalanced(summary, total: 90)
    }

    func testPercentageDiscountUsesAllocatedAmountWithDecimalPrecision() throws {
        let cart = try makeCart(
            subtotals: [XCTUnwrap(Decimal(string: "19.99")), XCTUnwrap(Decimal(string: "29.99"))],
            lineTotals: [XCTUnwrap(Decimal(string: "16.99")), XCTUnwrap(Decimal(string: "25.49"))],
            applications: [application(amount: XCTUnwrap(Decimal(string: "7.50")), code: "SAVE15PERCENT")],
            total: XCTUnwrap(Decimal(string: "42.48"))
        )

        let summary = PassKitFactory.shared.mapToApplePayLineItems(cart: cart, merchantName: "Test Store")

        XCTAssertEqual(summary.first { $0.label == "SAVE15PERCENT" }?.amount.decimalValue, Decimal(string: "-7.50"))
        try assertBalanced(summary, total: XCTUnwrap(Decimal(string: "42.48")))
    }

    func testAutomaticAndCustomDiscountsShareTheGeneralDiscountLabel() throws {
        let cart = try makeCart(
            subtotals: [100],
            lineTotals: [85],
            applications: [
                application(amount: 10, typename: "CartAutomaticDiscountApplication"),
                application(amount: 5, typename: "CartCustomDiscountApplication")
            ],
            total: 85
        )

        let allocations = try PassKitFactory.shared.createDiscountAllocations(cart: cart)
        let summary = PassKitFactory.shared.mapToApplePayLineItems(cart: cart, merchantName: "Test Store")
        let discounts = summary.filter { $0.amount.decimalValue < 0 }

        XCTAssertEqual(allocations.count, 2)
        XCTAssertTrue(allocations.allSatisfy { $0.code == nil && $0.currencyCode == "USD" })
        XCTAssertEqual(discounts.count, 1)
        XCTAssertEqual(discounts.first?.amount.decimalValue, -15)
        assertBalanced(summary, total: 85)
    }

    func testProductAndOrderDiscountsWithSameCodeAreCombinedOnce() throws {
        let cart = try makeCart(
            subtotals: [20, 80],
            lineTotals: [13, 72],
            applications: [application(amount: 5, code: "COMBINED"), application(amount: 10, code: "COMBINED")],
            total: 85
        )

        let summary = PassKitFactory.shared.mapToApplePayLineItems(cart: cart, merchantName: "Test Store")

        XCTAssertEqual(summary.filter { $0.label == "COMBINED" }.count, 1)
        XCTAssertEqual(summary.first { $0.label == "COMBINED" }?.amount.decimalValue, -15)
        assertBalanced(summary, total: 85)
    }

    func testZeroAmountDiscountDoesNotAddASummaryRow() throws {
        let cart = try makeCart(
            subtotals: [100],
            lineTotals: [100],
            applications: [application(amount: 0, code: "ZERO")],
            total: 100
        )

        let summary = PassKitFactory.shared.mapToApplePayLineItems(cart: cart, merchantName: "Test Store")

        XCTAssertEqual(summary.count, 2)
        XCTAssertFalse(summary.contains { $0.label == "ZERO" })
        assertBalanced(summary, total: 100)
    }

    func testEmptyApplicationsDecodeWithoutLegacyAllocationFields() throws {
        let cart = try makeCart(subtotals: [100], lineTotals: [100], applications: [], total: 100)

        XCTAssertTrue(try PassKitFactory.shared.createDiscountAllocations(cart: cart).isEmpty)
    }

    func testFreeShippingIsDeductedOnceAndPreservesTheShippingQuote() throws {
        let cart = try makeCart(
            subtotals: [100],
            lineTotals: [100],
            applications: [application(amount: 10, code: "FREESHIP", targetType: "SHIPPING_LINE")],
            total: 100,
            deliveryGroups: [deliveryGroup(cost: 10)]
        )

        let summary = PassKitFactory.shared.mapToApplePayLineItems(cart: cart, merchantName: "Test Store")
        let shippingMethods = PassKitFactory.shared.createShippingMethods(deliveryGroups: cart.deliveryGroups.nodes)

        XCTAssertEqual(summary[1].amount.decimalValue, 10)
        XCTAssertEqual(summary.first { $0.label == "FREESHIP" }?.amount.decimalValue, -10)
        XCTAssertEqual(shippingMethods.first?.amount.decimalValue, 10)
        assertBalanced(summary, total: 100)
    }

    func testPartialShippingDiscountIsDeductedOnce() throws {
        let cart = try makeCart(
            subtotals: [100],
            lineTotals: [100],
            applications: [application(amount: 4, code: "SHIP4", targetType: "SHIPPING_LINE")],
            total: 106,
            deliveryGroups: [deliveryGroup(cost: 10)]
        )

        let summary = PassKitFactory.shared.mapToApplePayLineItems(cart: cart, merchantName: "Test Store")

        XCTAssertEqual(summary[1].amount.decimalValue, 10)
        XCTAssertEqual(summary.first { $0.label == "SHIP4" }?.amount.decimalValue, -4)
        assertBalanced(summary, total: 106)
    }

    func testCombinedProductAndShippingDiscountAcrossDeliveryGroups() throws {
        let cart = try makeCart(
            subtotals: [40, 60],
            lineTotals: [36, 54],
            applications: [
                application(amount: 10, code: "COMBINED"),
                application(amount: 5, code: "COMBINED", targetType: "SHIPPING_LINE")
            ],
            total: 100,
            deliveryGroups: [deliveryGroup(cost: 10), deliveryGroup(cost: 5, groupType: "SUBSCRIPTION")]
        )

        let summary = PassKitFactory.shared.mapToApplePayLineItems(cart: cart, merchantName: "Test Store")
        let shippingMethods = PassKitFactory.shared.createShippingMethods(deliveryGroups: cart.deliveryGroups.nodes)

        XCTAssertEqual(summary[1].amount.decimalValue, 10)
        XCTAssertEqual(summary[2].amount.decimalValue, 5)
        XCTAssertNotEqual(summary[1].label, summary[2].label)
        XCTAssertEqual(summary.filter { $0.label == "COMBINED" }.count, 1)
        XCTAssertEqual(summary.first { $0.label == "COMBINED" }?.amount.decimalValue, -15)
        XCTAssertEqual(shippingMethods.first?.amount.decimalValue, 15)
        assertBalanced(summary, total: 100)
    }

    func testUnselectedShippingOptionDoesNotAddAShippingCharge() throws {
        let cart = try makeCart(
            subtotals: [100],
            lineTotals: [90],
            applications: [application(amount: 10, code: "SAVE10")],
            total: 90,
            deliveryGroups: [deliveryGroup(cost: 10, selected: false)]
        )

        let summary = PassKitFactory.shared.mapToApplePayLineItems(cart: cart, merchantName: "Test Store")

        XCTAssertEqual(summary[1].amount.decimalValue, 0)
        assertBalanced(summary, total: 90)
    }

    func testCartTotalRemainsAuthoritative() throws {
        let cart = try makeCart(
            subtotals: [100],
            lineTotals: [90],
            applications: [application(amount: 10, code: "SAVE10")],
            total: 87
        )

        let summary = PassKitFactory.shared.mapToApplePayLineItems(cart: cart, merchantName: "Test Store")

        XCTAssertEqual(summary.last?.amount.decimalValue, 87)
    }

    private func assertBalanced(
        _ summary: [PKPaymentSummaryItem],
        total: Decimal,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(summary.last?.label, "Test Store", file: file, line: line)
        XCTAssertEqual(summary.last?.amount.decimalValue, total, file: file, line: line)
        XCTAssertEqual(summary.dropLast().reduce(Decimal.zero) { $0 + $1.amount.decimalValue }, total, file: file, line: line)
    }

    private func makeCart(
        subtotals: [Decimal],
        lineTotals: [Decimal],
        applications: [[String: Any]],
        total: Decimal,
        deliveryGroups: [[String: Any]] = []
    ) throws -> StorefrontAPI.Cart {
        let lines = zip(subtotals, lineTotals).enumerated().map { index, amounts in
            [
                "id": "gid://shopify/CartLine/\(index)",
                "quantity": 1,
                "cost": ["subtotalAmount": money(amounts.0), "totalAmount": money(amounts.1)]
            ] as [String: Any]
        }
        let cart: [String: Any] = [
            "id": "gid://shopify/Cart/test-cart",
            "checkoutUrl": "https://test-shop.myshopify.com/checkout",
            "totalQuantity": lines.count,
            "deliveryGroups": ["nodes": deliveryGroups],
            "lines": ["nodes": lines],
            "cost": ["totalAmount": money(total)],
            "discountApplications": applications
        ]
        return try JSONDecoder().decode(StorefrontAPI.Cart.self, from: JSONSerialization.data(withJSONObject: cart))
    }

    private func application(
        amount: Decimal,
        code: String? = nil,
        typename: String = "CartCodeDiscountApplication",
        targetType: String = "LINE_ITEM"
    ) -> [String: Any] {
        var result: [String: Any] = [
            "__typename": typename,
            "targetType": targetType,
            "totalAllocatedAmount": money(amount)
        ]
        if let code {
            result["code"] = code
        }
        return result
    }

    private func deliveryGroup(
        cost: Decimal,
        groupType: String = "ONE_TIME_PURCHASE",
        selected: Bool = true
    ) -> [String: Any] {
        let option: [String: Any] = [
            "handle": "shipping-\(groupType)",
            "title": "Standard Shipping",
            "deliveryMethodType": "SHIPPING",
            "estimatedCost": money(cost)
        ]
        return [
            "id": "gid://shopify/CartDeliveryGroup/\(groupType)",
            "groupType": groupType,
            "deliveryOptions": [option],
            "selectedDeliveryOption": selected ? option : NSNull()
        ]
    }

    private func money(_ amount: Decimal) -> [String: String] {
        ["amount": "\(amount)", "currencyCode": "USD"]
    }
}
