// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension Storefront {
    /// The input fields to provide exactly one of a variety of delivery address types.
    struct CartAddressInput: InputObject {
        private(set) var __data: InputDict

        init(_ data: InputDict) {
            __data = data
        }

        init(
            deliveryAddress: GraphQLNullable<CartDeliveryAddressInput> = nil,
            copyFromCustomerAddressId: GraphQLNullable<ID> = nil
        ) {
            __data = InputDict([
                "deliveryAddress": deliveryAddress,
                "copyFromCustomerAddressId": copyFromCustomerAddressId
            ])
        }

        /// A delivery address stored on this cart.
        var deliveryAddress: GraphQLNullable<CartDeliveryAddressInput> {
            get { __data["deliveryAddress"] }
            set { __data["deliveryAddress"] = newValue }
        }

        /// Copies details from the customer address to an address on this cart.
        var copyFromCustomerAddressId: GraphQLNullable<ID> {
            get { __data["copyFromCustomerAddressId"] }
            set { __data["copyFromCustomerAddressId"] = newValue }
        }
    }
}
