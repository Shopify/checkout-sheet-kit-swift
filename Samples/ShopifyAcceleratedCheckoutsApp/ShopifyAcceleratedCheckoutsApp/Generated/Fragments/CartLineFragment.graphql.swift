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
    struct CartLineFragment: Storefront.SelectionSet, Fragment {
        static var fragmentDefinition: StaticString {
            #"fragment CartLineFragment on BaseCartLine { __typename id quantity merchandise { __typename ... on ProductVariant { id title image { __typename url } price { __typename amount currencyCode } product { __typename title vendor featuredImage { __typename url } } requiresShipping } } cost { __typename totalAmount { __typename amount currencyCode } } }"#
        }

        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { Storefront.Interfaces.BaseCartLine }
        static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", Storefront.ID.self),
            .field("quantity", Int.self),
            .field("merchandise", Merchandise.self),
            .field("cost", Cost.self)
        ] }

        /// A globally-unique ID.
        var id: Storefront.ID { __data["id"] }
        /// The quantity of the merchandise that the customer intends to purchase.
        var quantity: Int { __data["quantity"] }
        /// The merchandise that the buyer intends to purchase.
        var merchandise: Merchandise { __data["merchandise"] }
        /// The cost of the merchandise that the buyer will pay for at checkout. The costs are subject to change and changes will be reflected at checkout.
        var cost: Cost { __data["cost"] }

        /// Merchandise
        ///
        /// Parent Type: `Merchandise`
        struct Merchandise: Storefront.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { Storefront.Unions.Merchandise }
            static var __selections: [ApolloAPI.Selection] { [
                .field("__typename", String.self),
                .inlineFragment(AsProductVariant.self)
            ] }

            var asProductVariant: AsProductVariant? { _asInlineFragment() }

            /// Merchandise.AsProductVariant
            ///
            /// Parent Type: `ProductVariant`
            struct AsProductVariant: Storefront.InlineFragment {
                let __data: DataDict
                init(_dataDict: DataDict) { __data = _dataDict }

                typealias RootEntityType = CartLineFragment.Merchandise
                static var __parentType: any ApolloAPI.ParentType { Storefront.Objects.ProductVariant }
                static var __selections: [ApolloAPI.Selection] { [
                    .field("id", Storefront.ID.self),
                    .field("title", String.self),
                    .field("image", Image?.self),
                    .field("price", Price.self),
                    .field("product", Product.self),
                    .field("requiresShipping", Bool.self)
                ] }

                /// A globally-unique ID.
                var id: Storefront.ID { __data["id"] }
                /// The product variant’s title.
                var title: String { __data["title"] }
                /// Image associated with the product variant. This field falls back to the product image if no image is available.
                var image: Image? { __data["image"] }
                /// The product variant’s price.
                var price: Price { __data["price"] }
                /// The product object that the product variant belongs to.
                var product: Product { __data["product"] }
                /// Whether a customer needs to provide a shipping address when placing an order for the product variant.
                var requiresShipping: Bool { __data["requiresShipping"] }

                /// Merchandise.AsProductVariant.Image
                ///
                /// Parent Type: `Image`
                struct Image: Storefront.SelectionSet {
                    let __data: DataDict
                    init(_dataDict: DataDict) { __data = _dataDict }

                    static var __parentType: any ApolloAPI.ParentType { Storefront.Objects.Image }
                    static var __selections: [ApolloAPI.Selection] { [
                        .field("__typename", String.self),
                        .field("url", Storefront.URL.self)
                    ] }

                    /// The location of the image as a URL.
                    ///
                    /// If no transform options are specified, then the original image will be preserved including any pre-applied transforms.
                    ///
                    /// All transformation options are considered "best-effort". Any transformation that the original image type doesn't support will be ignored.
                    ///
                    /// If you need multiple variations of the same image, then you can use [GraphQL aliases](https://graphql.org/learn/queries/#aliases).
                    var url: Storefront.URL { __data["url"] }
                }

                /// Merchandise.AsProductVariant.Price
                ///
                /// Parent Type: `MoneyV2`
                struct Price: Storefront.SelectionSet {
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

                /// Merchandise.AsProductVariant.Product
                ///
                /// Parent Type: `Product`
                struct Product: Storefront.SelectionSet {
                    let __data: DataDict
                    init(_dataDict: DataDict) { __data = _dataDict }

                    static var __parentType: any ApolloAPI.ParentType { Storefront.Objects.Product }
                    static var __selections: [ApolloAPI.Selection] { [
                        .field("__typename", String.self),
                        .field("title", String.self),
                        .field("vendor", String.self),
                        .field("featuredImage", FeaturedImage?.self)
                    ] }

                    /// The name for the product that displays to customers. The title is used to construct the product's handle.
                    /// For example, if a product is titled "Black Sunglasses", then the handle is `black-sunglasses`.
                    var title: String { __data["title"] }
                    /// The name of the product's vendor.
                    var vendor: String { __data["vendor"] }
                    /// The featured image for the product.
                    ///
                    /// This field is functionally equivalent to `images(first: 1)`.
                    var featuredImage: FeaturedImage? { __data["featuredImage"] }

                    /// Merchandise.AsProductVariant.Product.FeaturedImage
                    ///
                    /// Parent Type: `Image`
                    struct FeaturedImage: Storefront.SelectionSet {
                        let __data: DataDict
                        init(_dataDict: DataDict) { __data = _dataDict }

                        static var __parentType: any ApolloAPI.ParentType { Storefront.Objects.Image }
                        static var __selections: [ApolloAPI.Selection] { [
                            .field("__typename", String.self),
                            .field("url", Storefront.URL.self)
                        ] }

                        /// The location of the image as a URL.
                        ///
                        /// If no transform options are specified, then the original image will be preserved including any pre-applied transforms.
                        ///
                        /// All transformation options are considered "best-effort". Any transformation that the original image type doesn't support will be ignored.
                        ///
                        /// If you need multiple variations of the same image, then you can use [GraphQL aliases](https://graphql.org/learn/queries/#aliases).
                        var url: Storefront.URL { __data["url"] }
                    }
                }
            }
        }

        /// Cost
        ///
        /// Parent Type: `CartLineCost`
        struct Cost: Storefront.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { Storefront.Objects.CartLineCost }
            static var __selections: [ApolloAPI.Selection] { [
                .field("__typename", String.self),
                .field("totalAmount", TotalAmount.self)
            ] }

            /// The total cost of the merchandise line.
            var totalAmount: TotalAmount { __data["totalAmount"] }

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
        }
    }
}
