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

public struct CheckoutCompleteEvent: Codable, CheckoutNotification, CheckoutEventDecodable {
    public static let method = "checkout.complete"
    public let orderConfirmation: OrderConfirmation
    public let cart: Cart
}

func createEmptyCheckoutCompleteEvent(id: String? = "") -> CheckoutCompleteEvent {
    return CheckoutCompleteEvent(
        orderConfirmation: OrderConfirmation(
            url: nil,
            order: OrderConfirmation.Order(id: id ?? ""),
            number: nil,
            isFirstOrder: false
        ),
        cart: Cart(
            id: "",
            lines: [],
            cost: CartCost(
                subtotalAmount: Money(amount: "", currencyCode: ""),
                totalAmount: Money(amount: "", currencyCode: "")
            ),
            buyerIdentity: CartBuyerIdentity(
                email: nil,
                phone: nil,
                customer: nil,
                countryCode: nil
            ),
            deliveryGroups: [],
            discountCodes: [],
            appliedGiftCards: [],
            discountAllocations: [],
            delivery: CartDelivery(addresses: []),
            payment: .init(instruments: [])
        )
    )
}
