// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension Storefront {
    struct CartBuyerIdentityInput: InputObject {
        private(set) var __data: InputDict

        init(_ data: InputDict) {
            __data = data
        }

        init(
            email: GraphQLNullable<String> = nil,
            phone: GraphQLNullable<String> = nil,
            countryCode: GraphQLNullable<GraphQLEnum<CountryCode>> = nil,
            customerAccessToken: GraphQLNullable<String> = nil,
            deliveryAddressPreferences: GraphQLNullable<[DeliveryAddressInput]> = nil
        ) {
            __data = InputDict([
                "email": email,
                "phone": phone,
                "countryCode": countryCode,
                "customerAccessToken": customerAccessToken,
                "deliveryAddressPreferences": deliveryAddressPreferences
            ])
        }

        var email: GraphQLNullable<String> {
            get { __data["email"] }
            set { __data["email"] = newValue }
        }

        var phone: GraphQLNullable<String> {
            get { __data["phone"] }
            set { __data["phone"] = newValue }
        }

        var countryCode: GraphQLNullable<GraphQLEnum<CountryCode>> {
            get { __data["countryCode"] }
            set { __data["countryCode"] = newValue }
        }

        var customerAccessToken: GraphQLNullable<String> {
            get { __data["customerAccessToken"] }
            set { __data["customerAccessToken"] = newValue }
        }

        var deliveryAddressPreferences: GraphQLNullable<[DeliveryAddressInput]> {
            get { __data["deliveryAddressPreferences"] }
            set { __data["deliveryAddressPreferences"] = newValue }
        }
    }
}
