// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension Storefront {
    /// The input fields for an attribute.
    struct AttributeInput: InputObject {
        private(set) var __data: InputDict

        init(_ data: InputDict) {
            __data = data
        }

        init(
            key: String,
            value: String
        ) {
            __data = InputDict([
                "key": key,
                "value": value
            ])
        }

        /// Key or name of the attribute.
        var key: String {
            get { __data["key"] }
            set { __data["key"] = newValue }
        }

        /// Value of the attribute.
        var value: String {
            get { __data["value"] }
            set { __data["value"] = newValue }
        }
    }
}
