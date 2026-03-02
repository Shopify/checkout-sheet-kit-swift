// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension Storefront {
    class CartCreateMutation: GraphQLMutation {
        static let operationName: String = "CartCreate"
        static let operationDocument: ApolloAPI.OperationDocument = .init(
            definition: .init(
                #"mutation CartCreate($input: CartInput!, $country: CountryCode!, $language: LanguageCode!) @inContext(country: $country, language: $language) { cartCreate(input: $input) { __typename cart { __typename ...CartFragment } userErrors { __typename ...CartUserErrorFragment } } }"#,
                fragments: [CartDeliveryGroupFragment.self, CartFragment.self, CartLineFragment.self, CartUserErrorFragment.self]
            )
        )

        public var input: CartInput
        public var country: GraphQLEnum<CountryCode>
        public var language: GraphQLEnum<LanguageCode>

        public init(
            input: CartInput,
            country: GraphQLEnum<CountryCode>,
            language: GraphQLEnum<LanguageCode>
        ) {
            self.input = input
            self.country = country
            self.language = language
        }

        public var __variables: Variables? {
            [
                "input": input,
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
                    .field("cartCreate", CartCreate?.self, arguments: ["input": .variable("input")])
                ]
            }

            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
                [
                    CartCreateMutation.Data.self
                ]
            }

            var cartCreate: CartCreate? {
                __data["cartCreate"]
            }

            /// CartCreate
            ///
            /// Parent Type: `CartCreatePayload`
            struct CartCreate: Storefront.SelectionSet {
                let __data: DataDict
                init(_dataDict: DataDict) {
                    __data = _dataDict
                }

                static var __parentType: any ApolloAPI.ParentType {
                    Storefront.Objects.CartCreatePayload
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
                        CartCreateMutation.Data.CartCreate.self
                    ]
                }

                var cart: Cart? {
                    __data["cart"]
                }

                var userErrors: [UserError] {
                    __data["userErrors"]
                }

                /// CartCreate.Cart
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
                            CartCreateMutation.Data.CartCreate.Cart.self,
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

                /// CartCreate.UserError
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
                            CartCreateMutation.Data.CartCreate.UserError.self,
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
