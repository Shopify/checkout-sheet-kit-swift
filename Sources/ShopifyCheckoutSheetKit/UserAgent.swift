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
import UIKit

public enum UserAgent {
    public enum ColorScheme: String, CaseIterable {
        /// Uses a light, idiomatic color scheme.
        case light
        /// Uses a dark, idiomatic color scheme.
        case dark
        /// Infers either `.light` or `.dark` based on the current `UIUserInterfaceStyle`.
        case automatic
        /// The color scheme presented to buyers using a desktop or mobile browser.
        case web = "web_default"
    }

    package enum CheckoutType {
        case standard
        case recovery
    }

    // TODO: Undo the hardcoded version
    private static let baseUserAgent = "ShopifyCheckoutSDK/3.5.0"

    // Shared format for CheckoutSheetKit and AcceleratedCheckouts
    package static func string(
        type: CheckoutType,
        colorScheme: ColorScheme,
        platform: MetaData.Platform? = nil,
        entryPoint: MetaData.EntryPoint? = nil
    ) -> String {
        var parameters: String
        switch type {
        case .standard:
            parameters = "\(MetaData.schemaVersion);\(colorScheme.rawValue);standard"
        case .recovery:
            parameters = "noconnect;\(colorScheme.rawValue);standard_recovery"
        }

        var userAgentString = "\(baseUserAgent) (\(parameters))"

        if let platform {
            userAgentString.append(" \(platform.rawValue)")
        }

        if let entryPoint {
            userAgentString.append(" \(entryPoint.rawValue)")
        }

        return userAgentString
    }
}
