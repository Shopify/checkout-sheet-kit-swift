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

import PassKit

@available(iOS 17.0, *)
extension ShopifyAcceleratedCheckouts {
    @Observable public class Configuration {
        /**
         * The domain of the shop without the protocol.
         *
         * @example: `my-shop.myshopify.com`
         * @see: https://shopify.dev/docs/storefronts/themes/getting-started/build-a-theme#get-the-shop-domain
         */
        public var shopDomain: String

        /**
         * The storefront access token.
         *
         * @see: https://shopify.dev/docs/storefronts/themes/getting-started/build-a-theme#get-the-storefront-access-token
         */
        public var storefrontAccessToken: String

        /*
          * The customer to use for the checkout.
         */
        public var customer: Customer?

        public init(
            shopDomain: String,
            storefrontAccessToken: String,
            customer: Customer? = nil
        ) {
            self.shopDomain = shopDomain
            self.storefrontAccessToken = storefrontAccessToken
            self.customer = customer
        }
    }

    @Observable public class Customer {
        public var email: String?

        public init(email: String?) {
            self.email = email
        }
    }
}
