// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension Storefront {
    struct CartUserErrorFragment: Storefront.SelectionSet, Fragment {
        static var fragmentDefinition: StaticString {
            #"fragment CartUserErrorFragment on CartUserError { __typename code message field }"#
        }

        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { Storefront.Objects.CartUserError }
        static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("code", GraphQLEnum<Storefront.CartErrorCode>?.self),
            .field("message", String.self),
            .field("field", [String]?.self)
        ] }

        /// The error code.
        var code: GraphQLEnum<Storefront.CartErrorCode>? { __data["code"] }
        /// The error message.
        var message: String { __data["message"] }
        /// The path to the input field that caused the error.
        var field: [String]? { __data["field"] }
    }
}
