// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) @_spi(Unsafe) import ApolloAPI

extension Storefront {
    /// The input fields for a selectable delivery address to present to the buyer. Used by [`CartDeliveryInput`](https://shopify.dev/docs/api/storefront/current/input-objects/CartDeliveryInput) when creating a cart with the [`cartCreate`](https://shopify.dev/docs/api/storefront/current/mutations/cartCreate) mutation.
    ///
    /// You can pre-select an address for the buyer, mark it as one-time use so it isn't saved after checkout, and specify how strictly the address should be validated.
    struct CartSelectableAddressInput: InputObject {
        private(set) var __data: InputDict

        init(_ data: InputDict) {
            __data = data
        }

        init(
            address: CartAddressInput,
            selected: GraphQLNullable<Bool> = nil,
            oneTimeUse: GraphQLNullable<Bool> = nil,
            validationStrategy: GraphQLNullable<GraphQLEnum<DeliveryAddressValidationStrategy>> = nil
        ) {
            __data = InputDict([
                "address": address,
                "selected": selected,
                "oneTimeUse": oneTimeUse,
                "validationStrategy": validationStrategy
            ])
        }

        /// Exactly one kind of delivery address.
        var address: CartAddressInput {
            get { __data["address"] }
            set { __data["address"] = newValue }
        }

        /// Sets exactly one address as pre-selected for the buyer.
        var selected: GraphQLNullable<Bool> {
            get { __data["selected"] }
            set { __data["selected"] = newValue }
        }

        /// When true, this delivery address will not be associated with the buyer after a successful checkout.
        var oneTimeUse: GraphQLNullable<Bool> {
            get { __data["oneTimeUse"] }
            set { __data["oneTimeUse"] = newValue }
        }

        /// Defines what kind of address validation is requested.
        var validationStrategy: GraphQLNullable<GraphQLEnum<DeliveryAddressValidationStrategy>> {
            get { __data["validationStrategy"] }
            set { __data["validationStrategy"] = newValue }
        }
    }
}
