/*
 MIT License

 Copyright 2023 - Present, Shopify Inc.

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

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
            case "Checkout": return Storefront.Objects.Checkout
            case "CheckoutLineItem": return Storefront.Objects.CheckoutLineItem
            case "CheckoutUserError": return Storefront.Objects.CheckoutUserError
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
            case "Payment": return Storefront.Objects.Payment
            case "Product": return Storefront.Objects.Product
            case "ProductConnection": return Storefront.Objects.ProductConnection
            case "ProductOption": return Storefront.Objects.ProductOption
            case "ProductVariant": return Storefront.Objects.ProductVariant
            case "ProductVariantConnection": return Storefront.Objects.ProductVariantConnection
            case "QueryRoot": return Storefront.Objects.QueryRoot
            case "SearchQuerySuggestion": return Storefront.Objects.SearchQuerySuggestion
            case "Shop": return Storefront.Objects.Shop
            case "ShopPolicy": return Storefront.Objects.ShopPolicy
            case "UrlRedirect": return Storefront.Objects.UrlRedirect
            case "UserError": return Storefront.Objects.UserError
            case "Video": return Storefront.Objects.Video
            default: return nil
            }
        }
    }

    enum Objects {}
    enum Interfaces {}
    enum Unions {}
}
