import Foundation
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

@MainActor
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

    let webPixelsLogger = FileLogger("analytics.txt")

    init() {
        if let savedMode = UserDefaults.standard.string(forKey: AppStorageKeys.buyerIdentityMode.rawValue),
           let mode = BuyerIdentityMode(rawValue: savedMode)
        {
            buyerIdentityMode = mode
        }
    }
}

@MainActor
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
