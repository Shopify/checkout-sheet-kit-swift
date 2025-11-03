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

import CryptoKit
import Foundation

/// JWT header field keys
private enum JWTHeaderKey {
    static let algorithm = "alg"
}

/// JWT header field values
private enum JWTHeaderValue {
    static let hmacSHA256 = "HS256"
}

/// JWT payload field keys
private enum JWTPayloadKey {
    static let apiKey = "api_key"
    static let accessToken = "access_token"
    static let issuedAt = "iat"
    static let jwtID = "jti"
}

/// Generates JWT authentication tokens for authenticated checkouts
///
/// WARNING: This is for SAMPLE APP demonstration purposes only.
/// Production apps MUST generate tokens server-side to protect secrets.
enum JWTTokenGenerator {
    /// Generates a JWT auth token
    /// - Parameters:
    ///   - apiKey: The app's API key
    ///   - sharedSecret: The app's shared secret
    ///   - accessToken: The app's access token
    /// - Returns: JWT token string, or nil if generation fails
    static func generateAuthToken(
        apiKey: String,
        sharedSecret: String,
        accessToken: String
    ) -> String? {
        guard let encryptedAccessToken = AccessTokenEncryptor.encryptAndSignBase64URLSafe(
            plaintext: accessToken,
            secret: sharedSecret
        ) else {
            return nil
        }

        let issuedAt = Int(Date().timeIntervalSince1970)
        let jti = UUID().uuidString

        let payload: [String: Any] = [
            JWTPayloadKey.apiKey: apiKey,
            JWTPayloadKey.accessToken: encryptedAccessToken,
            JWTPayloadKey.issuedAt: issuedAt,
            JWTPayloadKey.jwtID: jti
        ]

        return encodeJWT(payload: payload, secret: sharedSecret)
    }

    /// Encodes a JWT with HS256 (HMAC-SHA256) signature
    ///
    /// - Parameters:
    ///   - payload: The JWT payload as a dictionary
    ///   - secret: The shared secret for HMAC signing
    /// - Returns: Complete JWT string (header.payload.signature), or nil if encoding fails
    private static func encodeJWT(payload: [String: Any], secret: String) -> String? {
        let header: [String: Any] = [
            JWTHeaderKey.algorithm: JWTHeaderValue.hmacSHA256
        ]

        guard let headerJSON = try? JSONSerialization.data(withJSONObject: header, options: .sortedKeys),
              let payloadJSON = try? JSONSerialization.data(withJSONObject: payload, options: .sortedKeys),
              let secretData = secret.data(using: .utf8)
        else {
            return nil
        }

        let headerBase64 = headerJSON.base64URLEncodedString()
        let payloadBase64 = payloadJSON.base64URLEncodedString()

        // Create signing input: "header.payload"
        let signingInput = "\(headerBase64).\(payloadBase64)"

        guard let signingInputData = signingInput.data(using: .utf8) else {
            return nil
        }

        // Sign with HMAC-SHA256
        let key = SymmetricKey(data: secretData)
        let signature = HMAC<SHA256>.authenticationCode(for: signingInputData, using: key)
        let signatureBase64 = Data(signature).base64URLEncodedString()

        // Return complete JWT: "header.payload.signature"
        return "\(signingInput).\(signatureBase64)"
    }
}
