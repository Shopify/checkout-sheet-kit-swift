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

import Common
import UIKit

public enum Platform: String {
    case reactNative = "ReactNative"
}

public struct Configuration {
    /// Determines the color scheme used when checkout is presented.
    ///
    /// By default, the color scheme is determined based on the current
    /// `UITraitCollection.userInterfaceStyle`. To force a
    /// particular idiomatic color scheme, use the corresponding `.light`
    /// or `.dark` values.
    ///
    /// Alternatively you can use `.web` to match the look and feel of what your
    /// buyers will see when performing a checkout via a desktop or mobile browser.
    public var colorScheme = ColorScheme.automatic

    public var confetti = Configuration.Confetti()

    public var preloading = Configuration.Preloading()

    public var privacyConsent: Configuration.PrivacyConsent?

    /// Shop credentials for Storefront API used for consent encoding.
    /// When set, privacy consent will be encoded for checkout URLs.
    public var shopCredentials: Configuration.ShopCredentials?

    public var tintColor: UIColor = .init(red: 0.09, green: 0.45, blue: 0.69, alpha: 1.00)

    @available(*, renamed: "tintColor", message: "spinnerColor has been superseded by tintColor")
    public var spinnerColor: UIColor = .init(red: 0.09, green: 0.45, blue: 0.69, alpha: 1.00)

    public var backgroundColor: UIColor = .systemBackground

    public var logger: Logger = NoOpLogger()

    public var title: String = NSLocalizedString("shopify_checkout_sheet_title", value: "Checkout", comment: "The title of the checkout sheet.")

    /// The tint color for the close button. If nil, uses the system default.
    public var closeButtonTintColor: UIColor?

    /// Custom enum for identifying traffic from alternative platforms
    public var platform: Platform?

    /// Levels: all, debug, error, none
    /// Default: .error - which will emit "error" and "fault" logs
    public var logLevel: LogLevel = .error
}

extension Configuration {
    public typealias ColorScheme = UserAgent.ColorScheme
}

extension Configuration {
    public struct Confetti {
        public var enabled: Bool = false

        public var particles = [UIImage]()
    }
}

extension Configuration {
    public struct Preloading {
        public var enabled: Bool = true {
            didSet {
                CheckoutWebView.preloadingActivatedByClient = false
            }
        }
    }
}

extension Configuration {
    public struct PrivacyConsent: OptionSet {
        public let rawValue: Int

        /// Creates a PrivacyConsent from a raw value.
        /// - Warning: Do not use this initializer directly. Use the provided static properties instead.
        /// - Parameter rawValue: The raw integer value
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let marketing = PrivacyConsent(rawValue: 1 << 0)
        public static let analytics = PrivacyConsent(rawValue: 1 << 1)
        public static let preferences = PrivacyConsent(rawValue: 1 << 2)
        public static let saleOfData = PrivacyConsent(rawValue: 1 << 3)

        public static let all: PrivacyConsent = [.marketing, .analytics, .preferences, .saleOfData]
        public static let none: PrivacyConsent = []
    }
}

extension Configuration {
    /// Shop credentials for consent encoding
    public struct ShopCredentials {
        public let shopDomain: String
        public let storefrontAccessToken: String

        /// Creates shop credentials for consent encoding
        /// - Parameters:
        ///   - shopDomain: The shop domain (e.g., "your-shop.myshopify.com")
        ///   - storefrontAccessToken: The Storefront API access token
        public init(shopDomain: String, storefrontAccessToken: String) throws {
            guard !shopDomain.isEmpty else {
                throw ConsentEncodingError.invalidShopDomain
            }
            guard !storefrontAccessToken.isEmpty else {
                throw ConsentEncodingError.missingAccessToken
            }

            self.shopDomain = shopDomain
            self.storefrontAccessToken = storefrontAccessToken
        }
    }
}
