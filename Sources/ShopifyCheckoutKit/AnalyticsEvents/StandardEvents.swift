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
    var cartViewed: CartViewed?
    var checkoutAddressInfoSubmitted: CheckoutAddressInfoSubmitted?
    var checkoutCompleted: CheckoutCompleted?
    var checkoutContactInfoSubmitted: CheckoutContactInfoSubmitted?
    var checkoutShippingInfoSubmitted: CheckoutShippingInfoSubmitted?
    var checkoutStarted: CheckoutStarted?
    var collectionViewed: CollectionViewed?
    var pageViewed: PageViewed?
    var paymentInfoSubmitted: PaymentInfoSubmitted?
    var productAddedToCart: ProductAddedToCart?
    var productRemovedFromCart: ProductRemovedFromCart?
    var productVariantViewed: ProductVariantViewed?
    var productViewed: ProductViewed?
    var searchSubmitted: SearchSubmitted?
}
