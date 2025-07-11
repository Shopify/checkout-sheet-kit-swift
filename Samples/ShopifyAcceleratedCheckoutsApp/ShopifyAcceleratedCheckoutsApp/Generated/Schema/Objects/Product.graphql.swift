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

extension Storefront.Objects {
    /// The `Product` object lets you manage products in a merchant’s store.
    ///
    /// Products are the goods and services that merchants offer to customers.
    /// They can include various details such as title, description, price, images, and options such as size or color.
    /// You can use [product variants](/docs/api/storefront/latest/objects/ProductVariant)
    /// to create or update different versions of the same product.
    /// You can also add or update product [media](/docs/api/storefront/latest/interfaces/Media).
    /// Products can be organized by grouping them into a [collection](/docs/api/storefront/latest/objects/Collection).
    ///
    /// Learn more about working with [products and collections](/docs/storefronts/headless/building-with-the-storefront-api/products-collections).
    static let Product = ApolloAPI.Object(
        typename: "Product",
        implementedInterfaces: [
            Storefront.Interfaces.HasMetafields.self,
            Storefront.Interfaces.Node.self,
            Storefront.Interfaces.OnlineStorePublishable.self,
            Storefront.Interfaces.Trackable.self
        ],
        keyFields: nil
    )
}
