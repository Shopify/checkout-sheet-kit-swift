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

@_exported import ApolloAPI

extension Storefront {
    struct CartUserErrorFragment: Storefront.SelectionSet, Fragment {
        static var fragmentDefinition: StaticString {
            #"fragment CartUserErrorFragment on CartUserError { __typename code message field }"#
        }

        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { Storefront.Objects.CartUserError }
        static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("code", GraphQLEnum<Storefront.CartErrorCode>?.self),
            .field("message", String.self),
            .field("field", [String]?.self)
        ] }

        /// The error code.
        var code: GraphQLEnum<Storefront.CartErrorCode>? { __data["code"] }
        /// The error message.
        var message: String { __data["message"] }
        /// The path to the input field that caused the error.
        var field: [String]? { __data["field"] }
    }
}
