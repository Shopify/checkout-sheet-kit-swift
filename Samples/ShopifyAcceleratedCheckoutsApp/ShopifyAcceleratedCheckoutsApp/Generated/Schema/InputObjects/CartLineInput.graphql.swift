// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) @_spi(Unsafe) import ApolloAPI

extension Storefront {
    /// The input fields for adding a merchandise line to a cart. Each line represents a [`ProductVariant`](https://shopify.dev/docs/api/storefront/current/objects/ProductVariant) the buyer intends to purchase, along with the quantity and optional [`SellingPlan`](https://shopify.dev/docs/api/storefront/current/objects/SellingPlan) for subscriptions.
    ///
    /// Used by the [`cartCreate`](https://shopify.dev/docs/api/storefront/current/mutations/cartCreate) mutation when creating a cart with initial items, and the [`cartLinesAdd`](https://shopify.dev/docs/api/storefront/current/mutations/cartLinesAdd) mutation when adding items to an existing cart.
    struct CartLineInput: InputObject {
        private(set) var __data: InputDict

        init(_ data: InputDict) {
            __data = data
        }

        init(
            attributes: GraphQLNullable<[AttributeInput]> = nil,
            quantity: GraphQLNullable<Int32> = nil,
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
        var quantity: GraphQLNullable<Int32> {
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
