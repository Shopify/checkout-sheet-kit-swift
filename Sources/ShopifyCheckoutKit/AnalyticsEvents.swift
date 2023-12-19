typealias ClientId = String

typealias Id = String

typealias Timestamp = String

struct Location {
    var hash: String
    var host: String
    var hostname: String
    var href: String
    var origin: String
    var pathname: String
    var port: String
    var `protocol`: String
    var search: String
}

struct WebPixelsDocument {
    var characterSet: String
    var location: Location
    var referrer: String
    var title: String
}

struct WebPixelsNavigator {
    var cookieEnabled: Bool
    var language: String
    var languages: [String]
    var userAgent: String
}

struct Screen {
    var height: Int
    var width: Int
}

struct WebPixelsWindow {
    var innerHeight: Int
    var innerWidth: Int
    var location: Location
    var origin: String
    var outerHeight: Int
    var outerWidth: Int
    var pageXOffset: Int
    var pageYOffset: Int
    var screen: Screen
    var screenX: Int
    var screenY: Int
    var scrollX: Int
    var scrollY: Int
}

struct Context {
    var document: WebPixelsDocument
    var navigator: WebPixelsNavigator
    var window: WebPixelsWindow
}

struct MoneyV2 {
    var amount: Double
    var currencyCode: String
}

struct CartCost {
    var totalAmount: MoneyV2
}

struct CartLineCost {
    var totalAmount: MoneyV2
}

struct Image {
    var src: String
}

struct Product {
    var id: String
    var title: String
    var type: String?
    var untranslatedTitle: String
    var url: String
    var vendor: String
}

struct ProductVariant {
    var id: String
    var image: Image?
    var price: MoneyV2
    var product: Product
    var sku: String?
    var title: String
    var untranslatedTitle: String
}

struct CartLine {
    var cost: CartLineCost
    var merchandise: ProductVariant
    var quantity: Int
}

struct Cart {
    var cost: CartCost
    var id: String
    var lines: [CartLine]
    var totalQuantity: Int
}

struct PixelEventsCartViewedData {
    var cart: Cart?
}

public struct PixelEventsCartViewed {
    var clientId: ClientId
    var context: Context
    var data: PixelEventsCartViewedData
    var id: Id
    var name: String
    var timestamp: Timestamp
}
