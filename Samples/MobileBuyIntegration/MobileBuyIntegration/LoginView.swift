import Buy
import ShopifyCheckoutSheetKit
import SwiftUI
import SwiftUICore
import WebKit

struct LoginView: View {
    @ObservedObject private var customerAccountClient = CustomerAccountClient.shared
    @State private var showSheet = false

    var body: some View {
        VStack(spacing: 20) {
            if customerAccountClient.authenticated {
                // Logged in state
                VStack(spacing: 16) {
                    Text("You are logged in")
                        .font(.headline)

                    Button(action: {
                        refreshToken()
                    }) {
                        Text("Refresh Token")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }

                    Button(action: {
                        showSheet = true
                    }) {
                        Text("Logout")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            } else {
                // Logged out state
                VStack(spacing: 16) {
                    Text("You are not logged in")
                        .font(.headline)

                    Button(action: {
                        showSheet = true
                    }) {
                        Text("Login")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .navigationTitle("Login")
        .sheet(isPresented: $showSheet) {
            let isAuthenticated = customerAccountClient.isAuthenticated()
            let authData = customerAccountClient.buildAuthData()
            let url = isAuthenticated ? customerAccountClient.logoutUrl() : authData?.authorizationUrl
            AuthenticationWebView(
                url: url,
                authData: authData,
                redirectUri: URLComponents(string: customerAccountClient.getRedirectUri()),
                completionHandler: { _ in
                    self.showSheet = false
                }
            )
        }
    }
}

private func refreshToken() {
    CustomerAccountClient.shared.refreshAccessToken { accessToken, _ in
        print("Refreshed token: \(String(describing: accessToken))")
    }
}

// Preview provider
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            LoginView()
        }
    }
}
