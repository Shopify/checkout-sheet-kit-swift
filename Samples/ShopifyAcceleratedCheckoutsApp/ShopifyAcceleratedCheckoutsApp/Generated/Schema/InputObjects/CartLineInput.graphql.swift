// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension Storefront {
    /// The input fields to create a merchandise line on a cart.
    struct CartLineInput: InputObject {
        private(set) var __data: InputDict

        init(_ data: InputDict) {
            __data = data
        }

        init(
            attributes: GraphQLNullable<[AttributeInput]> = nil,
            quantity: GraphQLNullable<Int> = nil,
            merchandiseId: ID,
            sellingPlanId: GraphQLNullable<ID> = nil
        ) {
            __data = InputDict([
                "attributes": attributes,
                "quantity": quantity,
                "merchandiseId": merchandiseId,
                "sellingPlanId": sellingPlanId
            ])
        }

        /// An array of key-value pairs that contains additional information about the merchandise line.
        ///
        /// The input must not contain more than `250` values.
        var attributes: GraphQLNullable<[AttributeInput]> {
            get { __data["attributes"] }
            set { __data["attributes"] = newValue }
        }

        /// The quantity of the merchandise.
        var quantity: GraphQLNullable<Int> {
            get { __data["quantity"] }
            set { __data["quantity"] = newValue }
        }

        /// The ID of the merchandise that the buyer intends to purchase.
        var merchandiseId: ID {
            get { __data["merchandiseId"] }
            set { __data["merchandiseId"] = newValue }
        }

        /// The ID of the selling plan that the merchandise is being purchased with.
        var sellingPlanId: GraphQLNullable<ID> {
            get { __data["sellingPlanId"] }
            set { __data["sellingPlanId"] = newValue }
        }
    }
}
