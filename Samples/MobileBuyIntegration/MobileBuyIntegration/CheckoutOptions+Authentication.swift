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
import ShopifyCheckoutSheetKit
import OSLog

extension CheckoutOptions {
    static func withAccessToken() async -> CheckoutOptions? {
        guard AuthenticationService.shared.hasConfiguration() else {
            OSLogger.shared.debug("[AuthenticationService] Not configured, returning nil options")
            return nil
        }

        do {
            let token = try await AuthenticationService.shared.getAccessToken()
            OSLogger.shared.debug("[AuthenticationService] Successfully fetched token for checkout")
            return CheckoutOptions(authentication: .token(token))
        } catch {
            OSLogger.shared.error("[AuthenticationService] Failed to fetch token: \(error.localizedDescription)")
            return nil
        }
    }
}
