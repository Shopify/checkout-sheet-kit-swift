// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension Storefront {
    struct CartDeliveryGroupFragment: Storefront.SelectionSet, Fragment {
        static var fragmentDefinition: StaticString {
            #"fragment CartDeliveryGroupFragment on CartDeliveryGroup { __typename id groupType deliveryAddress { __typename address1 address2 city countryCodeV2 firstName lastName phone province zip } deliveryOptions { __typename handle title code deliveryMethodType description estimatedCost { __typename amount currencyCode } } selectedDeliveryOption { __typename description title handle estimatedCost { __typename amount currencyCode } } }"#
        }

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
                .field("id", Storefront.ID.self),
                .field("groupType", GraphQLEnum<Storefront.CartDeliveryGroupType>?.self),
                .field("deliveryAddress", DeliveryAddress?.self),
                .field("deliveryOptions", [DeliveryOption].self),
                .field("selectedDeliveryOption", SelectedDeliveryOption?.self)
            ]
        }

        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
            [
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

        /// DeliveryAddress
        ///
        /// Parent Type: `MailingAddress`
        struct DeliveryAddress: Storefront.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) {
                __data = _dataDict
            }

            static var __parentType: any ApolloAPI.ParentType {
                Storefront.Objects.MailingAddress
            }

            static var __selections: [ApolloAPI.Selection] {
                [
                    .field("__typename", String.self),
                    .field("address1", String?.self),
                    .field("address2", String?.self),
                    .field("city", String?.self),
                    .field("countryCodeV2", GraphQLEnum<Storefront.CountryCode>?.self),
                    .field("firstName", String?.self),
                    .field("lastName", String?.self),
                    .field("phone", String?.self),
                    .field("province", String?.self),
                    .field("zip", String?.self)
                ]
            }

            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
                [
                    CartDeliveryGroupFragment.DeliveryAddress.self
                ]
            }

            var address1: String? {
                __data["address1"]
            }

            var address2: String? {
                __data["address2"]
            }

            var city: String? {
                __data["city"]
            }

            var countryCodeV2: GraphQLEnum<Storefront.CountryCode>? {
                __data["countryCodeV2"]
            }

            var firstName: String? {
                __data["firstName"]
            }

            var lastName: String? {
                __data["lastName"]
            }

            var phone: String? {
                __data["phone"]
            }

            var province: String? {
                __data["province"]
            }

            var zip: String? {
                __data["zip"]
            }
        }

        /// DeliveryOption
        ///
        /// Parent Type: `CartDeliveryOption`
        struct DeliveryOption: Storefront.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) {
                __data = _dataDict
            }

            static var __parentType: any ApolloAPI.ParentType {
                Storefront.Objects.CartDeliveryOption
            }

            static var __selections: [ApolloAPI.Selection] {
                [
                    .field("__typename", String.self),
                    .field("handle", String.self),
                    .field("title", String?.self),
                    .field("code", String?.self),
                    .field("deliveryMethodType", GraphQLEnum<Storefront.DeliveryMethodType>.self),
                    .field("description", String?.self),
                    .field("estimatedCost", EstimatedCost.self)
                ]
            }

            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
                [
                    CartDeliveryGroupFragment.DeliveryOption.self
                ]
            }

            var handle: String {
                __data["handle"]
            }

            var title: String? {
                __data["title"]
            }

            var code: String? {
                __data["code"]
            }

            var deliveryMethodType: GraphQLEnum<Storefront.DeliveryMethodType> {
                __data["deliveryMethodType"]
            }

            var description: String? {
                __data["description"]
            }

            var estimatedCost: EstimatedCost {
                __data["estimatedCost"]
            }

            /// DeliveryOption.EstimatedCost
            ///
            /// Parent Type: `MoneyV2`
            struct EstimatedCost: Storefront.SelectionSet {
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
                        CartDeliveryGroupFragment.DeliveryOption.EstimatedCost.self
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

        /// SelectedDeliveryOption
        ///
        /// Parent Type: `CartDeliveryOption`
        struct SelectedDeliveryOption: Storefront.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) {
                __data = _dataDict
            }

            static var __parentType: any ApolloAPI.ParentType {
                Storefront.Objects.CartDeliveryOption
            }

            static var __selections: [ApolloAPI.Selection] {
                [
                    .field("__typename", String.self),
                    .field("description", String?.self),
                    .field("title", String?.self),
                    .field("handle", String.self),
                    .field("estimatedCost", EstimatedCost.self)
                ]
            }

            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
                [
                    CartDeliveryGroupFragment.SelectedDeliveryOption.self
                ]
            }

            var description: String? {
                __data["description"]
            }

            var title: String? {
                __data["title"]
            }

            var handle: String {
                __data["handle"]
            }

            var estimatedCost: EstimatedCost {
                __data["estimatedCost"]
            }

            /// SelectedDeliveryOption.EstimatedCost
            ///
            /// Parent Type: `MoneyV2`
            struct EstimatedCost: Storefront.SelectionSet {
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
                        CartDeliveryGroupFragment.SelectedDeliveryOption.EstimatedCost.self
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
