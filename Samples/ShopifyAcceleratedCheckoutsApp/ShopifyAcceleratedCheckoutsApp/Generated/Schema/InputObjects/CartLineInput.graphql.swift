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
    /// The input fields to create a merchandise line on a cart.
    struct CartLineInput: InputObject {
        private(set) var __data: InputDict

        init(_ data: InputDict) {
            __data = data
        }

        init(
            attributes: GraphQLNullable<[AttributeInput]> = nil,
            quantity: GraphQLNullable<Int> = nil,
            merchandiseId: ID,
            sellingPlanId: GraphQLNullable<ID> = nil
        ) {
            __data = InputDict([
                "attributes": attributes,
                "quantity": quantity,
                "merchandiseId": merchandiseId,
                "sellingPlanId": sellingPlanId
            ])
        }

        /// An array of key-value pairs that contains additional information about the merchandise line.
        ///
        /// The input must not contain more than `250` values.
        var attributes: GraphQLNullable<[AttributeInput]> {
            get { __data["attributes"] }
            set { __data["attributes"] = newValue }
        }

        /// The quantity of the merchandise.
        var quantity: GraphQLNullable<Int> {
            get { __data["quantity"] }
            set { __data["quantity"] = newValue }
        }

        /// The ID of the merchandise that the buyer intends to purchase.
        var merchandiseId: ID {
            get { __data["merchandiseId"] }
            set { __data["merchandiseId"] = newValue }
        }

        /// The ID of the selling plan that the merchandise is being purchased with.
        var sellingPlanId: GraphQLNullable<ID> {
            get { __data["sellingPlanId"] }
            set { __data["sellingPlanId"] = newValue }
        }
    }
}
