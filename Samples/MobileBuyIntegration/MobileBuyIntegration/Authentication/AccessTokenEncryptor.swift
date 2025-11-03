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
import CryptoKit
import Foundation

/// Encrypts access tokens for use in JWT authentication payloads
enum AccessTokenEncryptor {
    /// AES-128 key and block size in bytes (128 bits = 16 bytes)
    private static let aes128KeySize = 16

    /// Encrypts plaintext, returning base64url-encoded result
    /// Using AES-128-CBC
    ///
    /// - Parameters:
    ///   - plaintext: The string to encrypt
    ///   - secret: The shared secret used for encryption
    /// - Returns: Base64url-encoded encrypted data, or nil if encryption fails
    static func encryptAndSignBase64URLSafe(plaintext: String, secret: String) -> String? {
        guard let plaintextData = plaintext.data(using: .utf8),
              let secretData = secret.data(using: .utf8)
        else {
            return nil
        }

        // Derive keys from the shared secret using SHA-256
        // Splits the 32-byte hash into two 16-byte keys:
        // - Bytes 0-15: encryption key
        // - Bytes 16-31: signature key
        let keyHash = SHA256.hash(data: secretData)
        let encryptionKey = Data(keyHash.prefix(aes128KeySize))
        let signatureKey = Data(keyHash.dropFirst(aes128KeySize))

        var iv = Data(count: aes128KeySize)
        let randomStatus = iv.withUnsafeMutableBytes { ivBytes in
            guard let baseAddress = ivBytes.baseAddress else {
                return errSecParam
            }
            return SecRandomCopyBytes(kSecRandomDefault, aes128KeySize, baseAddress)
        }

        guard randomStatus == errSecSuccess else {
            return nil
        }

        guard let ciphertext = encryptAES128CBC(data: plaintextData, key: encryptionKey, iv: iv) else {
            return nil
        }

        let combined = iv + ciphertext
        let signature = signData(combined, signatureKey: signatureKey)
        let signedData = combined + signature
        return signedData.base64URLEncodedString()
    }

    /// Signs data using HMAC-SHA256
    private static func signData(_ data: Data, signatureKey: Data) -> Data {
        let key = SymmetricKey(data: signatureKey)
        let signature = HMAC<SHA256>.authenticationCode(for: data, using: key)
        return Data(signature)
    }

    /// Performs AES-128-CBC encryption
    private static func encryptAES128CBC(data: Data, key: Data, iv: Data) -> Data? {
        let cryptLength = data.count + kCCBlockSizeAES128
        var cryptData = Data(count: cryptLength)

        var numBytesEncrypted: size_t = 0

        let cryptStatus = cryptData.withUnsafeMutableBytes { cryptBytes in
            data.withUnsafeBytes { dataBytes in
                iv.withUnsafeBytes { ivBytes in
                    key.withUnsafeBytes { keyBytes in
                        CCCrypt(
                            CCOperation(kCCEncrypt),
                            CCAlgorithm(kCCAlgorithmAES),
                            CCOptions(kCCOptionPKCS7Padding),
                            keyBytes.baseAddress, key.count,
                            ivBytes.baseAddress,
                            dataBytes.baseAddress, data.count,
                            cryptBytes.baseAddress, cryptLength,
                            &numBytesEncrypted
                        )
                    }
                }
            }
        }

        guard cryptStatus == kCCSuccess else {
            return nil
        }

        cryptData.count = numBytesEncrypted
        return cryptData
    }
}

extension Data {
    /// Encodes data as base64url (RFC 4648 Section 5) - no padding, URL-safe characters
    func base64URLEncodedString() -> String {
        let base64 = base64EncodedString()
        return base64
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
