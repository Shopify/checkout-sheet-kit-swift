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
    /// The input fields for a cart metafield value to set.
    struct CartInputMetafieldInput: InputObject {
        private(set) var __data: InputDict

        init(_ data: InputDict) {
            __data = data
        }

        init(
            key: String,
            value: String,
            type: String
        ) {
            __data = InputDict([
                "key": key,
                "value": value,
                "type": type
            ])
        }

        /// The key name of the metafield.
        var key: String {
            get { __data["key"] }
            set { __data["key"] = newValue }
        }

        /// The data to store in the cart metafield. The data is always stored as a string, regardless of the metafield's type.
        var value: String {
            get { __data["value"] }
            set { __data["value"] = newValue }
        }

        /// The type of data that the cart metafield stores.
        /// The type of data must be a [supported type](https://shopify.dev/apps/metafields/types).
        var type: String {
            get { __data["type"] }
            set { __data["type"] = newValue }
        }
    }
}
