// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension Storefront {
    /// The input fields for the cart's delivery properties.
    struct CartDeliveryInput: InputObject {
        private(set) var __data: InputDict

        init(_ data: InputDict) {
            __data = data
        }

        init(
            addresses: GraphQLNullable<[CartSelectableAddressInput]> = nil
        ) {
            __data = InputDict([
                "addresses": addresses
            ])
        }

        /// Selectable addresses to present to the buyer on the cart.
        ///
        /// The input must not contain more than `250` values.
        var addresses: GraphQLNullable<[CartSelectableAddressInput]> {
            get { __data["addresses"] }
            set { __data["addresses"] = newValue }
        }
    }
}
