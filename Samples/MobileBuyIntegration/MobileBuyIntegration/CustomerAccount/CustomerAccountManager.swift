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

    private static let shopId = "86942908764"
    private static let clientId = "shp_33c68c51-8265-4d0b-bd93-7727f949262d"
    private static let redirectUri = "shop.\(shopId).app://callback"

    static let authorizationEndpoint = "https://shopify.com/authentication/\(shopId)/oauth/authorize"
    static let tokenEndpoint = "https://shopify.com/authentication/\(shopId)/oauth/token"
    static let logoutEndpoint = "https://shopify.com/authentication/\(shopId)/logout"
    static let customerAccountUrl = "https://shopify.com/\(shopId)/account"

    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var customerEmail: String?

    private var codeVerifier: String?
    private var savedState: String?

    private init() {
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
        codeVerifier = generateCodeVerifier()
        savedState = generateState()

        guard let verifier = codeVerifier, let state = savedState else {
            return nil
        }

        let codeChallenge = generateCodeChallenge(for: verifier)

        var components = URLComponents(string: Self.authorizationEndpoint)
        components?.queryItems = [
            URLQueryItem(name: "scope", value: "openid email customer-account-api:full"),
            URLQueryItem(name: "client_id", value: Self.clientId),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: Self.redirectUri),
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
        guard let verifier = codeVerifier else {
            throw CustomerAccountError.invalidAuthorizationCode
        }

        isLoading = true
        defer { isLoading = false }

        let body: [String: String] = [
            "grant_type": "authorization_code",
            "client_id": Self.clientId,
            "redirect_uri": Self.redirectUri,
            "code": code,
            "code_verifier": verifier
        ]

        let tokens = try await performTokenRequest(body: body)
        KeychainHelper.shared.saveTokens(tokens)
        isAuthenticated = true
        extractEmailFromIdToken(tokens.idToken)

        codeVerifier = nil
        savedState = nil
    }

    func refreshAccessToken() async throws {
        guard let tokens = KeychainHelper.shared.getTokens(),
              let refreshToken = tokens.refreshToken
        else {
            throw CustomerAccountError.notAuthenticated
        }

        isLoading = true
        defer { isLoading = false }

        let body: [String: String] = [
            "grant_type": "refresh_token",
            "client_id": Self.clientId,
            "refresh_token": refreshToken
        ]

        let newTokens = try await performTokenRequest(body: body)
        KeychainHelper.shared.saveTokens(newTokens)
        extractEmailFromIdToken(newTokens.idToken)
    }

    func getValidAccessToken() async throws -> String {
        guard let tokens = KeychainHelper.shared.getTokens() else {
            throw CustomerAccountError.notAuthenticated
        }

        if tokens.isExpiringSoon {
            try await refreshAccessToken()
            guard let refreshedTokens = KeychainHelper.shared.getTokens() else {
                throw CustomerAccountError.notAuthenticated
            }
            return refreshedTokens.accessToken
        }

        return tokens.accessToken
    }

    func logout() {
        KeychainHelper.shared.clearTokens()
        isAuthenticated = false
        customerEmail = nil
        codeVerifier = nil
        savedState = nil
    }

    func checkExistingSession() {
        if let tokens = KeychainHelper.shared.getTokens() {
            if !tokens.isExpired {
                isAuthenticated = true
                extractEmailFromIdToken(tokens.idToken)
            } else if tokens.refreshToken != nil {
                Task {
                    do {
                        try await refreshAccessToken()
                        isAuthenticated = true
                    } catch {
                        logout()
                    }
                }
            } else {
                logout()
            }
        }
    }

    private func performTokenRequest(body: [String: String]) async throws -> OAuthTokenResult {
        guard let url = URL(string: Self.tokenEndpoint) else {
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
        guard let idToken else { return }

        let parts = idToken.split(separator: ".")
        guard parts.count == 3 else { return }

        var payload = String(parts[1])
        while payload.count % 4 != 0 {
            payload += "="
        }
        payload = payload
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        guard let data = Data(base64Encoded: payload),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let email = json["email"] as? String
        else {
            return
        }

        customerEmail = email
    }

    func handleCallback(url: URL) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.scheme == "shop.86942908764.app",
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
                print("Failed to exchange code for tokens: \(error)")
            }
        }

        return true
    }
}
