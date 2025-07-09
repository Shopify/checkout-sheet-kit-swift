//
//  ShopifyAcceleratedCheckouts+Configuration.swift
//  ShopifyAcceleratedCheckouts
//

import PassKit

@available(iOS 17.0, *)
public extension ShopifyAcceleratedCheckouts {
    @Observable class Configuration {
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

    @Observable class Customer {
        public var email: String?

        public init(email: String?) {
            self.email = email
        }
    }
}
