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
    /// The input fields to create a cart.
    struct CartInput: InputObject {
        private(set) var __data: InputDict

        init(_ data: InputDict) {
            __data = data
        }

        init(
            attributes: GraphQLNullable<[AttributeInput]> = nil,
            lines: GraphQLNullable<[CartLineInput]> = nil,
            discountCodes: GraphQLNullable<[String]> = nil,
            note: GraphQLNullable<String> = nil,
            buyerIdentity: GraphQLNullable<CartBuyerIdentityInput> = nil,
            metafields: GraphQLNullable<[CartInputMetafieldInput]> = nil
        ) {
            __data = InputDict([
                "attributes": attributes,
                "lines": lines,
                "discountCodes": discountCodes,
                "note": note,
                "buyerIdentity": buyerIdentity,
                "metafields": metafields
            ])
        }

        /// An array of key-value pairs that contains additional information about the cart.
        ///
        /// The input must not contain more than `250` values.
        var attributes: GraphQLNullable<[AttributeInput]> {
            get { __data["attributes"] }
            set { __data["attributes"] = newValue }
        }

        /// A list of merchandise lines to add to the cart.
        ///
        /// The input must not contain more than `250` values.
        var lines: GraphQLNullable<[CartLineInput]> {
            get { __data["lines"] }
            set { __data["lines"] = newValue }
        }

        /// The case-insensitive discount codes that the customer added at checkout.
        ///
        /// The input must not contain more than `250` values.
        var discountCodes: GraphQLNullable<[String]> {
            get { __data["discountCodes"] }
            set { __data["discountCodes"] = newValue }
        }

        /// A note that's associated with the cart. For example, the note can be a personalized message to the buyer.
        var note: GraphQLNullable<String> {
            get { __data["note"] }
            set { __data["note"] = newValue }
        }

        /// The customer associated with the cart. Used to determine [international pricing]
        /// (https://shopify.dev/custom-storefronts/internationalization/international-pricing).
        /// Buyer identity should match the customer's shipping address.
        var buyerIdentity: GraphQLNullable<CartBuyerIdentityInput> {
            get { __data["buyerIdentity"] }
            set { __data["buyerIdentity"] = newValue }
        }

        /// The metafields to associate with this cart.
        ///
        /// The input must not contain more than `250` values.
        var metafields: GraphQLNullable<[CartInputMetafieldInput]> {
            get { __data["metafields"] }
            set { __data["metafields"] = newValue }
        }
    }
}
