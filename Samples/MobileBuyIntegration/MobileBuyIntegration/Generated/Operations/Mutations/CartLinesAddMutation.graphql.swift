// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension Storefront {
    class CartLinesAddMutation: GraphQLMutation {
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

        public var __variables: Variables? {
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

                var cart: Cart? {
                    __data["cart"]
                }

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

                    var id: Storefront.ID {
                        __data["id"]
                    }

                    var checkoutUrl: String {
                        __data["checkoutUrl"]
                    }

                    var totalQuantity: Int {
                        __data["totalQuantity"]
                    }

                    var buyerIdentity: BuyerIdentity {
                        __data["buyerIdentity"]
                    }

                    var deliveryGroups: DeliveryGroups {
                        __data["deliveryGroups"]
                    }

                    var lines: Lines {
                        __data["lines"]
                    }

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

                    var code: String? {
                        __data["code"]
                    }

                    var message: String {
                        __data["message"]
                    }

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
