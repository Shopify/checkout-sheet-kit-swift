/*
 MIT License

 Copyright 2023 - Present, Shopify Inc.

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

@_exported import ApolloAPI

extension Storefront {
    class GetCartQuery: GraphQLQuery {
        static let operationName: String = "GetCart"
        static let operationDocument: ApolloAPI.OperationDocument = .init(
            definition: .init(
                #"query GetCart($id: ID!, $country: CountryCode!, $language: LanguageCode!) @inContext(country: $country, language: $language) { cart(id: $id) { __typename ...CartFragment } }"#,
                fragments: [CartDeliveryGroupFragment.self, CartFragment.self, CartLineFragment.self]
            ))

        var id: ID
        var country: GraphQLEnum<CountryCode>
        var language: GraphQLEnum<LanguageCode>

        init(
            id: ID,
            country: GraphQLEnum<CountryCode>,
            language: GraphQLEnum<LanguageCode>
        ) {
            self.id = id
            self.country = country
            self.language = language
        }

        var __variables: Variables? { [
            "id": id,
            "country": country,
            "language": language
        ] }

        struct Data: Storefront.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { Storefront.Objects.QueryRoot }
            static var __selections: [ApolloAPI.Selection] { [
                .field("cart", Cart?.self, arguments: ["id": .variable("id")])
            ] }

            /// Retrieve a cart by its ID. For more information, refer to
            /// [Manage a cart with the Storefront API](https://shopify.dev/custom-storefronts/cart/manage).
            var cart: Cart? { __data["cart"] }

            /// Cart
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
        }
    }
}
