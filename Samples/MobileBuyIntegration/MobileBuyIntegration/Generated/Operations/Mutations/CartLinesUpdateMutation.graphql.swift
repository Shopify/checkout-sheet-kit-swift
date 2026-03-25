// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension Storefront {
    struct CartLinesUpdateMutation: GraphQLMutation {
        static let operationName: String = "CartLinesUpdate"
        static let operationDocument: ApolloAPI.OperationDocument = .init(
            definition: .init(
                #"mutation CartLinesUpdate($cartId: ID!, $lines: [CartLineUpdateInput!]!, $country: CountryCode!, $language: LanguageCode!) @inContext(country: $country, language: $language) { cartLinesUpdate(cartId: $cartId, lines: $lines) { __typename cart { __typename ...CartFragment } userErrors { __typename ...CartUserErrorFragment } } }"#,
                fragments: [CartDeliveryGroupFragment.self, CartFragment.self, CartLineFragment.self, CartUserErrorFragment.self]
            ))

        public var cartId: ID
        public var lines: [CartLineUpdateInput]
        public var country: GraphQLEnum<CountryCode>
        public var language: GraphQLEnum<LanguageCode>

        public init(
            cartId: ID,
            lines: [CartLineUpdateInput],
            country: GraphQLEnum<CountryCode>,
            language: GraphQLEnum<LanguageCode>
        ) {
            self.cartId = cartId
            self.lines = lines
            self.country = country
            self.language = language
        }

        @_spi(Unsafe) public var __variables: Variables? { [
            "cartId": cartId,
            "lines": lines,
            "country": country,
            "language": language
        ] }

        struct Data: Storefront.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { Storefront.Objects.Mutation }
            static var __selections: [ApolloAPI.Selection] { [
                .field("cartLinesUpdate", CartLinesUpdate?.self, arguments: [
                    "cartId": .variable("cartId"),
                    "lines": .variable("lines")
                ])
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                CartLinesUpdateMutation.Data.self
            ] }

            /// Updates one or more merchandise lines on a [`Cart`](https://shopify.dev/docs/api/storefront/current/objects/Cart). You can modify the quantity, swap the merchandise, change custom attributes, or update the selling plan for each line. You can update a maximum of 250 lines per request.
            ///
            /// Omitting the [`attributes`](https://shopify.dev/docs/api/storefront/current/mutations/cartLinesUpdate#arguments-lines.fields.attributes) field or setting it to null preserves existing line attributes. Pass an empty array to clear all attributes from a line.
            var cartLinesUpdate: CartLinesUpdate? { __data["cartLinesUpdate"] }

            /// CartLinesUpdate
            ///
            /// Parent Type: `CartLinesUpdatePayload`
            struct CartLinesUpdate: Storefront.SelectionSet {
                let __data: DataDict
                init(_dataDict: DataDict) { __data = _dataDict }

                static var __parentType: any ApolloAPI.ParentType { Storefront.Objects.CartLinesUpdatePayload }
                static var __selections: [ApolloAPI.Selection] { [
                    .field("__typename", String.self),
                    .field("cart", Cart?.self),
                    .field("userErrors", [UserError].self)
                ] }
                static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                    CartLinesUpdateMutation.Data.CartLinesUpdate.self
                ] }

                /// The updated cart.
                var cart: Cart? { __data["cart"] }
                /// The list of errors that occurred from executing the mutation.
                var userErrors: [UserError] { __data["userErrors"] }

                /// CartLinesUpdate.Cart
                ///
                /// Parent Type: `Cart`
                struct Cart: Storefront.SelectionSet {
                    let __data: DataDict
                    init(_dataDict: DataDict) { __data = _dataDict }

                    static var __parentType: any ApolloAPI.ParentType { Storefront.Objects.Cart }
                    static var __selections: [ApolloAPI.Selection] { [
                        .field("__typename", String.self),
                        .fragment(CartFragment.self)
                    ] }
                    static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                        CartLinesUpdateMutation.Data.CartLinesUpdate.Cart.self,
                        CartFragment.self
                    ] }

                    /// A globally-unique ID.
                    var id: Storefront.ID { __data["id"] }
                    /// The URL of the checkout for the cart.
                    var checkoutUrl: Storefront.URL { __data["checkoutUrl"] }
                    /// The total number of items in the cart.
                    var totalQuantity: Int { __data["totalQuantity"] }
                    /// Information about the buyer that's interacting with the cart.
                    var buyerIdentity: BuyerIdentity { __data["buyerIdentity"] }
                    /// The delivery groups available for the cart, based on the buyer identity default
                    /// delivery address preference or the default address of the logged-in customer.
                    var deliveryGroups: DeliveryGroups { __data["deliveryGroups"] }
                    /// A list of lines containing information about the items the customer intends to purchase.
                    var lines: Lines { __data["lines"] }
                    /// The estimated costs that the buyer will pay at checkout. The costs are subject to change and changes will be reflected at checkout. The `cost` field uses the `buyerIdentity` field to determine [international pricing](https://shopify.dev/custom-storefronts/internationalization/international-pricing).
                    var cost: Cost { __data["cost"] }

                    struct Fragments: FragmentContainer {
                        let __data: DataDict
                        init(_dataDict: DataDict) { __data = _dataDict }

                        var cartFragment: CartFragment { _toFragment() }
                    }

                    typealias BuyerIdentity = CartFragment.BuyerIdentity

                    typealias DeliveryGroups = CartFragment.DeliveryGroups

                    typealias Lines = CartFragment.Lines

                    typealias Cost = CartFragment.Cost
                }

                /// CartLinesUpdate.UserError
                ///
                /// Parent Type: `CartUserError`
                struct UserError: Storefront.SelectionSet {
                    let __data: DataDict
                    init(_dataDict: DataDict) { __data = _dataDict }

                    static var __parentType: any ApolloAPI.ParentType { Storefront.Objects.CartUserError }
                    static var __selections: [ApolloAPI.Selection] { [
                        .field("__typename", String.self),
                        .fragment(CartUserErrorFragment.self)
                    ] }
                    static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                        CartLinesUpdateMutation.Data.CartLinesUpdate.UserError.self,
                        CartUserErrorFragment.self
                    ] }

                    /// The error code.
                    var code: GraphQLEnum<Storefront.CartErrorCode>? { __data["code"] }
                    /// The error message.
                    var message: String { __data["message"] }
                    /// The path to the input field that caused the error.
                    var field: [String]? { __data["field"] }

                    struct Fragments: FragmentContainer {
                        let __data: DataDict
                        init(_dataDict: DataDict) { __data = _dataDict }

                        var cartUserErrorFragment: CartUserErrorFragment { _toFragment() }
                    }
                }
            }
        }
    }
}
