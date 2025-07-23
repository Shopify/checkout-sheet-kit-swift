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

// Reference the LanguageCode enum from Models to avoid namespace conflict
typealias ShopifyLanguageCode = LanguageCode

/// Extension to detect device locale and map to Shopify types
@available(iOS 17.0, *)
extension Locale {
    private static let defaultCountryCode: CountryCode = .US
    private static let defaultLanguageCode: ShopifyLanguageCode = .EN

    /// Returns the device's current country code mapped to CountryCode enum
    static var deviceCountryCode: CountryCode {
        guard let regionCode = Locale.current.region?.identifier,
            let countryCode = CountryCode(rawValue: regionCode)
        else {
            return defaultCountryCode 
        }
        return countryCode
    }

    /// Returns the device's current language code mapped to LanguageCode enum
    static var deviceLanguageCode: ShopifyLanguageCode {
        guard let languageCode = Locale.current.language.languageCode?.identifier else {
            return defaultLanguageCode 
        }

        // Handle special cases for language codes that need mapping
        switch languageCode {
        case "zh-Hans", "zh-CN":
            return ShopifyLanguageCode.ZH_CN
        case "zh-Hant", "zh-TW":
            return ShopifyLanguageCode.ZH_TW
        case "pt-BR":
            return ShopifyLanguageCode.PT_BR
        case "pt-PT":
            return ShopifyLanguageCode.PT_PT
        default:
            // Try to map the language code directly
            if let mappedCode = ShopifyLanguageCode(rawValue: languageCode.uppercased()) {
                return mappedCode
            }

            // Handle cases where we need to extract the base language
            let baseLanguage = String(languageCode.prefix(2))
            if let mappedCode = ShopifyLanguageCode(rawValue: baseLanguage.uppercased()) {
                return mappedCode
            }

            return defaultLanguageCode 
        }
    }
}
