// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension Storefront {
    struct CartInput: InputObject {
        private(set) var __data: InputDict

        init(_ data: InputDict) {
            __data = data
        }

        init(
            lines: GraphQLNullable<[CartLineInput]> = nil,
            buyerIdentity: GraphQLNullable<CartBuyerIdentityInput> = nil
        ) {
            __data = InputDict([
                "lines": lines,
                "buyerIdentity": buyerIdentity
            ])
        }

        var lines: GraphQLNullable<[CartLineInput]> {
            get { __data["lines"] }
            set { __data["lines"] = newValue }
        }

        var buyerIdentity: GraphQLNullable<CartBuyerIdentityInput> {
            get { __data["buyerIdentity"] }
            set { __data["buyerIdentity"] = newValue }
        }
    }
}
