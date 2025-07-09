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

//
//  StorefrontAPI+Queries.swift
//  ShopifyAcceleratedCheckouts
//

import Foundation

// MARK: - Query Operations

@available(iOS 17.0, *)
extension StorefrontAPI {
    /// Get a cart by ID
    /// - Parameter id: Cart ID
    /// - Returns: The cart or nil if not found
    func cart(by id: GraphQLScalars.ID) async throws -> Cart? {
        let variables: [String: Any] = [
            "id": id.rawValue
        ]

        let response = try await client.query(
            Operations.getCart(variables: variables)
        )

        return response.data?.cart
    }

    /// Get products
    /// - Parameter first: Number of products to fetch
    /// - Returns: Array of products
    func products(first limit: Int = 10) async throws -> [Product] {
        let variables: [String: Any] = [
            "first": limit
        ]

        let response = try await client.query(
            Operations.getProducts(variables: variables)
        )

        return response.data?.products.nodes ?? []
    }

    /// Get shop information
    /// - Returns: Shop details
    func shop() async throws -> Shop {
        let response = try await client.query(
            Operations.getShop()
        )

        guard let shop = response.data?.shop else {
            throw StorefrontAPI.Errors.payload(propertyName: "shop")
        }
        return shop
    }
}
