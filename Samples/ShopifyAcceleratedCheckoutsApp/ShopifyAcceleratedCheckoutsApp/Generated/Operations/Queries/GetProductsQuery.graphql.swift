// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension Storefront {
    class GetProductsQuery: GraphQLQuery {
        static let operationName: String = "GetProducts"
        static let operationDocument: ApolloAPI.OperationDocument = .init(
            definition: .init(
                #"query GetProducts($first: Int = 10, $country: CountryCode!, $language: LanguageCode!) @inContext(country: $country, language: $language) { products(first: $first) { __typename nodes { __typename id title featuredImage { __typename url } variants(first: 10) { __typename nodes { __typename id title requiresShipping image { __typename url } price { __typename amount currencyCode } } } } } }"#
            ))

        public var first: GraphQLNullable<Int>
        public var country: GraphQLEnum<CountryCode>
        public var language: GraphQLEnum<LanguageCode>

        public init(
            first: GraphQLNullable<Int> = 10,
            country: GraphQLEnum<CountryCode>,
            language: GraphQLEnum<LanguageCode>
        ) {
            self.first = first
            self.country = country
            self.language = language
        }

        public var __variables: Variables? { [
            "first": first,
            "country": country,
            "language": language
        ] }

        struct Data: Storefront.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { Storefront.Objects.QueryRoot }
            static var __selections: [ApolloAPI.Selection] { [
                .field("products", Products.self, arguments: ["first": .variable("first")])
            ] }

            /// Returns a list of the shop's products. For storefront search, use the [`search`](https://shopify.dev/docs/api/storefront/latest/queries/search) query.
            var products: Products { __data["products"] }

            /// Products
            ///
            /// Parent Type: `ProductConnection`
            struct Products: Storefront.SelectionSet {
                let __data: DataDict
                init(_dataDict: DataDict) { __data = _dataDict }

                static var __parentType: any ApolloAPI.ParentType { Storefront.Objects.ProductConnection }
                static var __selections: [ApolloAPI.Selection] { [
                    .field("__typename", String.self),
                    .field("nodes", [Node].self)
                ] }

                /// A list of the nodes contained in ProductEdge.
                var nodes: [Node] { __data["nodes"] }

                /// Products.Node
                ///
                /// Parent Type: `Product`
                struct Node: Storefront.SelectionSet {
                    let __data: DataDict
                    init(_dataDict: DataDict) { __data = _dataDict }

                    static var __parentType: any ApolloAPI.ParentType { Storefront.Objects.Product }
                    static var __selections: [ApolloAPI.Selection] { [
                        .field("__typename", String.self),
                        .field("id", Storefront.ID.self),
                        .field("title", String.self),
                        .field("featuredImage", FeaturedImage?.self),
                        .field("variants", Variants.self, arguments: ["first": 10])
                    ] }

                    /// A globally-unique ID.
                    var id: Storefront.ID { __data["id"] }
                    /// The name for the product that displays to customers. The title is used to construct the product's handle.
                    /// For example, if a product is titled "Black Sunglasses", then the handle is `black-sunglasses`.
                    var title: String { __data["title"] }
                    /// The featured image for the product.
                    ///
                    /// This field is functionally equivalent to `images(first: 1)`.
                    var featuredImage: FeaturedImage? { __data["featuredImage"] }
                    /// A list of [variants](/docs/api/storefront/latest/objects/ProductVariant) that are associated with the product.
                    var variants: Variants { __data["variants"] }

                    /// Products.Node.FeaturedImage
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

                    /// Products.Node.Variants
                    ///
                    /// Parent Type: `ProductVariantConnection`
                    struct Variants: Storefront.SelectionSet {
                        let __data: DataDict
                        init(_dataDict: DataDict) { __data = _dataDict }

                        static var __parentType: any ApolloAPI.ParentType { Storefront.Objects.ProductVariantConnection }
                        static var __selections: [ApolloAPI.Selection] { [
                            .field("__typename", String.self),
                            .field("nodes", [Node].self)
                        ] }

                        /// A list of the nodes contained in ProductVariantEdge.
                        var nodes: [Node] { __data["nodes"] }

                        /// Products.Node.Variants.Node
                        ///
                        /// Parent Type: `ProductVariant`
                        struct Node: Storefront.SelectionSet {
                            let __data: DataDict
                            init(_dataDict: DataDict) { __data = _dataDict }

                            static var __parentType: any ApolloAPI.ParentType { Storefront.Objects.ProductVariant }
                            static var __selections: [ApolloAPI.Selection] { [
                                .field("__typename", String.self),
                                .field("id", Storefront.ID.self),
                                .field("title", String.self),
                                .field("requiresShipping", Bool.self),
                                .field("image", Image?.self),
                                .field("price", Price.self)
                            ] }

                            /// A globally-unique ID.
                            var id: Storefront.ID { __data["id"] }
                            /// The product variant’s title.
                            var title: String { __data["title"] }
                            /// Whether a customer needs to provide a shipping address when placing an order for the product variant.
                            var requiresShipping: Bool { __data["requiresShipping"] }
                            /// Image associated with the product variant. This field falls back to the product image if no image is available.
                            var image: Image? { __data["image"] }
                            /// The product variant’s price.
                            var price: Price { __data["price"] }

                            /// Products.Node.Variants.Node.Image
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

                            /// Products.Node.Variants.Node.Price
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
                        }
                    }
                }
            }
        }
    }
}
