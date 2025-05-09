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

import Combine
import Foundation
import UIKit

class ProfileViewController: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isLoggedIn: Bool = false
    @Published var errorMessage: String = ""
    @Published var showError: Bool = false
    @Published var showCopiedFeedback: String = ""
    @Published var lastCopiedField: String = ""

    private var feedbackTimer: Timer?

    init() {
        loadSavedCredentials()
    }

    private func loadSavedCredentials() {
        if let credentials = try? KeychainManager.shared.getCredentials() {
            email = credentials.email
            password = credentials.password
            isLoggedIn = true
        }
    }

    func login() {
        guard !email.isEmpty, !password.isEmpty else { return }

        do {
            try KeychainManager.shared.saveCredentials(email: email, password: password)
            isLoggedIn = true
        } catch {
            showError = true
            errorMessage = "Failed to save credentials: \(error.localizedDescription)"
        }
    }

    func logout() {
        do {
            try KeychainManager.shared.clearCredentials()
            isLoggedIn = false
            email = ""
            password = ""
        } catch {
            showError = true
            errorMessage = "Failed to clear credentials: \(error.localizedDescription)"
        }
    }

    func dismissError() {
        showError = false
        errorMessage = ""
    }

    func copyToClipboard(_ text: String, field: String) {
        UIPasteboard.general.string = text
        lastCopiedField = field
        showCopiedFeedback = field

        // Reset the feedback after 2 seconds
        feedbackTimer?.invalidate()
        feedbackTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.showCopiedFeedback = ""
            }
        }
    }
}
