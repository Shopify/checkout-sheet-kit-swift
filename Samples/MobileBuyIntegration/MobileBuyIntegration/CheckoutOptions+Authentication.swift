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