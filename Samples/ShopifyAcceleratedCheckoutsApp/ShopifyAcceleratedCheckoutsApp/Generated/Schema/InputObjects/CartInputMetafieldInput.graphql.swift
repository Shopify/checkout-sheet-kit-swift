// @generated
// This file was automatically generated and should not be edited.

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
