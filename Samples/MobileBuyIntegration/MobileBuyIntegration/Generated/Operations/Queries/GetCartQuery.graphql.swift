// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension Storefront {
    class GetCartQuery: GraphQLQuery {
        static let operationName: String = "GetCart"
        static let operationDocument: ApolloAPI.OperationDocument = .init(
            definition: .init(
                #"query GetCart($id: ID!, $country: CountryCode!, $language: LanguageCode!) @inContext(country: $country, language: $language) { cart(id: $id) { __typename ...CartFragment } }"#,
                fragments: [CartDeliveryGroupFragment.self, CartFragment.self, CartLineFragment.self]
            )
        )

        public var id: ID
        public var country: GraphQLEnum<CountryCode>
        public var language: GraphQLEnum<LanguageCode>

        public init(
            id: ID,
            country: GraphQLEnum<CountryCode>,
            language: GraphQLEnum<LanguageCode>
        ) {
            self.id = id
            self.country = country
            self.language = language
        }

        public var __variables: Variables? {
            [
                "id": id,
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
                Storefront.Objects.Query
            }

            static var __selections: [ApolloAPI.Selection] {
                [
                    .field("cart", Cart?.self, arguments: ["id": .variable("id")])
                ]
            }

            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
                [
                    GetCartQuery.Data.self
                ]
            }

            var cart: Cart? {
                __data["cart"]
            }

            /// Cart
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
                        GetCartQuery.Data.Cart.self,
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
        }
    }
}
