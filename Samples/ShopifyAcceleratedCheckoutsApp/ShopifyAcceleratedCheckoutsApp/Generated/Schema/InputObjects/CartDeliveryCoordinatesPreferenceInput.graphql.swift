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
    /// Preferred location used to find the closest pick up point based on coordinates.
    struct CartDeliveryCoordinatesPreferenceInput: InputObject {
        private(set) var __data: InputDict

        init(_ data: InputDict) {
            __data = data
        }

        init(
            latitude: Double,
            longitude: Double,
            countryCode: GraphQLEnum<CountryCode>
        ) {
            __data = InputDict([
                "latitude": latitude,
                "longitude": longitude,
                "countryCode": countryCode
            ])
        }

        /// The geographic latitude for a given location. Coordinates are required in order to set pickUpHandle for pickup points.
        var latitude: Double {
            get { __data["latitude"] }
            set { __data["latitude"] = newValue }
        }

        /// The geographic longitude for a given location. Coordinates are required in order to set pickUpHandle for pickup points.
        var longitude: Double {
            get { __data["longitude"] }
            set { __data["longitude"] = newValue }
        }

        /// The two-letter code for the country of the preferred location.
        ///
        /// For example, US.
        var countryCode: GraphQLEnum<CountryCode> {
            get { __data["countryCode"] }
            set { __data["countryCode"] = newValue }
        }
    }
}
