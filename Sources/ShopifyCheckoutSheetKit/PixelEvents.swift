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

// swiftlint:disable file_length

import Foundation

public enum PixelEvent {
	case customEvent(CustomEvent)
	case checkoutAddressInfoSubmitted(PixelEventsCheckoutAddressInfoSubmitted)
	case checkoutCompleted(PixelEventsCheckoutCompleted)
	case checkoutContactInfoSubmitted(PixelEventsCheckoutContactInfoSubmitted)
	case checkoutShippingInfoSubmitted(PixelEventsCheckoutShippingInfoSubmitted)
	case checkoutStarted(PixelEventsCheckoutStarted)
	case pageViewed(PixelEventsPageViewed)
	case paymentInfoSubmitted(PixelEventsPaymentInfoSubmitted)
}

public protocol BaseEvent: Codable {
	var context: Context? {get}
	/// The ID of the customer event
	var id: String? {get}
	/// The name of the customer event
	var name: String? {get}
	/// The timestamp of when the customer event occurred, in [ISO
	/// 8601](https://en.wikipedia.org/wiki/ISO_8601) format
	var timestamp: String? {get}
}

public struct StandardEvent<T>: BaseEvent where T: Codable {
	public let context: Context?
	public let data: T?
	/// The ID of the customer event
	public let id: String?
	/// The name of the customer event
	public let name: String?
	/// The timestamp of when the customer event occurred, in [ISO
	/// 8601](https://en.wikipedia.org/wiki/ISO_8601) format
	public let timestamp: String?

	enum CodingKeys: String, CodingKey {
		case context, data, id, name, timestamp
	}
}

/// This event represents any custom events emitted by partners or merchants via
/// the `publish` method
public struct CustomEvent: BaseEvent {
	public let context: Context?
	public let customData: CustomData?
	/// The ID of the customer event
	public let id: String?
	/// The name of the customer event
	public let name: String?
	/// The timestamp of when the customer event occurred, in [ISO
	/// 8601](https://en.wikipedia.org/wiki/ISO_8601) format
	public let timestamp: String?

	enum CodingKeys: String, CodingKey {
		case context, customData, id, name, timestamp
	}
}

/// The `checkout_address_info_submitted` event logs an instance of a customer
/// submitting their mailing address. This event is only available in checkouts
/// where checkout extensibility for customizations is enabled
public typealias PixelEventsCheckoutAddressInfoSubmitted = StandardEvent<PixelEventsCheckoutAddressInfoSubmittedData>

/// The `checkout_completed` event logs when a visitor completes a purchase. This
/// event is available on the order status and checkout pages
public typealias PixelEventsCheckoutCompleted = StandardEvent<PixelEventsCheckoutCompletedData>

/// The `checkout_contact_info_submitted` event logs an instance where a customer
/// submits a checkout form. This event is only available in checkouts where
/// checkout extensibility for customizations is enabled
public typealias PixelEventsCheckoutContactInfoSubmitted = StandardEvent<PixelEventsCheckoutContactInfoSubmittedData>

/// The `checkout_shipping_info_submitted` event logs an instance where the
/// customer chooses a shipping rate. This event is only available in checkouts
/// where checkout extensibility for customizations is enabled
public typealias PixelEventsCheckoutShippingInfoSubmitted = StandardEvent<PixelEventsCheckoutShippingInfoSubmittedData>

/// The `checkout_started` event logs an instance of a customer starting
/// the checkout process. This event is available on the checkout page. For
/// checkout extensibility, this event is triggered every time a customer
/// enters checkout. For non-checkout extensible shops, this event is only
/// triggered the first time a customer enters checkout.
public typealias PixelEventsCheckoutStarted = StandardEvent<PixelEventsCheckoutStartedData>

/// The `page_viewed` event logs an instance where a customer visited a page.
/// This event is available on the online store, checkout, and order status pages
public typealias PixelEventsPageViewed = StandardEvent<PixelEventsPageViewedData>

/// The `payment_info_submitted` event logs an instance of a customer
/// submitting their payment information. This event is available on the
/// checkout page
public typealias PixelEventsPaymentInfoSubmitted = StandardEvent<PixelEventsPaymentInfoSubmittedData>

// MARK: - Context

/// A snapshot of various read-only properties of the browser at the time of
/// event
public struct Context: Codable {
	/// Snapshot of a subset of properties of the `document` object in the top
	/// frame of the browser
	public let document: WebPixelsDocument?
	/// Snapshot of a subset of properties of the `navigator` object in the top
	/// frame of the browser
	public let navigator: WebPixelsNavigator?
	/// Snapshot of a subset of properties of the `window` object in the top frame
	/// of the browser
	public let window: WebPixelsWindow?
}

// MARK: - WebPixelsDocument

/// Snapshot of a subset of properties of the `document` object in the top
/// frame of the browser
///
/// A snapshot of a subset of properties of the `document` object in the top
/// frame of the browser
public struct WebPixelsDocument: Codable {
	/// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Document),
	/// returns the character set being used by the document
	public let characterSet: String?
	/// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Document),
	/// returns the URI of the current document
	public let location: Location?
	/// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Document),
	/// returns the URI of the page that linked to this page
	public let referrer: String?
	/// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Document),
	/// returns the title of the current document
	public let title: String?
}

// MARK: - Location

/// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Document),
/// returns the URI of the current document
///
/// A snapshot of a subset of properties of the `location` object in the top
/// frame of the browser
///
/// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Window), the
/// location, or current URL, of the window object
public struct Location: Codable {
	/// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Location), a
	/// string containing a `'#'` followed by the fragment identifier of the URL
	public let hash: String?
	/// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Location), a
	/// string containing the host, that is the hostname, a `':'`, and the port of
	/// the URL
	public let host: String?
	/// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Location), a
	/// string containing the domain of the URL
	public let hostname: String?
	/// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Location), a
	/// string containing the entire URL
	public let href: String?
	/// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Location), a
	/// string containing the canonical form of the origin of the specific location
	public let origin: String?
	/// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Location), a
	/// string containing an initial `'/'` followed by the path of the URL, not
	/// including the query string or fragment
	public let pathname: String?
	/// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Location), a
	/// string containing the port number of the URL
	public let port: String?
	/// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Location), a
	/// string containing the protocol scheme of the URL, including the final `':'`
	public let locationProtocol: String?
	/// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Location), a
	/// string containing a `'?'` followed by the parameters or "querystring" of
	/// the URL
	public let search: String?

	enum CodingKeys: String, CodingKey {
		case hash, host, hostname, href, origin, pathname, port
		case locationProtocol = "protocol"
		case search
	}
}

// MARK: - WebPixelsNavigator

/// Snapshot of a subset of properties of the `navigator` object in the top
/// frame of the browser
///
/// A snapshot of a subset of properties of the `navigator` object in the top
/// frame of the browser
public struct WebPixelsNavigator: Codable {
	/// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Navigator),
	/// returns `false` if setting a cookie will be ignored and true otherwise
	public let cookieEnabled: Bool?
	/// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Navigator),
	/// returns a string representing the preferred language of the user, usually
	/// the language of the browser UI. The `null` value is returned when this
	/// is unknown
	public let language: String?
	/// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Navigator),
	/// returns an array of strings representing the languages known to the user,
	/// by order of preference
	public let languages: [String]?
	/// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Navigator),
	/// returns the user agent string for the current browser
	public let userAgent: String?
}

// MARK: - WebPixelsWindow

/// Snapshot of a subset of properties of the `window` object in the top frame
/// of the browser
///
/// A snapshot of a subset of properties of the `window` object in the top frame
/// of the browser
public struct WebPixelsWindow: Codable {
	/// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Window),
	/// gets the height of the content area of the browser window including, if
	/// rendered, the horizontal scrollbar
	public let innerHeight: Double?
	/// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Window), gets
	/// the width of the content area of the browser window including, if rendered,
	/// the vertical scrollbar
	public let innerWidth: Double?
	/// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Window), the
	/// location, or current URL, of the window object
	public let location: Location?
	/// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Window), the
	/// global object's origin, serialized as a string
	public let origin: String?
	/// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Window), gets
	/// the height of the outside of the browser window
	public let outerHeight: Double?
	/// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Window), gets
	/// the width of the outside of the browser window
	public let outerWidth: Double?
	/// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Window), an
	/// alias for window.scrollX
	public let pageXOffset: Double?
	/// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Window), an
	/// alias for window.scrollY
	public let pageYOffset: Double?
	/// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Screen), the
	/// interface representing a screen, usually the one on which the current
	/// window is being rendered
	public let screen: Screen?
	/// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Window), the
	/// horizontal distance from the left border of the user's browser viewport to
	/// the left side of the screen
	public let screenX: Double?
	/// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Window), the
	/// vertical distance from the top border of the user's browser viewport to the
	/// top side of the screen
	public let screenY: Double?
	/// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Window), the
	/// number of pixels that the document has already been scrolled horizontally
	public let scrollX: Double?
	/// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Window), the
	/// number of pixels that the document has already been scrolled vertically
	public let scrollY: Double?
}

// MARK: - Screen

/// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Screen), the
/// interface representing a screen, usually the one on which the current
/// window is being rendered
///
/// The interface representing a screen, usually the one on which the current
/// window is being rendered
public struct Screen: Codable {
	/// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Screen/height),
	/// the height of the screen
	public let height: Double?
	/// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Screen/width),
	/// the width of the screen
	public let width: Double?
}

// MARK: - MoneyV2

/// The total amount for the customer to pay.
///
/// A monetary value with currency.
///
/// The total cost of the merchandise line.
///
/// The product variant’s price.
///
/// The monetary value with currency allocated to the discount.
///
/// Price of this shipping rate.
///
/// The price at checkout before duties, shipping, and taxes.
///
/// The sum of all the prices of all the items in the checkout, including
/// duties, taxes, and discounts.
///
/// The sum of all the taxes applied to the line items and shipping lines in
/// the checkout.
///
/// The monetary value with currency allocated to the transaction method.
public struct MoneyV2: Codable {
	/// The decimal money amount.
	public let amount: Double?
	/// The three-letter code that represents the currency, for example, USD.
	/// Supported codes include standard ISO 4217 codes, legacy codes, and non-
	/// standard codes.
	public let currencyCode: String?
}

// MARK: - CartLine

/// Information about the merchandise in the cart.
public struct CartLine: Codable {
	/// The cost of the merchandise that the customer will pay for at checkout. The
	/// costs are subject to change and changes will be reflected at checkout.
	public let cost: CartLineCost?
	/// The merchandise that the buyer intends to purchase.
	public let merchandise: ProductVariant?
	/// The quantity of the merchandise that the customer intends to purchase.
	public let quantity: Double?
}

// MARK: - CartLineCost

/// The cost of the merchandise that the customer will pay for at checkout. The
/// costs are subject to change and changes will be reflected at checkout.
///
/// The cost of the merchandise line that the customer will pay at checkout.
public struct CartLineCost: Codable {
	/// The total cost of the merchandise line.
	public let totalAmount: MoneyV2?
}

// MARK: - ProductVariant

/// The merchandise that the buyer intends to purchase.
///
/// A product variant represents a different version of a product, such as
/// differing sizes or differing colors.
public struct ProductVariant: Codable {
	/// A globally unique identifier.
	public let id: String?
	/// Image associated with the product variant. This field falls back to the
	/// product image if no image is available.
	public let image: Image?
	/// The product variant’s price.
	public let price: MoneyV2?
	/// The product object that the product variant belongs to.
	public let product: Product?
	/// The SKU (stock keeping unit) associated with the variant.
	public let sku: String?
	/// The product variant’s title.
	public let title: String?
	/// The product variant’s untranslated title.
	public let untranslatedTitle: String?
}

// MARK: - Image

/// An image resource.
public struct Image: Codable {
	/// The location of the image as a URL.
	public let src: String?
}

// MARK: - Product

/// The product object that the product variant belongs to.
///
/// A product is an individual item for sale in a Shopify store.
public struct Product: Codable {
	/// The ID of the product.
	public let id: String?
	/// The product’s title.
	public let title: String?
	/// The [product
	/// type](https://help.shopify.com/en/manual/products/details/product-type)
	/// specified by the merchant.
	public let type: String?
	/// The product’s untranslated title.
	public let untranslatedTitle: String?
	/// The relative URL of the product.
	public let url: String?
	/// The product’s vendor name.
	public let vendor: String?
}

// MARK: PixelEventsCheckoutAddressInfoSubmitted convenience initializers and mutators

extension PixelEventsCheckoutAddressInfoSubmitted {
	init(from webPixelsEventBody: WebPixelsEventBody) {
		self.context = webPixelsEventBody.context
		self.id = webPixelsEventBody.id
		self.name = webPixelsEventBody.name
		self.timestamp = webPixelsEventBody.timestamp

		if let dataDict = webPixelsEventBody.data {
			self.data = PixelEventsCheckoutAddressInfoSubmittedData(from: dataDict)
		} else {
			self.data = nil
		}
	}
}

// MARK: - PixelEventsCheckoutAddressInfoSubmittedData
// swiftlint:disable type_name
public struct PixelEventsCheckoutAddressInfoSubmittedData: Codable {
	public let checkout: Checkout?
}
// swiftlint:enable type_name

// MARK: PixelEventsCheckoutAddressInfoSubmittedData convenience initializers and mutators

extension PixelEventsCheckoutAddressInfoSubmittedData {
	init?(from dictionary: [String: Any]) {
		guard let jsonData = try? JSONSerialization.data(withJSONObject: dictionary, options: []),
			let pixelData = try? JSONDecoder().decode(PixelEventsCheckoutAddressInfoSubmittedData.self, from: jsonData) else {
				return nil
			}
		self = pixelData
	}
}

// MARK: - Checkout

/// A container for all the information required to add items to checkout and
/// pay.
public struct Checkout: Codable {
	/// A list of attributes accumulated throughout the checkout process.
	public let attributes: [Attribute]?
	/// The billing address to where the order will be charged.
	public let billingAddress: MailingAddress?
	/// The three-letter code that represents the currency, for example, USD.
	/// Supported codes include standard ISO 4217 codes, legacy codes, and non-
	/// standard codes.
	public let currencyCode: String?
	/// A list of discount applications.
	public let discountApplications: [DiscountApplication]?
	/// The email attached to this checkout.
	public let email: String?
	/// A list of line item objects, each one containing information about an item
	/// in the checkout.
	public let lineItems: [CheckoutLineItem]?
	/// The resulting order from a paid checkout.
	public let order: Order?
	/// A unique phone number for the customer. Formatted using E.164 standard. For
	/// example, *+16135551111*.
	public let phone: String?
	/// The shipping address to where the line items will be shipped.
	public let shippingAddress: MailingAddress?
	/// Once a shipping rate is selected by the customer it is transitioned to a
	/// `shipping_line` object.
	public let shippingLine: ShippingRate?
	/// The price at checkout before duties, shipping, and taxes.
	public let subtotalPrice: MoneyV2?
	/// A unique identifier for a particular checkout.
	public let token: String?
	/// The sum of all the prices of all the items in the checkout, including
	/// duties, taxes, and discounts.
	public let totalPrice: MoneyV2?
	/// The sum of all the taxes applied to the line items and shipping lines in
	/// the checkout.
	public let totalTax: MoneyV2?
	/// A list of transactions associated with a checkout or order.
	public let transactions: [Transaction]?
}

// MARK: - Attribute

/// Custom attributes left by the customer to the merchant, either in their cart
/// or during checkout.
public struct Attribute: Codable {
	/// The key for the attribute.
	public let key: String?
	/// The value for the attribute.
	public let value: String?
}

// MARK: - MailingAddress

/// A mailing address for customers and shipping.
public struct MailingAddress: Codable {
	/// The first line of the address. This is usually the street address or a P.O.
	/// Box number.
	public let address1: String?
	/// The second line of the address. This is usually an apartment, suite, or
	/// unit number.
	public let address2: String?
	/// The name of the city, district, village, or town.
	public let city: String?
	/// The name of the country.
	public let country: String?
	/// The two-letter code that represents the country, for example, US.
	/// The country codes generally follows ISO 3166-1 alpha-2 guidelines.
	public let countryCode: String?
	/// The customer’s first name.
	public let firstName: String?
	/// The customer’s last name.
	public let lastName: String?
	/// The phone number for this mailing address as entered by the customer.
	public let phone: String?
	/// The region of the address, such as the province, state, or district.
	public let province: String?
	/// The two-letter code for the region.
	/// For example, ON.
	public let provinceCode: String?
	/// The ZIP or postal code of the address.
	public let zip: String?
}

// MARK: - DiscountApplication

/// The information about the intent of the discount.
public struct DiscountApplication: Codable {
	/// The method by which the discount's value is applied to its entitled items.
	///
	/// - `ACROSS`: The value is spread across all entitled lines.
	/// - `EACH`: The value is applied onto every entitled line.
	public let allocationMethod: String?
	/// How the discount amount is distributed on the discounted lines.
	///
	/// - `ALL`: The discount is allocated onto all the lines.
	/// - `ENTITLED`: The discount is allocated onto only the lines that it's
	/// entitled for.
	/// - `EXPLICIT`: The discount is allocated onto explicitly chosen lines.
	public let targetSelection: String?
	/// The type of line (i.e. line item or shipping line) on an order that the
	/// discount is applicable towards.
	///
	/// - `LINE_ITEM`: The discount applies onto line items.
	/// - `SHIPPING_LINE`: The discount applies onto shipping lines.
	public let targetType: String?
	/// The customer-facing name of the discount. If the type of discount is
	/// a `DISCOUNT_CODE`, this `title` attribute represents the code of the
	/// discount.
	public let title: String?
	/// The type of the discount.
	///
	/// - `AUTOMATIC`: A discount automatically at checkout or in the cart without
	/// the need for a code.
	/// - `DISCOUNT_CODE`: A discount applied onto checkouts through the use of
	/// a code.
	/// - `MANUAL`: A discount that is applied to an order by a merchant or store
	/// owner manually, rather than being automatically applied by the system or
	/// through a script.
	/// - `SCRIPT`: A discount applied to a customer's order using a script
	public let type: String?
	/// The value of the discount. Fixed discounts return a `Money` Object, while
	/// Percentage discounts return a `PricingPercentageValue` object.
	public let value: Value?
}

// MARK: - Value

/// The value of the discount. Fixed discounts return a `Money` Object, while
/// Percentage discounts return a `PricingPercentageValue` object.
///
/// The total amount for the customer to pay.
///
/// A monetary value with currency.
///
/// The total cost of the merchandise line.
///
/// The product variant’s price.
///
/// The monetary value with currency allocated to the discount.
///
/// Price of this shipping rate.
///
/// The price at checkout before duties, shipping, and taxes.
///
/// The sum of all the prices of all the items in the checkout, including
/// duties, taxes, and discounts.
///
/// The sum of all the taxes applied to the line items and shipping lines in
/// the checkout.
///
/// The monetary value with currency allocated to the transaction method.
///
/// A value given to a customer when a discount is applied to an order. The
/// application of a discount with this value gives the customer the specified
/// percentage off a specified item.
public struct Value: Codable {
	/// The decimal money amount.
	public let amount: Double?
	/// The three-letter code that represents the currency, for example, USD.
	/// Supported codes include standard ISO 4217 codes, legacy codes, and non-
	/// standard codes.
	public let currencyCode: String?
	/// The percentage value of the object.
	public let percentage: Double?
}

// MARK: - CheckoutLineItem

/// A single line item in the checkout, grouped by variant and attributes.
public struct CheckoutLineItem: Codable {
	/// The discounts that have been applied to the checkout line item by a
	/// discount application.
	public let discountAllocations: [DiscountAllocation]?
	/// A globally unique identifier.
	public let id: String?
	/// The quantity of the line item.
	public let quantity: Double?
	/// The title of the line item. Defaults to the product's title.
	public let title: String?
	/// Product variant of the line item.
	public let variant: ProductVariant?
}

// MARK: - DiscountAllocation

/// The discount that has been applied to the checkout line item.
public struct DiscountAllocation: Codable {
	/// The monetary value with currency allocated to the discount.
	public let amount: MoneyV2?
	/// The information about the intent of the discount.
	public let discountApplication: DiscountApplication?
}

// MARK: - Order

/// An order is a customer’s completed request to purchase one or more products
/// from a shop. An order is created when a customer completes the checkout
/// process.
public struct Order: Codable {
	/// The ID of the order.
	public let id: String?
}

// MARK: - ShippingRate

/// A shipping rate to be applied to a checkout.
public struct ShippingRate: Codable {
	/// Price of this shipping rate.
	public let price: MoneyV2?
}

// MARK: - Transaction

/// A transaction associated with a checkout or order.
public struct Transaction: Codable {
	/// The monetary value with currency allocated to the transaction method.
	public let amount: MoneyV2?
	/// The name of the payment provider used for the transaction.
	public let gateway: String?
}

// MARK: PixelEventsCheckoutCompleted convenience initializers and mutators

extension PixelEventsCheckoutCompleted {
	init(from webPixelsEventBody: WebPixelsEventBody) {
		self.context = webPixelsEventBody.context
		self.id = webPixelsEventBody.id
		self.name = webPixelsEventBody.name
		self.timestamp = webPixelsEventBody.timestamp

		if let dataDict = webPixelsEventBody.data {
			self.data = PixelEventsCheckoutCompletedData(from: dataDict)
		} else {
			self.data = nil
		}
	}
}

// MARK: - PixelEventsCheckoutCompletedData
public struct PixelEventsCheckoutCompletedData: Codable {
	public let checkout: Checkout?
}

// MARK: PixelEventsCheckoutCompletedData convenience initializers and mutators

extension PixelEventsCheckoutCompletedData {
	init?(from dictionary: [String: Any]) {
		guard let jsonData = try? JSONSerialization.data(withJSONObject: dictionary, options: []),
			let pixelData = try? JSONDecoder().decode(PixelEventsCheckoutCompletedData.self, from: jsonData) else {
				return nil
			}
		self = pixelData
	}
}

// MARK: PixelEventsCheckoutContactInfoSubmitted convenience initializers and mutators

extension PixelEventsCheckoutContactInfoSubmitted {
	init(from webPixelsEventBody: WebPixelsEventBody) {
		self.context = webPixelsEventBody.context
		self.id = webPixelsEventBody.id
		self.name = webPixelsEventBody.name
		self.timestamp = webPixelsEventBody.timestamp

		if let dataDict = webPixelsEventBody.data {
			self.data = PixelEventsCheckoutContactInfoSubmittedData(from: dataDict)
		} else {
			self.data = nil
		}
	}
}

// MARK: - PixelEventsCheckoutContactInfoSubmittedData

// swiftlint:disable type_name
public struct PixelEventsCheckoutContactInfoSubmittedData: Codable {
	public let checkout: Checkout?
}
// swiftlint:enable type_name

// MARK: PixelEventsCheckoutContactInfoSubmittedData convenience initializers and mutators

extension PixelEventsCheckoutContactInfoSubmittedData {
	init?(from dictionary: [String: Any]) {
		guard let jsonData = try? JSONSerialization.data(withJSONObject: dictionary, options: []),
			let pixelData = try? JSONDecoder().decode(PixelEventsCheckoutContactInfoSubmittedData.self, from: jsonData) else {
				return nil
			}
		self = pixelData
	}
}

// MARK: PixelEventsCheckoutShippingInfoSubmitted convenience initializers and mutators

extension PixelEventsCheckoutShippingInfoSubmitted {
	init(from webPixelsEventBody: WebPixelsEventBody) {
		self.context = webPixelsEventBody.context
		self.id = webPixelsEventBody.id
		self.name = webPixelsEventBody.name
		self.timestamp = webPixelsEventBody.timestamp

		if let dataDict = webPixelsEventBody.data {
			self.data = PixelEventsCheckoutShippingInfoSubmittedData(from: dataDict)
		} else {
			self.data = nil
		}
	}
}

// MARK: - PixelEventsCheckoutShippingInfoSubmittedData
// swiftlint:disable type_name
public struct PixelEventsCheckoutShippingInfoSubmittedData: Codable {
	public let checkout: Checkout?
}
// swiftlint:enable type_name

// MARK: PixelEventsCheckoutShippingInfoSubmittedData convenience initializers and mutators

extension PixelEventsCheckoutShippingInfoSubmittedData {
	init?(from dictionary: [String: Any]) {
		guard let jsonData = try? JSONSerialization.data(withJSONObject: dictionary, options: []),
			let pixelData = try? JSONDecoder().decode(PixelEventsCheckoutShippingInfoSubmittedData.self, from: jsonData) else {
				return nil
			}
		self = pixelData
	}
}

// MARK: PixelEventsCheckoutStarted convenience initializers and mutators

extension PixelEventsCheckoutStarted {
	init(from webPixelsEventBody: WebPixelsEventBody) {
		self.context = webPixelsEventBody.context
		self.id = webPixelsEventBody.id
		self.name = webPixelsEventBody.name
		self.timestamp = webPixelsEventBody.timestamp

		if let dataDict = webPixelsEventBody.data {
			self.data = PixelEventsCheckoutStartedData(from: dataDict)
		} else {
			self.data = nil
		}
	}
}

// MARK: - PixelEventsCheckoutStartedData
public struct PixelEventsCheckoutStartedData: Codable {
	public let checkout: Checkout?
}

// MARK: PixelEventsCheckoutStartedData convenience initializers and mutators

extension PixelEventsCheckoutStartedData {
	init?(from dictionary: [String: Any]) {
		guard let jsonData = try? JSONSerialization.data(withJSONObject: dictionary, options: []),
			let pixelData = try? JSONDecoder().decode(PixelEventsCheckoutStartedData.self, from: jsonData) else {
				return nil
			}
		self = pixelData
	}
}

// MARK: PixelEventsPageViewed convenience initializers and mutators

extension PixelEventsPageViewed {
	init(from webPixelsEventBody: WebPixelsEventBody) {
		self.context = webPixelsEventBody.context
		self.id = webPixelsEventBody.id
		self.name = webPixelsEventBody.name
		self.timestamp = webPixelsEventBody.timestamp

		if let dataDict = webPixelsEventBody.data {
			self.data = PixelEventsPageViewedData(from: dataDict)
		} else {
			self.data = nil
		}
	}
}

// MARK: - PixelEventsPageViewedData
public struct PixelEventsPageViewedData: Codable {
}

// MARK: PixelEventsPageViewedData convenience initializers and mutators

extension PixelEventsPageViewedData {
	init?(from dictionary: [String: Any]) {
		guard let jsonData = try? JSONSerialization.data(withJSONObject: dictionary, options: []),
			let pixelData = try? JSONDecoder().decode(PixelEventsPageViewedData.self, from: jsonData) else {
				return nil
			}
		self = pixelData
	}
}

// MARK: PixelEventsPaymentInfoSubmitted convenience initializers and mutators

extension PixelEventsPaymentInfoSubmitted {
	init(from webPixelsEventBody: WebPixelsEventBody) {
		self.context = webPixelsEventBody.context
		self.id = webPixelsEventBody.id
		self.name = webPixelsEventBody.name
		self.timestamp = webPixelsEventBody.timestamp

		if let dataDict = webPixelsEventBody.data {
			self.data = PixelEventsPaymentInfoSubmittedData(from: dataDict)
		} else {
			self.data = nil
		}
	}
}

// MARK: - PixelEventsPaymentInfoSubmittedData
public struct PixelEventsPaymentInfoSubmittedData: Codable {
	public let checkout: Checkout?
}

// MARK: PixelEventsPaymentInfoSubmittedData convenience initializers and mutators

extension PixelEventsPaymentInfoSubmittedData {
	init?(from dictionary: [String: Any]) {
		guard let jsonData = try? JSONSerialization.data(withJSONObject: dictionary, options: []),
			let pixelData = try? JSONDecoder().decode(PixelEventsPaymentInfoSubmittedData.self, from: jsonData) else {
				return nil
			}
		self = pixelData
	}
}

// MARK: CustomEvent convenience initializers and mutators

extension CustomEvent {
	init(from webPixelsEventBody: WebPixelsEventBody) {
		self.context = webPixelsEventBody.context
		self.customData = webPixelsEventBody.customData
		self.id = webPixelsEventBody.id
		self.name = webPixelsEventBody.name
		self.timestamp = webPixelsEventBody.timestamp
	}
}

// MARK: - CustomData

/// A free-form object representing data specific to a custom event provided by
/// the custom event publisher
public struct CustomData: Codable {
}

// MARK: - PricingPercentageValue

/// A value given to a customer when a discount is applied to an order. The
/// application of a discount with this value gives the customer the specified
/// percentage off a specified item.
public struct PricingPercentageValue: Codable {
	/// The percentage value of the object.
	let percentage: Double?
}

// swiftlint:disable type_name
typealias ID = String
// swiftlint:enable type_name

typealias Name = String
typealias Timestamp = String

// MARK: - Helper functions for creating encoders and decoders

func newJSONDecoder() -> JSONDecoder {
	let decoder = JSONDecoder()
	if #available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *) {
		decoder.dateDecodingStrategy = .iso8601
	}
	return decoder
}

func newJSONEncoder() -> JSONEncoder {
	let encoder = JSONEncoder()
	if #available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *) {
		encoder.dateEncodingStrategy = .iso8601
	}
	return encoder
}

// swiftlint:enable file_length
