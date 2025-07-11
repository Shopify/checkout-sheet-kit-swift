// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension Storefront {
    /// Specifies the input fields to update the buyer information associated with a cart.
    /// Buyer identity is used to determine
    /// [international pricing](https://shopify.dev/custom-storefronts/internationalization/international-pricing)
    /// and should match the customer's shipping address.
    struct CartBuyerIdentityInput: InputObject {
        private(set) var __data: InputDict

        init(_ data: InputDict) {
            __data = data
        }

        init(
            email: GraphQLNullable<String> = nil,
            phone: GraphQLNullable<String> = nil,
            companyLocationId: GraphQLNullable<ID> = nil,
            countryCode: GraphQLNullable<GraphQLEnum<CountryCode>> = nil,
            customerAccessToken: GraphQLNullable<String> = nil,
            preferences: GraphQLNullable<CartPreferencesInput> = nil
        ) {
            __data = InputDict([
                "email": email,
                "phone": phone,
                "companyLocationId": companyLocationId,
                "countryCode": countryCode,
                "customerAccessToken": customerAccessToken,
                "preferences": preferences
            ])
        }

        /// The email address of the buyer that is interacting with the cart.
        var email: GraphQLNullable<String> {
            get { __data["email"] }
            set { __data["email"] = newValue }
        }

        /// The phone number of the buyer that is interacting with the cart.
        var phone: GraphQLNullable<String> {
            get { __data["phone"] }
            set { __data["phone"] = newValue }
        }

        /// The company location of the buyer that is interacting with the cart.
        var companyLocationId: GraphQLNullable<ID> {
            get { __data["companyLocationId"] }
            set { __data["companyLocationId"] = newValue }
        }

        /// The country where the buyer is located.
        var countryCode: GraphQLNullable<GraphQLEnum<CountryCode>> {
            get { __data["countryCode"] }
            set { __data["countryCode"] = newValue }
        }

        /// The access token used to identify the customer associated with the cart.
        var customerAccessToken: GraphQLNullable<String> {
            get { __data["customerAccessToken"] }
            set { __data["customerAccessToken"] = newValue }
        }

        /// A set of preferences tied to the buyer interacting with the cart. Preferences are used to prefill fields in at checkout to streamline information collection.
        /// Preferences are not synced back to the cart if they are overwritten.
        var preferences: GraphQLNullable<CartPreferencesInput> {
            get { __data["preferences"] }
            set { __data["preferences"] = newValue }
        }
    }
}
