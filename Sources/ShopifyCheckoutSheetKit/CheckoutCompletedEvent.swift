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
	public let orderDetails: OrderDetails?

	enum CodingKeys: String, CodingKey {
		case orderDetails
	}

	init() {
		orderDetails = nil
	}
}

extension CheckoutCompletedEvent {
	public struct OrderDetails: Decodable {
		public let id: String?
		public let email: String?
		public let phone: String?
		public let cart: CartInfo?
		public let paymentMethods: [OrderPaymentMethod]?
		public let billingAddress: Address?
		public let deliveries: [DeliveryInfo]?

		enum CodingKeys: String, CodingKey {
			case id
			case email
			case phone
			case cart
			case paymentMethods
			case billingAddress
			case deliveries
		}
	}

	public struct CartInfo: Decodable {
		public let lines: [CartLine]?
		public let price: PriceSet?

		enum CodingKeys: String, CodingKey {
			case lines
			case price
		}
	}

	public struct OrderPaymentMethod: Decodable {
		public let type: String?
		public let details: [String: String?]

		enum CodingKeys: String, CodingKey {
			case type
			case details
		}
	}

	public struct Address: Decodable {
		public let referenceId: String?
		public let name: String?
		public let firstName: String?
		public let lastName: String?
		public let address1: String?
		public let address2: String?
		public let city: String?
		public let countryCode: String?
		public let zoneCode: String?
		public let postalCode: String?
		public let phone: String?

		enum CodingKeys: String, CodingKey {
			case referenceId
			case name
			case firstName
			case lastName
			case address1
			case address2
			case city
			case countryCode
			case zoneCode
			case postalCode
			case phone
		}
	}

	public struct DeliveryInfo: Decodable {
		public let method: String?
		public let details: DeliveryDetails?

		enum CodingKeys: String, CodingKey {
			case method
			case details
		}
	}

	public struct DeliveryDetails: Decodable {
		public let name: String?
		public let location: Address?
		public let additionalInfo: String?

		enum CodingKeys: String, CodingKey {
			case name
			case location
			case additionalInfo
		}
	}

	public struct PriceSet: Decodable {
		public let subtotal: Money?
		public let total: Money?
		public let taxes: Money?
		public let discounts: [Discount]?
		public let shipping: Money?

		enum CodingKeys: String, CodingKey {
			case subtotal
			case total
			case taxes
			case discounts
			case shipping
		}
	}

	public struct Discount: Decodable {
		public let title: String?
		public let amount: Money?
		public let applicationType: String?
		public let valueType: String?
		public let value: Double?
	}

	public struct CartLineImage: Decodable {
		public let sm: String?
		public let md: String?
		public let lg: String?
		public let altText: String?

		enum CodingKeys: String, CodingKey {
			case sm
			case md
			case lg
			case altText
		}
	}

	public struct CartLine: Decodable {
		public let title: String?
		public let quantity: Int?
		public let price: Money?
		public let image: CartLineImage?
		public let merchandiseId: String?
		public let productId: String?
		public let discounts: [Discount]?

		enum CodingKeys: String, CodingKey {
			case title
			case quantity
			case price
			case image
			case merchandiseId
			case productId
			case discounts
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
