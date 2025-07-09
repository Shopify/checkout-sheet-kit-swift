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
