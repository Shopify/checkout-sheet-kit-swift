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

typealias ClientId = String?
typealias Identifier = String?
typealias Timestamp = String?

struct Location {
    var hash: String?
    var host: String?
    var hostname: String?
    var href: String?
    var origin: String?
    var pathname: String?
    var port: String?
    var `protocol`: String?
    var search: String?
}

struct WebPixelsDocument {
    var characterSet: String?
    var location: Location?
    var referrer: String?
    var title: String?
}

struct WebPixelsNavigator {
    var cookieEnabled: Bool?
    var language: String?
    var languages: [String]?
    var userAgent: String?
}

struct Screen {
    var height: Int?
    var width: Int?
}

struct WebPixelsWindow {
    var innerHeight: Int?
    var innerWidth: Int?
    var location: Location?
    var origin: String?
    var outerHeight: Int?
    var outerWidth: Int?
    var pageXOffset: Int?
    var pageYOffset: Int?
    var screen: Screen?
    var screenX: Int?
    var screenY: Int?
    var scrollX: Int?
    var scrollY: Int?
}

struct Context {
    var document: WebPixelsDocument?
    var navigator: WebPixelsNavigator?
    var window: WebPixelsWindow?
}

struct MoneyV2 {
    var amount: Double?
    var currencyCode: String?
}

struct CartCost {
    var totalAmount: MoneyV2?
}

struct CartLineCost {
    var totalAmount: MoneyV2?
}

struct Image {
    var src: String?
}

struct Product {
    var id: String?
    var title: String?
    var type: String?
    var untranslatedTitle: String?
    var url: String?
    var vendor: String?
}

struct ProductVariant {
    var id: String?
    var image: Image?
    var price: MoneyV2?
    var product: Product?
    var sku: String?
    var title: String?
    var untranslatedTitle: String?
}

struct CartLine {
    var cost: CartLineCost?
    var merchandise: ProductVariant?
    var quantity: Int?
}

struct Cart {
    var cost: CartCost?
    var id: String?
    var lines: [CartLine]?
    var totalQuantity: Int?
}

struct CartViewedData {
    var cart: Cart?
}

struct Attribute {
    var key: String?
    var value: String?
}

struct MailingAddress {
    var address1: String?
    var address2: String?
    var city: String?
    var country: String?
    var countryCode: String?
    var firstName: String?
    var lastName: String?
    var phone: String?
    var province: String?
    var provinceCode: String?
    var zip: String?
}

struct PricingPercentageValue {
    var percentage: Double?
}

struct DiscountApplication {
    var allocationMethod: String?
    var targetSelection: String?
    var targetType: String?
    var title: String?
    var type: String?
    var value: DiscountValue?
}

enum DiscountValue {
    case money(MoneyV2?)
    case percentage(PricingPercentageValue?)
}

struct DiscountAllocation {
    var amount: MoneyV2?
    var discountApplication: DiscountApplication?
}

struct CheckoutLineItem {
    var discountAllocations: [DiscountAllocation]?
    var id: String?
    var quantity: Int?
    var title: String?
    var variant: ProductVariant?
}

struct Order {
    var id: String?
}

struct ShippingRate {
    var price: MoneyV2?
}

struct Transaction {
    var amount: MoneyV2?
    var gateway: String?
}

struct Checkout {
    var attributes: [Attribute]?
    var billingAddress: MailingAddress?
    var currencyCode: String?
    var discountApplications: [DiscountApplication]?
    var email: String?
    var lineItems: [CheckoutLineItem]?
    var order: Order?
    var phone: String?
    var shippingAddress: MailingAddress?
    var shippingLine: ShippingRate?
    var subtotalPrice: MoneyV2?
    var token: String?
    var totalPrice: MoneyV2?
    var totalTax: MoneyV2?
    var transactions: [Transaction]?
}
