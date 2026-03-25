// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension Storefront {
    struct GetProductsQuery: GraphQLQuery {
        static let operationName: String = "GetProducts"
        static let operationDocument: ApolloAPI.OperationDocument = .init(
            definition: .init(
                #"query GetProducts($first: Int = 20, $country: CountryCode!, $language: LanguageCode!) @inContext(country: $country, language: $language) { products(first: $first) { __typename nodes { __typename id title handle description vendor featuredImage { __typename url } collections(first: 1) { __typename nodes { __typename id title } } variants(first: 1) { __typename nodes { __typename id title availableForSale price { __typename amount currencyCode } } } } } }"#
            ))

        public var first: GraphQLNullable<Int32>
        public var country: GraphQLEnum<CountryCode>
        public var language: GraphQLEnum<LanguageCode>

        public init(
            first: GraphQLNullable<Int32> = 20,
            country: GraphQLEnum<CountryCode>,
            language: GraphQLEnum<LanguageCode>
        ) {
            self.first = first
            self.country = country
            self.language = language
        }

        @_spi(Unsafe) public var __variables: Variables? { [
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
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                GetProductsQuery.Data.self
            ] }

            /// Returns a paginated list of the shop's [products](https://shopify.dev/docs/api/storefront/current/objects/Product).
            ///
            /// For full-text storefront search, use the [`search`](https://shopify.dev/docs/api/storefront/current/queries/search) query instead.
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
                static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                    GetProductsQuery.Data.Products.self
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
                        .field("handle", String.self),
                        .field("description", String.self),
                        .field("vendor", String.self),
                        .field("featuredImage", FeaturedImage?.self),
                        .field("collections", Collections.self, arguments: ["first": 1]),
                        .field("variants", Variants.self, arguments: ["first": 1])
                    ] }
                    static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                        GetProductsQuery.Data.Products.Node.self
                    ] }

                    /// A globally-unique ID.
                    var id: Storefront.ID { __data["id"] }
                    /// The name for the product that displays to customers. The title is used to construct the product's handle.
                    /// For example, if a product is titled "Black Sunglasses", then the handle is `black-sunglasses`.
                    var title: String { __data["title"] }
                    /// A unique, human-readable string of the product's title.
                    /// A handle can contain letters, hyphens (`-`), and numbers, but no spaces.
                    /// The handle is used in the online store URL for the product.
                    var handle: String { __data["handle"] }
                    /// A single-line description of the product, with [HTML tags](https://developer.mozilla.org/en-US/docs/Web/HTML) removed.
                    var description: String { __data["description"] }
                    /// The name of the product's vendor.
                    var vendor: String { __data["vendor"] }
                    /// The featured image for the product.
                    ///
                    /// This field is functionally equivalent to `images(first: 1)`.
                    var featuredImage: FeaturedImage? { __data["featuredImage"] }
                    /// A list of [collections](/docs/api/storefront/latest/objects/Collection) that include the product.
                    var collections: Collections { __data["collections"] }
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
                        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                            GetProductsQuery.Data.Products.Node.FeaturedImage.self
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

                    /// Products.Node.Collections
                    ///
                    /// Parent Type: `CollectionConnection`
                    struct Collections: Storefront.SelectionSet {
                        let __data: DataDict
                        init(_dataDict: DataDict) { __data = _dataDict }

                        static var __parentType: any ApolloAPI.ParentType { Storefront.Objects.CollectionConnection }
                        static var __selections: [ApolloAPI.Selection] { [
                            .field("__typename", String.self),
                            .field("nodes", [Node].self)
                        ] }
                        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                            GetProductsQuery.Data.Products.Node.Collections.self
                        ] }

                        /// A list of the nodes contained in CollectionEdge.
                        var nodes: [Node] { __data["nodes"] }

                        /// Products.Node.Collections.Node
                        ///
                        /// Parent Type: `Collection`
                        struct Node: Storefront.SelectionSet {
                            let __data: DataDict
                            init(_dataDict: DataDict) { __data = _dataDict }

                            static var __parentType: any ApolloAPI.ParentType { Storefront.Objects.Collection }
                            static var __selections: [ApolloAPI.Selection] { [
                                .field("__typename", String.self),
                                .field("id", Storefront.ID.self),
                                .field("title", String.self)
                            ] }
                            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                                GetProductsQuery.Data.Products.Node.Collections.Node.self
                            ] }

                            /// A globally-unique ID.
                            var id: Storefront.ID { __data["id"] }
                            /// The collection’s name. Limit of 255 characters.
                            var title: String { __data["title"] }
                        }
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
                        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                            GetProductsQuery.Data.Products.Node.Variants.self
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
                                .field("availableForSale", Bool.self),
                                .field("price", Price.self)
                            ] }
                            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                                GetProductsQuery.Data.Products.Node.Variants.Node.self
                            ] }

                            /// A globally-unique ID.
                            var id: Storefront.ID { __data["id"] }
                            /// The product variant’s title.
                            var title: String { __data["title"] }
                            /// Indicates if the product variant is available for sale.
                            var availableForSale: Bool { __data["availableForSale"] }
                            /// The product variant’s price.
                            var price: Price { __data["price"] }

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
                                static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                                    GetProductsQuery.Data.Products.Node.Variants.Node.Price.self
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
