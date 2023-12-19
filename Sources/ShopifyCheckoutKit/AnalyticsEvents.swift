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
struct CheckoutAddressInfoSubmittedData {
    var checkout: Checkout?
}

struct CheckoutCompletedData {
    var checkout: Checkout?
}

struct CheckoutContactInfoSubmittedData {
    var checkout: Checkout?
}

struct CheckoutShippingInfoSubmittedData {
    var checkout: Checkout?
}

struct CheckoutStartedData {
    var checkout: Checkout?
}

struct Collection {
    var id: String?
    var productVariants: [ProductVariant]?
    var title: String?
}

struct CollectionViewedData {
    var collection: Collection?
}

struct PageViewedData {}

struct PaymentInfoSubmittedData {
    var checkout: Checkout?
}

struct ProductAddedToCartData {
    var cartLine: CartLine?
}

struct ProductRemovedFromCartData {
    var cartLine: CartLine?
}

struct ProductVariantViewedData {
    var productVariant: ProductVariant?
}

struct ProductViewedData {
    var productVariant: ProductVariant?
}

struct SearchResult {
    var productVariants: [ProductVariant]?
    var query: String?
}

struct SearchSubmittedData {
    var searchResult: SearchResult?
}

public struct CartViewed {
    var clientId: ClientId?
    var context: Context?
    var data: CartViewedData?
    var id: Identifier?
    var name: String?
    var timestamp: Timestamp?
}

public struct CheckoutAddressInfoSubmitted {
    var clientId: ClientId?
    var context: Context?
    var data: CheckoutAddressInfoSubmittedData?
    var id: Identifier?
    var name: String?
    var timestamp: Timestamp?
}

public struct CheckoutCompleted {
    var clientId: ClientId?
    var context: Context?
    var data: CheckoutCompletedData?
    var id: Identifier?
    var name: String?
    var timestamp: Timestamp?
}

public struct CheckoutContactInfoSubmitted {
    var clientId: ClientId?
    var context: Context?
    var data: CheckoutContactInfoSubmittedData?
    var id: Identifier?
    var name: String?
    var timestamp: Timestamp?
}

public struct CheckoutShippingInfoSubmitted {
    var clientId: ClientId?
    var context: Context?
    var data: CheckoutShippingInfoSubmittedData?
    var id: Identifier?
    var name: String?
    var timestamp: Timestamp?
}

public struct CheckoutStarted {
    var clientId: ClientId?
    var context: Context?
    var data: CheckoutStartedData?
    var id: Identifier?
    var name: String?
    var timestamp: Timestamp?
}

public struct CollectionViewed {
    var clientId: ClientId?
    var context: Context?
    var data: CollectionViewedData?
    var id: Identifier?
    var name: String?
    var timestamp: Timestamp?
}

public struct PageViewed {
    var clientId: ClientId?
    var context: Context?
    var data: PageViewedData?
    var id: Identifier?
    var name: String?
    var timestamp: Timestamp?
}

public struct PaymentInfoSubmitted {
    var clientId: ClientId?
    var context: Context?
    var data: PaymentInfoSubmittedData?
    var id: Identifier?
    var name: String?
    var timestamp: Timestamp?
}

public struct ProductAddedToCart {
    var clientId: ClientId?
    var context: Context?
    var data: ProductAddedToCartData?
    var id: Identifier?
    var name: String?
    var timestamp: Timestamp?
}

public struct ProductRemovedFromCart {
    var clientId: ClientId?
    var context: Context?
    var data: ProductRemovedFromCartData?
    var id: Identifier?
    var name: String?
    var timestamp: Timestamp?
}

public struct ProductVariantViewed {
    var clientId: ClientId?
    var context: Context?
    var data: ProductVariantViewedData?
    var id: Identifier?
    var name: String?
    var timestamp: Timestamp?
}

public struct ProductViewed {
    var clientId: ClientId?
    var context: Context?
    var data: ProductViewedData?
    var id: Identifier?
    var name: String?
    var timestamp: Timestamp?
}

public struct SearchSubmitted {
    var clientId: ClientId?
    var context: Context?
    var data: SearchSubmittedData?
    var id: Identifier?
    var name: String?
    var timestamp: Timestamp?
}

public struct PixelEvents {
    var cartViewed: CartViewed
    var checkoutAddressInfoSubmitted: CheckoutAddressInfoSubmitted
    var checkoutCompleted: CheckoutCompleted
    var checkoutContactInfoSubmitted: CheckoutContactInfoSubmitted
    var checkoutShippingInfoSubmitted: CheckoutShippingInfoSubmitted
    var checkoutStarted: CheckoutStarted
    var collectionViewed: CollectionViewed
    var pageViewed: PageViewed
    var paymentInfoSubmitted: PaymentInfoSubmitted
    var productAddedToCart: ProductAddedToCart
    var productRemovedFromCart: ProductRemovedFromCart
    var productVariantViewed: ProductVariantViewed
    var productViewed: ProductViewed
    var searchSubmitted: SearchSubmitted
}

public typealias CustomEvents: [String: CustomEvent]
