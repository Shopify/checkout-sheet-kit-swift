// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

protocol Storefront_SelectionSet: ApolloAPI.SelectionSet & ApolloAPI.RootSelectionSet
    where Schema == Storefront.SchemaMetadata {}

protocol Storefront_InlineFragment: ApolloAPI.SelectionSet & ApolloAPI.InlineFragment
    where Schema == Storefront.SchemaMetadata {}

protocol Storefront_MutableSelectionSet: ApolloAPI.MutableRootSelectionSet
    where Schema == Storefront.SchemaMetadata {}

protocol Storefront_MutableInlineFragment: ApolloAPI.MutableSelectionSet & ApolloAPI.InlineFragment
    where Schema == Storefront.SchemaMetadata {}

extension Storefront {
    typealias SelectionSet = Storefront_SelectionSet

    typealias InlineFragment = Storefront_InlineFragment

    typealias MutableSelectionSet = Storefront_MutableSelectionSet

    typealias MutableInlineFragment = Storefront_MutableInlineFragment

    enum SchemaMetadata: ApolloAPI.SchemaMetadata {
        /// nonisolated(unsafe) is applied manually whilst we're on Apollo v1
        /// Apollo provides Swift 6 support in v2 - this workaround will be removed then
        nonisolated(unsafe) static let configuration: any ApolloAPI.SchemaConfiguration.Type = SchemaConfiguration.self

        static func objectType(forTypename typename: String) -> ApolloAPI.Object? {
            switch typename {
            case "BaseCartLineConnection": return Storefront.Objects.BaseCartLineConnection
            case "Cart": return Storefront.Objects.Cart
            case "CartBuyerIdentity": return Storefront.Objects.CartBuyerIdentity
            case "CartCost": return Storefront.Objects.CartCost
            case "CartCreatePayload": return Storefront.Objects.CartCreatePayload
            case "CartDeliveryGroup": return Storefront.Objects.CartDeliveryGroup
            case "CartDeliveryGroupConnection": return Storefront.Objects.CartDeliveryGroupConnection
            case "CartDeliveryOption": return Storefront.Objects.CartDeliveryOption
            case "CartLine": return Storefront.Objects.CartLine
            case "CartLineCost": return Storefront.Objects.CartLineCost
            case "CartLinesAddPayload": return Storefront.Objects.CartLinesAddPayload
            case "CartLinesUpdatePayload": return Storefront.Objects.CartLinesUpdatePayload
            case "CartUserError": return Storefront.Objects.CartUserError
            case "Collection": return Storefront.Objects.Collection
            case "CollectionConnection": return Storefront.Objects.CollectionConnection
            case "Customer": return Storefront.Objects.Customer
            case "Image": return Storefront.Objects.Image
            case "MailingAddress": return Storefront.Objects.MailingAddress
            case "MoneyV2": return Storefront.Objects.MoneyV2
            case "Mutation": return Storefront.Objects.Mutation
            case "Product": return Storefront.Objects.Product
            case "ProductConnection": return Storefront.Objects.ProductConnection
            case "ProductVariant": return Storefront.Objects.ProductVariant
            case "ProductVariantConnection": return Storefront.Objects.ProductVariantConnection
            case "Query": return Storefront.Objects.Query
            default: return nil
            }
        }
    }

    enum Objects {}
    enum Interfaces {}
    enum Unions {}
}
