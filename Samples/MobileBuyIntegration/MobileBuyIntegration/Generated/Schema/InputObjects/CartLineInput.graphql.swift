// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension Storefront {
    struct CartLineInput: InputObject {
        private(set) var __data: InputDict

        init(_ data: InputDict) {
            __data = data
        }

        init(
            merchandiseId: ID,
            quantity: GraphQLNullable<Int> = nil
        ) {
            __data = InputDict([
                "merchandiseId": merchandiseId,
                "quantity": quantity
            ])
        }

        var merchandiseId: ID {
            get { __data["merchandiseId"] }
            set { __data["merchandiseId"] = newValue }
        }

        var quantity: GraphQLNullable<Int> {
            get { __data["quantity"] }
            set { __data["quantity"] = newValue }
        }
    }
}
