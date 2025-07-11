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
            ))

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

        public var __variables: Variables? { [
            "input": input,
            "country": country,
            "language": language
        ] }

        struct Data: Storefront.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { Storefront.Objects.Mutation }
            static var __selections: [ApolloAPI.Selection] { [
                .field("cartCreate", CartCreate?.self, arguments: ["input": .variable("input")])
            ] }

            /// Creates a new cart.
            var cartCreate: CartCreate? { __data["cartCreate"] }

            /// CartCreate
            ///
            /// Parent Type: `CartCreatePayload`
            struct CartCreate: Storefront.SelectionSet {
                let __data: DataDict
                init(_dataDict: DataDict) { __data = _dataDict }

                static var __parentType: any ApolloAPI.ParentType { Storefront.Objects.CartCreatePayload }
                static var __selections: [ApolloAPI.Selection] { [
                    .field("__typename", String.self),
                    .field("cart", Cart?.self),
                    .field("userErrors", [UserError].self)
                ] }

                /// The new cart.
                var cart: Cart? { __data["cart"] }
                /// The list of errors that occurred from executing the mutation.
                var userErrors: [UserError] { __data["userErrors"] }

                /// CartCreate.Cart
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

                /// CartCreate.UserError
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
