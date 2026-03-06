// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension Storefront {
    struct CartUserErrorFragment: Storefront.SelectionSet, Fragment {
        static var fragmentDefinition: StaticString {
            #"fragment CartUserErrorFragment on CartUserError { __typename code message field }"#
        }

        let __data: DataDict
        init(_dataDict: DataDict) {
            __data = _dataDict
        }

        static var __parentType: any ApolloAPI.ParentType {
            Storefront.Objects.CartUserError
        }

        static var __selections: [ApolloAPI.Selection] {
            [
                .field("__typename", String.self),
                .field("code", String?.self),
                .field("message", String.self),
                .field("field", [String]?.self)
            ]
        }

        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] {
            [
                CartUserErrorFragment.self
            ]
        }

        var code: String? {
            __data["code"]
        }

        var message: String {
            __data["message"]
        }

        var field: [String]? {
            __data["field"]
        }
    }
}
