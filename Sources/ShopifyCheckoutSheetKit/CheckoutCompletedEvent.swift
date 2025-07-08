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

public struct CheckoutCompletedEvent: Codable {
    public let orderDetails: OrderDetails
}

public extension CheckoutCompletedEvent {
    struct Address: Codable {
        public let address1: String?
        public let address2: String?
        public let city: String?
        public let countryCode: String?
        public let firstName: String?
        public let lastName: String?
        public let name: String?
        public let phone: String?
        public let postalCode: String?
        public let referenceId: String?
        public let zoneCode: String?
    }

    struct CartInfo: Codable {
        public let lines: [CartLine]
        public let price: Price
        public let token: String
    }

    struct CartLineImage: Codable {
        public let altText: String?
        // swiftlint:disable identifier_name
        public let lg: String
        public let md: String
        public let sm: String
        // swiftlint:enable identifier_name
    }

    struct CartLine: Codable {
        public let discounts: [Discount]?
        public let image: CartLineImage?
        public let merchandiseId: String?
        public let price: Money
        public let productId: String?
        public let quantity: Int
        public let title: String
    }

    struct DeliveryDetails: Codable {
        public let additionalInfo: String?
        public let location: Address?
        public let name: String?
    }

    struct DeliveryInfo: Codable {
        public let details: DeliveryDetails
        public let method: String
    }

    struct Discount: Codable {
        public let amount: Money?
        public let applicationType: String?
        public let title: String?
        public let value: Double?
        public let valueType: String?
    }

    struct OrderDetails: Codable {
        public let billingAddress: Address?
        public let cart: CartInfo
        public let deliveries: [DeliveryInfo]?
        public let email: String?
        public let id: String
        public let paymentMethods: [PaymentMethod]?
        public let phone: String?
    }

    struct PaymentMethod: Codable {
        public let details: [String: String?]
        public let type: String
    }

    struct Price: Codable {
        public let discounts: [Discount]?
        public let shipping: Money?
        public let subtotal: Money?
        public let taxes: Money?
        public let total: Money?
    }

    struct Money: Codable {
        public let amount: Double?
        public let currencyCode: String?
    }
}

func createEmptyCheckoutCompletedEvent(id: String? = "") -> CheckoutCompletedEvent {
    return CheckoutCompletedEvent(
        orderDetails: CheckoutCompletedEvent.OrderDetails(
            billingAddress: CheckoutCompletedEvent.Address(
                address1: nil,
                address2: nil,
                city: nil,
                countryCode: nil,
                firstName: nil,
                lastName: nil,
                name: nil,
                phone: nil,
                postalCode: nil,
                referenceId: nil,
                zoneCode: nil
            ),
            cart: CheckoutCompletedEvent.CartInfo(
                lines: [],
                price: CheckoutCompletedEvent.Price(
                    discounts: nil,
                    shipping: CheckoutCompletedEvent.Money(amount: nil, currencyCode: nil),
                    subtotal: CheckoutCompletedEvent.Money(amount: nil, currencyCode: nil),
                    taxes: CheckoutCompletedEvent.Money(amount: nil, currencyCode: nil),
                    total: CheckoutCompletedEvent.Money(amount: nil, currencyCode: nil)
                ),
                token: ""
            ),
            deliveries: nil,
            email: nil,
            id: id ?? "",
            paymentMethods: nil,
            phone: nil
        )
    )
}
