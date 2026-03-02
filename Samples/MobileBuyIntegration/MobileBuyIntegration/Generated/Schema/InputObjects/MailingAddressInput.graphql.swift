// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension Storefront {
    struct MailingAddressInput: InputObject {
        private(set) var __data: InputDict

        init(_ data: InputDict) {
            __data = data
        }

        init(
            address1: GraphQLNullable<String> = nil,
            address2: GraphQLNullable<String> = nil,
            city: GraphQLNullable<String> = nil,
            company: GraphQLNullable<String> = nil,
            country: GraphQLNullable<String> = nil,
            firstName: GraphQLNullable<String> = nil,
            lastName: GraphQLNullable<String> = nil,
            phone: GraphQLNullable<String> = nil,
            province: GraphQLNullable<String> = nil,
            zip: GraphQLNullable<String> = nil
        ) {
            __data = InputDict([
                "address1": address1,
                "address2": address2,
                "city": city,
                "company": company,
                "country": country,
                "firstName": firstName,
                "lastName": lastName,
                "phone": phone,
                "province": province,
                "zip": zip
            ])
        }

        var address1: GraphQLNullable<String> {
            get { __data["address1"] }
            set { __data["address1"] = newValue }
        }

        var address2: GraphQLNullable<String> {
            get { __data["address2"] }
            set { __data["address2"] = newValue }
        }

        var city: GraphQLNullable<String> {
            get { __data["city"] }
            set { __data["city"] = newValue }
        }

        var company: GraphQLNullable<String> {
            get { __data["company"] }
            set { __data["company"] = newValue }
        }

        var country: GraphQLNullable<String> {
            get { __data["country"] }
            set { __data["country"] = newValue }
        }

        var firstName: GraphQLNullable<String> {
            get { __data["firstName"] }
            set { __data["firstName"] = newValue }
        }

        var lastName: GraphQLNullable<String> {
            get { __data["lastName"] }
            set { __data["lastName"] = newValue }
        }

        var phone: GraphQLNullable<String> {
            get { __data["phone"] }
            set { __data["phone"] = newValue }
        }

        var province: GraphQLNullable<String> {
            get { __data["province"] }
            set { __data["province"] = newValue }
        }

        var zip: GraphQLNullable<String> {
            get { __data["zip"] }
            set { __data["zip"] = newValue }
        }
    }
}
