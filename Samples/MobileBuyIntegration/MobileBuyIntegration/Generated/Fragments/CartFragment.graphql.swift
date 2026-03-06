// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension Storefront {
    struct CartFragment: Storefront.SelectionSet, Fragment {
        static var fragmentDefinition: StaticString {
            #"fragment CartFragment on Cart { __typename id checkoutUrl totalQuantity buyerIdentity { __typename email phone customer { __typename email phone } } deliveryGroups(first: 10) { __typename nodes { __typename ...CartDeliveryGroupFragment } } lines(first: 250) { __typename nodes { __typename ...CartLineFragment } } cost { __typename totalAmount { __typename amount currencyCode } subtotalAmount { __typename amount currencyCode } totalTaxAmount { __typename amount currencyCode } } }"#
        }

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
                .field("id", Storefront.ID.self),
                .field("checkoutUrl", String.self),
                .field("totalQuantity", Int.self),
                .field("buyerIdentity", BuyerIdentity.self),
                .field("deliveryGroups", DeliveryGroups.self, arguments: ["first": 10]),
                .field("lines", Lines.self, arguments: ["first": 250]),
                .field("cost", Cost.self)
            ]
        }

        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
            [
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

        /// BuyerIdentity
        ///
        /// Parent Type: `CartBuyerIdentity`
        struct BuyerIdentity: Storefront.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) {
                __data = _dataDict
            }

            static var __parentType: any ApolloAPI.ParentType {
                Storefront.Objects.CartBuyerIdentity
            }

            static var __selections: [ApolloAPI.Selection] {
                [
                    .field("__typename", String.self),
                    .field("email", String?.self),
                    .field("phone", String?.self),
                    .field("customer", Customer?.self)
                ]
            }

            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
                [
                    CartFragment.BuyerIdentity.self
                ]
            }

            var email: String? {
                __data["email"]
            }

            var phone: String? {
                __data["phone"]
            }

            var customer: Customer? {
                __data["customer"]
            }

            /// BuyerIdentity.Customer
            ///
            /// Parent Type: `Customer`
            struct Customer: Storefront.SelectionSet {
                let __data: DataDict
                init(_dataDict: DataDict) {
                    __data = _dataDict
                }

                static var __parentType: any ApolloAPI.ParentType {
                    Storefront.Objects.Customer
                }

                static var __selections: [ApolloAPI.Selection] {
                    [
                        .field("__typename", String.self),
                        .field("email", String?.self),
                        .field("phone", String?.self)
                    ]
                }

                static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
                    [
                        CartFragment.BuyerIdentity.Customer.self
                    ]
                }

                var email: String? {
                    __data["email"]
                }

                var phone: String? {
                    __data["phone"]
                }
            }
        }

        /// DeliveryGroups
        ///
        /// Parent Type: `CartDeliveryGroupConnection`
        struct DeliveryGroups: Storefront.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) {
                __data = _dataDict
            }

            static var __parentType: any ApolloAPI.ParentType {
                Storefront.Objects.CartDeliveryGroupConnection
            }

            static var __selections: [ApolloAPI.Selection] {
                [
                    .field("__typename", String.self),
                    .field("nodes", [Node].self)
                ]
            }

            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
                [
                    CartFragment.DeliveryGroups.self
                ]
            }

            var nodes: [Node] {
                __data["nodes"]
            }

            /// DeliveryGroups.Node
            ///
            /// Parent Type: `CartDeliveryGroup`
            struct Node: Storefront.SelectionSet {
                let __data: DataDict
                init(_dataDict: DataDict) {
                    __data = _dataDict
                }

                static var __parentType: any ApolloAPI.ParentType {
                    Storefront.Objects.CartDeliveryGroup
                }

                static var __selections: [ApolloAPI.Selection] {
                    [
                        .field("__typename", String.self),
                        .fragment(CartDeliveryGroupFragment.self)
                    ]
                }

                static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
                    [
                        CartFragment.DeliveryGroups.Node.self,
                        CartDeliveryGroupFragment.self
                    ]
                }

                var id: Storefront.ID {
                    __data["id"]
                }

                var groupType: GraphQLEnum<Storefront.CartDeliveryGroupType>? {
                    __data["groupType"]
                }

                var deliveryAddress: DeliveryAddress? {
                    __data["deliveryAddress"]
                }

                var deliveryOptions: [DeliveryOption] {
                    __data["deliveryOptions"]
                }

                var selectedDeliveryOption: SelectedDeliveryOption? {
                    __data["selectedDeliveryOption"]
                }

                struct Fragments: FragmentContainer {
                    let __data: DataDict
                    init(_dataDict: DataDict) {
                        __data = _dataDict
                    }

                    var cartDeliveryGroupFragment: CartDeliveryGroupFragment {
                        _toFragment()
                    }
                }

                typealias DeliveryAddress = CartDeliveryGroupFragment.DeliveryAddress

                typealias DeliveryOption = CartDeliveryGroupFragment.DeliveryOption

                typealias SelectedDeliveryOption = CartDeliveryGroupFragment.SelectedDeliveryOption
            }
        }

        /// Lines
        ///
        /// Parent Type: `BaseCartLineConnection`
        struct Lines: Storefront.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) {
                __data = _dataDict
            }

            static var __parentType: any ApolloAPI.ParentType {
                Storefront.Objects.BaseCartLineConnection
            }

            static var __selections: [ApolloAPI.Selection] {
                [
                    .field("__typename", String.self),
                    .field("nodes", [Node].self)
                ]
            }

            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
                [
                    CartFragment.Lines.self
                ]
            }

            var nodes: [Node] {
                __data["nodes"]
            }

            /// Lines.Node
            ///
            /// Parent Type: `BaseCartLine`
            struct Node: Storefront.SelectionSet {
                let __data: DataDict
                init(_dataDict: DataDict) {
                    __data = _dataDict
                }

                static var __parentType: any ApolloAPI.ParentType {
                    Storefront.Interfaces.BaseCartLine
                }

                static var __selections: [ApolloAPI.Selection] {
                    [
                        .field("__typename", String.self),
                        .fragment(CartLineFragment.self)
                    ]
                }

                static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
                    [
                        CartFragment.Lines.Node.self,
                        CartLineFragment.self
                    ]
                }

                var id: Storefront.ID {
                    __data["id"]
                }

                var quantity: Int {
                    __data["quantity"]
                }

                var merchandise: Merchandise {
                    __data["merchandise"]
                }

                var cost: Cost {
                    __data["cost"]
                }

                struct Fragments: FragmentContainer {
                    let __data: DataDict
                    init(_dataDict: DataDict) {
                        __data = _dataDict
                    }

                    var cartLineFragment: CartLineFragment {
                        _toFragment()
                    }
                }

                typealias Merchandise = CartLineFragment.Merchandise

                typealias Cost = CartLineFragment.Cost
            }
        }

        /// Cost
        ///
        /// Parent Type: `CartCost`
        struct Cost: Storefront.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) {
                __data = _dataDict
            }

            static var __parentType: any ApolloAPI.ParentType {
                Storefront.Objects.CartCost
            }

            static var __selections: [ApolloAPI.Selection] {
                [
                    .field("__typename", String.self),
                    .field("totalAmount", TotalAmount.self),
                    .field("subtotalAmount", SubtotalAmount.self),
                    .field("totalTaxAmount", TotalTaxAmount?.self)
                ]
            }

            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
                [
                    CartFragment.Cost.self
                ]
            }

            var totalAmount: TotalAmount {
                __data["totalAmount"]
            }

            var subtotalAmount: SubtotalAmount {
                __data["subtotalAmount"]
            }

            var totalTaxAmount: TotalTaxAmount? {
                __data["totalTaxAmount"]
            }

            /// Cost.TotalAmount
            ///
            /// Parent Type: `MoneyV2`
            struct TotalAmount: Storefront.SelectionSet {
                let __data: DataDict
                init(_dataDict: DataDict) {
                    __data = _dataDict
                }

                static var __parentType: any ApolloAPI.ParentType {
                    Storefront.Objects.MoneyV2
                }

                static var __selections: [ApolloAPI.Selection] {
                    [
                        .field("__typename", String.self),
                        .field("amount", String.self),
                        .field("currencyCode", GraphQLEnum<Storefront.CurrencyCode>.self)
                    ]
                }

                static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
                    [
                        CartFragment.Cost.TotalAmount.self
                    ]
                }

                var amount: String {
                    __data["amount"]
                }

                var currencyCode: GraphQLEnum<Storefront.CurrencyCode> {
                    __data["currencyCode"]
                }
            }

            /// Cost.SubtotalAmount
            ///
            /// Parent Type: `MoneyV2`
            struct SubtotalAmount: Storefront.SelectionSet {
                let __data: DataDict
                init(_dataDict: DataDict) {
                    __data = _dataDict
                }

                static var __parentType: any ApolloAPI.ParentType {
                    Storefront.Objects.MoneyV2
                }

                static var __selections: [ApolloAPI.Selection] {
                    [
                        .field("__typename", String.self),
                        .field("amount", String.self),
                        .field("currencyCode", GraphQLEnum<Storefront.CurrencyCode>.self)
                    ]
                }

                static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
                    [
                        CartFragment.Cost.SubtotalAmount.self
                    ]
                }

                var amount: String {
                    __data["amount"]
                }

                var currencyCode: GraphQLEnum<Storefront.CurrencyCode> {
                    __data["currencyCode"]
                }
            }

            /// Cost.TotalTaxAmount
            ///
            /// Parent Type: `MoneyV2`
            struct TotalTaxAmount: Storefront.SelectionSet {
                let __data: DataDict
                init(_dataDict: DataDict) {
                    __data = _dataDict
                }

                static var __parentType: any ApolloAPI.ParentType {
                    Storefront.Objects.MoneyV2
                }

                static var __selections: [ApolloAPI.Selection] {
                    [
                        .field("__typename", String.self),
                        .field("amount", String.self),
                        .field("currencyCode", GraphQLEnum<Storefront.CurrencyCode>.self)
                    ]
                }

                static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
                    [
                        CartFragment.Cost.TotalTaxAmount.self
                    ]
                }

                var amount: String {
                    __data["amount"]
                }

                var currencyCode: GraphQLEnum<Storefront.CurrencyCode> {
                    __data["currencyCode"]
                }
            }
        }
    }
}
