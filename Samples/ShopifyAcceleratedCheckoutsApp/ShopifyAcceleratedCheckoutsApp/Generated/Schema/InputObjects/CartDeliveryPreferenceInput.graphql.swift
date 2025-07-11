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
    /// Delivery preferences can be used to prefill the delivery section at checkout.
    struct CartDeliveryPreferenceInput: InputObject {
        private(set) var __data: InputDict

        init(_ data: InputDict) {
            __data = data
        }

        init(
            deliveryMethod: GraphQLNullable<[GraphQLEnum<PreferenceDeliveryMethodType>]> = nil,
            pickupHandle: GraphQLNullable<[String]> = nil,
            coordinates: GraphQLNullable<CartDeliveryCoordinatesPreferenceInput> = nil
        ) {
            __data = InputDict([
                "deliveryMethod": deliveryMethod,
                "pickupHandle": pickupHandle,
                "coordinates": coordinates
            ])
        }

        /// The preferred delivery methods such as shipping, local pickup or through pickup points.
        ///
        /// The input must not contain more than `250` values.
        var deliveryMethod: GraphQLNullable<[GraphQLEnum<PreferenceDeliveryMethodType>]> {
            get { __data["deliveryMethod"] }
            set { __data["deliveryMethod"] = newValue }
        }

        /// The pickup handle prefills checkout fields with the location for either local pickup or pickup points delivery methods.
        /// It accepts both location ID for local pickup and external IDs for pickup points.
        ///
        /// The input must not contain more than `250` values.
        var pickupHandle: GraphQLNullable<[String]> {
            get { __data["pickupHandle"] }
            set { __data["pickupHandle"] = newValue }
        }

        /// The coordinates of a delivery location in order of preference.
        var coordinates: GraphQLNullable<CartDeliveryCoordinatesPreferenceInput> {
            get { __data["coordinates"] }
            set { __data["coordinates"] = newValue }
        }
    }
}
