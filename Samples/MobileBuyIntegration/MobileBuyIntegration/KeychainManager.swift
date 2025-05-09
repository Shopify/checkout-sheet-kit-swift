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
import Security

enum KeychainError: Error {
    case duplicateEntry
    case unknown(OSStatus)
    case itemNotFound
    case invalidItemFormat
    case serializationError
}

class KeychainManager {
    static let shared = KeychainManager()

    private init() {}

    private let service = Bundle.main.bundleIdentifier ?? "com.shopify.checkout-sheet-kit"
    private let shopifyTokenKey = "shopifyToken"

    func saveCredentials(email: String, password: String) throws {
        // Save email
        try saveItem(email, for: "email")

        // Save password
        try saveItem(password, for: "password")
    }

    func getCredentials() throws -> (email: String, password: String) {
        let email = try getString(for: "email")
        let password = try getString(for: "password")
        return (email, password)
    }

    func clearCredentials() throws {
        try deleteItem(for: "email")
        try deleteItem(for: "password")
    }

    // MARK: - Shopify Token Methods

    func saveShopifyToken(_ token: ShopifyToken) throws {
        let encoder = JSONEncoder()
        guard let tokenData = try? encoder.encode(token) else {
            throw KeychainError.serializationError
        }

        try saveData(tokenData, for: shopifyTokenKey)
    }

    func getShopifyToken() throws -> ShopifyToken {
        let tokenData = try getData(for: shopifyTokenKey)

        let decoder = JSONDecoder()
        guard let token = try? decoder.decode(ShopifyToken.self, from: tokenData) else {
            throw KeychainError.serializationError
        }

        return token
    }

    func clearShopifyToken() throws {
        try deleteItem(for: shopifyTokenKey)
    }

    private func saveItem(_ item: String, for key: String) throws {
        guard let data = item.data(using: .utf8) else {
            throw KeychainError.serializationError
        }

        try saveData(data, for: key)
    }

    private func saveData(_ data: Data, for key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        if status == errSecDuplicateItem {
            // Item already exists, update it
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: key
            ]

            let attributes: [String: Any] = [
                kSecValueData as String: data
            ]

            let updateStatus = SecItemUpdate(updateQuery as CFDictionary, attributes as CFDictionary)
            guard updateStatus == errSecSuccess else {
                throw KeychainError.unknown(updateStatus)
            }
        } else if status != errSecSuccess {
            throw KeychainError.unknown(status)
        }
    }

    private func getString(for key: String) throws -> String {
        let data = try getData(for: key)

        guard let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidItemFormat
        }

        return string
    }

    private func getData(for key: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            throw KeychainError.itemNotFound
        }

        guard let data = result as? Data else {
            throw KeychainError.invalidItemFormat
        }

        return data
    }

    private func deleteItem(for key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unknown(status)
        }
    }
}
