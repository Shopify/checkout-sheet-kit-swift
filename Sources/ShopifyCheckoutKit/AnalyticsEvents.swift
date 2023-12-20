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

// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let pixelEventsCartViewedData = try PixelEventsCartViewedData(json)
//   let pixelEventsCartViewed = try PixelEventsCartViewed(json)
//   let pixelEventsCheckoutAddressInfoSubmittedData = try PixelEventsCheckoutAddressInfoSubmittedData(json)
//   let pixelEventsCheckoutAddressInfoSubmitted = try PixelEventsCheckoutAddressInfoSubmitted(json)
//   let pixelEventsCheckoutCompletedData = try PixelEventsCheckoutCompletedData(json)
//   let pixelEventsCheckoutCompleted = try PixelEventsCheckoutCompleted(json)
//   let pixelEventsCheckoutContactInfoSubmittedData = try PixelEventsCheckoutContactInfoSubmittedData(json)
//   let pixelEventsCheckoutContactInfoSubmitted = try PixelEventsCheckoutContactInfoSubmitted(json)
//   let pixelEventsCheckoutShippingInfoSubmittedData = try PixelEventsCheckoutShippingInfoSubmittedData(json)
//   let pixelEventsCheckoutShippingInfoSubmitted = try PixelEventsCheckoutShippingInfoSubmitted(json)
//   let pixelEventsCheckoutStartedData = try PixelEventsCheckoutStartedData(json)
//   let pixelEventsCheckoutStarted = try PixelEventsCheckoutStarted(json)
//   let pixelEventsCollectionViewedData = try PixelEventsCollectionViewedData(json)
//   let pixelEventsCollectionViewed = try PixelEventsCollectionViewed(json)
//   let pixelEventsPageViewedData = try PixelEventsPageViewedData(json)
//   let pixelEventsPageViewed = try PixelEventsPageViewed(json)
//   let pixelEventsPaymentInfoSubmittedData = try PixelEventsPaymentInfoSubmittedData(json)
//   let pixelEventsPaymentInfoSubmitted = try PixelEventsPaymentInfoSubmitted(json)
//   let pixelEventsProductAddedToCartData = try PixelEventsProductAddedToCartData(json)
//   let pixelEventsProductAddedToCart = try PixelEventsProductAddedToCart(json)
//   let pixelEventsProductRemovedFromCartData = try PixelEventsProductRemovedFromCartData(json)
//   let pixelEventsProductRemovedFromCart = try PixelEventsProductRemovedFromCart(json)
//   let pixelEventsProductVariantViewedData = try PixelEventsProductVariantViewedData(json)
//   let pixelEventsProductVariantViewed = try PixelEventsProductVariantViewed(json)
//   let pixelEventsProductViewedData = try PixelEventsProductViewedData(json)
//   let pixelEventsProductViewed = try PixelEventsProductViewed(json)
//   let pixelEventsSearchSubmittedData = try PixelEventsSearchSubmittedData(json)
//   let pixelEventsSearchSubmitted = try PixelEventsSearchSubmitted(json)
//   let pixelEvents = try PixelEvents(json)
//   let attribute = try Attribute(json)
//   let browserCookie = try BrowserCookie(json)
//   let browserLocalStorage = try BrowserLocalStorage(json)
//   let browserSessionStorage = try BrowserSessionStorage(json)
//   let browser = try Browser(json)
//   let cart = try Cart(json)
//   let cartCost = try CartCost(json)
//   let cartLine = try CartLine(json)
//   let cartLineCost = try CartLineCost(json)
//   let checkout = try Checkout(json)
//   let checkoutLineItem = try CheckoutLineItem(json)
//   let clientID = try ClientID(json)
//   let collection = try Collection(json)
//   let context = try Context(json)
//   let customData = try CustomData(json)
//   let customEvent = try CustomEvent(json)
//   let customer = try Customer(json)
//   let purpleData = try PurpleData(json)
//   let discountAllocation = try DiscountAllocation(json)
//   let discountApplication = try DiscountApplication(json)
//   let iD = try ID(json)
//   let image = try Image(json)
//   let initData = try InitData(json)
//   let location = try Location(json)
//   let mailingAddress = try MailingAddress(json)
//   let moneyV2 = try MoneyV2(json)
//   let name = try Name(json)
//   let order = try Order(json)
//   let pricingPercentageValue = try PricingPercentageValue(json)
//   let product = try Product(json)
//   let productVariant = try ProductVariant(json)
//   let screen = try Screen(json)
//   let searchResult = try SearchResult(json)
//   let shippingRate = try ShippingRate(json)
//   let timestamp = try Timestamp(json)
//   let transaction = try Transaction(json)
//   let webPixelsDocument = try WebPixelsDocument(json)
//   let webPixelsNavigator = try WebPixelsNavigator(json)
//   let webPixelsWindow = try WebPixelsWindow(json)

import Foundation

// MARK: - PixelEvents
struct PixelEvents: Codable {
    /// The `cart_viewed` event logs an instance where a customer visited the cart
    /// page
    let cartViewed: PixelEventsCartViewed?
    /// The `checkout_address_info_submitted` event logs an instance of a customer
    /// submitting their mailing address. This event is only available in checkouts
    /// where checkout extensibility for customizations is enabled
    let checkoutAddressInfoSubmitted: PixelEventsCheckoutAddressInfoSubmitted?
    /// The `checkout_completed` event logs when a visitor completes a purchase.
    /// This event is available on the order status and checkout pages
    let checkoutCompleted: PixelEventsCheckoutCompleted?
    /// The `checkout_contact_info_submitted` event logs an instance where a
    /// customer submits a checkout form. This event is only available in checkouts
    /// where checkout extensibility for customizations is enabled
    let checkoutContactInfoSubmitted: PixelEventsCheckoutContactInfoSubmitted?
    /// The `checkout_shipping_info_submitted` event logs an instance where the
    /// customer chooses a shipping rate. This event is only available in checkouts
    /// where checkout extensibility for customizations is enabled
    let checkoutShippingInfoSubmitted: PixelEventsCheckoutShippingInfoSubmitted?
    /// The `checkout_started` event logs an instance of a customer starting
    /// the checkout process. This event is available on the checkout page. For
    /// checkout extensibility, this event is triggered every time a customer
    /// enters checkout. For non-checkout extensible shops, this event is only
    /// triggered the first time a customer enters checkout.
    let checkoutStarted: PixelEventsCheckoutStarted?
    /// The `collection_viewed` event logs an instance where a customer visited a
    /// product collection index page. This event is available on the online store
    /// page
    let collectionViewed: PixelEventsCollectionViewed?
    /// The `page_viewed` event logs an instance where a customer visited a page.
    /// This event is available on the online store, checkout, and order status
    /// pages
    let pageViewed: PixelEventsPageViewed?
    /// The `payment_info_submitted` event logs an instance of a customer
    /// submitting their payment information. This event is available on the
    /// checkout page
    let paymentInfoSubmitted: PixelEventsPaymentInfoSubmitted?
    /// The `product_added_to_cart` event logs an instance where a customer adds a
    /// product to their cart. This event is available on the online store page
    let productAddedToCart: PixelEventsProductAddedToCart?
    /// The `product_removed_from_cart` event logs an instance where a customer
    /// removes a product from their cart. This event is available on the online
    /// store page
    let productRemovedFromCart: PixelEventsProductRemovedFromCart?
    /// The `product_variant_viewed` event logs an instance where a customer
    /// interacts with the product page and views a different variant than the
    /// initial `product_viewed` impression. This event is available on the Product
    /// page
    let productVariantViewed: PixelEventsProductVariantViewed?
    /// The `product_viewed` event logs an instance where a customer visited a
    /// product details page. This event is available on the product page
    let productViewed: PixelEventsProductViewed?
    /// The `search_submitted` event logs an instance where a customer performed a
    /// search on the storefront. This event is available on the online store page
    let searchSubmitted: PixelEventsSearchSubmitted?

    enum CodingKeys: String, CodingKey {
        case cartViewed = "cart_viewed"
        case checkoutAddressInfoSubmitted = "checkout_address_info_submitted"
        case checkoutCompleted = "checkout_completed"
        case checkoutContactInfoSubmitted = "checkout_contact_info_submitted"
        case checkoutShippingInfoSubmitted = "checkout_shipping_info_submitted"
        case checkoutStarted = "checkout_started"
        case collectionViewed = "collection_viewed"
        case pageViewed = "page_viewed"
        case paymentInfoSubmitted = "payment_info_submitted"
        case productAddedToCart = "product_added_to_cart"
        case productRemovedFromCart = "product_removed_from_cart"
        case productVariantViewed = "product_variant_viewed"
        case productViewed = "product_viewed"
        case searchSubmitted = "search_submitted"
    }
}

// MARK: PixelEvents convenience initializers and mutators

extension PixelEvents {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(PixelEvents.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        cartViewed: PixelEventsCartViewed?? = nil,
        checkoutAddressInfoSubmitted: PixelEventsCheckoutAddressInfoSubmitted?? = nil,
        checkoutCompleted: PixelEventsCheckoutCompleted?? = nil,
        checkoutContactInfoSubmitted: PixelEventsCheckoutContactInfoSubmitted?? = nil,
        checkoutShippingInfoSubmitted: PixelEventsCheckoutShippingInfoSubmitted?? = nil,
        checkoutStarted: PixelEventsCheckoutStarted?? = nil,
        collectionViewed: PixelEventsCollectionViewed?? = nil,
        pageViewed: PixelEventsPageViewed?? = nil,
        paymentInfoSubmitted: PixelEventsPaymentInfoSubmitted?? = nil,
        productAddedToCart: PixelEventsProductAddedToCart?? = nil,
        productRemovedFromCart: PixelEventsProductRemovedFromCart?? = nil,
        productVariantViewed: PixelEventsProductVariantViewed?? = nil,
        productViewed: PixelEventsProductViewed?? = nil,
        searchSubmitted: PixelEventsSearchSubmitted?? = nil
    ) -> PixelEvents {
        return PixelEvents(
            cartViewed: cartViewed ?? self.cartViewed,
            checkoutAddressInfoSubmitted: checkoutAddressInfoSubmitted ?? self.checkoutAddressInfoSubmitted,
            checkoutCompleted: checkoutCompleted ?? self.checkoutCompleted,
            checkoutContactInfoSubmitted: checkoutContactInfoSubmitted ?? self.checkoutContactInfoSubmitted,
            checkoutShippingInfoSubmitted: checkoutShippingInfoSubmitted ?? self.checkoutShippingInfoSubmitted,
            checkoutStarted: checkoutStarted ?? self.checkoutStarted,
            collectionViewed: collectionViewed ?? self.collectionViewed,
            pageViewed: pageViewed ?? self.pageViewed,
            paymentInfoSubmitted: paymentInfoSubmitted ?? self.paymentInfoSubmitted,
            productAddedToCart: productAddedToCart ?? self.productAddedToCart,
            productRemovedFromCart: productRemovedFromCart ?? self.productRemovedFromCart,
            productVariantViewed: productVariantViewed ?? self.productVariantViewed,
            productViewed: productViewed ?? self.productViewed,
            searchSubmitted: searchSubmitted ?? self.searchSubmitted
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

/// The `cart_viewed` event logs an instance where a customer visited the cart
/// page
// MARK: - PixelEventsCartViewed
struct PixelEventsCartViewed: Codable {
    /// The client-side ID of the customer, provided by Shopify
    let clientID: String?
    let context: Context?
    let data: PixelEventsCartViewedData?
    /// The ID of the customer event
    let id: String?
    /// The name of the customer event
    let name: PixelEventsCartViewedName?
    /// The timestamp of when the customer event occurred, in [ISO
    /// 8601](https://en.wikipedia.org/wiki/ISO_8601) format
    let timestamp: String?

    enum CodingKeys: String, CodingKey {
        case clientID = "clientId"
        case context, data, id, name, timestamp
    }
}

// MARK: PixelEventsCartViewed convenience initializers and mutators

extension PixelEventsCartViewed {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(PixelEventsCartViewed.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        clientID: String?? = nil,
        context: Context?? = nil,
        data: PixelEventsCartViewedData?? = nil,
        id: String?? = nil,
        name: PixelEventsCartViewedName?? = nil,
        timestamp: String?? = nil
    ) -> PixelEventsCartViewed {
        return PixelEventsCartViewed(
            clientID: clientID ?? self.clientID,
            context: context ?? self.context,
            data: data ?? self.data,
            id: id ?? self.id,
            name: name ?? self.name,
            timestamp: timestamp ?? self.timestamp
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

/// A snapshot of various read-only properties of the browser at the time of
/// event
// MARK: - Context
struct Context: Codable {
    /// Snapshot of a subset of properties of the `document` object in the top
    /// frame of the browser
    let document: WebPixelsDocument?
    /// Snapshot of a subset of properties of the `navigator` object in the top
    /// frame of the browser
    let navigator: WebPixelsNavigator?
    /// Snapshot of a subset of properties of the `window` object in the top frame
    /// of the browser
    let window: WebPixelsWindow?
}

// MARK: Context convenience initializers and mutators

extension Context {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(Context.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        document: WebPixelsDocument?? = nil,
        navigator: WebPixelsNavigator?? = nil,
        window: WebPixelsWindow?? = nil
    ) -> Context {
        return Context(
            document: document ?? self.document,
            navigator: navigator ?? self.navigator,
            window: window ?? self.window
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

/// Snapshot of a subset of properties of the `document` object in the top
/// frame of the browser
///
/// A snapshot of a subset of properties of the `document` object in the top
/// frame of the browser
// MARK: - WebPixelsDocument
struct WebPixelsDocument: Codable {
    /// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Document),
    /// returns the character set being used by the document
    let characterSet: String?
    /// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Document),
    /// returns the URI of the current document
    let location: Location?
    /// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Document),
    /// returns the URI of the page that linked to this page
    let referrer: String?
    /// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Document),
    /// returns the title of the current document
    let title: String?
}

// MARK: WebPixelsDocument convenience initializers and mutators

extension WebPixelsDocument {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(WebPixelsDocument.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        characterSet: String?? = nil,
        location: Location?? = nil,
        referrer: String?? = nil,
        title: String?? = nil
    ) -> WebPixelsDocument {
        return WebPixelsDocument(
            characterSet: characterSet ?? self.characterSet,
            location: location ?? self.location,
            referrer: referrer ?? self.referrer,
            title: title ?? self.title
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

/// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Document),
/// returns the URI of the current document
///
/// A snapshot of a subset of properties of the `location` object in the top
/// frame of the browser
///
/// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Window), the
/// location, or current URL, of the window object
// MARK: - Location
struct Location: Codable {
    /// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Location), a
    /// string containing a `'#'` followed by the fragment identifier of the URL
    let hash: String?
    /// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Location), a
    /// string containing the host, that is the hostname, a `':'`, and the port of
    /// the URL
    let host: String?
    /// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Location), a
    /// string containing the domain of the URL
    let hostname: String?
    /// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Location), a
    /// string containing the entire URL
    let href: String?
    /// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Location), a
    /// string containing the canonical form of the origin of the specific location
    let origin: String?
    /// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Location), a
    /// string containing an initial `'/'` followed by the path of the URL, not
    /// including the query string or fragment
    let pathname: String?
    /// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Location), a
    /// string containing the port number of the URL
    let port: String?
    /// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Location), a
    /// string containing the protocol scheme of the URL, including the final `':'`
    let locationProtocol: String?
    /// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Location), a
    /// string containing a `'?'` followed by the parameters or "querystring" of
    /// the URL
    let search: String?

    enum CodingKeys: String, CodingKey {
        case hash, host, hostname, href, origin, pathname, port
        case locationProtocol = "protocol"
        case search
    }
}

// MARK: Location convenience initializers and mutators

extension Location {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(Location.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        hash: String?? = nil,
        host: String?? = nil,
        hostname: String?? = nil,
        href: String?? = nil,
        origin: String?? = nil,
        pathname: String?? = nil,
        port: String?? = nil,
        locationProtocol: String?? = nil,
        search: String?? = nil
    ) -> Location {
        return Location(
            hash: hash ?? self.hash,
            host: host ?? self.host,
            hostname: hostname ?? self.hostname,
            href: href ?? self.href,
            origin: origin ?? self.origin,
            pathname: pathname ?? self.pathname,
            port: port ?? self.port,
            locationProtocol: locationProtocol ?? self.locationProtocol,
            search: search ?? self.search
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

/// Snapshot of a subset of properties of the `navigator` object in the top
/// frame of the browser
///
/// A snapshot of a subset of properties of the `navigator` object in the top
/// frame of the browser
// MARK: - WebPixelsNavigator
struct WebPixelsNavigator: Codable {
    /// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Navigator),
    /// returns `false` if setting a cookie will be ignored and true otherwise
    let cookieEnabled: Bool?
    /// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Navigator),
    /// returns a string representing the preferred language of the user, usually
    /// the language of the browser UI. The `null` value is returned when this
    /// is unknown
    let language: String?
    /// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Navigator),
    /// returns an array of strings representing the languages known to the user,
    /// by order of preference
    let languages: [String]?
    /// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Navigator),
    /// returns the user agent string for the current browser
    let userAgent: String?
}

// MARK: WebPixelsNavigator convenience initializers and mutators

extension WebPixelsNavigator {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(WebPixelsNavigator.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        cookieEnabled: Bool?? = nil,
        language: String?? = nil,
        languages: [String]?? = nil,
        userAgent: String?? = nil
    ) -> WebPixelsNavigator {
        return WebPixelsNavigator(
            cookieEnabled: cookieEnabled ?? self.cookieEnabled,
            language: language ?? self.language,
            languages: languages ?? self.languages,
            userAgent: userAgent ?? self.userAgent
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

/// Snapshot of a subset of properties of the `window` object in the top frame
/// of the browser
///
/// A snapshot of a subset of properties of the `window` object in the top frame
/// of the browser
// MARK: - WebPixelsWindow
struct WebPixelsWindow: Codable {
    /// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Window),
    /// gets the height of the content area of the browser window including, if
    /// rendered, the horizontal scrollbar
    let innerHeight: Double?
    /// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Window), gets
    /// the width of the content area of the browser window including, if rendered,
    /// the vertical scrollbar
    let innerWidth: Double?
    /// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Window), the
    /// location, or current URL, of the window object
    let location: Location?
    /// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Window), the
    /// global object's origin, serialized as a string
    let origin: String?
    /// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Window), gets
    /// the height of the outside of the browser window
    let outerHeight: Double?
    /// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Window), gets
    /// the width of the outside of the browser window
    let outerWidth: Double?
    /// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Window), an
    /// alias for window.scrollX
    let pageXOffset: Double?
    /// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Window), an
    /// alias for window.scrollY
    let pageYOffset: Double?
    /// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Screen), the
    /// interface representing a screen, usually the one on which the current
    /// window is being rendered
    let screen: Screen?
    /// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Window), the
    /// horizontal distance from the left border of the user's browser viewport to
    /// the left side of the screen
    let screenX: Double?
    /// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Window), the
    /// vertical distance from the top border of the user's browser viewport to the
    /// top side of the screen
    let screenY: Double?
    /// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Window), the
    /// number of pixels that the document has already been scrolled horizontally
    let scrollX: Double?
    /// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Window), the
    /// number of pixels that the document has already been scrolled vertically
    let scrollY: Double?
}

// MARK: WebPixelsWindow convenience initializers and mutators

extension WebPixelsWindow {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(WebPixelsWindow.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        innerHeight: Double?? = nil,
        innerWidth: Double?? = nil,
        location: Location?? = nil,
        origin: String?? = nil,
        outerHeight: Double?? = nil,
        outerWidth: Double?? = nil,
        pageXOffset: Double?? = nil,
        pageYOffset: Double?? = nil,
        screen: Screen?? = nil,
        screenX: Double?? = nil,
        screenY: Double?? = nil,
        scrollX: Double?? = nil,
        scrollY: Double?? = nil
    ) -> WebPixelsWindow {
        return WebPixelsWindow(
            innerHeight: innerHeight ?? self.innerHeight,
            innerWidth: innerWidth ?? self.innerWidth,
            location: location ?? self.location,
            origin: origin ?? self.origin,
            outerHeight: outerHeight ?? self.outerHeight,
            outerWidth: outerWidth ?? self.outerWidth,
            pageXOffset: pageXOffset ?? self.pageXOffset,
            pageYOffset: pageYOffset ?? self.pageYOffset,
            screen: screen ?? self.screen,
            screenX: screenX ?? self.screenX,
            screenY: screenY ?? self.screenY,
            scrollX: scrollX ?? self.scrollX,
            scrollY: scrollY ?? self.scrollY
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

/// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Screen), the
/// interface representing a screen, usually the one on which the current
/// window is being rendered
///
/// The interface representing a screen, usually the one on which the current
/// window is being rendered
// MARK: - Screen
struct Screen: Codable {
    /// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Screen/height),
    /// the height of the screen
    let height: Double?
    /// Per [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Screen/width),
    /// the width of the screen
    let width: Double?
}

// MARK: Screen convenience initializers and mutators

extension Screen {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(Screen.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        height: Double?? = nil,
        width: Double?? = nil
    ) -> Screen {
        return Screen(
            height: height ?? self.height,
            width: width ?? self.width
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - PixelEventsCartViewedData
struct PixelEventsCartViewedData: Codable {
    let cart: Cart?
}

// MARK: PixelEventsCartViewedData convenience initializers and mutators

extension PixelEventsCartViewedData {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(PixelEventsCartViewedData.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        cart: Cart?? = nil
    ) -> PixelEventsCartViewedData {
        return PixelEventsCartViewedData(
            cart: cart ?? self.cart
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

/// A cart represents the merchandise that a customer intends to purchase, and
/// the estimated cost associated with the cart.
// MARK: - Cart
struct Cart: Codable {
    /// The estimated costs that the customer will pay at checkout.
    let cost: CartCost?
    /// A globally unique identifier.
    let id: String?
    let lines: [CartLine]?
    /// The total number of items in the cart.
    let totalQuantity: Double?
}

// MARK: Cart convenience initializers and mutators

extension Cart {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(Cart.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        cost: CartCost?? = nil,
        id: String?? = nil,
        lines: [CartLine]?? = nil,
        totalQuantity: Double?? = nil
    ) -> Cart {
        return Cart(
            cost: cost ?? self.cost,
            id: id ?? self.id,
            lines: lines ?? self.lines,
            totalQuantity: totalQuantity ?? self.totalQuantity
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

/// The estimated costs that the customer will pay at checkout.
///
/// The costs that the customer will pay at checkout. It uses
/// [`CartBuyerIdentity`](https://shopify.dev/api/storefront/reference/cart/cartb
/// uyeridentity) to determine [international pricing](https://shopify.dev/custom-
/// storefronts/internationalization/international-pricing#create-a-cart).
// MARK: - CartCost
struct CartCost: Codable {
    /// The total amount for the customer to pay.
    let totalAmount: MoneyV2?
}

// MARK: CartCost convenience initializers and mutators

extension CartCost {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(CartCost.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        totalAmount: MoneyV2?? = nil
    ) -> CartCost {
        return CartCost(
            totalAmount: totalAmount ?? self.totalAmount
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

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
// MARK: - MoneyV2
struct MoneyV2: Codable {
    /// The decimal money amount.
    let amount: Double?
    /// The three-letter code that represents the currency, for example, USD.
    /// Supported codes include standard ISO 4217 codes, legacy codes, and non-
    /// standard codes.
    let currencyCode: String?
}

// MARK: MoneyV2 convenience initializers and mutators

extension MoneyV2 {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(MoneyV2.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        amount: Double?? = nil,
        currencyCode: String?? = nil
    ) -> MoneyV2 {
        return MoneyV2(
            amount: amount ?? self.amount,
            currencyCode: currencyCode ?? self.currencyCode
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

/// Information about the merchandise in the cart.
// MARK: - CartLine
struct CartLine: Codable {
    /// The cost of the merchandise that the customer will pay for at checkout. The
    /// costs are subject to change and changes will be reflected at checkout.
    let cost: CartLineCost?
    /// The merchandise that the buyer intends to purchase.
    let merchandise: ProductVariant?
    /// The quantity of the merchandise that the customer intends to purchase.
    let quantity: Double?
}

// MARK: CartLine convenience initializers and mutators

extension CartLine {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(CartLine.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        cost: CartLineCost?? = nil,
        merchandise: ProductVariant?? = nil,
        quantity: Double?? = nil
    ) -> CartLine {
        return CartLine(
            cost: cost ?? self.cost,
            merchandise: merchandise ?? self.merchandise,
            quantity: quantity ?? self.quantity
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

/// The cost of the merchandise that the customer will pay for at checkout. The
/// costs are subject to change and changes will be reflected at checkout.
///
/// The cost of the merchandise line that the customer will pay at checkout.
// MARK: - CartLineCost
struct CartLineCost: Codable {
    /// The total cost of the merchandise line.
    let totalAmount: MoneyV2?
}

// MARK: CartLineCost convenience initializers and mutators

extension CartLineCost {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(CartLineCost.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        totalAmount: MoneyV2?? = nil
    ) -> CartLineCost {
        return CartLineCost(
            totalAmount: totalAmount ?? self.totalAmount
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

/// The merchandise that the buyer intends to purchase.
///
/// A product variant represents a different version of a product, such as
/// differing sizes or differing colors.
// MARK: - ProductVariant
struct ProductVariant: Codable {
    /// A globally unique identifier.
    let id: String?
    /// Image associated with the product variant. This field falls back to the
    /// product image if no image is available.
    let image: Image?
    /// The product variant’s price.
    let price: MoneyV2?
    /// The product object that the product variant belongs to.
    let product: Product?
    /// The SKU (stock keeping unit) associated with the variant.
    let sku: String?
    /// The product variant’s title.
    let title: String?
    /// The product variant’s untranslated title.
    let untranslatedTitle: String?
}

// MARK: ProductVariant convenience initializers and mutators

extension ProductVariant {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(ProductVariant.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        id: String?? = nil,
        image: Image?? = nil,
        price: MoneyV2?? = nil,
        product: Product?? = nil,
        sku: String?? = nil,
        title: String?? = nil,
        untranslatedTitle: String?? = nil
    ) -> ProductVariant {
        return ProductVariant(
            id: id ?? self.id,
            image: image ?? self.image,
            price: price ?? self.price,
            product: product ?? self.product,
            sku: sku ?? self.sku,
            title: title ?? self.title,
            untranslatedTitle: untranslatedTitle ?? self.untranslatedTitle
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

/// An image resource.
// MARK: - Image
struct Image: Codable {
    /// The location of the image as a URL.
    let src: String?
}

// MARK: Image convenience initializers and mutators

extension Image {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(Image.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        src: String?? = nil
    ) -> Image {
        return Image(
            src: src ?? self.src
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

/// The product object that the product variant belongs to.
///
/// A product is an individual item for sale in a Shopify store.
// MARK: - Product
struct Product: Codable {
    /// The ID of the product.
    let id: String?
    /// The product’s title.
    let title: String?
    /// The [product
    /// type](https://help.shopify.com/en/manual/products/details/product-type)
    /// specified by the merchant.
    let type: String?
    /// The product’s untranslated title.
    let untranslatedTitle: String?
    /// The relative URL of the product.
    let url: String?
    /// The product’s vendor name.
    let vendor: String?
}

// MARK: Product convenience initializers and mutators

extension Product {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(Product.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        id: String?? = nil,
        title: String?? = nil,
        type: String?? = nil,
        untranslatedTitle: String?? = nil,
        url: String?? = nil,
        vendor: String?? = nil
    ) -> Product {
        return Product(
            id: id ?? self.id,
            title: title ?? self.title,
            type: type ?? self.type,
            untranslatedTitle: untranslatedTitle ?? self.untranslatedTitle,
            url: url ?? self.url,
            vendor: vendor ?? self.vendor
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

/// The name of the customer event
enum PixelEventsCartViewedName: String, Codable {
    case cartViewed = "cart_viewed"
}

/// The `checkout_address_info_submitted` event logs an instance of a customer
/// submitting their mailing address. This event is only available in checkouts
/// where checkout extensibility for customizations is enabled
// MARK: - PixelEventsCheckoutAddressInfoSubmitted
struct PixelEventsCheckoutAddressInfoSubmitted: Codable {
    /// The client-side ID of the customer, provided by Shopify
    let clientID: String?
    let context: Context?
    let data: PixelEventsCheckoutAddressInfoSubmittedData?
    /// The ID of the customer event
    let id: String?
    /// The name of the customer event
    let name: PixelEventsCheckoutAddressInfoSubmittedName?
    /// The timestamp of when the customer event occurred, in [ISO
    /// 8601](https://en.wikipedia.org/wiki/ISO_8601) format
    let timestamp: String?

    enum CodingKeys: String, CodingKey {
        case clientID = "clientId"
        case context, data, id, name, timestamp
    }
}

// MARK: PixelEventsCheckoutAddressInfoSubmitted convenience initializers and mutators

extension PixelEventsCheckoutAddressInfoSubmitted {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(PixelEventsCheckoutAddressInfoSubmitted.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        clientID: String?? = nil,
        context: Context?? = nil,
        data: PixelEventsCheckoutAddressInfoSubmittedData?? = nil,
        id: String?? = nil,
        name: PixelEventsCheckoutAddressInfoSubmittedName?? = nil,
        timestamp: String?? = nil
    ) -> PixelEventsCheckoutAddressInfoSubmitted {
        return PixelEventsCheckoutAddressInfoSubmitted(
            clientID: clientID ?? self.clientID,
            context: context ?? self.context,
            data: data ?? self.data,
            id: id ?? self.id,
            name: name ?? self.name,
            timestamp: timestamp ?? self.timestamp
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - PixelEventsCheckoutAddressInfoSubmittedData
struct PixelEventsCheckoutAddressInfoSubmittedData: Codable {
    let checkout: Checkout?
}

// MARK: PixelEventsCheckoutAddressInfoSubmittedData convenience initializers and mutators

extension PixelEventsCheckoutAddressInfoSubmittedData {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(PixelEventsCheckoutAddressInfoSubmittedData.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        checkout: Checkout?? = nil
    ) -> PixelEventsCheckoutAddressInfoSubmittedData {
        return PixelEventsCheckoutAddressInfoSubmittedData(
            checkout: checkout ?? self.checkout
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

/// A container for all the information required to add items to checkout and
/// pay.
// MARK: - Checkout
struct Checkout: Codable {
    /// A list of attributes accumulated throughout the checkout process.
    let attributes: [Attribute]?
    /// The billing address to where the order will be charged.
    let billingAddress: MailingAddress?
    /// The three-letter code that represents the currency, for example, USD.
    /// Supported codes include standard ISO 4217 codes, legacy codes, and non-
    /// standard codes.
    let currencyCode: String?
    /// A list of discount applications.
    let discountApplications: [DiscountApplication]?
    /// The email attached to this checkout.
    let email: String?
    /// A list of line item objects, each one containing information about an item
    /// in the checkout.
    let lineItems: [CheckoutLineItem]?
    /// The resulting order from a paid checkout.
    let order: Order?
    /// A unique phone number for the customer. Formatted using E.164 standard. For
    /// example, *+16135551111*.
    let phone: String?
    /// The shipping address to where the line items will be shipped.
    let shippingAddress: MailingAddress?
    /// Once a shipping rate is selected by the customer it is transitioned to a
    /// `shipping_line` object.
    let shippingLine: ShippingRate?
    /// The price at checkout before duties, shipping, and taxes.
    let subtotalPrice: MoneyV2?
    /// A unique identifier for a particular checkout.
    let token: String?
    /// The sum of all the prices of all the items in the checkout, including
    /// duties, taxes, and discounts.
    let totalPrice: MoneyV2?
    /// The sum of all the taxes applied to the line items and shipping lines in
    /// the checkout.
    let totalTax: MoneyV2?
    /// A list of transactions associated with a checkout or order.
    let transactions: [Transaction]?
}

// MARK: Checkout convenience initializers and mutators

extension Checkout {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(Checkout.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        attributes: [Attribute]?? = nil,
        billingAddress: MailingAddress?? = nil,
        currencyCode: String?? = nil,
        discountApplications: [DiscountApplication]?? = nil,
        email: String?? = nil,
        lineItems: [CheckoutLineItem]?? = nil,
        order: Order?? = nil,
        phone: String?? = nil,
        shippingAddress: MailingAddress?? = nil,
        shippingLine: ShippingRate?? = nil,
        subtotalPrice: MoneyV2?? = nil,
        token: String?? = nil,
        totalPrice: MoneyV2?? = nil,
        totalTax: MoneyV2?? = nil,
        transactions: [Transaction]?? = nil
    ) -> Checkout {
        return Checkout(
            attributes: attributes ?? self.attributes,
            billingAddress: billingAddress ?? self.billingAddress,
            currencyCode: currencyCode ?? self.currencyCode,
            discountApplications: discountApplications ?? self.discountApplications,
            email: email ?? self.email,
            lineItems: lineItems ?? self.lineItems,
            order: order ?? self.order,
            phone: phone ?? self.phone,
            shippingAddress: shippingAddress ?? self.shippingAddress,
            shippingLine: shippingLine ?? self.shippingLine,
            subtotalPrice: subtotalPrice ?? self.subtotalPrice,
            token: token ?? self.token,
            totalPrice: totalPrice ?? self.totalPrice,
            totalTax: totalTax ?? self.totalTax,
            transactions: transactions ?? self.transactions
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

/// Custom attributes left by the customer to the merchant, either in their cart
/// or during checkout.
// MARK: - Attribute
struct Attribute: Codable {
    /// The key for the attribute.
    let key: String?
    /// The value for the attribute.
    let value: String?
}

// MARK: Attribute convenience initializers and mutators

extension Attribute {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(Attribute.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        key: String?? = nil,
        value: String?? = nil
    ) -> Attribute {
        return Attribute(
            key: key ?? self.key,
            value: value ?? self.value
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

/// A mailing address for customers and shipping.
// MARK: - MailingAddress
struct MailingAddress: Codable {
    /// The first line of the address. This is usually the street address or a P.O.
    /// Box number.
    let address1: String?
    /// The second line of the address. This is usually an apartment, suite, or
    /// unit number.
    let address2: String?
    /// The name of the city, district, village, or town.
    let city: String?
    /// The name of the country.
    let country: String?
    /// The two-letter code that represents the country, for example, US.
    /// The country codes generally follows ISO 3166-1 alpha-2 guidelines.
    let countryCode: String?
    /// The customer’s first name.
    let firstName: String?
    /// The customer’s last name.
    let lastName: String?
    /// The phone number for this mailing address as entered by the customer.
    let phone: String?
    /// The region of the address, such as the province, state, or district.
    let province: String?
    /// The two-letter code for the region.
    /// For example, ON.
    let provinceCode: String?
    /// The ZIP or postal code of the address.
    let zip: String?
}

// MARK: MailingAddress convenience initializers and mutators

extension MailingAddress {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(MailingAddress.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        address1: String?? = nil,
        address2: String?? = nil,
        city: String?? = nil,
        country: String?? = nil,
        countryCode: String?? = nil,
        firstName: String?? = nil,
        lastName: String?? = nil,
        phone: String?? = nil,
        province: String?? = nil,
        provinceCode: String?? = nil,
        zip: String?? = nil
    ) -> MailingAddress {
        return MailingAddress(
            address1: address1 ?? self.address1,
            address2: address2 ?? self.address2,
            city: city ?? self.city,
            country: country ?? self.country,
            countryCode: countryCode ?? self.countryCode,
            firstName: firstName ?? self.firstName,
            lastName: lastName ?? self.lastName,
            phone: phone ?? self.phone,
            province: province ?? self.province,
            provinceCode: provinceCode ?? self.provinceCode,
            zip: zip ?? self.zip
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

/// The information about the intent of the discount.
// MARK: - DiscountApplication
struct DiscountApplication: Codable {
    /// The method by which the discount's value is applied to its entitled items.
    ///
    /// - `ACROSS`: The value is spread across all entitled lines.
    /// - `EACH`: The value is applied onto every entitled line.
    let allocationMethod: String?
    /// How the discount amount is distributed on the discounted lines.
    ///
    /// - `ALL`: The discount is allocated onto all the lines.
    /// - `ENTITLED`: The discount is allocated onto only the lines that it's
    /// entitled for.
    /// - `EXPLICIT`: The discount is allocated onto explicitly chosen lines.
    let targetSelection: String?
    /// The type of line (i.e. line item or shipping line) on an order that the
    /// discount is applicable towards.
    ///
    /// - `LINE_ITEM`: The discount applies onto line items.
    /// - `SHIPPING_LINE`: The discount applies onto shipping lines.
    let targetType: String?
    /// The customer-facing name of the discount. If the type of discount is
    /// a `DISCOUNT_CODE`, this `title` attribute represents the code of the
    /// discount.
    let title: String?
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
    let type: String?
    /// The value of the discount. Fixed discounts return a `Money` Object, while
    /// Percentage discounts return a `PricingPercentageValue` object.
    let value: Value?
}

// MARK: DiscountApplication convenience initializers and mutators

extension DiscountApplication {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(DiscountApplication.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        allocationMethod: String?? = nil,
        targetSelection: String?? = nil,
        targetType: String?? = nil,
        title: String?? = nil,
        type: String?? = nil,
        value: Value?? = nil
    ) -> DiscountApplication {
        return DiscountApplication(
            allocationMethod: allocationMethod ?? self.allocationMethod,
            targetSelection: targetSelection ?? self.targetSelection,
            targetType: targetType ?? self.targetType,
            title: title ?? self.title,
            type: type ?? self.type,
            value: value ?? self.value
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

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
// MARK: - Value
struct Value: Codable {
    /// The decimal money amount.
    let amount: Double?
    /// The three-letter code that represents the currency, for example, USD.
    /// Supported codes include standard ISO 4217 codes, legacy codes, and non-
    /// standard codes.
    let currencyCode: String?
    /// The percentage value of the object.
    let percentage: Double?
}

// MARK: Value convenience initializers and mutators

extension Value {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(Value.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        amount: Double?? = nil,
        currencyCode: String?? = nil,
        percentage: Double?? = nil
    ) -> Value {
        return Value(
            amount: amount ?? self.amount,
            currencyCode: currencyCode ?? self.currencyCode,
            percentage: percentage ?? self.percentage
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

/// A single line item in the checkout, grouped by variant and attributes.
// MARK: - CheckoutLineItem
struct CheckoutLineItem: Codable {
    /// The discounts that have been applied to the checkout line item by a
    /// discount application.
    let discountAllocations: [DiscountAllocation]?
    /// A globally unique identifier.
    let id: String?
    /// The quantity of the line item.
    let quantity: Double?
    /// The title of the line item. Defaults to the product's title.
    let title: String?
    /// Product variant of the line item.
    let variant: ProductVariant?
}

// MARK: CheckoutLineItem convenience initializers and mutators

extension CheckoutLineItem {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(CheckoutLineItem.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        discountAllocations: [DiscountAllocation]?? = nil,
        id: String?? = nil,
        quantity: Double?? = nil,
        title: String?? = nil,
        variant: ProductVariant?? = nil
    ) -> CheckoutLineItem {
        return CheckoutLineItem(
            discountAllocations: discountAllocations ?? self.discountAllocations,
            id: id ?? self.id,
            quantity: quantity ?? self.quantity,
            title: title ?? self.title,
            variant: variant ?? self.variant
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

/// The discount that has been applied to the checkout line item.
// MARK: - DiscountAllocation
struct DiscountAllocation: Codable {
    /// The monetary value with currency allocated to the discount.
    let amount: MoneyV2?
    /// The information about the intent of the discount.
    let discountApplication: DiscountApplication?
}

// MARK: DiscountAllocation convenience initializers and mutators

extension DiscountAllocation {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(DiscountAllocation.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        amount: MoneyV2?? = nil,
        discountApplication: DiscountApplication?? = nil
    ) -> DiscountAllocation {
        return DiscountAllocation(
            amount: amount ?? self.amount,
            discountApplication: discountApplication ?? self.discountApplication
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

/// An order is a customer’s completed request to purchase one or more products
/// from a shop. An order is created when a customer completes the checkout
/// process.
// MARK: - Order
struct Order: Codable {
    /// The ID of the order.
    let id: String?
}

// MARK: Order convenience initializers and mutators

extension Order {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(Order.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        id: String?? = nil
    ) -> Order {
        return Order(
            id: id ?? self.id
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

/// A shipping rate to be applied to a checkout.
// MARK: - ShippingRate
struct ShippingRate: Codable {
    /// Price of this shipping rate.
    let price: MoneyV2?
}

// MARK: ShippingRate convenience initializers and mutators

extension ShippingRate {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(ShippingRate.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        price: MoneyV2?? = nil
    ) -> ShippingRate {
        return ShippingRate(
            price: price ?? self.price
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

/// A transaction associated with a checkout or order.
// MARK: - Transaction
struct Transaction: Codable {
    /// The monetary value with currency allocated to the transaction method.
    let amount: MoneyV2?
    /// The name of the payment provider used for the transaction.
    let gateway: String?
}

// MARK: Transaction convenience initializers and mutators

extension Transaction {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(Transaction.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        amount: MoneyV2?? = nil,
        gateway: String?? = nil
    ) -> Transaction {
        return Transaction(
            amount: amount ?? self.amount,
            gateway: gateway ?? self.gateway
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

/// The name of the customer event
enum PixelEventsCheckoutAddressInfoSubmittedName: String, Codable {
    case checkoutAddressInfoSubmitted = "checkout_address_info_submitted"
}

/// The `checkout_completed` event logs when a visitor completes a purchase. This
/// event is available on the order status and checkout pages
///
/// The `checkout_completed` event logs when a visitor completes a purchase.
/// This event is available on the order status and checkout pages
// MARK: - PixelEventsCheckoutCompleted
struct PixelEventsCheckoutCompleted: Codable {
    /// The client-side ID of the customer, provided by Shopify
    let clientID: String?
    let context: Context?
    let data: PixelEventsCheckoutCompletedData?
    /// The ID of the customer event
    let id: String?
    /// The name of the customer event
    let name: PixelEventsCheckoutCompletedName?
    /// The timestamp of when the customer event occurred, in [ISO
    /// 8601](https://en.wikipedia.org/wiki/ISO_8601) format
    let timestamp: String?

    enum CodingKeys: String, CodingKey {
        case clientID = "clientId"
        case context, data, id, name, timestamp
    }
}

// MARK: PixelEventsCheckoutCompleted convenience initializers and mutators

extension PixelEventsCheckoutCompleted {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(PixelEventsCheckoutCompleted.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        clientID: String?? = nil,
        context: Context?? = nil,
        data: PixelEventsCheckoutCompletedData?? = nil,
        id: String?? = nil,
        name: PixelEventsCheckoutCompletedName?? = nil,
        timestamp: String?? = nil
    ) -> PixelEventsCheckoutCompleted {
        return PixelEventsCheckoutCompleted(
            clientID: clientID ?? self.clientID,
            context: context ?? self.context,
            data: data ?? self.data,
            id: id ?? self.id,
            name: name ?? self.name,
            timestamp: timestamp ?? self.timestamp
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - PixelEventsCheckoutCompletedData
struct PixelEventsCheckoutCompletedData: Codable {
    let checkout: Checkout?
}

// MARK: PixelEventsCheckoutCompletedData convenience initializers and mutators

extension PixelEventsCheckoutCompletedData {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(PixelEventsCheckoutCompletedData.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        checkout: Checkout?? = nil
    ) -> PixelEventsCheckoutCompletedData {
        return PixelEventsCheckoutCompletedData(
            checkout: checkout ?? self.checkout
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

/// The name of the customer event
enum PixelEventsCheckoutCompletedName: String, Codable {
    case checkoutCompleted = "checkout_completed"
}

/// The `checkout_contact_info_submitted` event logs an instance where a customer
/// submits a checkout form. This event is only available in checkouts where
/// checkout extensibility for customizations is enabled
///
/// The `checkout_contact_info_submitted` event logs an instance where a
/// customer submits a checkout form. This event is only available in checkouts
/// where checkout extensibility for customizations is enabled
// MARK: - PixelEventsCheckoutContactInfoSubmitted
struct PixelEventsCheckoutContactInfoSubmitted: Codable {
    /// The client-side ID of the customer, provided by Shopify
    let clientID: String?
    let context: Context?
    let data: PixelEventsCheckoutContactInfoSubmittedData?
    /// The ID of the customer event
    let id: String?
    /// The name of the customer event
    let name: PixelEventsCheckoutContactInfoSubmittedName?
    /// The timestamp of when the customer event occurred, in [ISO
    /// 8601](https://en.wikipedia.org/wiki/ISO_8601) format
    let timestamp: String?

    enum CodingKeys: String, CodingKey {
        case clientID = "clientId"
        case context, data, id, name, timestamp
    }
}

// MARK: PixelEventsCheckoutContactInfoSubmitted convenience initializers and mutators

extension PixelEventsCheckoutContactInfoSubmitted {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(PixelEventsCheckoutContactInfoSubmitted.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        clientID: String?? = nil,
        context: Context?? = nil,
        data: PixelEventsCheckoutContactInfoSubmittedData?? = nil,
        id: String?? = nil,
        name: PixelEventsCheckoutContactInfoSubmittedName?? = nil,
        timestamp: String?? = nil
    ) -> PixelEventsCheckoutContactInfoSubmitted {
        return PixelEventsCheckoutContactInfoSubmitted(
            clientID: clientID ?? self.clientID,
            context: context ?? self.context,
            data: data ?? self.data,
            id: id ?? self.id,
            name: name ?? self.name,
            timestamp: timestamp ?? self.timestamp
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - PixelEventsCheckoutContactInfoSubmittedData
struct PixelEventsCheckoutContactInfoSubmittedData: Codable {
    let checkout: Checkout?
}

// MARK: PixelEventsCheckoutContactInfoSubmittedData convenience initializers and mutators

extension PixelEventsCheckoutContactInfoSubmittedData {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(PixelEventsCheckoutContactInfoSubmittedData.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        checkout: Checkout?? = nil
    ) -> PixelEventsCheckoutContactInfoSubmittedData {
        return PixelEventsCheckoutContactInfoSubmittedData(
            checkout: checkout ?? self.checkout
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

/// The name of the customer event
enum PixelEventsCheckoutContactInfoSubmittedName: String, Codable {
    case checkoutContactInfoSubmitted = "checkout_contact_info_submitted"
}

/// The `checkout_shipping_info_submitted` event logs an instance where the
/// customer chooses a shipping rate. This event is only available in checkouts
/// where checkout extensibility for customizations is enabled
// MARK: - PixelEventsCheckoutShippingInfoSubmitted
struct PixelEventsCheckoutShippingInfoSubmitted: Codable {
    /// The client-side ID of the customer, provided by Shopify
    let clientID: String?
    let context: Context?
    let data: PixelEventsCheckoutShippingInfoSubmittedData?
    /// The ID of the customer event
    let id: String?
    /// The name of the customer event
    let name: PixelEventsCheckoutShippingInfoSubmittedName?
    /// The timestamp of when the customer event occurred, in [ISO
    /// 8601](https://en.wikipedia.org/wiki/ISO_8601) format
    let timestamp: String?

    enum CodingKeys: String, CodingKey {
        case clientID = "clientId"
        case context, data, id, name, timestamp
    }
}

// MARK: PixelEventsCheckoutShippingInfoSubmitted convenience initializers and mutators

extension PixelEventsCheckoutShippingInfoSubmitted {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(PixelEventsCheckoutShippingInfoSubmitted.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        clientID: String?? = nil,
        context: Context?? = nil,
        data: PixelEventsCheckoutShippingInfoSubmittedData?? = nil,
        id: String?? = nil,
        name: PixelEventsCheckoutShippingInfoSubmittedName?? = nil,
        timestamp: String?? = nil
    ) -> PixelEventsCheckoutShippingInfoSubmitted {
        return PixelEventsCheckoutShippingInfoSubmitted(
            clientID: clientID ?? self.clientID,
            context: context ?? self.context,
            data: data ?? self.data,
            id: id ?? self.id,
            name: name ?? self.name,
            timestamp: timestamp ?? self.timestamp
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - PixelEventsCheckoutShippingInfoSubmittedData
struct PixelEventsCheckoutShippingInfoSubmittedData: Codable {
    let checkout: Checkout?
}

// MARK: PixelEventsCheckoutShippingInfoSubmittedData convenience initializers and mutators

extension PixelEventsCheckoutShippingInfoSubmittedData {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(PixelEventsCheckoutShippingInfoSubmittedData.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        checkout: Checkout?? = nil
    ) -> PixelEventsCheckoutShippingInfoSubmittedData {
        return PixelEventsCheckoutShippingInfoSubmittedData(
            checkout: checkout ?? self.checkout
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

/// The name of the customer event
enum PixelEventsCheckoutShippingInfoSubmittedName: String, Codable {
    case checkoutShippingInfoSubmitted = "checkout_shipping_info_submitted"
}

/// The `checkout_started` event logs an instance of a customer starting the
/// checkout process. This event is available on the checkout page. For checkout
/// extensibility, this event is triggered every time a customer enters checkout.
/// For non-checkout extensible shops, this event is only triggered the first
/// time a customer enters checkout.
///
/// The `checkout_started` event logs an instance of a customer starting
/// the checkout process. This event is available on the checkout page. For
/// checkout extensibility, this event is triggered every time a customer
/// enters checkout. For non-checkout extensible shops, this event is only
/// triggered the first time a customer enters checkout.
// MARK: - PixelEventsCheckoutStarted
struct PixelEventsCheckoutStarted: Codable {
    /// The client-side ID of the customer, provided by Shopify
    let clientID: String?
    let context: Context?
    let data: PixelEventsCheckoutStartedData?
    /// The ID of the customer event
    let id: String?
    /// The name of the customer event
    let name: PixelEventsCheckoutStartedName?
    /// The timestamp of when the customer event occurred, in [ISO
    /// 8601](https://en.wikipedia.org/wiki/ISO_8601) format
    let timestamp: String?

    enum CodingKeys: String, CodingKey {
        case clientID = "clientId"
        case context, data, id, name, timestamp
    }
}

// MARK: PixelEventsCheckoutStarted convenience initializers and mutators

extension PixelEventsCheckoutStarted {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(PixelEventsCheckoutStarted.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        clientID: String?? = nil,
        context: Context?? = nil,
        data: PixelEventsCheckoutStartedData?? = nil,
        id: String?? = nil,
        name: PixelEventsCheckoutStartedName?? = nil,
        timestamp: String?? = nil
    ) -> PixelEventsCheckoutStarted {
        return PixelEventsCheckoutStarted(
            clientID: clientID ?? self.clientID,
            context: context ?? self.context,
            data: data ?? self.data,
            id: id ?? self.id,
            name: name ?? self.name,
            timestamp: timestamp ?? self.timestamp
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - PixelEventsCheckoutStartedData
struct PixelEventsCheckoutStartedData: Codable {
    let checkout: Checkout?
}

// MARK: PixelEventsCheckoutStartedData convenience initializers and mutators

extension PixelEventsCheckoutStartedData {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(PixelEventsCheckoutStartedData.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        checkout: Checkout?? = nil
    ) -> PixelEventsCheckoutStartedData {
        return PixelEventsCheckoutStartedData(
            checkout: checkout ?? self.checkout
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

/// The name of the customer event
enum PixelEventsCheckoutStartedName: String, Codable {
    case checkoutStarted = "checkout_started"
}

/// The `collection_viewed` event logs an instance where a customer visited a
/// product collection index page. This event is available on the online store
/// page
// MARK: - PixelEventsCollectionViewed
struct PixelEventsCollectionViewed: Codable {
    /// The client-side ID of the customer, provided by Shopify
    let clientID: String?
    let context: Context?
    let data: PixelEventsCollectionViewedData?
    /// The ID of the customer event
    let id: String?
    /// The name of the customer event
    let name: PixelEventsCollectionViewedName?
    /// The timestamp of when the customer event occurred, in [ISO
    /// 8601](https://en.wikipedia.org/wiki/ISO_8601) format
    let timestamp: String?

    enum CodingKeys: String, CodingKey {
        case clientID = "clientId"
        case context, data, id, name, timestamp
    }
}

// MARK: PixelEventsCollectionViewed convenience initializers and mutators

extension PixelEventsCollectionViewed {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(PixelEventsCollectionViewed.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        clientID: String?? = nil,
        context: Context?? = nil,
        data: PixelEventsCollectionViewedData?? = nil,
        id: String?? = nil,
        name: PixelEventsCollectionViewedName?? = nil,
        timestamp: String?? = nil
    ) -> PixelEventsCollectionViewed {
        return PixelEventsCollectionViewed(
            clientID: clientID ?? self.clientID,
            context: context ?? self.context,
            data: data ?? self.data,
            id: id ?? self.id,
            name: name ?? self.name,
            timestamp: timestamp ?? self.timestamp
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - PixelEventsCollectionViewedData
struct PixelEventsCollectionViewedData: Codable {
    let collection: Collection?
}

// MARK: PixelEventsCollectionViewedData convenience initializers and mutators

extension PixelEventsCollectionViewedData {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(PixelEventsCollectionViewedData.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        collection: Collection?? = nil
    ) -> PixelEventsCollectionViewedData {
        return PixelEventsCollectionViewedData(
            collection: collection ?? self.collection
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

/// A collection is a group of products that a shop owner can create to organize
/// them or make their shops easier to browse.
// MARK: - Collection
struct Collection: Codable {
    /// A globally unique identifier.
    let id: String?
    let productVariants: [ProductVariant]?
    /// The collection’s name. Maximum length: 255 characters.
    let title: String?
}

// MARK: Collection convenience initializers and mutators

extension Collection {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(Collection.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        id: String?? = nil,
        productVariants: [ProductVariant]?? = nil,
        title: String?? = nil
    ) -> Collection {
        return Collection(
            id: id ?? self.id,
            productVariants: productVariants ?? self.productVariants,
            title: title ?? self.title
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

/// The name of the customer event
enum PixelEventsCollectionViewedName: String, Codable {
    case collectionViewed = "collection_viewed"
}

/// The `page_viewed` event logs an instance where a customer visited a page.
/// This event is available on the online store, checkout, and order status pages
///
/// The `page_viewed` event logs an instance where a customer visited a page.
/// This event is available on the online store, checkout, and order status
/// pages
// MARK: - PixelEventsPageViewed
struct PixelEventsPageViewed: Codable {
    /// The client-side ID of the customer, provided by Shopify
    let clientID: String?
    let context: Context?
    let data: PixelEventsPageViewedData?
    /// The ID of the customer event
    let id: String?
    /// The name of the customer event
    let name: PixelEventsPageViewedName?
    /// The timestamp of when the customer event occurred, in [ISO
    /// 8601](https://en.wikipedia.org/wiki/ISO_8601) format
    let timestamp: String?

    enum CodingKeys: String, CodingKey {
        case clientID = "clientId"
        case context, data, id, name, timestamp
    }
}

// MARK: PixelEventsPageViewed convenience initializers and mutators

extension PixelEventsPageViewed {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(PixelEventsPageViewed.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        clientID: String?? = nil,
        context: Context?? = nil,
        data: PixelEventsPageViewedData?? = nil,
        id: String?? = nil,
        name: PixelEventsPageViewedName?? = nil,
        timestamp: String?? = nil
    ) -> PixelEventsPageViewed {
        return PixelEventsPageViewed(
            clientID: clientID ?? self.clientID,
            context: context ?? self.context,
            data: data ?? self.data,
            id: id ?? self.id,
            name: name ?? self.name,
            timestamp: timestamp ?? self.timestamp
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - PixelEventsPageViewedData
struct PixelEventsPageViewedData: Codable {
}

// MARK: PixelEventsPageViewedData convenience initializers and mutators

extension PixelEventsPageViewedData {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(PixelEventsPageViewedData.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
    ) -> PixelEventsPageViewedData {
        return PixelEventsPageViewedData(
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

/// The name of the customer event
enum PixelEventsPageViewedName: String, Codable {
    case pageViewed = "page_viewed"
}

/// The `payment_info_submitted` event logs an instance of a customer submitting
/// their payment information. This event is available on the checkout page
///
/// The `payment_info_submitted` event logs an instance of a customer
/// submitting their payment information. This event is available on the
/// checkout page
// MARK: - PixelEventsPaymentInfoSubmitted
struct PixelEventsPaymentInfoSubmitted: Codable {
    /// The client-side ID of the customer, provided by Shopify
    let clientID: String?
    let context: Context?
    let data: PixelEventsPaymentInfoSubmittedData?
    /// The ID of the customer event
    let id: String?
    /// The name of the customer event
    let name: PixelEventsPaymentInfoSubmittedName?
    /// The timestamp of when the customer event occurred, in [ISO
    /// 8601](https://en.wikipedia.org/wiki/ISO_8601) format
    let timestamp: String?

    enum CodingKeys: String, CodingKey {
        case clientID = "clientId"
        case context, data, id, name, timestamp
    }
}

// MARK: PixelEventsPaymentInfoSubmitted convenience initializers and mutators

extension PixelEventsPaymentInfoSubmitted {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(PixelEventsPaymentInfoSubmitted.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        clientID: String?? = nil,
        context: Context?? = nil,
        data: PixelEventsPaymentInfoSubmittedData?? = nil,
        id: String?? = nil,
        name: PixelEventsPaymentInfoSubmittedName?? = nil,
        timestamp: String?? = nil
    ) -> PixelEventsPaymentInfoSubmitted {
        return PixelEventsPaymentInfoSubmitted(
            clientID: clientID ?? self.clientID,
            context: context ?? self.context,
            data: data ?? self.data,
            id: id ?? self.id,
            name: name ?? self.name,
            timestamp: timestamp ?? self.timestamp
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - PixelEventsPaymentInfoSubmittedData
struct PixelEventsPaymentInfoSubmittedData: Codable {
    let checkout: Checkout?
}

// MARK: PixelEventsPaymentInfoSubmittedData convenience initializers and mutators

extension PixelEventsPaymentInfoSubmittedData {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(PixelEventsPaymentInfoSubmittedData.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        checkout: Checkout?? = nil
    ) -> PixelEventsPaymentInfoSubmittedData {
        return PixelEventsPaymentInfoSubmittedData(
            checkout: checkout ?? self.checkout
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

/// The name of the customer event
enum PixelEventsPaymentInfoSubmittedName: String, Codable {
    case paymentInfoSubmitted = "payment_info_submitted"
}

/// The `product_added_to_cart` event logs an instance where a customer adds a
/// product to their cart. This event is available on the online store page
// MARK: - PixelEventsProductAddedToCart
struct PixelEventsProductAddedToCart: Codable {
    /// The client-side ID of the customer, provided by Shopify
    let clientID: String?
    let context: Context?
    let data: PixelEventsProductAddedToCartData?
    /// The ID of the customer event
    let id: String?
    /// The name of the customer event
    let name: PixelEventsProductAddedToCartName?
    /// The timestamp of when the customer event occurred, in [ISO
    /// 8601](https://en.wikipedia.org/wiki/ISO_8601) format
    let timestamp: String?

    enum CodingKeys: String, CodingKey {
        case clientID = "clientId"
        case context, data, id, name, timestamp
    }
}

// MARK: PixelEventsProductAddedToCart convenience initializers and mutators

extension PixelEventsProductAddedToCart {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(PixelEventsProductAddedToCart.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        clientID: String?? = nil,
        context: Context?? = nil,
        data: PixelEventsProductAddedToCartData?? = nil,
        id: String?? = nil,
        name: PixelEventsProductAddedToCartName?? = nil,
        timestamp: String?? = nil
    ) -> PixelEventsProductAddedToCart {
        return PixelEventsProductAddedToCart(
            clientID: clientID ?? self.clientID,
            context: context ?? self.context,
            data: data ?? self.data,
            id: id ?? self.id,
            name: name ?? self.name,
            timestamp: timestamp ?? self.timestamp
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - PixelEventsProductAddedToCartData
struct PixelEventsProductAddedToCartData: Codable {
    let cartLine: CartLine?
}

// MARK: PixelEventsProductAddedToCartData convenience initializers and mutators

extension PixelEventsProductAddedToCartData {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(PixelEventsProductAddedToCartData.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        cartLine: CartLine?? = nil
    ) -> PixelEventsProductAddedToCartData {
        return PixelEventsProductAddedToCartData(
            cartLine: cartLine ?? self.cartLine
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

/// The name of the customer event
enum PixelEventsProductAddedToCartName: String, Codable {
    case productAddedToCart = "product_added_to_cart"
}

/// The `product_removed_from_cart` event logs an instance where a customer
/// removes a product from their cart. This event is available on the online
/// store page
// MARK: - PixelEventsProductRemovedFromCart
struct PixelEventsProductRemovedFromCart: Codable {
    /// The client-side ID of the customer, provided by Shopify
    let clientID: String?
    let context: Context?
    let data: PixelEventsProductRemovedFromCartData?
    /// The ID of the customer event
    let id: String?
    /// The name of the customer event
    let name: PixelEventsProductRemovedFromCartName?
    /// The timestamp of when the customer event occurred, in [ISO
    /// 8601](https://en.wikipedia.org/wiki/ISO_8601) format
    let timestamp: String?

    enum CodingKeys: String, CodingKey {
        case clientID = "clientId"
        case context, data, id, name, timestamp
    }
}

// MARK: PixelEventsProductRemovedFromCart convenience initializers and mutators

extension PixelEventsProductRemovedFromCart {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(PixelEventsProductRemovedFromCart.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        clientID: String?? = nil,
        context: Context?? = nil,
        data: PixelEventsProductRemovedFromCartData?? = nil,
        id: String?? = nil,
        name: PixelEventsProductRemovedFromCartName?? = nil,
        timestamp: String?? = nil
    ) -> PixelEventsProductRemovedFromCart {
        return PixelEventsProductRemovedFromCart(
            clientID: clientID ?? self.clientID,
            context: context ?? self.context,
            data: data ?? self.data,
            id: id ?? self.id,
            name: name ?? self.name,
            timestamp: timestamp ?? self.timestamp
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - PixelEventsProductRemovedFromCartData
struct PixelEventsProductRemovedFromCartData: Codable {
    let cartLine: CartLine?
}

// MARK: PixelEventsProductRemovedFromCartData convenience initializers and mutators

extension PixelEventsProductRemovedFromCartData {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(PixelEventsProductRemovedFromCartData.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        cartLine: CartLine?? = nil
    ) -> PixelEventsProductRemovedFromCartData {
        return PixelEventsProductRemovedFromCartData(
            cartLine: cartLine ?? self.cartLine
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

/// The name of the customer event
enum PixelEventsProductRemovedFromCartName: String, Codable {
    case productRemovedFromCart = "product_removed_from_cart"
}

/// The `product_variant_viewed` event logs an instance where a customer
/// interacts with the product page and views a different variant than the
/// initial `product_viewed` impression. This event is available on the Product
/// page
// MARK: - PixelEventsProductVariantViewed
struct PixelEventsProductVariantViewed: Codable {
    /// The client-side ID of the customer, provided by Shopify
    let clientID: String?
    let context: Context?
    let data: PixelEventsProductVariantViewedData?
    /// The ID of the customer event
    let id: String?
    /// The name of the customer event
    let name: PixelEventsProductVariantViewedName?
    /// The timestamp of when the customer event occurred, in [ISO
    /// 8601](https://en.wikipedia.org/wiki/ISO_8601) format
    let timestamp: String?

    enum CodingKeys: String, CodingKey {
        case clientID = "clientId"
        case context, data, id, name, timestamp
    }
}

// MARK: PixelEventsProductVariantViewed convenience initializers and mutators

extension PixelEventsProductVariantViewed {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(PixelEventsProductVariantViewed.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        clientID: String?? = nil,
        context: Context?? = nil,
        data: PixelEventsProductVariantViewedData?? = nil,
        id: String?? = nil,
        name: PixelEventsProductVariantViewedName?? = nil,
        timestamp: String?? = nil
    ) -> PixelEventsProductVariantViewed {
        return PixelEventsProductVariantViewed(
            clientID: clientID ?? self.clientID,
            context: context ?? self.context,
            data: data ?? self.data,
            id: id ?? self.id,
            name: name ?? self.name,
            timestamp: timestamp ?? self.timestamp
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - PixelEventsProductVariantViewedData
struct PixelEventsProductVariantViewedData: Codable {
    let productVariant: ProductVariant?
}

// MARK: PixelEventsProductVariantViewedData convenience initializers and mutators

extension PixelEventsProductVariantViewedData {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(PixelEventsProductVariantViewedData.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        productVariant: ProductVariant?? = nil
    ) -> PixelEventsProductVariantViewedData {
        return PixelEventsProductVariantViewedData(
            productVariant: productVariant ?? self.productVariant
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

/// The name of the customer event
enum PixelEventsProductVariantViewedName: String, Codable {
    case productVariantViewed = "product_variant_viewed"
}

/// The `product_viewed` event logs an instance where a customer visited a
/// product details page. This event is available on the product page
// MARK: - PixelEventsProductViewed
struct PixelEventsProductViewed: Codable {
    /// The client-side ID of the customer, provided by Shopify
    let clientID: String?
    let context: Context?
    let data: PixelEventsProductViewedData?
    /// The ID of the customer event
    let id: String?
    /// The name of the customer event
    let name: PixelEventsProductViewedName?
    /// The timestamp of when the customer event occurred, in [ISO
    /// 8601](https://en.wikipedia.org/wiki/ISO_8601) format
    let timestamp: String?

    enum CodingKeys: String, CodingKey {
        case clientID = "clientId"
        case context, data, id, name, timestamp
    }
}

// MARK: PixelEventsProductViewed convenience initializers and mutators

extension PixelEventsProductViewed {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(PixelEventsProductViewed.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        clientID: String?? = nil,
        context: Context?? = nil,
        data: PixelEventsProductViewedData?? = nil,
        id: String?? = nil,
        name: PixelEventsProductViewedName?? = nil,
        timestamp: String?? = nil
    ) -> PixelEventsProductViewed {
        return PixelEventsProductViewed(
            clientID: clientID ?? self.clientID,
            context: context ?? self.context,
            data: data ?? self.data,
            id: id ?? self.id,
            name: name ?? self.name,
            timestamp: timestamp ?? self.timestamp
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - PixelEventsProductViewedData
struct PixelEventsProductViewedData: Codable {
    let productVariant: ProductVariant?
}

// MARK: PixelEventsProductViewedData convenience initializers and mutators

extension PixelEventsProductViewedData {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(PixelEventsProductViewedData.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        productVariant: ProductVariant?? = nil
    ) -> PixelEventsProductViewedData {
        return PixelEventsProductViewedData(
            productVariant: productVariant ?? self.productVariant
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

/// The name of the customer event
enum PixelEventsProductViewedName: String, Codable {
    case productViewed = "product_viewed"
}

/// The `search_submitted` event logs an instance where a customer performed a
/// search on the storefront. This event is available on the online store page
// MARK: - PixelEventsSearchSubmitted
struct PixelEventsSearchSubmitted: Codable {
    /// The client-side ID of the customer, provided by Shopify
    let clientID: String?
    let context: Context?
    let data: PixelEventsSearchSubmittedData?
    /// The ID of the customer event
    let id: String?
    /// The name of the customer event
    let name: PixelEventsSearchSubmittedName?
    /// The timestamp of when the customer event occurred, in [ISO
    /// 8601](https://en.wikipedia.org/wiki/ISO_8601) format
    let timestamp: String?

    enum CodingKeys: String, CodingKey {
        case clientID = "clientId"
        case context, data, id, name, timestamp
    }
}

// MARK: PixelEventsSearchSubmitted convenience initializers and mutators

extension PixelEventsSearchSubmitted {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(PixelEventsSearchSubmitted.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        clientID: String?? = nil,
        context: Context?? = nil,
        data: PixelEventsSearchSubmittedData?? = nil,
        id: String?? = nil,
        name: PixelEventsSearchSubmittedName?? = nil,
        timestamp: String?? = nil
    ) -> PixelEventsSearchSubmitted {
        return PixelEventsSearchSubmitted(
            clientID: clientID ?? self.clientID,
            context: context ?? self.context,
            data: data ?? self.data,
            id: id ?? self.id,
            name: name ?? self.name,
            timestamp: timestamp ?? self.timestamp
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - PixelEventsSearchSubmittedData
struct PixelEventsSearchSubmittedData: Codable {
    let searchResult: SearchResult?
}

// MARK: PixelEventsSearchSubmittedData convenience initializers and mutators

extension PixelEventsSearchSubmittedData {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(PixelEventsSearchSubmittedData.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        searchResult: SearchResult?? = nil
    ) -> PixelEventsSearchSubmittedData {
        return PixelEventsSearchSubmittedData(
            searchResult: searchResult ?? self.searchResult
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

/// An object that contains the metadata of when a search has been performed.
// MARK: - SearchResult
struct SearchResult: Codable {
    let productVariants: [ProductVariant]?
    /// The search query that was executed
    let query: String?
}

// MARK: SearchResult convenience initializers and mutators

extension SearchResult {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(SearchResult.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        productVariants: [ProductVariant]?? = nil,
        query: String?? = nil
    ) -> SearchResult {
        return SearchResult(
            productVariants: productVariants ?? self.productVariants,
            query: query ?? self.query
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

/// The name of the customer event
enum PixelEventsSearchSubmittedName: String, Codable {
    case searchSubmitted = "search_submitted"
}

// MARK: - Browser
struct Browser: Codable {
    /// This object replaces the native document.cookie API and provides a
    /// setter/getter to set cookies on the top frame.
    let cookie: BrowserCookie?
    let localStorage: BrowserLocalStorage?
    let sendBeacon: SendBeacon?
    let sessionStorage: BrowserSessionStorage?
}

// MARK: Browser convenience initializers and mutators

extension Browser {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(Browser.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        cookie: BrowserCookie?? = nil,
        localStorage: BrowserLocalStorage?? = nil,
        sendBeacon: SendBeacon?? = nil,
        sessionStorage: BrowserSessionStorage?? = nil
    ) -> Browser {
        return Browser(
            cookie: cookie ?? self.cookie,
            localStorage: localStorage ?? self.localStorage,
            sendBeacon: sendBeacon ?? self.sendBeacon,
            sessionStorage: sessionStorage ?? self.sessionStorage
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

/// This object replaces the native document.cookie API and provides a
/// setter/getter to set cookies on the top frame.
// MARK: - BrowserCookie
struct BrowserCookie: Codable {
    /// An asynchronous method to get a specific cookie by name. Takes a cookie
    /// name of type `string` and returns the cookie value as a `string`
    let browserCookieGet: Get?
    /// An asynchronous method to set a cookie by name. It
    /// takes two arguments, a string of form `key=value` as
    /// [described here](https://developer.mozilla.org/en-
    /// US/docs/Web/API/Document/cookie#write_a_new_cookie) or the name of the
    /// cookie as the first argument and the value as the second argument.
    let browserCookieSet: Set?

    enum CodingKeys: String, CodingKey {
        case browserCookieGet = "get"
        case browserCookieSet = "set"
    }
}

// MARK: BrowserCookie convenience initializers and mutators

extension BrowserCookie {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(BrowserCookie.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        browserCookieGet: Get?? = nil,
        browserCookieSet: Set?? = nil
    ) -> BrowserCookie {
        return BrowserCookie(
            browserCookieGet: browserCookieGet ?? self.browserCookieGet,
            browserCookieSet: browserCookieSet ?? self.browserCookieSet
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

/// An asynchronous method to get a specific cookie by name. Takes a cookie
/// name of type `string` and returns the cookie value as a `string`
// MARK: - Get
struct Get: Codable {
}

// MARK: Get convenience initializers and mutators

extension Get {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(Get.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
    ) -> Get {
        return Get(
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

/// An asynchronous method to set a cookie by name. It
/// takes two arguments, a string of form `key=value` as
/// [described here](https://developer.mozilla.org/en-
/// US/docs/Web/API/Document/cookie#write_a_new_cookie) or the name of the
/// cookie as the first argument and the value as the second argument.
// MARK: - Set
struct Set: Codable {
}

// MARK: Set convenience initializers and mutators

extension Set {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(Set.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
    ) -> Set {
        return Set(
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - BrowserLocalStorage
struct BrowserLocalStorage: Codable {
    /// When invoked, will empty all keys out of the storage.
    let clear: BrowserLocalStorageClear?
    /// When passed a key name, will return that key's value.
    let getItem: BrowserLocalStorageGetItem?
    /// When passed a number n, this method will return the name of the nth key in
    /// the storage.
    let key: BrowserLocalStorageKey?
    /// Returns an integer representing the number of data items stored in the
    /// Storage object.
    let length: BrowserLocalStorageLength?
    /// When passed a key name, will remove that key from the storage.
    let removeItem: BrowserLocalStorageRemoveItem?
    /// When passed a key name and value, will add that key to the storage, or
    /// update that key's value if it already exists.
    let setItem: BrowserLocalStorageSetItem?
}

// MARK: BrowserLocalStorage convenience initializers and mutators

extension BrowserLocalStorage {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(BrowserLocalStorage.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        clear: BrowserLocalStorageClear?? = nil,
        getItem: BrowserLocalStorageGetItem?? = nil,
        key: BrowserLocalStorageKey?? = nil,
        length: BrowserLocalStorageLength?? = nil,
        removeItem: BrowserLocalStorageRemoveItem?? = nil,
        setItem: BrowserLocalStorageSetItem?? = nil
    ) -> BrowserLocalStorage {
        return BrowserLocalStorage(
            clear: clear ?? self.clear,
            getItem: getItem ?? self.getItem,
            key: key ?? self.key,
            length: length ?? self.length,
            removeItem: removeItem ?? self.removeItem,
            setItem: setItem ?? self.setItem
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

/// When invoked, will empty all keys out of the storage.
// MARK: - BrowserLocalStorageClear
struct BrowserLocalStorageClear: Codable {
}

// MARK: BrowserLocalStorageClear convenience initializers and mutators

extension BrowserLocalStorageClear {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(BrowserLocalStorageClear.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
    ) -> BrowserLocalStorageClear {
        return BrowserLocalStorageClear(
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

/// When passed a key name, will return that key's value.
// MARK: - BrowserLocalStorageGetItem
struct BrowserLocalStorageGetItem: Codable {
}

// MARK: BrowserLocalStorageGetItem convenience initializers and mutators

extension BrowserLocalStorageGetItem {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(BrowserLocalStorageGetItem.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
    ) -> BrowserLocalStorageGetItem {
        return BrowserLocalStorageGetItem(
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

/// When passed a number n, this method will return the name of the nth key in
/// the storage.
// MARK: - BrowserLocalStorageKey
struct BrowserLocalStorageKey: Codable {
}

// MARK: BrowserLocalStorageKey convenience initializers and mutators

extension BrowserLocalStorageKey {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(BrowserLocalStorageKey.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
    ) -> BrowserLocalStorageKey {
        return BrowserLocalStorageKey(
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

/// Returns an integer representing the number of data items stored in the
/// Storage object.
// MARK: - BrowserLocalStorageLength
struct BrowserLocalStorageLength: Codable {
}

// MARK: BrowserLocalStorageLength convenience initializers and mutators

extension BrowserLocalStorageLength {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(BrowserLocalStorageLength.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
    ) -> BrowserLocalStorageLength {
        return BrowserLocalStorageLength(
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

/// When passed a key name, will remove that key from the storage.
// MARK: - BrowserLocalStorageRemoveItem
struct BrowserLocalStorageRemoveItem: Codable {
}

// MARK: BrowserLocalStorageRemoveItem convenience initializers and mutators

extension BrowserLocalStorageRemoveItem {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(BrowserLocalStorageRemoveItem.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
    ) -> BrowserLocalStorageRemoveItem {
        return BrowserLocalStorageRemoveItem(
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

/// When passed a key name and value, will add that key to the storage, or
/// update that key's value if it already exists.
// MARK: - BrowserLocalStorageSetItem
struct BrowserLocalStorageSetItem: Codable {
}

// MARK: BrowserLocalStorageSetItem convenience initializers and mutators

extension BrowserLocalStorageSetItem {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(BrowserLocalStorageSetItem.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
    ) -> BrowserLocalStorageSetItem {
        return BrowserLocalStorageSetItem(
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - SendBeacon
struct SendBeacon: Codable {
}

// MARK: SendBeacon convenience initializers and mutators

extension SendBeacon {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(SendBeacon.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
    ) -> SendBeacon {
        return SendBeacon(
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - BrowserSessionStorage
struct BrowserSessionStorage: Codable {
    /// When invoked, will empty all keys out of the storage.
    let clear: BrowserSessionStorageClear?
    /// When passed a key name, will return that key's value.
    let getItem: BrowserSessionStorageGetItem?
    /// When passed a number n, this method will return the name of the nth key in
    /// the storage.
    let key: BrowserSessionStorageKey?
    /// Returns an integer representing the number of data items stored in the
    /// Storage object.
    let length: BrowserSessionStorageLength?
    /// When passed a key name, will remove that key from the storage.
    let removeItem: BrowserSessionStorageRemoveItem?
    /// When passed a key name and value, will add that key to the storage, or
    /// update that key's value if it already exists.
    let setItem: BrowserSessionStorageSetItem?
}

// MARK: BrowserSessionStorage convenience initializers and mutators

extension BrowserSessionStorage {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(BrowserSessionStorage.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        clear: BrowserSessionStorageClear?? = nil,
        getItem: BrowserSessionStorageGetItem?? = nil,
        key: BrowserSessionStorageKey?? = nil,
        length: BrowserSessionStorageLength?? = nil,
        removeItem: BrowserSessionStorageRemoveItem?? = nil,
        setItem: BrowserSessionStorageSetItem?? = nil
    ) -> BrowserSessionStorage {
        return BrowserSessionStorage(
            clear: clear ?? self.clear,
            getItem: getItem ?? self.getItem,
            key: key ?? self.key,
            length: length ?? self.length,
            removeItem: removeItem ?? self.removeItem,
            setItem: setItem ?? self.setItem
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

/// When invoked, will empty all keys out of the storage.
// MARK: - BrowserSessionStorageClear
struct BrowserSessionStorageClear: Codable {
}

// MARK: BrowserSessionStorageClear convenience initializers and mutators

extension BrowserSessionStorageClear {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(BrowserSessionStorageClear.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
    ) -> BrowserSessionStorageClear {
        return BrowserSessionStorageClear(
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

/// When passed a key name, will return that key's value.
// MARK: - BrowserSessionStorageGetItem
struct BrowserSessionStorageGetItem: Codable {
}

// MARK: BrowserSessionStorageGetItem convenience initializers and mutators

extension BrowserSessionStorageGetItem {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(BrowserSessionStorageGetItem.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
    ) -> BrowserSessionStorageGetItem {
        return BrowserSessionStorageGetItem(
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

/// When passed a number n, this method will return the name of the nth key in
/// the storage.
// MARK: - BrowserSessionStorageKey
struct BrowserSessionStorageKey: Codable {
}

// MARK: BrowserSessionStorageKey convenience initializers and mutators

extension BrowserSessionStorageKey {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(BrowserSessionStorageKey.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
    ) -> BrowserSessionStorageKey {
        return BrowserSessionStorageKey(
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

/// Returns an integer representing the number of data items stored in the
/// Storage object.
// MARK: - BrowserSessionStorageLength
struct BrowserSessionStorageLength: Codable {
}

// MARK: BrowserSessionStorageLength convenience initializers and mutators

extension BrowserSessionStorageLength {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(BrowserSessionStorageLength.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
    ) -> BrowserSessionStorageLength {
        return BrowserSessionStorageLength(
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

/// When passed a key name, will remove that key from the storage.
// MARK: - BrowserSessionStorageRemoveItem
struct BrowserSessionStorageRemoveItem: Codable {
}

// MARK: BrowserSessionStorageRemoveItem convenience initializers and mutators

extension BrowserSessionStorageRemoveItem {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(BrowserSessionStorageRemoveItem.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
    ) -> BrowserSessionStorageRemoveItem {
        return BrowserSessionStorageRemoveItem(
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

/// When passed a key name and value, will add that key to the storage, or
/// update that key's value if it already exists.
// MARK: - BrowserSessionStorageSetItem
struct BrowserSessionStorageSetItem: Codable {
}

// MARK: BrowserSessionStorageSetItem convenience initializers and mutators

extension BrowserSessionStorageSetItem {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(BrowserSessionStorageSetItem.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
    ) -> BrowserSessionStorageSetItem {
        return BrowserSessionStorageSetItem(
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

/// This event represents any custom events emitted by partners or merchants via
/// the `publish` method
// MARK: - CustomEvent
struct CustomEvent: Codable {
    /// The client-side ID of the customer, provided by Shopify
    let clientID: String?
    let context: Context?
    let customData: CustomData?
    /// The ID of the customer event
    let id: String?
    /// Arbitrary name of the custom event
    let name: String?
    /// The timestamp of when the customer event occurred, in [ISO
    /// 8601](https://en.wikipedia.org/wiki/ISO_8601) format
    let timestamp: String?

    enum CodingKeys: String, CodingKey {
        case clientID = "clientId"
        case context, customData, id, name, timestamp
    }
}

// MARK: CustomEvent convenience initializers and mutators

extension CustomEvent {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(CustomEvent.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        clientID: String?? = nil,
        context: Context?? = nil,
        customData: CustomData?? = nil,
        id: String?? = nil,
        name: String?? = nil,
        timestamp: String?? = nil
    ) -> CustomEvent {
        return CustomEvent(
            clientID: clientID ?? self.clientID,
            context: context ?? self.context,
            customData: customData ?? self.customData,
            id: id ?? self.id,
            name: name ?? self.name,
            timestamp: timestamp ?? self.timestamp
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

/// A free-form object representing data specific to a custom event provided by
/// the custom event publisher
// MARK: - CustomData
struct CustomData: Codable {
}

// MARK: CustomData convenience initializers and mutators

extension CustomData {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(CustomData.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
    ) -> CustomData {
        return CustomData(
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

/// A free-form object representing data specific to this event provided by
/// Shopify. Refer to [standard events](#standard-events) for details on the
/// payload available to each event
// MARK: - PurpleData
struct PurpleData: Codable {
}

// MARK: PurpleData convenience initializers and mutators

extension PurpleData {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(PurpleData.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
    ) -> PurpleData {
        return PurpleData(
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - InitData
struct InitData: Codable {
    let cart: Cart?
    let checkout: Checkout?
    let customer: Customer?
    let productVariants: [ProductVariant]?
}

// MARK: InitData convenience initializers and mutators

extension InitData {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(InitData.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        cart: Cart?? = nil,
        checkout: Checkout?? = nil,
        customer: Customer?? = nil,
        productVariants: [ProductVariant]?? = nil
    ) -> InitData {
        return InitData(
            cart: cart ?? self.cart,
            checkout: checkout ?? self.checkout,
            customer: customer ?? self.customer,
            productVariants: productVariants ?? self.productVariants
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

/// A customer represents a customer account with the shop. Customer accounts
/// store contact information for the customer, saving logged-in customers the
/// trouble of having to provide it at every checkout.
// MARK: - Customer
struct Customer: Codable {
    /// The customer’s email address.
    let email: String?
    /// The customer’s first name.
    let firstName: String?
    /// The ID of the customer.
    let id: String?
    /// The customer’s last name.
    let lastName: String?
    /// The total number of orders that the customer has placed.
    let ordersCount: Double?
    /// The customer’s phone number.
    let phone: String?
}

// MARK: Customer convenience initializers and mutators

extension Customer {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(Customer.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        email: String?? = nil,
        firstName: String?? = nil,
        id: String?? = nil,
        lastName: String?? = nil,
        ordersCount: Double?? = nil,
        phone: String?? = nil
    ) -> Customer {
        return Customer(
            email: email ?? self.email,
            firstName: firstName ?? self.firstName,
            id: id ?? self.id,
            lastName: lastName ?? self.lastName,
            ordersCount: ordersCount ?? self.ordersCount,
            phone: phone ?? self.phone
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

/// A value given to a customer when a discount is applied to an order. The
/// application of a discount with this value gives the customer the specified
/// percentage off a specified item.
// MARK: - PricingPercentageValue
struct PricingPercentageValue: Codable {
    /// The percentage value of the object.
    let percentage: Double?
}

// MARK: PricingPercentageValue convenience initializers and mutators

extension PricingPercentageValue {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(PricingPercentageValue.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        percentage: Double?? = nil
    ) -> PricingPercentageValue {
        return PricingPercentageValue(
            percentage: percentage ?? self.percentage
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

typealias ClientID = String
typealias ID = String
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
