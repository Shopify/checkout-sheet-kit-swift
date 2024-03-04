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

// swiftlint:disable identifier_name

import Foundation

public struct CheckoutCompletedEvent: Decodable {
	public let orderDetails: OrderDetails

	enum CodingKeys: String, CodingKey {
		case orderDetails
	}
}

extension CheckoutCompletedEvent {
	public struct Address: Decodable {
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

		enum CodingKeys: String, CodingKey {
			case address1
			case address2
			case city
			case countryCode
			case firstName
			case lastName
			case name
			case phone
			case postalCode
			case referenceId
			case zoneCode
		}
	}

	public struct CartInfo: Decodable {
		public let lines: [CartLine]
		public let price: Price
		public let token: String

		enum CodingKeys: String, CodingKey {
			case lines
			case price
			case token
		}
	}

	public struct CartLineImage: Decodable {
		public let altText: String?
		public let lg: String
		public let md: String
		public let sm: String

		enum CodingKeys: String, CodingKey {
			case altText
			case lg
			case md
			case sm
		}
	}

	public struct CartLine: Decodable {
		public let discounts: [Discount]?
		public let image: CartLineImage?
		public let merchandiseId: String?
		public let price: Money
		public let productId: String?
		public let quantity: Int
		public let title: String

		enum CodingKeys: String, CodingKey {
			case discounts
			case image
			case merchandiseId
			case price
			case productId
			case quantity
			case title
		}
	}

	public struct DeliveryDetails: Decodable {
		public let additionalInfo: String?
		public let location: Address?
		public let name: String?

		enum CodingKeys: String, CodingKey {
			case additionalInfo
			case location
			case name
		}
	}

	public struct DeliveryInfo: Decodable {
		public let details: DeliveryDetails
		public let method: String

		enum CodingKeys: String, CodingKey {
			case details
			case method
		}
	}

	public struct Discount: Decodable {
		public let amount: Money?
		public let applicationType: String?
		public let title: String?
		public let value: Double?
		public let valueType: String?
	}

	public struct OrderDetails: Decodable {
		public let billingAddress: Address?
		public let cart: CartInfo
		public let deliveries: [DeliveryInfo]?
		public let email: String?
		public let id: String
		public let paymentMethods: [PaymentMethod]?
		public let phone: String?

		enum CodingKeys: String, CodingKey {
			case billingAddress
			case cart
			case deliveries
			case email
			case id
			case paymentMethods
			case phone
		}
	}

	public struct PaymentMethod: Decodable {
		public let details: [String: String?]
		public let type: String

		enum CodingKeys: String, CodingKey {
			case details
			case type
		}
	}

	public struct Price: Decodable {
		public let discounts: [Discount]?
		public let shipping: Money?
		public let subtotal: Money?
		public let taxes: Money?
		public let total: Money?

		enum CodingKeys: String, CodingKey {
			case discounts
			case shipping
			case subtotal
			case taxes
			case total
		}
	}

	public struct Money: Decodable {
		public let amount: Double?
		public let currencyCode: String?

		enum CodingKeys: String, CodingKey {
			case amount
			case currencyCode
		}
	}
}

// swiftlint:enable identifier_name

internal let emptyCheckoutCompletedEvent = CheckoutCompletedEvent(
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
		id: "",
		paymentMethods: nil,
		phone: nil
	)
)
