import Foundation
import OSLog
import ShopifyCheckoutSheetKit

class AuthenticationService {
    static let shared = AuthenticationService()

    private let clientId: String
    private let clientSecret: String
    private let authEndpoint: String

    private init() {
        let info = InfoDictionary.shared
        self.clientId = info.clientId
        self.clientSecret = info.clientSecret
        self.authEndpoint = info.authEndpoint

        if authEndpoint.isEmpty {
            OSLogger.shared.debug("[AuthenticationService] Warning: ShopifyAuthEndpoint not configured")
        }
    }

    func fetchAccessToken() async throws -> String {
        guard !clientId.isEmpty && !clientSecret.isEmpty else {
            throw AuthError.missingCredentials
        }

        guard !authEndpoint.isEmpty else {
            throw AuthError.invalidEndpoint
        }

        guard let url = URL(string: authEndpoint) else {
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

        OSLogger.shared.debug("[AuthenticationService] Fetching access token from \(authEndpoint)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            OSLogger.shared.error("[AuthenticationService] Failed to fetch access token: HTTP \(httpResponse.statusCode)")
            throw AuthError.requestFailed(statusCode: httpResponse.statusCode)
        }

        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)

        OSLogger.shared.debug("[AuthenticationService] Successfully fetched access token")

        return tokenResponse.accessToken
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
