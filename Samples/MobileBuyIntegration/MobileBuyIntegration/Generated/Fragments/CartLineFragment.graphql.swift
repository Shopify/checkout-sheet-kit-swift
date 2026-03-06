// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension Storefront {
    struct CartLineFragment: Storefront.SelectionSet, Fragment {
        static var fragmentDefinition: StaticString {
            #"fragment CartLineFragment on BaseCartLine { __typename id quantity merchandise { __typename ... on ProductVariant { id title image { __typename url } price { __typename amount currencyCode } product { __typename title vendor featuredImage { __typename url } } requiresShipping } } cost { __typename totalAmount { __typename amount currencyCode } } }"#
        }

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
                .field("id", Storefront.ID.self),
                .field("quantity", Int.self),
                .field("merchandise", Merchandise.self),
                .field("cost", Cost.self)
            ]
        }

        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
            [
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

        /// Merchandise
        ///
        /// Parent Type: `Merchandise`
        struct Merchandise: Storefront.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) {
                __data = _dataDict
            }

            static var __parentType: any ApolloAPI.ParentType {
                Storefront.Unions.Merchandise
            }

            static var __selections: [ApolloAPI.Selection] {
                [
                    .field("__typename", String.self),
                    .inlineFragment(AsProductVariant.self)
                ]
            }

            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
                [
                    CartLineFragment.Merchandise.self
                ]
            }

            var asProductVariant: AsProductVariant? {
                _asInlineFragment()
            }

            /// Merchandise.AsProductVariant
            ///
            /// Parent Type: `ProductVariant`
            struct AsProductVariant: Storefront.InlineFragment {
                let __data: DataDict
                init(_dataDict: DataDict) {
                    __data = _dataDict
                }

                typealias RootEntityType = CartLineFragment.Merchandise
                static var __parentType: any ApolloAPI.ParentType {
                    Storefront.Objects.ProductVariant
                }

                static var __selections: [ApolloAPI.Selection] {
                    [
                        .field("id", Storefront.ID.self),
                        .field("title", String.self),
                        .field("image", Image?.self),
                        .field("price", Price.self),
                        .field("product", Product.self),
                        .field("requiresShipping", Bool.self)
                    ]
                }

                static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
                    [
                        CartLineFragment.Merchandise.self,
                        CartLineFragment.Merchandise.AsProductVariant.self
                    ]
                }

                var id: Storefront.ID {
                    __data["id"]
                }

                var title: String {
                    __data["title"]
                }

                var image: Image? {
                    __data["image"]
                }

                var price: Price {
                    __data["price"]
                }

                var product: Product {
                    __data["product"]
                }

                var requiresShipping: Bool {
                    __data["requiresShipping"]
                }

                /// Merchandise.AsProductVariant.Image
                ///
                /// Parent Type: `Image`
                struct Image: Storefront.SelectionSet {
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
                            CartLineFragment.Merchandise.AsProductVariant.Image.self
                        ]
                    }

                    var url: String {
                        __data["url"]
                    }
                }

                /// Merchandise.AsProductVariant.Price
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
                            CartLineFragment.Merchandise.AsProductVariant.Price.self
                        ]
                    }

                    var amount: String {
                        __data["amount"]
                    }

                    var currencyCode: GraphQLEnum<Storefront.CurrencyCode> {
                        __data["currencyCode"]
                    }
                }

                /// Merchandise.AsProductVariant.Product
                ///
                /// Parent Type: `Product`
                struct Product: Storefront.SelectionSet {
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
                            .field("title", String.self),
                            .field("vendor", String.self),
                            .field("featuredImage", FeaturedImage?.self)
                        ]
                    }

                    static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
                        [
                            CartLineFragment.Merchandise.AsProductVariant.Product.self
                        ]
                    }

                    var title: String {
                        __data["title"]
                    }

                    var vendor: String {
                        __data["vendor"]
                    }

                    var featuredImage: FeaturedImage? {
                        __data["featuredImage"]
                    }

                    /// Merchandise.AsProductVariant.Product.FeaturedImage
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
                                CartLineFragment.Merchandise.AsProductVariant.Product.FeaturedImage.self
                            ]
                        }

                        var url: String {
                            __data["url"]
                        }
                    }
                }
            }
        }

        /// Cost
        ///
        /// Parent Type: `CartLineCost`
        struct Cost: Storefront.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) {
                __data = _dataDict
            }

            static var __parentType: any ApolloAPI.ParentType {
                Storefront.Objects.CartLineCost
            }

            static var __selections: [ApolloAPI.Selection] {
                [
                    .field("__typename", String.self),
                    .field("totalAmount", TotalAmount.self)
                ]
            }

            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
                [
                    CartLineFragment.Cost.self
                ]
            }

            var totalAmount: TotalAmount {
                __data["totalAmount"]
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
                        CartLineFragment.Cost.TotalAmount.self
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
