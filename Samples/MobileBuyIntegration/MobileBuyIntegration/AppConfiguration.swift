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
import ShopifyAcceleratedCheckouts
import ShopifyCheckoutSheetKit

public enum BuyerIdentityMode: String, CaseIterable {
    case guest
    case hardcoded
    case customerAccount

    var displayName: String {
        switch self {
        case .guest: return "Guest"
        case .hardcoded: return "Hardcoded"
        case .customerAccount: return "Customer Account"
        }
    }
}

public final class AppConfiguration: ObservableObject {
    public var storefrontDomain: String = InfoDictionary.shared.domain

    @Published public var universalLinks = UniversalLinks()

    @Published public var buyerIdentityMode: BuyerIdentityMode = .guest {
        didSet {
            if oldValue == .customerAccount, buyerIdentityMode != .customerAccount {
                Task { @MainActor in
                    CustomerAccountManager.shared.logout()
                }
            }
            UserDefaults.standard.set(buyerIdentityMode.rawValue, forKey: AppStorageKeys.buyerIdentityMode.rawValue)
            Task { @MainActor in
                CartManager.shared.resetCart()
            }
        }
    }

    /// Logger to retain Web Pixel events
    let webPixelsLogger = FileLogger("analytics.txt")

    /// Configure ShopifyAcceleratedCheckouts
    init() {
        if let savedMode = UserDefaults.standard.string(forKey: AppStorageKeys.buyerIdentityMode.rawValue),
           let mode = BuyerIdentityMode(rawValue: savedMode)
        {
            buyerIdentityMode = mode
        }
    }

    var customer: ShopifyAcceleratedCheckouts.Customer? {
        switch buyerIdentityMode {
        case .hardcoded:
            return .init(
                email: InfoDictionary.shared.email,
                phoneNumber: InfoDictionary.shared.phone
            )
        case .customerAccount:
            guard let token = KeychainHelper.shared.getTokens()?.accessToken else { return nil }
            return .init(customerAccessToken: token)
        case .guest:
            return nil
        }
    }

    var acceleratedCheckoutsStorefrontConfig: ShopifyAcceleratedCheckouts.Configuration {
        ShopifyAcceleratedCheckouts.Configuration(
            storefrontDomain: InfoDictionary.shared.domain,
            storefrontAccessToken: InfoDictionary.shared.accessToken,
            customer: customer
        )
    }

    let acceleratedCheckoutsApplePayConfig = ShopifyAcceleratedCheckouts.ApplePayConfiguration(
        merchantIdentifier: InfoDictionary.shared.merchantIdentifier,
        contactFields: [.email, .phone]
    )
}

public var appConfiguration = AppConfiguration() {
    didSet {
        Task { @MainActor in
            CartManager.shared.resetCart()
        }
    }
}

public struct UniversalLinks {
    public var checkout: Bool = true
    public var cart: Bool = true
    public var products: Bool = true

    public var handleAllURLsInApp: Bool = true {
        didSet {
            if handleAllURLsInApp {
                enableAllURLs()
            }
        }
    }

    private mutating func enableAllURLs() {
        checkout = true
        products = true
        cart = true
    }
}
