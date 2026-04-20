// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension Storefront {
    struct CartLinesAddMutation: GraphQLMutation {
        static let operationName: String = "CartLinesAdd"
        static let operationDocument: ApolloAPI.OperationDocument = .init(
            definition: .init(
                #"mutation CartLinesAdd($cartId: ID!, $lines: [CartLineInput!]!, $country: CountryCode!, $language: LanguageCode!) @inContext(country: $country, language: $language) { cartLinesAdd(cartId: $cartId, lines: $lines) { __typename cart { __typename ...CartFragment } userErrors { __typename ...CartUserErrorFragment } } }"#,
                fragments: [CartDeliveryGroupFragment.self, CartFragment.self, CartLineFragment.self, CartUserErrorFragment.self]
            )
        )

        public var cartId: ID
        public var lines: [CartLineInput]
        public var country: GraphQLEnum<CountryCode>
        public var language: GraphQLEnum<LanguageCode>

        public init(
            cartId: ID,
            lines: [CartLineInput],
            country: GraphQLEnum<CountryCode>,
            language: GraphQLEnum<LanguageCode>
        ) {
            self.cartId = cartId
            self.lines = lines
            self.country = country
            self.language = language
        }

        @_spi(Unsafe) public var __variables: Variables? {
            [
                "cartId": cartId,
                "lines": lines,
                "country": country,
                "language": language
            ]
        }

        struct Data: Storefront.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) {
                __data = _dataDict
            }

            static var __parentType: any ApolloAPI.ParentType {
                Storefront.Objects.Mutation
            }

            static var __selections: [ApolloAPI.Selection] {
                [
                    .field("cartLinesAdd", CartLinesAdd?.self, arguments: [
                        "cartId": .variable("cartId"),
                        "lines": .variable("lines")
                    ])
                ]
            }

            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
                [
                    CartLinesAddMutation.Data.self
                ]
            }

            /// Adds one or more merchandise lines to an existing [`Cart`](https://shopify.dev/docs/api/storefront/current/objects/Cart). Each line specifies the [product variant](https://shopify.dev/docs/api/storefront/current/objects/ProductVariant) to purchase. Quantity defaults to `1` if not provided.
            ///
            /// You can add up to 250 lines in a single request. Use [`CartLineInput`](https://shopify.dev/docs/api/storefront/current/input-objects/CartLineInput) to configure each line's merchandise, quantity, selling plan, custom attributes, and any parent relationships for nested line items such as warranties or add-ons.
            var cartLinesAdd: CartLinesAdd? {
                __data["cartLinesAdd"]
            }

            /// CartLinesAdd
            ///
            /// Parent Type: `CartLinesAddPayload`
            struct CartLinesAdd: Storefront.SelectionSet {
                let __data: DataDict
                init(_dataDict: DataDict) {
                    __data = _dataDict
                }

                static var __parentType: any ApolloAPI.ParentType {
                    Storefront.Objects.CartLinesAddPayload
                }

                static var __selections: [ApolloAPI.Selection] {
                    [
                        .field("__typename", String.self),
                        .field("cart", Cart?.self),
                        .field("userErrors", [UserError].self)
                    ]
                }

                static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
                    [
                        CartLinesAddMutation.Data.CartLinesAdd.self
                    ]
                }

                /// The updated cart.
                var cart: Cart? {
                    __data["cart"]
                }

                /// The list of errors that occurred from executing the mutation.
                var userErrors: [UserError] {
                    __data["userErrors"]
                }

                /// CartLinesAdd.Cart
                ///
                /// Parent Type: `Cart`
                struct Cart: Storefront.SelectionSet {
                    let __data: DataDict
                    init(_dataDict: DataDict) {
                        __data = _dataDict
                    }

                    static var __parentType: any ApolloAPI.ParentType {
                        Storefront.Objects.Cart
                    }

                    static var __selections: [ApolloAPI.Selection] {
                        [
                            .field("__typename", String.self),
                            .fragment(CartFragment.self)
                        ]
                    }

                    static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
                        [
                            CartLinesAddMutation.Data.CartLinesAdd.Cart.self,
                            CartFragment.self
                        ]
                    }

                    /// A globally-unique ID.
                    var id: Storefront.ID {
                        __data["id"]
                    }

                    /// The URL of the checkout for the cart.
                    var checkoutUrl: Storefront.URL {
                        __data["checkoutUrl"]
                    }

                    /// The total number of items in the cart.
                    var totalQuantity: Int {
                        __data["totalQuantity"]
                    }

                    /// Information about the buyer that's interacting with the cart.
                    var buyerIdentity: BuyerIdentity {
                        __data["buyerIdentity"]
                    }

                    /// The delivery groups available for the cart, based on the buyer identity default
                    /// delivery address preference or the default address of the logged-in customer.
                    var deliveryGroups: DeliveryGroups {
                        __data["deliveryGroups"]
                    }

                    /// A list of lines containing information about the items the customer intends to purchase.
                    var lines: Lines {
                        __data["lines"]
                    }

                    /// The estimated costs that the buyer will pay at checkout. The costs are subject to change and changes will be reflected at checkout. The `cost` field uses the `buyerIdentity` field to determine [international pricing](https://shopify.dev/custom-storefronts/internationalization/international-pricing).
                    var cost: Cost {
                        __data["cost"]
                    }

                    struct Fragments: FragmentContainer {
                        let __data: DataDict
                        init(_dataDict: DataDict) {
                            __data = _dataDict
                        }

                        var cartFragment: CartFragment {
                            _toFragment()
                        }
                    }

                    typealias BuyerIdentity = CartFragment.BuyerIdentity

                    typealias DeliveryGroups = CartFragment.DeliveryGroups

                    typealias Lines = CartFragment.Lines

                    typealias Cost = CartFragment.Cost
                }

                /// CartLinesAdd.UserError
                ///
                /// Parent Type: `CartUserError`
                struct UserError: Storefront.SelectionSet {
                    let __data: DataDict
                    init(_dataDict: DataDict) {
                        __data = _dataDict
                    }

                    static var __parentType: any ApolloAPI.ParentType {
                        Storefront.Objects.CartUserError
                    }

                    static var __selections: [ApolloAPI.Selection] {
                        [
                            .field("__typename", String.self),
                            .fragment(CartUserErrorFragment.self)
                        ]
                    }

                    static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
                        [
                            CartLinesAddMutation.Data.CartLinesAdd.UserError.self,
                            CartUserErrorFragment.self
                        ]
                    }

                    /// The error code.
                    var code: GraphQLEnum<Storefront.CartErrorCode>? {
                        __data["code"]
                    }

                    /// The error message.
                    var message: String {
                        __data["message"]
                    }

                    /// The path to the input field that caused the error.
                    var field: [String]? {
                        __data["field"]
                    }

                    struct Fragments: FragmentContainer {
                        let __data: DataDict
                        init(_dataDict: DataDict) {
                            __data = _dataDict
                        }

                        var cartUserErrorFragment: CartUserErrorFragment {
                            _toFragment()
                        }
                    }
                }
            }
        }
    }
}
