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
import SwiftUI

@available(iOS 16.0, *)
extension ShopifyAcceleratedCheckouts {
    public class Configuration: ObservableObject, NSCopying {
        /// The domain of the shop without the protocol.
        ///
        /// Example: `my-shop.myshopify.com`
        ///
        /// See: https://shopify.dev/docs/storefronts/themes/getting-started/build-a-theme#get-the-shop-domain
        @Published public var storefrontDomain: String

        /// The storefront access token.
        ///
        /// See: https://shopify.dev/docs/storefronts/themes/getting-started/build-a-theme#get-the-storefront-access-token
        @Published public var storefrontAccessToken: String

        /// Data to attach to the buyerIdentity during cart creation
        /// - Apple Pay sheet will skip requesting email/phone number fields if provided here
        ///
        /// See: https://shopify.dev/docs/api/storefront/latest/mutations/cartBuyerIdentityUpdate
        @Published public var customer: Customer?

        public init(
            storefrontDomain: String,
            storefrontAccessToken: String,
            customer: Customer? = nil
        ) {
            self.storefrontDomain = storefrontDomain
            self.storefrontAccessToken = storefrontAccessToken
            self.customer = customer
        }

        public func copy(with _: NSZone? = nil) -> Any {
            let copy = Configuration(
                storefrontDomain: storefrontDomain,
                storefrontAccessToken: storefrontAccessToken,
                customer: customer?.copy() as? Customer
            )
            return copy
        }
    }

    public class Customer: ObservableObject, NSCopying {
        /// The email to attribute an order to on `buyerIdentity`
        ///
        /// Apple Pay - This property is ignored when `.email` is included in `ApplePayConfiguration.contactFields`
        @Published public var email: String?

        /// The phoneNumber to attribute an order to on `buyerIdentity`
        ///
        /// Apple Pay - This property is ignored when `.phone` is included in `ApplePayConfiguration.contactFields`
        @Published public var phoneNumber: String?

        /// The customer access token to attribute an order to on `buyerIdentity`
        @Published public var customerAccessToken: String?

        public init(email: String?, phoneNumber: String?, customerAccessToken: String? = nil) {
            self.email = email
            self.phoneNumber = phoneNumber
            self.customerAccessToken = customerAccessToken
        }

        public func copy(with _: NSZone? = nil) -> Any {
            let copy = Customer(
                email: email,
                phoneNumber: phoneNumber,
                customerAccessToken: customerAccessToken
            )
            return copy
        }
    }
}
