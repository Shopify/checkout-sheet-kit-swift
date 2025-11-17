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
import OSLog
import ShopifyCheckoutSheetKit
import UIKit

actor TokenManager {
    private var cachedToken: String?
    private var tokenExpiryDate: Date?
    private var tokenFetchTask: Task<String, Error>?

    private let minimumTokenLifetime: TimeInterval = 5 * 60
    private let tokenBufferTime: TimeInterval = 5 * 60

    func getValidToken() -> String? {
        guard let token = cachedToken,
            let expiry = tokenExpiryDate,
            expiry > Date().addingTimeInterval(minimumTokenLifetime)
        else {
            return nil
        }
        return token
    }

    func cacheToken(_ token: String, expiresIn: Int?) {
        cachedToken = token

        if let expiresIn = expiresIn {
            let ttl = max(TimeInterval(expiresIn) - tokenBufferTime, minimumTokenLifetime)
            tokenExpiryDate = Date().addingTimeInterval(ttl)
            OSLogger.shared.debug("[AuthenticationService] Token cached with TTL: \(ttl) seconds")
        } else {
            tokenExpiryDate = Date().addingTimeInterval(55 * 60)
            OSLogger.shared.debug(
                "[AuthenticationService] Token cached with default TTL: 55 minutes"
            )
        }
    }

    func getExistingTask() -> Task<String, Error>? {
        return tokenFetchTask
    }

    func setTask(_ task: Task<String, Error>?) {
        tokenFetchTask = task
    }

    func remainingTokenLifetime() -> TimeInterval? {
        guard let expiry = tokenExpiryDate else { return nil }
        return expiry.timeIntervalSinceNow
    }
}

class AuthenticationService {
    static let shared = AuthenticationService()

    private let clientId: String
    private let clientSecret: String
    private let authEndpoint: String

    private let tokenManager = TokenManager()

    private init() {
        let info = InfoDictionary.shared
        self.clientId = info.clientId
        self.clientSecret = info.clientSecret
        self.authEndpoint = info.authEndpoint

        if authEndpoint.isEmpty {
            OSLogger.shared.debug(
                "[AuthenticationService] Warning: ShopifyAuthEndpoint not configured"
            )
        }
    }

    func getAccessToken() async throws -> String {
        // Check for valid cached token
        if let token = await tokenManager.getValidToken() {
            let remaining = await tokenManager.remainingTokenLifetime() ?? 0
            OSLogger.shared.debug(
                "[AuthenticationService] Using cached token with remaining lifetime: \(remaining) seconds"
            )
            return token
        }

        // Check for existing fetch task
        if let existingTask = await tokenManager.getExistingTask() {
            OSLogger.shared.debug("[AuthenticationService] Waiting for existing token fetch")
            return try await existingTask.value
        }

        // Create new fetch task
        let task = Task<String, Error> {
            try await self.fetchNewAccessToken()
        }

        await tokenManager.setTask(task)

        do {
            let token = try await task.value
            await tokenManager.setTask(nil)
            return token
        } catch {
            await tokenManager.setTask(nil)
            throw error
        }
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
                OSLogger.shared.debug(
                    "[AuthenticationService] Successfully prefetched token in background"
                )
            } catch {
                OSLogger.shared.error(
                    "[AuthenticationService] Failed to prefetch token: \(error.localizedDescription)"
                )
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
            OSLogger.shared.error(
                "[AuthenticationService] Failed to create URL from: '\(authEndpoint)'"
            )
            throw AuthError.invalidEndpoint
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "client_id": clientId,
            "client_secret": clientSecret,
            "grant_type": "client_credentials",
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        OSLogger.shared.debug(
            "[AuthenticationService] Fetching new access token from \(authEndpoint)"
        )

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            OSLogger.shared.error(
                "[AuthenticationService] Failed to fetch access token: HTTP \(httpResponse.statusCode)"
            )
            throw AuthError.requestFailed(statusCode: httpResponse.statusCode)
        }

        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)

        OSLogger.shared.debug("[AuthenticationService] Successfully fetched new access token")

        await tokenManager.cacheToken(tokenResponse.accessToken, expiresIn: tokenResponse.expiresIn)

        return tokenResponse.accessToken
    }

    func hasConfiguration() -> Bool {
        let configured = !clientId.isEmpty && !clientSecret.isEmpty && !authEndpoint.isEmpty
        OSLogger.shared.debug(
            "[AuthenticationService] hasConfiguration called - clientId: \(!clientId.isEmpty), clientSecret: \(!clientSecret.isEmpty), authEndpoint: \(!authEndpoint.isEmpty), result: \(configured)"
        )
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
