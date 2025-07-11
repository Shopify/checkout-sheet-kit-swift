// @generated
// This file was automatically generated and should not be edited.

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
