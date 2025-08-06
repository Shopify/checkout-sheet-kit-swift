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

/// The version of the `ShopifyCheckoutSheetKit` library.
public let version = "3.2.0"

var invalidateOnConfigurationChange = true

/// The configuration options for the `ShopifyCheckoutSheetKit` library.
public var configuration = Configuration() {
    didSet {
        if invalidateOnConfigurationChange {
            CheckoutWebView.invalidate()
        }

        if consentEncoder == nil, let credentials = configuration.shopCredentials {
            do {
                consentEncoder = try DefaultConsentEncoder(
                    shopDomain: credentials.shopDomain,
                    storefrontAccessToken: credentials.storefrontAccessToken
                )
            } catch {
                OSLogger.shared.error("Failed to create consent encoder: \(error)")
                consentEncoder = nil
            }
        } else {
            consentEncoder = nil
        }
    }
}

/// Internal consent encoder created from shop credentials.
private var consentEncoder: ConsentEncoder?

/// Internal storage for encoded privacy consent.
private var encodedPrivacyConsent: String? {
    get {
        UserDefaults.standard.string(forKey: "ShopifyCheckoutSheetKit.encodedPrivacyConsent")
    }
    set {
        if let newValue {
            UserDefaults.standard.set(newValue, forKey: "ShopifyCheckoutSheetKit.encodedPrivacyConsent")
        } else {
            UserDefaults.standard.removeObject(forKey: "ShopifyCheckoutSheetKit.encodedPrivacyConsent")
        }
    }
}

/// A convienence function for configuring the `ShopifyCheckoutSheetKit` library.
public func configure(_ block: (inout Configuration) -> Void) {
    block(&configuration)
}

/// Returns the currently stored encoded privacy consent, if any.
/// This value is automatically used for checkout URLs.
public var currentEncodedPrivacyConsent: String? {
    return encodedPrivacyConsent
}

/// Clears the stored encoded privacy consent.
/// Future checkouts will not include consent parameters until re-encoded.
public func clearEncodedPrivacyConsent() {
    encodedPrivacyConsent = nil
    OSLogger.shared.debug("Cleared stored encoded privacy consent")
}

/// Encodes the current privacy consent and stores it in user defaults.
/// - Returns: The encoded consent string that will be used for checkout URLs
/// - Throws: ConsentEncodingError if encoding fails or shop credentials are missing
@discardableResult
public func encodePrivacyConsent() async throws -> String? {
    guard let consent = configuration.privacyConsent else {
        throw ConsentEncodingError.invalidResponse("No privacy consent configured")
    }

    guard let encoder = consentEncoder else {
        throw ConsentEncodingError.invalidResponse("No consent encoder available. Configure shop credentials first.")
    }

    let encoded = try await encoder.encode(consent)

    encodedPrivacyConsent = encoded

    OSLogger.shared.debug("Privacy consent encoded and stored: \(encoded ?? "nil")")

    return encoded
}

/// Preloads the checkout for faster presentation.
public func preload(checkout url: URL) {
    guard configuration.preloading.enabled else {
        return
    }

    let checkoutURL = addConsentForCheckout(url: url)
    CheckoutWebView.preloadingActivatedByClient = true
    CheckoutWebView.for(checkout: url).load(checkout: checkoutURL, isPreload: true)
}

/// Invalidate the checkout cache from preload calls
public func invalidate() {
    CheckoutWebView.invalidate(disconnect: true)
}

/// Presents the checkout from a given `UIViewController`.
@discardableResult
public func present(checkout url: URL, from: UIViewController, delegate: CheckoutDelegate? = nil) -> CheckoutViewController {
    let checkoutURL = addConsentForCheckout(url: url)
    let viewController = CheckoutViewController(checkout: checkoutURL, delegate: delegate)
    from.present(viewController, animated: true)
    return viewController
}

/// Internal function that presents the checkout from a given `UIViewController` with a specified entry point.
/// This is only used by other modules such as ShopifyAcceleratedCheckouts.
/// Consumers will use the public `present` function, and the UserAgent will *not* contain the entry field.
@discardableResult
package func present(checkout url: URL, from: UIViewController, entryPoint: MetaData.EntryPoint, delegate: CheckoutDelegate? = nil) -> CheckoutViewController {
    let checkoutURL = addConsentForCheckout(url: url)
    let viewController = CheckoutViewController(checkout: checkoutURL, delegate: delegate, entryPoint: entryPoint)
    from.present(viewController, animated: true)
    return viewController
}

// MARK: - Internal Consent Processing

/// Appends encoded privacy consent it to the checkout URL if configured
private func addConsentForCheckout(url: URL) -> URL {
    guard let encodedConsent = encodedPrivacyConsent else {
        return url
    }

    var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
    var queryItems = urlComponents?.queryItems ?? []

    queryItems.removeAll { $0.name == "_cs" }

    queryItems.append(URLQueryItem(name: "_cs", value: encodedConsent))
    urlComponents?.queryItems = queryItems

    return urlComponents?.url ?? url
}
