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
@preconcurrency import ShopifyCheckoutSheetKit

struct OAuthTokenResult: Codable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int
    let expiresAt: Date
    let idToken: String?
    let tokenType: String

    init(accessToken: String, refreshToken: String?, expiresIn: Int, idToken: String?, tokenType: String = "Bearer") {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresIn = expiresIn
        expiresAt = Date().addingTimeInterval(TimeInterval(expiresIn))
        self.idToken = idToken
        self.tokenType = tokenType
    }

    var isExpired: Bool {
        Date() >= expiresAt
    }

    var isExpiringSoon: Bool {
        Date().addingTimeInterval(5 * 60) >= expiresAt
    }
}

final class KeychainHelper: Sendable {
    static let shared = KeychainHelper()

    private let logger = OSLogger(prefix: "Keychain", logLevel: ShopifyCheckoutSheetKit.configuration.logLevel)
    private let service = "com.shopify.mobilebuyintegration"
    private let tokensKey = "customer_account_tokens"
    private let emailKey = "customer_account_email"

    private init() {}

    @discardableResult
    func save(key: String, data: Data) -> Bool {
        delete(key: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    func read(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            return nil
        }

        return result as? Data
    }

    @discardableResult
    func delete(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    func saveTokens(_ tokens: OAuthTokenResult) {
        guard let data = try? JSONEncoder().encode(tokens) else {
            return
        }
        save(key: tokensKey, data: data)
    }

    func getTokens() -> OAuthTokenResult? {
        guard let data = read(key: tokensKey) else {
            return nil
        }
        return try? JSONDecoder().decode(OAuthTokenResult.self, from: data)
    }

    func clearTokens() {
        delete(key: tokensKey)
        delete(key: emailKey)
        logger.debug("Cleared tokens and email from keychain")
    }

    func saveEmail(_ email: String?) {
        guard let email, let data = email.data(using: .utf8) else {
            delete(key: emailKey)
            logger.debug("Cleared email from keychain (nil provided)")
            return
        }
        save(key: emailKey, data: data)
        logger.debug("Saved email to keychain: \(email)")
    }

    func getEmail() -> String? {
        guard let data = read(key: emailKey) else {
            logger.debug("No email found in keychain")
            return nil
        }
        let email = String(data: data, encoding: .utf8)
        logger.debug("Retrieved email from keychain: \(email ?? "nil")")
        return email
    }
}
