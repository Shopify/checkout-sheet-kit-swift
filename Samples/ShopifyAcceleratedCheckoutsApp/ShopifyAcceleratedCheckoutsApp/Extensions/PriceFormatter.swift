//
//  PriceFormatter.swift
//  ShopifyAcceleratedCheckoutsApp
//

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
