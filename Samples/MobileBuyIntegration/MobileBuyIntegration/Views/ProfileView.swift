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

struct ProfileView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isLoggedIn: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    init() {
        // Try to load credentials from keychain on init
        if let credentials = try? KeychainManager.shared.getCredentials() {
            _email = State(initialValue: credentials.email)
            _password = State(initialValue: credentials.password)
            _isLoggedIn = State(initialValue: true)
        }
    }

    var body: some View {
        NavigationView {
            Form {
                if !isLoggedIn {
                    Section(header: Text("Login Information")) {
                        TextField("Email", text: $email)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                        SecureField("Password", text: $password)

                        Button(action: login) {
                            Text("Login")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(email.isEmpty || password.isEmpty)
                    }
                } else {
                    Section {
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
        }
    }

    private func login() {
        if !email.isEmpty, !password.isEmpty {
            do {
                try KeychainManager.shared.saveCredentials(email: email, password: password)
                isLoggedIn = true
            } catch {
                showAlert = true
                alertMessage = "Failed to save credentials: \(error.localizedDescription)"
            }
        }
    }

    private func logout() {
        do {
            try KeychainManager.shared.clearCredentials()
            isLoggedIn = false
            email = ""
            password = ""
        } catch {
            showAlert = true
            alertMessage = "Failed to clear credentials: \(error.localizedDescription)"
        }
    }
}

#Preview {
    ProfileView()
}
