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

#if canImport(UIKit)
import UIKit
#endif
import WebKit

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
    public var colorScheme = ColorScheme.automatic

    /// Determines the branding used when checkout is presented.
    ///
    /// By default, shop branding is used. Set to `.app` to use app branding instead.
    public var branding = Branding.shop

    public var confetti = Configuration.Confetti()

    public var preloading = Configuration.Preloading()

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

    /// The webView instance used for checkout, set internally by the SDK
    internal var webView: WKWebView?
}

extension Configuration {
    public enum ColorScheme: String, CaseIterable {
        /// Uses a light, idiomatic color scheme.
        case light
        /// Uses a dark, idiomatic color scheme.
        case dark
        /// Infers either `.light` or `.dark` based on the current `UIUserInterfaceStyle`.
        case automatic
    }

    public enum Branding: String, CaseIterable {
        /// Uses app branding for the checkout experience.
        case app
        /// Uses shop branding for the checkout experience.
        case shop
    }
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
