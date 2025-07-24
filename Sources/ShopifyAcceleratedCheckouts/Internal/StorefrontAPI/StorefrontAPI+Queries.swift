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

    /// Get shop settings with caching and deduplication
    /// - Parameters:
    ///   - domain: The shop domain for cache key generation
    ///   - accessToken: The access token for cache key generation
    /// - Returns: Cached or fresh ShopSettings
    func shopSettings(domain: String, accessToken: String) async throws -> ShopSettings {
        return try await QueryCache.shared.loadCached(
            domain: domain,
            accessToken: accessToken,
            cacheKey: "shop"
        ) {
            let shop = try await self.shop()
            return ShopSettings(from: shop)
        }
    }
}

/// Generic cache manager for StorefrontAPI queries that handles request deduplication and caching
@available(iOS 17.0, *)
actor QueryCache {
    static let shared = QueryCache()

    private var cache: [String: Any] = [:]
    private var inflightRequests: [String: Any] = [:]

    private init() {}

    /// Loads data with deduplication - multiple simultaneous calls will share the same request
    func loadCached<T>(
        domain: String,
        accessToken: String,
        cacheKey: String,
        query: @escaping () async throws -> T
    ) async throws -> T {
        let key = buildCacheKey(domain: domain, accessToken: accessToken, queryKey: cacheKey)

        if let cached = cache[key] as? T {
            return cached
        }

        if let existingTask = inflightRequests[key] as? Task<T, Error> {
            return try await existingTask.value
        }

        let task = Task<T, Error> {
            let result = try await query()

            self.cacheResult(result, for: key)

            return result
        }

        inflightRequests[key] = task

        do {
            let result = try await task.value
            inflightRequests.removeValue(forKey: key)
            return result
        } catch {
            inflightRequests.removeValue(forKey: key)
            throw error
        }
    }

    func clearCache(domain: String? = nil, accessToken: String? = nil, cacheKey: String? = nil) {
        if let domain, let accessToken, let cacheKey {
            let key = buildCacheKey(domain: domain, accessToken: accessToken, queryKey: cacheKey)
            cache.removeValue(forKey: key)
            inflightRequests.removeValue(forKey: key)
        } else if let domain, let accessToken {
            let prefix = "\(domain)-\(accessToken.prefix(10))-"
            let keysToRemove = cache.keys.filter { $0.hasPrefix(prefix) }
            for key in keysToRemove {
                cache.removeValue(forKey: key)
                inflightRequests.removeValue(forKey: key)
            }
        } else {
            cache.removeAll()
            inflightRequests.removeAll()
        }
    }

    private func cacheResult(_ result: some Any, for key: String) {
        cache[key] = result
    }

    private func buildCacheKey(domain: String, accessToken: String, queryKey: String) -> String {
        return "\(domain)-\(accessToken.prefix(10))-\(queryKey)"
    }
}
