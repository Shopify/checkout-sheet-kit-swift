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

extension String {
    /// Maps currency code to its symbol
    static func currencySymbol(for code: String) -> String {
        switch code {
        case "USD": return "$"
        case "EUR": return "€"
        case "GBP": return "£"
        case "JPY": return "¥"
        case "CAD": return "C$"
        case "AUD": return "A$"
        default: return code + " "
        }
    }
}

extension NumberFormatter {
    /// Creates a currency formatter for the given currency code
    static func currencyFormatter(for currencyCode: String) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }
}

/// Utility struct for formatting prices
enum PriceFormatter {
    /// Formats a price amount with the given currency code
    static func format(amount: String, currencyCode: String) -> String {
        // Check if the amount is zero
        if let decimalAmount = Decimal(string: amount), decimalAmount == 0 {
            return "Free"
        }

        let formatter = NumberFormatter.currencyFormatter(for: currencyCode)

        if let formattedPrice = formatter.string(from: NSDecimalNumber(string: amount)) {
            return formattedPrice
        }

        // Fallback to manual formatting
        let symbol = String.currencySymbol(for: currencyCode)
        return "\(symbol)\(amount)"
    }
}
