import Foundation
import OSLog
import UIKit
import ShopifyCheckoutSheetKit

class AuthenticationService {
    static let shared = AuthenticationService()

    private let clientId: String
    private let clientSecret: String
    private let authEndpoint: String

    private var cachedToken: String?
    private var tokenExpiryDate: Date?
    private var tokenFetchTask: Task<String, Error>?
    private let tokenLock = NSLock()

    private let minimumTokenLifetime: TimeInterval = 5 * 60
    private let tokenBufferTime: TimeInterval = 5 * 60

    private init() {
        let info = InfoDictionary.shared
        self.clientId = info.clientId
        self.clientSecret = info.clientSecret
        self.authEndpoint = info.authEndpoint

        if authEndpoint.isEmpty {
            OSLogger.shared.debug("[AuthenticationService] Warning: ShopifyAuthEndpoint not configured")
        }
    }

    func getAccessToken() async throws -> String {
        tokenLock.lock()
        defer { tokenLock.unlock() }

        if let token = validCachedToken() {
            OSLogger.shared.debug("[AuthenticationService] Using cached token with remaining lifetime: \(remainingTokenLifetime() ?? 0) seconds")
            return token
        }

        if let existingTask = tokenFetchTask {
            tokenLock.unlock()
            OSLogger.shared.debug("[AuthenticationService] Waiting for existing token fetch")
            let result = try await existingTask.value
            tokenLock.lock()
            return result
        }

        let task = Task<String, Error> {
            try await self.fetchNewAccessToken()
        }
        tokenFetchTask = task

        tokenLock.unlock()
        let token = try await task.value
        tokenLock.lock()

        tokenFetchTask = nil
        return token
    }

    func fetchAccessToken() async throws -> String {
        return try await getAccessToken()
    }

    func prefetchTokenInBackground() {
        guard hasConfiguration() else {
            OSLogger.shared.debug("[AuthenticationService] Skipping prefetch - auth not configured")
            return
        }

        Task {
            do {
                _ = try await getAccessToken()
                OSLogger.shared.debug("[AuthenticationService] Successfully prefetched token in background")
            } catch {
                OSLogger.shared.error("[AuthenticationService] Failed to prefetch token: \(error.localizedDescription)")
            }
        }
    }

    private func fetchNewAccessToken() async throws -> String {
        guard !clientId.isEmpty && !clientSecret.isEmpty else {
            throw AuthError.missingCredentials
        }

        guard !authEndpoint.isEmpty else {
            OSLogger.shared.error("[AuthenticationService] Auth endpoint is empty")
            throw AuthError.invalidEndpoint
        }

        guard let url = URL(string: authEndpoint) else {
            OSLogger.shared.error("[AuthenticationService] Failed to create URL from: '\(authEndpoint)'")
            throw AuthError.invalidEndpoint
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "client_id": clientId,
            "client_secret": clientSecret,
            "grant_type": "client_credentials"
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        OSLogger.shared.debug("[AuthenticationService] Fetching new access token from \(authEndpoint)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            OSLogger.shared.error("[AuthenticationService] Failed to fetch access token: HTTP \(httpResponse.statusCode)")
            throw AuthError.requestFailed(statusCode: httpResponse.statusCode)
        }

        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)

        OSLogger.shared.debug("[AuthenticationService] Successfully fetched new access token")

        cacheToken(tokenResponse)

        return tokenResponse.accessToken
    }

    private func cacheToken(_ response: TokenResponse) {
        tokenLock.lock()
        defer { tokenLock.unlock() }

        cachedToken = response.accessToken

        if let expiresIn = response.expiresIn {
            let ttl = max(TimeInterval(expiresIn) - tokenBufferTime, minimumTokenLifetime)
            tokenExpiryDate = Date().addingTimeInterval(ttl)
            OSLogger.shared.debug("[AuthenticationService] Token cached with TTL: \(ttl) seconds")
        } else {
            tokenExpiryDate = Date().addingTimeInterval(55 * 60)
            OSLogger.shared.debug("[AuthenticationService] Token cached with default TTL: 55 minutes")
        }
    }

    private func validCachedToken() -> String? {
        guard let token = cachedToken,
              let expiry = tokenExpiryDate,
              expiry > Date().addingTimeInterval(minimumTokenLifetime) else {
            return nil
        }
        return token
    }

    private func remainingTokenLifetime() -> TimeInterval? {
        guard let expiry = tokenExpiryDate else { return nil }
        return expiry.timeIntervalSinceNow
    }

    func hasConfiguration() -> Bool {
        let configured = !clientId.isEmpty && !clientSecret.isEmpty && !authEndpoint.isEmpty
        OSLogger.shared.debug("[AuthenticationService] hasConfiguration called - clientId: \(!clientId.isEmpty), clientSecret: \(!clientSecret.isEmpty), authEndpoint: \(!authEndpoint.isEmpty), result: \(configured)")
        return configured
    }

    enum AuthError: LocalizedError {
        case missingCredentials
        case invalidEndpoint
        case requestFailed(statusCode: Int)
        case invalidResponse

        var errorDescription: String? {
            switch self {
            case .missingCredentials:
                return "Authentication credentials not configured"
            case .invalidEndpoint:
                return "Invalid or missing authentication endpoint"
            case .requestFailed(let statusCode):
                return "Authentication request failed with status code: \(statusCode)"
            case .invalidResponse:
                return "Invalid response from authentication server"
            }
        }
    }

    struct TokenResponse: Codable {
        let accessToken: String
        let tokenType: String?
        let expiresIn: Int?
        let scope: String?

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case tokenType = "token_type"
            case expiresIn = "expires_in"
            case scope = "scope"
        }
    }
}
