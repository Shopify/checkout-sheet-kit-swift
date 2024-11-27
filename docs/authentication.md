# Customer Account API Authentication Guide

This guide explains how to implement authentication using Shopify's Customer Account API to enable pre-filled checkout information for authenticated buyers.

## Prerequisites

<!-- TODO: Fact check this -->
- Your store must be on Shopify Plus
- [Customer Account API access must be enabled](https://shopify.dev/docs/storefronts/headless/building-with-the-customer-account-api/getting-started)
- Basic understanding of [OAuth 2.0 and PKCE flow](https://datatracker.ietf.org/doc/html/rfc7636)

## Implementation Steps

### 1. Configure Your Application

Set up your application configuration with the required OAuth credentials:
```swift
// Required in Info.plist
- ShopId: "<your-shop-id>"
- CustomerAccountsClientId: "<your-client-id>"
- CustomerAccountsRedirectUri: "shop.<shop-id>.app://callback" // Optional, will use default if not specified
```

### 2. Implement Authentication Flow

#### 2.1 Build an OAuth Authorization URL that directs the buyer to the authentication page

```swift
private func createCodeVerifier() -> String {
    var buffer = [UInt8](repeating: 0, count: 32)
    _ = SecRandomCopyBytes(kSecRandomDefault, buffer.count, &buffer)
    return base64Encode(Data(buffer))
}

private func codeChallenge(for verifier: String) -> String {
    guard let data = verifier.data(using: .utf8) else { fatalError() }
    var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
    data.withUnsafeBytes { bytes in
        _ = CC_SHA256(bytes.baseAddress, CC_LONG(data.count), &digest)
    }
    return base64Encode(Data(digest))
}

let codeVerifier = createCodeVerifier() // Generate random verifier
let codeChallenge = codeChallenge(for: codeVerifier) // SHA256 hash of verifier
let state = randomString(length: 36) // Random state string

var components = URLComponents(string: "https://shopify.com/\(shopId)/auth/oauth/authorize")
components?.queryItems = [
    URLQueryItem(name: "scope", value: "openid email customer-account-api:full"),
    URLQueryItem(name: "client_id", value: clientId),
    URLQueryItem(name: "response_type", value: "code"),
    URLQueryItem(name: "redirect_uri", value: redirectUri),
    URLQueryItem(name: "state", value: state),
    URLQueryItem(name: "code_challenge", value: codeChallenge),
    URLQueryItem(name: "code_challenge_method", value: "S256")
]
```

#### 2.2 Present a WebView to display the OAuth authorization (login) page
```swift
let webView = WKWebView()
webView.load(URLRequest(url: components.url!))
```

#### 2.3 Handle the OAuth callback by implementing WKNavigationDelegate

```swift
class AuthWebView: WKWebView, WKNavigationDelegate {
    private var redirectUri: URLComponents
    private var savedState: String
    private var codeVerifier: String
    weak var delegate: AuthWebViewDelegate?

    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = action.request.url,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            decisionHandler(.allow)
            return
        }

        // Check if this is our OAuth callback
        guard components.scheme == redirectUri.scheme else {
            decisionHandler(.allow)
            return
        }

        // Extract and validate state and code from callback URL
        let queryItems = components.queryItems
        guard let state = queryItems?.first(where: { $0.name == "state"})?.value,
              state == savedState, // Validate state matches
              let code = queryItems?.first(where: { $0.name == "code" })?.value else {
            decisionHandler(.cancel)
            return
        }

        // Exchange code for tokens
        let tokenParams = [
            "client_id": clientId,
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": redirectUri.string ?? "",
            "code_verifier": codeVerifier
        ]

        exchangeCodeForTokens(params: tokenParams)

        // Cancel the navigation since we've handled the callback
        decisionHandler(.cancel)
    }

    private func exchangeCodeForTokens(params: [String: String]) {
        guard let url = URL(string: "\(customerAccountsBaseUrl)/auth/oauth/token") else {
            delegate?.loginFailed(error: "Invalid token endpoint URL")
            return
        }

        // Convert parameters to form URL encoded format
        let formBody = params.map { key, value in
            "\(key)=\(value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        }.joined(separator: "&")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = formBody.data(using: .utf8)

        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                DispatchQueue.main.async {
                    self.delegate?.loginFailed(error: error.localizedDescription)
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    self.delegate?.loginFailed(error: "No data received")
                }
                return
            }

            do {
                let tokenResponse = try JSONDecoder().decode(CustomerAccountAccessTokenResponse.self, from: data)
                DispatchQueue.main.async {
                    self.delegate?.loginComplete(token: tokenResponse.accessToken)
                }
            } catch {
                DispatchQueue.main.async {
                    self.delegate?.loginFailed(error: "Failed to decode token response: \(error.localizedDescription)")
                }
            }
        }
        task.resume()
    }
}

// Token response model
struct CustomerAccountAccessTokenResponse: Codable {
    let accessToken: String
    let expiresIn: Int
    let idToken: String
    let refreshToken: String
    let tokenType: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case idToken = "id_token"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
    }
}

protocol AuthWebViewDelegate: AnyObject {
    func loginComplete(token: String)
    func loginFailed(error: String)
}
```
### 3. Token Management

#### Implement token refresh

```swift
let refreshParams = [
    "client_id": clientId,
    "grant_type": "refresh_token",
    "refresh_token": storedRefreshToken
]

// Refresh implementation
func refreshAccessToken(refreshToken: String, callback: @escaping (String?, String?) -> Void) {
    guard let url = URL(string: "\(customerAccountsBaseUrl)/auth/oauth/token") else {
        return
    }

    let params: [String: String] = [
        "client_id": clientId,
        "grant_type": "refresh_token",
        "refresh_token": refreshToken
    ]

    // Convert parameters to form URL encoded format
    var components = URLComponents()
    components.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
    let body = components.query?.data(using: .utf8)

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    request.httpBody = body

    let task = URLSession.shared.dataTask(with: request) { data, _, error in
        if let error = error {
            callback(nil, "Failed to refresh token: \(error.localizedDescription)")
            return
        }

        guard let data = data else {
            callback(nil, "No data received")
            return
        }

        do {
            let tokenResponse = try JSONDecoder().decode(RefreshedTokenResponse.self, from: data)
            callback(tokenResponse.accessToken, nil)
        } catch {
            callback(nil, "Failed to decode refresh token response: \(error.localizedDescription)")
        }
    }
    task.resume()
}

struct RefreshedTokenResponse: Codable {
    let accessToken: String
    let expiresIn: Int
    let refreshToken: String
    let tokenType: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
    }
}
```
#### Implementing Logout

To properly logout a user, you'll need to:
1. Call the logout endpoint with the ID token
2. Clear local token storage
3. Reset authentication state

```swift
func logout() {
    guard let idToken = customerAccountClient.getIdToken() else {
        return
    }

    customerAccountClient.logout(idToken: idToken) { success, error in
        if let error = error {
            // Handle error case
            print("Logout failed: \(error)")
            return
        }

        // Handle successful logout
        // Clear any local cart state, navigate to login screen, etc.
    }
}
```

> [!NOTE]
> After logout, you may want to clear any local cart state and redirect the user to an appropriate screen in your app.

### 4. Manage authenticated carts

Once authenticated, exchange the access token for a Storefront API token and create or update an authenticated cart:

```swift
// Exchange access token for Storefront API token
let mutation = """
    mutation {
        storefrontCustomerAccessTokenCreate {
            customerAccessToken
            userErrors {
                field
                message
            }
        }
    }
"""

// Add authorization header with the access token
var request = URLRequest(url: storefrontApiUrl)
request.httpMethod = "POST"
request.setValue("Bearer \(customerAccessToken)", forHTTPHeaderField: "Authorization")
request.setValue("application/json", forHTTPHeaderField: "Content-Type")
request.httpBody = try? JSONSerialization.data(withJSONObject: ["query": mutation])
```

#### Create a new authenticated cart

```swift
let mutation = """
mutation cartCreate($input: CartInput!) {
    cartCreate(input: $input) {
        cart {
            id
            checkoutUrl
            buyerIdentity {
                customer {
                    id
                }
            }
            // ... other cart fields ...
        }
        userErrors {
            field
            message
        }
    }
}
"""

// Example input with merchandise
let cartLines = [
    Storefront.CartLineInput.create(
        merchandiseId: "gid://shopify/ProductVariant/12345",
        quantity: 1
    )
]

let input = Storefront.CartInput.create(
    lines: cartLines,
    buyerIdentity: Input(orNull: Storefront.CartBuyerIdentityInput.create(
        customerAccessToken: Input(orNull: storefrontCustomerAccessToken)
    ))
)
```

#### Update an existing authenticated cart

```swift
let cartUpdateMutation = """
    mutation cartBuyerIdentityUpdate($buyerIdentity: CartBuyerIdentityInput!, $cartId: ID!) {
        cartBuyerIdentityUpdate(buyerIdentity: $buyerIdentity, cartId: $cartId) {
            cart {
                id
                buyerIdentity {
                    customer {
                        id
                    }
                }
            }
            userErrors {
                field
                message
            }
        }
    }
"""


```

When using authenticated checkout:
- Buyer information will be pre-filled based on their saved account details
- Address book and payment methods will be available if previously saved
- Order history will be associated with their customer account

> [!NOTE]
> The Customer Account API integration requires your store to be on Shopify Plus and to have Customer Account API access enabled.

> [!IMPORTANT]
> Always handle tokens securely and store them in the device keychain in production applications.
