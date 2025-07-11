// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension Storefront {
    struct CartDeliveryGroupFragment: Storefront.SelectionSet, Fragment {
        static var fragmentDefinition: StaticString {
            #"fragment CartDeliveryGroupFragment on CartDeliveryGroup { __typename id groupType deliveryAddress { __typename address1 address2 city countryCodeV2 firstName lastName phone province zip } deliveryOptions { __typename handle title code deliveryMethodType description estimatedCost { __typename amount currencyCode } } selectedDeliveryOption { __typename description title handle estimatedCost { __typename amount currencyCode } } }"#
        }

        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { Storefront.Objects.CartDeliveryGroup }
        static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", Storefront.ID.self),
            .field("groupType", GraphQLEnum<Storefront.CartDeliveryGroupType>.self),
            .field("deliveryAddress", DeliveryAddress.self),
            .field("deliveryOptions", [DeliveryOption].self),
            .field("selectedDeliveryOption", SelectedDeliveryOption?.self)
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

        /// DeliveryAddress
        ///
        /// Parent Type: `MailingAddress`
        struct DeliveryAddress: Storefront.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { Storefront.Objects.MailingAddress }
            static var __selections: [ApolloAPI.Selection] { [
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
            ] }

            /// The first line of the address. Typically the street address or PO Box number.
            var address1: String? { __data["address1"] }
            /// The second line of the address. Typically the number of the apartment, suite, or unit.
            var address2: String? { __data["address2"] }
            /// The name of the city, district, village, or town.
            var city: String? { __data["city"] }
            /// The two-letter code for the country of the address.
            ///
            /// For example, US.
            var countryCodeV2: GraphQLEnum<Storefront.CountryCode>? { __data["countryCodeV2"] }
            /// The first name of the customer.
            var firstName: String? { __data["firstName"] }
            /// The last name of the customer.
            var lastName: String? { __data["lastName"] }
            /// A unique phone number for the customer.
            ///
            /// Formatted using E.164 standard. For example, _+16135551111_.
            var phone: String? { __data["phone"] }
            /// The region of the address, such as the province, state, or district.
            var province: String? { __data["province"] }
            /// The zip or postal code of the address.
            var zip: String? { __data["zip"] }
        }

        /// DeliveryOption
        ///
        /// Parent Type: `CartDeliveryOption`
        struct DeliveryOption: Storefront.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { Storefront.Objects.CartDeliveryOption }
            static var __selections: [ApolloAPI.Selection] { [
                .field("__typename", String.self),
                .field("handle", String.self),
                .field("title", String?.self),
                .field("code", String?.self),
                .field("deliveryMethodType", GraphQLEnum<Storefront.DeliveryMethodType>.self),
                .field("description", String?.self),
                .field("estimatedCost", EstimatedCost.self)
            ] }

            /// The unique identifier of the delivery option.
            var handle: String { __data["handle"] }
            /// The title of the delivery option.
            var title: String? { __data["title"] }
            /// The code of the delivery option.
            var code: String? { __data["code"] }
            /// The method for the delivery option.
            var deliveryMethodType: GraphQLEnum<Storefront.DeliveryMethodType> { __data["deliveryMethodType"] }
            /// The description of the delivery option.
            var description: String? { __data["description"] }
            /// The estimated cost for the delivery option.
            var estimatedCost: EstimatedCost { __data["estimatedCost"] }

            /// DeliveryOption.EstimatedCost
            ///
            /// Parent Type: `MoneyV2`
            struct EstimatedCost: Storefront.SelectionSet {
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

        /// SelectedDeliveryOption
        ///
        /// Parent Type: `CartDeliveryOption`
        struct SelectedDeliveryOption: Storefront.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { Storefront.Objects.CartDeliveryOption }
            static var __selections: [ApolloAPI.Selection] { [
                .field("__typename", String.self),
                .field("description", String?.self),
                .field("title", String?.self),
                .field("handle", String.self),
                .field("estimatedCost", EstimatedCost.self)
            ] }

            /// The description of the delivery option.
            var description: String? { __data["description"] }
            /// The title of the delivery option.
            var title: String? { __data["title"] }
            /// The unique identifier of the delivery option.
            var handle: String { __data["handle"] }
            /// The estimated cost for the delivery option.
            var estimatedCost: EstimatedCost { __data["estimatedCost"] }

            /// SelectedDeliveryOption.EstimatedCost
            ///
            /// Parent Type: `MoneyV2`
            struct EstimatedCost: Storefront.SelectionSet {
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
