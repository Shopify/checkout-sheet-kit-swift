// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension Storefront {
    struct DeliveryAddressInput: InputObject {
        private(set) var __data: InputDict

        init(_ data: InputDict) {
            __data = data
        }

        init(
            deliveryAddress: GraphQLNullable<MailingAddressInput> = nil
        ) {
            __data = InputDict([
                "deliveryAddress": deliveryAddress
            ])
        }

        var deliveryAddress: GraphQLNullable<MailingAddressInput> {
            get { __data["deliveryAddress"] }
            set { __data["deliveryAddress"] = newValue }
        }
    }
}
