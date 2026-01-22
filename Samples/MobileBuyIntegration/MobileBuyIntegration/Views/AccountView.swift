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

import SwiftUI

struct AccountView: View {
    @ObservedObject var accountManager = CustomerAccountManager.shared
    @State private var showingLogin = false

    var body: some View {
        NavigationView {
            Group {
                if accountManager.isAuthenticated {
                    AuthenticatedAccountView()
                } else {
                    UnauthenticatedAccountView(showingLogin: $showingLogin)
                }
            }
            .navigationTitle(accountManager.isAuthenticated ? "Account" : "Sign In")
        }
        .sheet(isPresented: $showingLogin) {
            LoginSheetView()
        }
    }
}

struct AuthenticatedAccountView: View {
    @ObservedObject var accountManager = CustomerAccountManager.shared

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "person.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(Color(ColorPalette.primaryColor))

            VStack(spacing: 8) {
                Text("Signed In")
                    .font(.title2)
                    .fontWeight(.semibold)

                if let email = accountManager.customerEmail {
                    Text(email)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Text("Your checkout will be pre-filled with your account info.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 8)
            }

            Spacer()

            Button(action: { accountManager.logout() }) {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Sign Out")
                }
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding()
            }
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
    }
}

struct UnauthenticatedAccountView: View {
    @Binding var showingLogin: Bool

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "person.circle")
                .font(.system(size: 80))
                .foregroundColor(Color(ColorPalette.primaryColor))

            VStack(spacing: 8) {
                Text("Sign in to your account")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Access your orders, saved addresses, and checkout faster.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button(action: {
                showingLogin = true
            }) {
                Text("Sign In")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(ColorPalette.primaryColor))
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 12) {
                BenefitRow(icon: "clock.arrow.circlepath", text: "Faster checkout with saved info")
                BenefitRow(icon: "shippingbox", text: "Track your orders easily")
                BenefitRow(icon: "heart", text: "Save items to your wishlist")
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
    }
}

struct BenefitRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Color(ColorPalette.primaryColor))
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
    }
}

#Preview {
    AccountView()
}
