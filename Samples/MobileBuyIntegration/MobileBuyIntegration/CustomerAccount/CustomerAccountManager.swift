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

import CommonCrypto
import Foundation
import ShopifyCheckoutSheetKit

enum CustomerAccountError: LocalizedError {
    case missingConfiguration
    case invalidAuthorizationCode
    case tokenExchangeFailed(String)
    case tokenRefreshFailed(String)
    case notAuthenticated
    case invalidState

    var errorDescription: String? {
        switch self {
        case .missingConfiguration:
            return "Missing Customer Account API configuration"
        case .invalidAuthorizationCode:
            return "Invalid authorization code received"
        case let .tokenExchangeFailed(message):
            return "Token exchange failed: \(message)"
        case let .tokenRefreshFailed(message):
            return "Token refresh failed: \(message)"
        case .notAuthenticated:
            return "User is not authenticated"
        case .invalidState:
            return "Invalid state parameter - possible CSRF attack"
        }
    }
}

@MainActor
final class CustomerAccountManager: ObservableObject {
    static let shared = CustomerAccountManager()

    private let logger = OSLogger(prefix: "CustomerAccount", logLevel: ShopifyCheckoutSheetKit.configuration.logLevel)
    private let shopId: String?
    private let clientId: String?

    private var redirectUri: String? {
        InfoDictionary.shared.customerAccountApiRedirectUri
    }

    private var callbackScheme: String? {
        guard let shopId else { return nil }
        return "shop.\(shopId).app"
    }

    var authorizationEndpoint: String? {
        guard let shopId else { return nil }
        return "https://shopify.com/authentication/\(shopId)/oauth/authorize"
    }

    var tokenEndpoint: String? {
        guard let shopId else { return nil }
        return "https://shopify.com/authentication/\(shopId)/oauth/token"
    }

    var logoutEndpoint: String? {
        guard let shopId else { return nil }
        return "https://shopify.com/authentication/\(shopId)/logout"
    }

    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var customerEmail: String?
    @Published var tokenExpiresAt: Date?

    private var codeVerifier: String?
    private var savedState: String?

    private init() {
        shopId = InfoDictionary.shared.customerAccountApiShopId
        clientId = InfoDictionary.shared.customerAccountApiClientId
        checkExistingSession()
    }

    func generateCodeVerifier() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return base64URLEncode(Data(bytes))
    }

    func generateCodeChallenge(for verifier: String) -> String {
        guard let data = verifier.data(using: .utf8) else {
            return ""
        }

        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }

        return base64URLEncode(Data(hash))
    }

    private func base64URLEncode(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private func generateState() -> String {
        var bytes = [UInt8](repeating: 0, count: 27)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return base64URLEncode(Data(bytes))
    }

    func buildAuthorizationURL() -> URL? {
        guard let authorizationEndpoint, let clientId, let redirectUri else {
            return nil
        }

        codeVerifier = generateCodeVerifier()
        savedState = generateState()

        guard let verifier = codeVerifier, let state = savedState else {
            return nil
        }

        let codeChallenge = generateCodeChallenge(for: verifier)

        var components = URLComponents(string: authorizationEndpoint)
        components?.queryItems = [
            URLQueryItem(name: "scope", value: "openid email customer-account-api:full"),
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: redirectUri),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256")
        ]

        return components?.url
    }

    func validateState(_ state: String) -> Bool {
        guard let savedState else {
            return false
        }
        return state == savedState
    }

    func exchangeCodeForTokens(code: String) async throws {
        logger.debug("Exchanging authorization code for tokens...")

        guard let verifier = codeVerifier else {
            logger.error("No code verifier available")
            throw CustomerAccountError.invalidAuthorizationCode
        }

        guard let clientId, let redirectUri else {
            logger.error("Missing client ID or redirect URI")
            throw CustomerAccountError.missingConfiguration
        }

        isLoading = true
        defer { isLoading = false }

        let body: [String: String] = [
            "grant_type": "authorization_code",
            "client_id": clientId,
            "redirect_uri": redirectUri,
            "code": code,
            "code_verifier": verifier
        ]

        let tokens = try await performTokenRequest(body: body)
        logger.debug("Token exchange successful, expires at: \(tokens.expiresAt)")
        KeychainHelper.shared.saveTokens(tokens)
        isAuthenticated = true
        tokenExpiresAt = tokens.expiresAt
        extractEmailFromIdToken(tokens.idToken)

        CartManager.shared.resetCart()

        codeVerifier = nil
        savedState = nil
        logger.debug("Login complete, authenticated: \(isAuthenticated), email: \(customerEmail ?? "nil")")
    }

    func refreshAccessToken() async throws {
        logger.debug("Starting token refresh...")

        guard let tokens = KeychainHelper.shared.getTokens(),
              let refreshToken = tokens.refreshToken
        else {
            logger.error("No tokens or refresh token available")
            throw CustomerAccountError.notAuthenticated
        }

        guard let clientId else {
            logger.error("Missing client ID configuration")
            throw CustomerAccountError.missingConfiguration
        }

        let existingEmail = KeychainHelper.shared.getEmail()
        let existingIdToken = tokens.idToken
        logger.debug("Preserved existing email: \(existingEmail ?? "nil"), ID token present: \(existingIdToken != nil)")

        isLoading = true
        defer { isLoading = false }

        let body: [String: String] = [
            "grant_type": "refresh_token",
            "client_id": clientId,
            "refresh_token": refreshToken
        ]

        let newTokens = try await performTokenRequest(body: body)
        logger.debug("Token refresh successful, new expiry: \(newTokens.expiresAt)")

        let tokensToSave = OAuthTokenResult(
            accessToken: newTokens.accessToken,
            refreshToken: newTokens.refreshToken ?? refreshToken,
            expiresIn: newTokens.expiresIn,
            idToken: newTokens.idToken ?? existingIdToken,
            tokenType: newTokens.tokenType
        )
        KeychainHelper.shared.saveTokens(tokensToSave)
        tokenExpiresAt = tokensToSave.expiresAt
        logger.debug("Saved tokens with ID token preserved: \(tokensToSave.idToken != nil)")

        if let newIdToken = newTokens.idToken {
            logger.debug("New ID token received, extracting email")
            extractEmailFromIdToken(newIdToken)
        } else if let existingEmail {
            logger.debug("No new ID token, preserving existing email: \(existingEmail)")
            customerEmail = existingEmail
        } else if let existingIdToken {
            logger.debug("No stored email but have original ID token, extracting...")
            extractEmailFromIdToken(existingIdToken)
        } else {
            logger.error("No ID token in refresh response and no stored email or ID token")
        }
    }

    func getValidAccessToken() async throws -> String {
        logger.debug("Getting valid access token...")

        guard let tokens = KeychainHelper.shared.getTokens() else {
            logger.error("No tokens available")
            throw CustomerAccountError.notAuthenticated
        }

        if tokens.isExpiringSoon {
            logger.debug("Token expiring soon (expires at: \(tokens.expiresAt)), refreshing...")
            try await refreshAccessToken()
            guard let refreshedTokens = KeychainHelper.shared.getTokens() else {
                logger.error("No tokens after refresh")
                throw CustomerAccountError.notAuthenticated
            }
            logger.debug("Returning refreshed access token")
            return refreshedTokens.accessToken
        }

        logger.debug("Returning valid access token (expires at: \(tokens.expiresAt))")
        return tokens.accessToken
    }

    func logout() {
        logger.debug("Logging out...")
        let idToken = KeychainHelper.shared.getTokens()?.idToken

        KeychainHelper.shared.clearTokens()
        isAuthenticated = false
        customerEmail = nil
        tokenExpiresAt = nil
        codeVerifier = nil
        savedState = nil

        CartManager.shared.resetCart()

        if let idToken {
            logger.debug("Sending logout request to server")
            Task {
                await performLogoutRequest(idTokenHint: idToken)
            }
        }
        logger.debug("Logout complete")
    }

    private func performLogoutRequest(idTokenHint: String) async {
        guard let logoutEndpoint else { return }
        guard var components = URLComponents(string: logoutEndpoint) else { return }
        components.queryItems = [
            URLQueryItem(name: "id_token_hint", value: idTokenHint)
        ]

        guard let url = components.url else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        _ = try? await URLSession.shared.data(for: request)
    }

    func checkExistingSession() {
        logger.debug("Checking existing session...")

        guard let tokens = KeychainHelper.shared.getTokens() else {
            logger.debug("No tokens found in keychain")
            return
        }

        customerEmail = KeychainHelper.shared.getEmail()
        logger.debug("Loaded email from keychain: \(customerEmail ?? "nil")")

        if !tokens.isExpired {
            logger.debug("Tokens valid, expires at: \(tokens.expiresAt)")
            isAuthenticated = true
            tokenExpiresAt = tokens.expiresAt
            if customerEmail == nil {
                logger.debug("No stored email, attempting extraction from ID token")
                extractEmailFromIdToken(tokens.idToken)
            }
        } else if tokens.refreshToken != nil {
            logger.debug("Access token expired, attempting refresh...")
            Task {
                do {
                    try await refreshAccessToken()
                    isAuthenticated = true
                    logger.debug("Session restored after refresh")
                } catch {
                    logger.error("Refresh failed: \(error), logging out")
                    logout()
                }
            }
        } else {
            logger.error("Token expired and no refresh token available, logging out")
            logout()
        }
    }

    private func performTokenRequest(body: [String: String]) async throws -> OAuthTokenResult {
        guard let tokenEndpoint, let url = URL(string: tokenEndpoint) else {
            throw CustomerAccountError.tokenExchangeFailed("Invalid token endpoint URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let bodyString = body.map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value)" }
            .joined(separator: "&")
        request.httpBody = bodyString.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CustomerAccountError.tokenExchangeFailed("Invalid response")
        }

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw CustomerAccountError.tokenExchangeFailed("Status \(httpResponse.statusCode): \(errorMessage)")
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        struct TokenResponse: Decodable {
            let accessToken: String
            let refreshToken: String?
            let expiresIn: Int
            let idToken: String?
            let tokenType: String
        }

        let tokenResponse = try decoder.decode(TokenResponse.self, from: data)

        return OAuthTokenResult(
            accessToken: tokenResponse.accessToken,
            refreshToken: tokenResponse.refreshToken,
            expiresIn: tokenResponse.expiresIn,
            idToken: tokenResponse.idToken,
            tokenType: tokenResponse.tokenType
        )
    }

    private func extractEmailFromIdToken(_ idToken: String?) {
        guard let idToken else {
            logger.debug("extractEmailFromIdToken called with nil ID token")
            return
        }

        let parts = idToken.split(separator: ".")
        guard parts.count == 3 else {
            logger.error("Invalid ID token format (expected 3 parts, got \(parts.count))")
            return
        }

        var payload = String(parts[1])
        while payload.count % 4 != 0 {
            payload += "="
        }
        payload = payload
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        guard let data = Data(base64Encoded: payload),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            logger.error("Failed to decode ID token payload")
            return
        }

        logger.debug("ID Token payload claims:")
        for (key, value) in json.sorted(by: { $0.key < $1.key }) {
            logger.debug("  \(key): \(value)")
        }

        guard let email = json["email"] as? String else {
            logger.error("No 'email' claim found in ID token")
            return
        }

        logger.debug("Extracted email from ID token: \(email)")
        customerEmail = email
        KeychainHelper.shared.saveEmail(email)
    }

    func handleCallback(url: URL) -> Bool {
        guard let callbackScheme,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.scheme == callbackScheme,
              components.host == "callback"
        else {
            return false
        }

        guard let queryItems = components.queryItems else {
            return false
        }

        let queryDict = Dictionary(uniqueKeysWithValues: queryItems.compactMap { item -> (String, String)? in
            guard let value = item.value else { return nil }
            return (item.name, value)
        })

        guard let state = queryDict["state"], validateState(state) else {
            return false
        }

        guard let code = queryDict["code"] else {
            return false
        }

        Task {
            do {
                try await exchangeCodeForTokens(code: code)
            } catch {
                logger.error("Failed to exchange code for tokens: \(error)")
            }
        }

        return true
    }
}
