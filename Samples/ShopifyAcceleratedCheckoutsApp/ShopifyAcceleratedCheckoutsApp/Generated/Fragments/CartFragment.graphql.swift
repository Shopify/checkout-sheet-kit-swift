// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension Storefront {
    struct CartFragment: Storefront.SelectionSet, Fragment {
        static var fragmentDefinition: StaticString {
            #"fragment CartFragment on Cart { __typename id checkoutUrl totalQuantity buyerIdentity { __typename email phone customer { __typename email phone } } deliveryGroups(first: 10) { __typename nodes { __typename ...CartDeliveryGroupFragment } } lines(first: 250) { __typename nodes { __typename ...CartLineFragment } } cost { __typename totalAmount { __typename amount currencyCode } subtotalAmount { __typename amount currencyCode } totalTaxAmount { __typename amount currencyCode } } }"#
        }

        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { Storefront.Objects.Cart }
        static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", Storefront.ID.self),
            .field("checkoutUrl", Storefront.URL.self),
            .field("totalQuantity", Int.self),
            .field("buyerIdentity", BuyerIdentity.self),
            .field("deliveryGroups", DeliveryGroups.self, arguments: ["first": 10]),
            .field("lines", Lines.self, arguments: ["first": 250]),
            .field("cost", Cost.self)
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

        /// BuyerIdentity
        ///
        /// Parent Type: `CartBuyerIdentity`
        struct BuyerIdentity: Storefront.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { Storefront.Objects.CartBuyerIdentity }
            static var __selections: [ApolloAPI.Selection] { [
                .field("__typename", String.self),
                .field("email", String?.self),
                .field("phone", String?.self),
                .field("customer", Customer?.self)
            ] }

            /// The email address of the buyer that's interacting with the cart.
            var email: String? { __data["email"] }
            /// The phone number of the buyer that's interacting with the cart.
            var phone: String? { __data["phone"] }
            /// The customer account associated with the cart.
            var customer: Customer? { __data["customer"] }

            /// BuyerIdentity.Customer
            ///
            /// Parent Type: `Customer`
            struct Customer: Storefront.SelectionSet {
                let __data: DataDict
                init(_dataDict: DataDict) { __data = _dataDict }

                static var __parentType: any ApolloAPI.ParentType { Storefront.Objects.Customer }
                static var __selections: [ApolloAPI.Selection] { [
                    .field("__typename", String.self),
                    .field("email", String?.self),
                    .field("phone", String?.self)
                ] }

                /// The customer’s email address.
                var email: String? { __data["email"] }
                /// The customer’s phone number.
                var phone: String? { __data["phone"] }
            }
        }

        /// DeliveryGroups
        ///
        /// Parent Type: `CartDeliveryGroupConnection`
        struct DeliveryGroups: Storefront.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { Storefront.Objects.CartDeliveryGroupConnection }
            static var __selections: [ApolloAPI.Selection] { [
                .field("__typename", String.self),
                .field("nodes", [Node].self)
            ] }

            /// A list of the nodes contained in CartDeliveryGroupEdge.
            var nodes: [Node] { __data["nodes"] }

            /// DeliveryGroups.Node
            ///
            /// Parent Type: `CartDeliveryGroup`
            struct Node: Storefront.SelectionSet {
                let __data: DataDict
                init(_dataDict: DataDict) { __data = _dataDict }

                static var __parentType: any ApolloAPI.ParentType { Storefront.Objects.CartDeliveryGroup }
                static var __selections: [ApolloAPI.Selection] { [
                    .field("__typename", String.self),
                    .fragment(CartDeliveryGroupFragment.self)
                ] }

                /// The ID for the delivery group.
                var id: Storefront.ID { __data["id"] }
                /// The type of merchandise in the delivery group.
                var groupType: GraphQLEnum<Storefront.CartDeliveryGroupType> { __data["groupType"] }
                /// The destination address for the delivery group.
                var deliveryAddress: DeliveryAddress { __data["deliveryAddress"] }
                /// The delivery options available for the delivery group.
                var deliveryOptions: [DeliveryOption] { __data["deliveryOptions"] }
                /// The selected delivery option for the delivery group.
                var selectedDeliveryOption: SelectedDeliveryOption? { __data["selectedDeliveryOption"] }

                struct Fragments: FragmentContainer {
                    let __data: DataDict
                    init(_dataDict: DataDict) { __data = _dataDict }

                    var cartDeliveryGroupFragment: CartDeliveryGroupFragment { _toFragment() }
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
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { Storefront.Objects.BaseCartLineConnection }
            static var __selections: [ApolloAPI.Selection] { [
                .field("__typename", String.self),
                .field("nodes", [Node].self)
            ] }

            /// A list of the nodes contained in BaseCartLineEdge.
            var nodes: [Node] { __data["nodes"] }

            /// Lines.Node
            ///
            /// Parent Type: `BaseCartLine`
            struct Node: Storefront.SelectionSet {
                let __data: DataDict
                init(_dataDict: DataDict) { __data = _dataDict }

                static var __parentType: any ApolloAPI.ParentType { Storefront.Interfaces.BaseCartLine }
                static var __selections: [ApolloAPI.Selection] { [
                    .field("__typename", String.self),
                    .fragment(CartLineFragment.self)
                ] }

                /// A globally-unique ID.
                var id: Storefront.ID { __data["id"] }
                /// The quantity of the merchandise that the customer intends to purchase.
                var quantity: Int { __data["quantity"] }
                /// The merchandise that the buyer intends to purchase.
                var merchandise: Merchandise { __data["merchandise"] }
                /// The cost of the merchandise that the buyer will pay for at checkout. The costs are subject to change and changes will be reflected at checkout.
                var cost: Cost { __data["cost"] }

                struct Fragments: FragmentContainer {
                    let __data: DataDict
                    init(_dataDict: DataDict) { __data = _dataDict }

                    var cartLineFragment: CartLineFragment { _toFragment() }
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
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { Storefront.Objects.CartCost }
            static var __selections: [ApolloAPI.Selection] { [
                .field("__typename", String.self),
                .field("totalAmount", TotalAmount.self),
                .field("subtotalAmount", SubtotalAmount.self),
                .field("totalTaxAmount", TotalTaxAmount?.self)
            ] }

            /// The total amount for the customer to pay.
            var totalAmount: TotalAmount { __data["totalAmount"] }
            /// The amount, before taxes and cart-level discounts, for the customer to pay.
            var subtotalAmount: SubtotalAmount { __data["subtotalAmount"] }
            /// The tax amount for the customer to pay at checkout.
            @available(*, deprecated, message: "Tax and duty amounts are no longer available and will be removed in a future version.\nPlease see [the changelog](https://shopify.dev/changelog/tax-and-duties-are-deprecated-in-storefront-cart-api)\nfor more information.")
            var totalTaxAmount: TotalTaxAmount? { __data["totalTaxAmount"] }

            /// Cost.TotalAmount
            ///
            /// Parent Type: `MoneyV2`
            struct TotalAmount: Storefront.SelectionSet {
                let __data: DataDict
                init(_dataDict: DataDict) { __data = _dataDict }

                static var __parentType: any ApolloAPI.ParentType { Storefront.Objects.MoneyV2 }
                static var __selections: [ApolloAPI.Selection] { [
                    .field("__typename", String.self),
                    .field("amount", Storefront.Decimal.self),
                    .field("currencyCode", GraphQLEnum<Storefront.CurrencyCode>.self)
                ] }

                /// Decimal money amount.
                var amount: Storefront.Decimal { __data["amount"] }
                /// Currency of the money.
                var currencyCode: GraphQLEnum<Storefront.CurrencyCode> { __data["currencyCode"] }
            }

            /// Cost.SubtotalAmount
            ///
            /// Parent Type: `MoneyV2`
            struct SubtotalAmount: Storefront.SelectionSet {
                let __data: DataDict
                init(_dataDict: DataDict) { __data = _dataDict }

                static var __parentType: any ApolloAPI.ParentType { Storefront.Objects.MoneyV2 }
                static var __selections: [ApolloAPI.Selection] { [
                    .field("__typename", String.self),
                    .field("amount", Storefront.Decimal.self),
                    .field("currencyCode", GraphQLEnum<Storefront.CurrencyCode>.self)
                ] }

                /// Decimal money amount.
                var amount: Storefront.Decimal { __data["amount"] }
                /// Currency of the money.
                var currencyCode: GraphQLEnum<Storefront.CurrencyCode> { __data["currencyCode"] }
            }

            /// Cost.TotalTaxAmount
            ///
            /// Parent Type: `MoneyV2`
            struct TotalTaxAmount: Storefront.SelectionSet {
                let __data: DataDict
                init(_dataDict: DataDict) { __data = _dataDict }

                static var __parentType: any ApolloAPI.ParentType { Storefront.Objects.MoneyV2 }
                static var __selections: [ApolloAPI.Selection] { [
                    .field("__typename", String.self),
                    .field("amount", Storefront.Decimal.self),
                    .field("currencyCode", GraphQLEnum<Storefront.CurrencyCode>.self)
                ] }

                /// Decimal money amount.
                var amount: Storefront.Decimal { __data["amount"] }
                /// Currency of the money.
                var currencyCode: GraphQLEnum<Storefront.CurrencyCode> { __data["currencyCode"] }
            }
        }
    }
}
