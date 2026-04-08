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
        static let configuration: any ApolloAPI.SchemaConfiguration.Type = SchemaConfiguration.self

        static func objectType(forTypename typename: String) -> ApolloAPI.Object? {
            switch typename {
            case "AppliedGiftCard": return Storefront.Objects.AppliedGiftCard
            case "Article": return Storefront.Objects.Article
            case "BaseCartLineConnection": return Storefront.Objects.BaseCartLineConnection
            case "Blog": return Storefront.Objects.Blog
            case "Cart": return Storefront.Objects.Cart
            case "CartBuyerIdentity": return Storefront.Objects.CartBuyerIdentity
            case "CartCost": return Storefront.Objects.CartCost
            case "CartCreatePayload": return Storefront.Objects.CartCreatePayload
            case "CartDeliveryGroup": return Storefront.Objects.CartDeliveryGroup
            case "CartDeliveryGroupConnection": return Storefront.Objects.CartDeliveryGroupConnection
            case "CartDeliveryOption": return Storefront.Objects.CartDeliveryOption
            case "CartLine": return Storefront.Objects.CartLine
            case "CartLineCost": return Storefront.Objects.CartLineCost
            case "CartUserError": return Storefront.Objects.CartUserError
            case "Collection": return Storefront.Objects.Collection
            case "Comment": return Storefront.Objects.Comment
            case "Company": return Storefront.Objects.Company
            case "CompanyContact": return Storefront.Objects.CompanyContact
            case "CompanyLocation": return Storefront.Objects.CompanyLocation
            case "ComponentizableCartLine": return Storefront.Objects.ComponentizableCartLine
            case "Customer": return Storefront.Objects.Customer
            case "CustomerUserError": return Storefront.Objects.CustomerUserError
            case "ExternalVideo": return Storefront.Objects.ExternalVideo
            case "GenericFile": return Storefront.Objects.GenericFile
            case "Image": return Storefront.Objects.Image
            case "Location": return Storefront.Objects.Location
            case "MailingAddress": return Storefront.Objects.MailingAddress
            case "Market": return Storefront.Objects.Market
            case "MediaImage": return Storefront.Objects.MediaImage
            case "MediaPresentation": return Storefront.Objects.MediaPresentation
            case "Menu": return Storefront.Objects.Menu
            case "MenuItem": return Storefront.Objects.MenuItem
            case "Metafield": return Storefront.Objects.Metafield
            case "MetafieldDeleteUserError": return Storefront.Objects.MetafieldDeleteUserError
            case "MetafieldsSetUserError": return Storefront.Objects.MetafieldsSetUserError
            case "Metaobject": return Storefront.Objects.Metaobject
            case "Model3d": return Storefront.Objects.Model3d
            case "MoneyV2": return Storefront.Objects.MoneyV2
            case "Mutation": return Storefront.Objects.Mutation
            case "Order": return Storefront.Objects.Order
            case "Page": return Storefront.Objects.Page
            case "Product": return Storefront.Objects.Product
            case "ProductConnection": return Storefront.Objects.ProductConnection
            case "ProductOption": return Storefront.Objects.ProductOption
            case "ProductOptionValue": return Storefront.Objects.ProductOptionValue
            case "ProductVariant": return Storefront.Objects.ProductVariant
            case "ProductVariantConnection": return Storefront.Objects.ProductVariantConnection
            case "QueryRoot": return Storefront.Objects.QueryRoot
            case "SearchQuerySuggestion": return Storefront.Objects.SearchQuerySuggestion
            case "SellingPlan": return Storefront.Objects.SellingPlan
            case "Shop": return Storefront.Objects.Shop
            case "ShopPayInstallmentsFinancingPlan": return Storefront.Objects.ShopPayInstallmentsFinancingPlan
            case "ShopPayInstallmentsFinancingPlanTerm": return Storefront.Objects.ShopPayInstallmentsFinancingPlanTerm
            case "ShopPayInstallmentsProductVariantPricing": return Storefront.Objects.ShopPayInstallmentsProductVariantPricing
            case "ShopPolicy": return Storefront.Objects.ShopPolicy
            case "TaxonomyCategory": return Storefront.Objects.TaxonomyCategory
            case "UrlRedirect": return Storefront.Objects.UrlRedirect
            case "UserError": return Storefront.Objects.UserError
            case "UserErrorsShopPayPaymentRequestSessionUserErrors": return Storefront.Objects.UserErrorsShopPayPaymentRequestSessionUserErrors
            case "Video": return Storefront.Objects.Video
            default: return nil
            }
        }
    }

    enum Objects {}
    enum Interfaces {}
    enum Unions {}
}
