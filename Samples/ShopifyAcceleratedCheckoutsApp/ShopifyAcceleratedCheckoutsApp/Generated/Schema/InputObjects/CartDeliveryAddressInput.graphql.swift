// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension Storefront {
    /// The input fields to create or update a cart address.
    struct CartDeliveryAddressInput: InputObject {
        private(set) var __data: InputDict

        init(_ data: InputDict) {
            __data = data
        }

        init(
            address1: GraphQLNullable<String> = nil,
            address2: GraphQLNullable<String> = nil,
            city: GraphQLNullable<String> = nil,
            company: GraphQLNullable<String> = nil,
            countryCode: GraphQLNullable<GraphQLEnum<CountryCode>> = nil,
            firstName: GraphQLNullable<String> = nil,
            lastName: GraphQLNullable<String> = nil,
            phone: GraphQLNullable<String> = nil,
            provinceCode: GraphQLNullable<String> = nil,
            zip: GraphQLNullable<String> = nil
        ) {
            __data = InputDict([
                "address1": address1,
                "address2": address2,
                "city": city,
                "company": company,
                "countryCode": countryCode,
                "firstName": firstName,
                "lastName": lastName,
                "phone": phone,
                "provinceCode": provinceCode,
                "zip": zip
            ])
        }

        /// The first line of the address. Typically the street address or PO Box number.
        var address1: GraphQLNullable<String> {
            get { __data["address1"] }
            set { __data["address1"] = newValue }
        }

        /// The second line of the address. Typically the number of the apartment, suite, or unit.
        var address2: GraphQLNullable<String> {
            get { __data["address2"] }
            set { __data["address2"] = newValue }
        }

        /// The name of the city, district, village, or town.
        var city: GraphQLNullable<String> {
            get { __data["city"] }
            set { __data["city"] = newValue }
        }

        /// The name of the customer's company or organization.
        var company: GraphQLNullable<String> {
            get { __data["company"] }
            set { __data["company"] = newValue }
        }

        /// The name of the country.
        var countryCode: GraphQLNullable<GraphQLEnum<CountryCode>> {
            get { __data["countryCode"] }
            set { __data["countryCode"] = newValue }
        }

        /// The first name of the customer.
        var firstName: GraphQLNullable<String> {
            get { __data["firstName"] }
            set { __data["firstName"] = newValue }
        }

        /// The last name of the customer.
        var lastName: GraphQLNullable<String> {
            get { __data["lastName"] }
            set { __data["lastName"] = newValue }
        }

        /// A unique phone number for the customer.
        ///
        /// Formatted using E.164 standard. For example, _+16135551111_.
        var phone: GraphQLNullable<String> {
            get { __data["phone"] }
            set { __data["phone"] = newValue }
        }

        /// The region of the address, such as the province, state, or district.
        var provinceCode: GraphQLNullable<String> {
            get { __data["provinceCode"] }
            set { __data["provinceCode"] = newValue }
        }

        /// The zip or postal code of the address.
        var zip: GraphQLNullable<String> {
            get { __data["zip"] }
            set { __data["zip"] = newValue }
        }
    }
}
