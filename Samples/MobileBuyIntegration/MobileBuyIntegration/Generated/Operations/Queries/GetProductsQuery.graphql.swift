// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension Storefront {
    class GetProductsQuery: GraphQLQuery {
        static let operationName: String = "GetProducts"
        static let operationDocument: ApolloAPI.OperationDocument = .init(
            definition: .init(
                #"query GetProducts($first: Int = 20, $country: CountryCode!, $language: LanguageCode!) @inContext(country: $country, language: $language) { products(first: $first) { __typename nodes { __typename id title handle description vendor featuredImage { __typename url } collections(first: 1) { __typename nodes { __typename id title } } variants(first: 1) { __typename nodes { __typename id title availableForSale price { __typename amount currencyCode } } } } } }"#
            )
        )

        public var first: GraphQLNullable<Int>
        public var country: GraphQLEnum<CountryCode>
        public var language: GraphQLEnum<LanguageCode>

        public init(
            first: GraphQLNullable<Int> = 20,
            country: GraphQLEnum<CountryCode>,
            language: GraphQLEnum<LanguageCode>
        ) {
            self.first = first
            self.country = country
            self.language = language
        }

        public var __variables: Variables? {
            [
                "first": first,
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
                    .field("products", Products.self, arguments: ["first": .variable("first")])
                ]
            }

            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
                [
                    GetProductsQuery.Data.self
                ]
            }

            var products: Products {
                __data["products"]
            }

            /// Products
            ///
            /// Parent Type: `ProductConnection`
            struct Products: Storefront.SelectionSet {
                let __data: DataDict
                init(_dataDict: DataDict) {
                    __data = _dataDict
                }

                static var __parentType: any ApolloAPI.ParentType {
                    Storefront.Objects.ProductConnection
                }

                static var __selections: [ApolloAPI.Selection] {
                    [
                        .field("__typename", String.self),
                        .field("nodes", [Node].self)
                    ]
                }

                static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
                    [
                        GetProductsQuery.Data.Products.self
                    ]
                }

                var nodes: [Node] {
                    __data["nodes"]
                }

                /// Products.Node
                ///
                /// Parent Type: `Product`
                struct Node: Storefront.SelectionSet {
                    let __data: DataDict
                    init(_dataDict: DataDict) {
                        __data = _dataDict
                    }

                    static var __parentType: any ApolloAPI.ParentType {
                        Storefront.Objects.Product
                    }

                    static var __selections: [ApolloAPI.Selection] {
                        [
                            .field("__typename", String.self),
                            .field("id", Storefront.ID.self),
                            .field("title", String.self),
                            .field("handle", String.self),
                            .field("description", String.self),
                            .field("vendor", String.self),
                            .field("featuredImage", FeaturedImage?.self),
                            .field("collections", Collections.self, arguments: ["first": 1]),
                            .field("variants", Variants.self, arguments: ["first": 1])
                        ]
                    }

                    static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
                        [
                            GetProductsQuery.Data.Products.Node.self
                        ]
                    }

                    var id: Storefront.ID {
                        __data["id"]
                    }

                    var title: String {
                        __data["title"]
                    }

                    var handle: String {
                        __data["handle"]
                    }

                    var description: String {
                        __data["description"]
                    }

                    var vendor: String {
                        __data["vendor"]
                    }

                    var featuredImage: FeaturedImage? {
                        __data["featuredImage"]
                    }

                    var collections: Collections {
                        __data["collections"]
                    }

                    var variants: Variants {
                        __data["variants"]
                    }

                    /// Products.Node.FeaturedImage
                    ///
                    /// Parent Type: `Image`
                    struct FeaturedImage: Storefront.SelectionSet {
                        let __data: DataDict
                        init(_dataDict: DataDict) {
                            __data = _dataDict
                        }

                        static var __parentType: any ApolloAPI.ParentType {
                            Storefront.Objects.Image
                        }

                        static var __selections: [ApolloAPI.Selection] {
                            [
                                .field("__typename", String.self),
                                .field("url", String.self)
                            ]
                        }

                        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
                            [
                                GetProductsQuery.Data.Products.Node.FeaturedImage.self
                            ]
                        }

                        var url: String {
                            __data["url"]
                        }
                    }

                    /// Products.Node.Collections
                    ///
                    /// Parent Type: `CollectionConnection`
                    struct Collections: Storefront.SelectionSet {
                        let __data: DataDict
                        init(_dataDict: DataDict) {
                            __data = _dataDict
                        }

                        static var __parentType: any ApolloAPI.ParentType {
                            Storefront.Objects.CollectionConnection
                        }

                        static var __selections: [ApolloAPI.Selection] {
                            [
                                .field("__typename", String.self),
                                .field("nodes", [Node].self)
                            ]
                        }

                        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
                            [
                                GetProductsQuery.Data.Products.Node.Collections.self
                            ]
                        }

                        var nodes: [Node] {
                            __data["nodes"]
                        }

                        /// Products.Node.Collections.Node
                        ///
                        /// Parent Type: `Collection`
                        struct Node: Storefront.SelectionSet {
                            let __data: DataDict
                            init(_dataDict: DataDict) {
                                __data = _dataDict
                            }

                            static var __parentType: any ApolloAPI.ParentType {
                                Storefront.Objects.Collection
                            }

                            static var __selections: [ApolloAPI.Selection] {
                                [
                                    .field("__typename", String.self),
                                    .field("id", Storefront.ID.self),
                                    .field("title", String.self)
                                ]
                            }

                            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
                                [
                                    GetProductsQuery.Data.Products.Node.Collections.Node.self
                                ]
                            }

                            var id: Storefront.ID {
                                __data["id"]
                            }

                            var title: String {
                                __data["title"]
                            }
                        }
                    }

                    /// Products.Node.Variants
                    ///
                    /// Parent Type: `ProductVariantConnection`
                    struct Variants: Storefront.SelectionSet {
                        let __data: DataDict
                        init(_dataDict: DataDict) {
                            __data = _dataDict
                        }

                        static var __parentType: any ApolloAPI.ParentType {
                            Storefront.Objects.ProductVariantConnection
                        }

                        static var __selections: [ApolloAPI.Selection] {
                            [
                                .field("__typename", String.self),
                                .field("nodes", [Node].self)
                            ]
                        }

                        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
                            [
                                GetProductsQuery.Data.Products.Node.Variants.self
                            ]
                        }

                        var nodes: [Node] {
                            __data["nodes"]
                        }

                        /// Products.Node.Variants.Node
                        ///
                        /// Parent Type: `ProductVariant`
                        struct Node: Storefront.SelectionSet {
                            let __data: DataDict
                            init(_dataDict: DataDict) {
                                __data = _dataDict
                            }

                            static var __parentType: any ApolloAPI.ParentType {
                                Storefront.Objects.ProductVariant
                            }

                            static var __selections: [ApolloAPI.Selection] {
                                [
                                    .field("__typename", String.self),
                                    .field("id", Storefront.ID.self),
                                    .field("title", String.self),
                                    .field("availableForSale", Bool.self),
                                    .field("price", Price.self)
                                ]
                            }

                            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
                                [
                                    GetProductsQuery.Data.Products.Node.Variants.Node.self
                                ]
                            }

                            var id: Storefront.ID {
                                __data["id"]
                            }

                            var title: String {
                                __data["title"]
                            }

                            var availableForSale: Bool {
                                __data["availableForSale"]
                            }

                            var price: Price {
                                __data["price"]
                            }

                            /// Products.Node.Variants.Node.Price
                            ///
                            /// Parent Type: `MoneyV2`
                            struct Price: Storefront.SelectionSet {
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
                                        GetProductsQuery.Data.Products.Node.Variants.Node.Price.self
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
            }
        }
    }
}
