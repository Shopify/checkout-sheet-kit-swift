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

import ApolloAPI

extension Storefront {
    /// The input fields represent preferences for the buyer that is interacting with the cart.
    struct CartPreferencesInput: InputObject {
        private(set) var __data: InputDict

        init(_ data: InputDict) {
            __data = data
        }

        init(
            delivery: GraphQLNullable<CartDeliveryPreferenceInput> = nil,
            wallet: GraphQLNullable<[String]> = nil
        ) {
            __data = InputDict([
                "delivery": delivery,
                "wallet": wallet
            ])
        }

        /// Delivery preferences can be used to prefill the delivery section in at checkout.
        var delivery: GraphQLNullable<CartDeliveryPreferenceInput> {
            get { __data["delivery"] }
            set { __data["delivery"] = newValue }
        }

        /// Wallet preferences are used to populate relevant payment fields in the checkout flow.
        /// Accepted value: `["shop_pay"]`.
        ///
        /// The input must not contain more than `250` values.
        var wallet: GraphQLNullable<[String]> {
            get { __data["wallet"] }
            set { __data["wallet"] = newValue }
        }
    }
}
