// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension Storefront {
    struct CartLineUpdateInput: InputObject {
        private(set) var __data: InputDict

        init(_ data: InputDict) {
            __data = data
        }

        init(
            id: ID,
            quantity: GraphQLNullable<Int> = nil
        ) {
            __data = InputDict([
                "id": id,
                "quantity": quantity
            ])
        }

        var id: ID {
            get { __data["id"] }
            set { __data["id"] = newValue }
        }

        var quantity: GraphQLNullable<Int> {
            get { __data["quantity"] }
            set { __data["quantity"] = newValue }
        }
    }
}
