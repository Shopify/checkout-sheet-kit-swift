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
import SwiftUI
import WebKit

struct ShopifyToken: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    let createdAt: Date

    var isExpired: Bool {
        Date().timeIntervalSince(createdAt) > TimeInterval(expiresIn)
    }
}

struct ShopifyWebView: UIViewRepresentable {
    let url: String
    var onRedirect: (URL) -> Void

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ webView: WKWebView, context _: Context) {
        print("authURL: \(url)")
        let request = URLRequest(url: URL(string: url)!)
        webView.load(request)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: ShopifyWebView

        init(_ parent: ShopifyWebView) {
            self.parent = parent
        }

        func webView(
            _: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            guard let url = navigationAction.request.url else {
                return
            }

            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true)
            else {
                decisionHandler(.allow)
                return
            }

            guard let queryItems = components.queryItems else {
                decisionHandler(.allow)
                return
            }

            //   guard let state = queryItems.first(where: { $0.name == "state" })?.value,
//     state == savedState else {
//     decisionHandler(.allow)
//     return
            //   }

            guard let code = queryItems.first(where: { $0.name == "code" })?.value else {
                decisionHandler(.allow)
                return
            }

            if url.absoluteString.contains("callback") {
                parent.onRedirect(url)
                decisionHandler(.cancel)
                return
            }

            decisionHandler(.allow)
            parent.onRedirect(url)
        }
    }
}

struct ProfileView: View {
    @State private var isLoggedIn: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var showWebView: Bool = false
    @State private var codeVerifier: String = ""

    // These should be configured properly for your app
    private let clientId = "shp_33c68c51-8265-4d0b-bd93-7727f949262d"
    private let shopDomain = InfoDictionary.shared.domain
    private let callbackUrl = "https://shop.86942908764.app://callback"

    init() {
        // Try to load token from keychain on init
        if let token = try? KeychainManager.shared.getShopifyToken(), !token.isExpired {
            _isLoggedIn = State(initialValue: true)
        }
    }

    var body: some View {
        NavigationView {
            Form {
                if !isLoggedIn {
                    Section(header: Text("Login Information")) {
                        Button(action: initiateLogin) {
                            Text("Login with Shopify")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    Section {
                        // Show customer info if available
                        if let token = try? KeychainManager.shared.getShopifyToken() {
                            Text("Logged in with access token")
                                .fontWeight(.medium)

                            Text("Token expires in \(timeRemaining(token: token))")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }

                        Button(action: logout) {
                            Text("Sign Out")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .alert("Error", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
            .sheet(isPresented: $showWebView) {
                if let authURL = createAuthorizationURL() {
                    ShopifyWebView(url: authURL) { callbackURL in
                        handleCallback(url: callbackURL)
                        showWebView = false
                    }
                } else {
                    Text("Failed to create authorization URL")
                        .padding()
                }
            }
        }
    }

    private func timeRemaining(token: ShopifyToken) -> String {
        let elapsed = Date().timeIntervalSince(token.createdAt)
        let remaining = max(0, Double(token.expiresIn) - elapsed)

        let minutes = Int(remaining / 60)
        let seconds = Int(remaining.truncatingRemainder(dividingBy: 60))

        return "\(minutes)m \(seconds)s"
    }

    private func initiateLogin() {
        codeVerifier = generateCodeVerifier()
        showWebView = true
    }

    func generateCodeVerifier() -> String {
        var buffer = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, buffer.count, &buffer)
        return Data(buffer).base64EncodedString()
    }

    func generateCodeChallenge(for codeVerifier: String) -> String {
        guard let data = codeVerifier.data(using: .utf8) else { fatalError() }
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes { bytes in
            _ = CC_SHA256(bytes.baseAddress, CC_LONG(data.count), &digest)
        }
        return Data(digest).base64EncodedString()
    }

    private func createAuthorizationURL() -> String? {
        let codeChallenge = generateCodeChallenge(for: codeVerifier)

        var components = URLComponents(
            string: "https://shopify.com/authentication/86942908764/oauth/authorize")
        components?.queryItems = [
            URLQueryItem(name: "scope", value: "openid email customer-account-api:full"),
            URLQueryItem(name: "client_id", value: "shp_33c68c51-8265-4d0b-bd93-7727f949262d"),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: callbackUrl),
            URLQueryItem(
                name: "state",
                value: String(
                    (0 ..< 36).map { _ in
                        "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
                            .randomElement()!
                    })
            ),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256")
        ]

        return components?.url?.absoluteString
    }

    private func handleCallback(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value
        else {
            showAlert = true
            alertMessage = "Invalid callback URL"
            return
        }

        exchangeCodeForToken(code: code)
    }

    private func exchangeCodeForToken(code: String) {
        let url = URL(string: "https://shopify.com/authentication/86942908764/oauth/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let parameters: [String: String] = [
            "client_id": "shp_33c68c51-8265-4d0b-bd93-7727f949262d",
            "code": code,
            "grant_type": "authorization_code",
            "redirect_uri": callbackUrl,
            "code_verifier": codeVerifier
        ]

        let parameterString = parameters.map { key, value in
            let encodedKey =
                key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? key
            let encodedValue =
                value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
            return "\(encodedKey)=\(encodedValue)"
        }.joined(separator: "&")

        request.httpBody = parameterString.data(using: .utf8)

        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                if let error = error {
                    showAlert = true
                    alertMessage = "Network error: \(error.localizedDescription)"
                    return
                }

                guard let data = data else {
                    showAlert = true
                    alertMessage = "No data received"
                    return
                }

                do {
                    guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                          let accessToken = json["access_token"] as? String,
                          let refreshToken = json["refresh_token"] as? String,
                          let expiresIn = json["expires_in"] as? Int
                    else {
                        showAlert = true
                        alertMessage = "Invalid token response"
                        return
                    }

                    let token = ShopifyToken(
                        accessToken: accessToken,
                        refreshToken: refreshToken,
                        expiresIn: expiresIn,
                        createdAt: Date()
                    )

                    try KeychainManager.shared.saveShopifyToken(token)
                    isLoggedIn = true
                } catch {
                    showAlert = true
                    alertMessage = "Failed to process token: \(error.localizedDescription)"
                }
            }
        }.resume()
    }

    private func refreshToken() {
        guard let token = try? KeychainManager.shared.getShopifyToken() else {
            return
        }
        let url = URL(string: "https://shopify.com/authentication/86942908764/logout")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let parameters: [String: String] = [
            "client_id": "shp_33c68c51-8265-4d0b-bd93-7727f949262d",
            "grant_type": "refresh_token",
            "refresh_token": token.refreshToken
        ]

        let parameterString = parameters.map { key, value in
            let encodedKey =
                key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? key
            let encodedValue =
                value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
            return "\(encodedKey)=\(encodedValue)"
        }.joined(separator: "&")

        request.httpBody = parameterString.data(using: .utf8)

        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Refresh token error: \(error.localizedDescription)")
                    return
                }

                guard let data = data else { return }

                do {
                    guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                          let accessToken = json["access_token"] as? String,
                          let refreshToken = json["refresh_token"] as? String,
                          let expiresIn = json["expires_in"] as? Int
                    else {
                        return
                    }

                    let token = ShopifyToken(
                        accessToken: accessToken,
                        refreshToken: refreshToken,
                        expiresIn: expiresIn,
                        createdAt: Date()
                    )

                    try KeychainManager.shared.saveShopifyToken(token)
                } catch {
                    print("Failed to process refresh token: \(error.localizedDescription)")
                }
            }
        }.resume()
    }

    // private func generateCodeVerifier() -> String {
    //     var buffer = [UInt8](repeating: 0, count: 32)
    //     _ = SecRandomCopyBytes(kSecRandomDefault, buffer.count, &buffer)
    //     return Data(buffer).base64EncodedString()
    //         .replacingOccurrences(of: "+", with: "-")
    //         .replacingOccurrences(of: "/", with: "_")
    //         .replacingOccurrences(of: "=", with: "")
    //         .trimmingCharacters(in: .whitespaces)
    // }

    // private func generateCodeChallenge(from verifier: String) -> String? {
    //     guard let data = verifier.data(using: .utf8) else { return nil }

    //     if #available(iOS 13.0, *) {
    //         let hash = SHA256.hash(data: data)
    //         return Data(hash)
    //             .base64EncodedString()
    //             .replacingOccurrences(of: "+", with: "-")
    //             .replacingOccurrences(of: "/", with: "_")
    //             .replacingOccurrences(of: "=", with: "")
    //             .trimmingCharacters(in: .whitespaces)
    //     } else {
    //         var buffer = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
    //         data.withUnsafeBytes {
    //             _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &buffer)
    //         }
    //         return Data(buffer)
    //             .base64EncodedString()
    //             .replacingOccurrences(of: "+", with: "-")
    //             .replacingOccurrences(of: "/", with: "_")
    //             .replacingOccurrences(of: "=", with: "")
    //             .trimmingCharacters(in: .whitespaces)
    //     }
    // }

    private func logout() {
        // Request to logout endpoint
        var components = URLComponents()
        components.scheme = "https"
        components.host = shopDomain
        components.path = "/customer-account/logout"

        if let url = components.url {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"

            if let token = try? KeychainManager.shared.getShopifyToken() {
                request.addValue("Bearer \(token.accessToken)", forHTTPHeaderField: "Authorization")
            }

            URLSession.shared.dataTask(with: request) { _, _, _ in
                // Regardless of response, clear local tokens
                DispatchQueue.main.async {
                    do {
                        try KeychainManager.shared.clearShopifyToken()
                        isLoggedIn = false
                    } catch {
                        showAlert = true
                        alertMessage = "Failed to clear token: \(error.localizedDescription)"
                    }
                }
            }.resume()
        }
    }
}

#Preview {
    ProfileView()
}
