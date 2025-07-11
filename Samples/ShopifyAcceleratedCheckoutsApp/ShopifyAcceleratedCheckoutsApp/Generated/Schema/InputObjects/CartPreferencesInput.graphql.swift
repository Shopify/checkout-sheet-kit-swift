// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension Storefront {
    /// The input fields represent preferences for the buyer that is interacting with the cart.
    struct CartPreferencesInput: InputObject {
        private(set) var __data: InputDict

        init(_ data: InputDict) {
            __data = data
        }

        init(
            delivery: GraphQLNullable<CartDeliveryPreferenceInput> = nil,
            wallet: GraphQLNullable<[String]> = nil
        ) {
            __data = InputDict([
                "delivery": delivery,
                "wallet": wallet
            ])
        }

        /// Delivery preferences can be used to prefill the delivery section in at checkout.
        var delivery: GraphQLNullable<CartDeliveryPreferenceInput> {
            get { __data["delivery"] }
            set { __data["delivery"] = newValue }
        }

        /// Wallet preferences are used to populate relevant payment fields in the checkout flow.
        /// Accepted value: `["shop_pay"]`.
        ///
        /// The input must not contain more than `250` values.
        var wallet: GraphQLNullable<[String]> {
            get { __data["wallet"] }
            set { __data["wallet"] = newValue }
        }
    }
}
