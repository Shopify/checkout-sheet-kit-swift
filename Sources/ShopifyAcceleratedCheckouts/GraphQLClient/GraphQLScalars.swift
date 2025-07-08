//
//  GraphQLScalars.swift
//  ShopifyAcceleratedCheckouts
//

import Foundation

/// Custom scalar types for the Storefront API
enum GraphQLScalars {
    /// Represents a globally unique identifier (GID) in the Storefront API
    struct ID: Codable, Hashable, CustomStringConvertible {
        let rawValue: String

        init(_ rawValue: String) {
            self.rawValue = rawValue
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            rawValue = try container.decode(String.self)
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(rawValue)
        }

        var description: String {
            return rawValue
        }

        /// Extract the numeric ID from a GID (e.g., "gid://shopify/Product/123" -> "123")
        var numericId: String? {
            return rawValue.components(separatedBy: "/").last
        }
    }

    /// Represents a monetary value with a decimal amount and currency code
    struct Money: Codable, Hashable {
        let amount: Decimal
        let currencyCode: String
    }

    /// Represents an ISO 8601 encoded date-time string
    struct DateTime: Codable, Hashable {
        let date: Date

        init(_ date: Date) {
            self.date = date
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

            if let date = formatter.date(from: dateString) {
                self.date = date
            } else {
                // Fallback without fractional seconds
                formatter.formatOptions = [.withInternetDateTime]
                if let date = formatter.date(from: dateString) {
                    self.date = date
                } else {
                    throw DecodingError.dataCorruptedError(
                        in: container,
                        debugDescription: "Invalid date format: \(dateString)"
                    )
                }
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime]
            try container.encode(formatter.string(from: date))
        }
    }

    /// Represents an absolute URL
    struct URL: Codable, Hashable {
        let url: Foundation.URL

        init(_ url: Foundation.URL) {
            self.url = url
        }

        init?(string: String) {
            guard let url = Foundation.URL(string: string) else { return nil }
            self.url = url
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let urlString = try container.decode(String.self)
            guard let url = Foundation.URL(string: urlString) else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Invalid URL: \(urlString)"
                )
            }
            self.url = url
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(url.absoluteString)
        }
    }

    /// Represents HTML content
    struct HTML: Codable, Hashable {
        let rawValue: String

        init(_ rawValue: String) {
            self.rawValue = rawValue
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            rawValue = try container.decode(String.self)
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(rawValue)
        }
    }
}

// MARK: - Common Enums

/// ISO 4217 currency codes
enum CurrencyCode: String, Codable, CaseIterable {
    case aed = "AED"
    case afn = "AFN"
    case all = "ALL"
    case amd = "AMD"
    case ang = "ANG"
    case aoa = "AOA"
    case ars = "ARS"
    case aud = "AUD"
    case awg = "AWG"
    case azn = "AZN"
    case bam = "BAM"
    case bbd = "BBD"
    case bdt = "BDT"
    case bgn = "BGN"
    case bhd = "BHD"
    case bif = "BIF"
    case bmd = "BMD"
    case bnd = "BND"
    case bob = "BOB"
    case brl = "BRL"
    case bsd = "BSD"
    case btn = "BTN"
    case bwp = "BWP"
    case byn = "BYN"
    case bzd = "BZD"
    case cad = "CAD"
    case cdf = "CDF"
    case chf = "CHF"
    case clp = "CLP"
    case cny = "CNY"
    case cop = "COP"
    case crc = "CRC"
    case cve = "CVE"
    case czk = "CZK"
    case djf = "DJF"
    case dkk = "DKK"
    case dop = "DOP"
    case dzd = "DZD"
    case egp = "EGP"
    case ern = "ERN"
    case etb = "ETB"
    case eur = "EUR"
    case fjd = "FJD"
    case fkp = "FKP"
    case gbp = "GBP"
    case gel = "GEL"
    case ghs = "GHS"
    case gip = "GIP"
    case gmd = "GMD"
    case gnf = "GNF"
    case gtq = "GTQ"
    case gyd = "GYD"
    case hkd = "HKD"
    case hnl = "HNL"
    case hrk = "HRK"
    case htg = "HTG"
    case huf = "HUF"
    case idr = "IDR"
    case ils = "ILS"
    case inr = "INR"
    case iqd = "IQD"
    case irr = "IRR"
    case isk = "ISK"
    case jmd = "JMD"
    case jod = "JOD"
    case jpy = "JPY"
    case kes = "KES"
    case kgs = "KGS"
    case khr = "KHR"
    case kmf = "KMF"
    case kpw = "KPW"
    case krw = "KRW"
    case kwd = "KWD"
    case kyd = "KYD"
    case kzt = "KZT"
    case lak = "LAK"
    case lbp = "LBP"
    case lkr = "LKR"
    case lrd = "LRD"
    case lsl = "LSL"
    case ltl = "LTL"
    case lvl = "LVL"
    case lyd = "LYD"
    case mad = "MAD"
    case mdl = "MDL"
    case mga = "MGA"
    case mkd = "MKD"
    case mmk = "MMK"
    case mnt = "MNT"
    case mop = "MOP"
    case mru = "MRU"
    case mur = "MUR"
    case mvr = "MVR"
    case mwk = "MWK"
    case mxn = "MXN"
    case myr = "MYR"
    case mzn = "MZN"
    case nad = "NAD"
    case ngn = "NGN"
    case nio = "NIO"
    case nok = "NOK"
    case npr = "NPR"
    case nzd = "NZD"
    case omr = "OMR"
    case pab = "PAB"
    case pen = "PEN"
    case pgk = "PGK"
    case php = "PHP"
    case pkr = "PKR"
    case pln = "PLN"
    case pyg = "PYG"
    case qar = "QAR"
    case ron = "RON"
    case rsd = "RSD"
    case rub = "RUB"
    case rwf = "RWF"
    case sar = "SAR"
    case sbd = "SBD"
    case scr = "SCR"
    case sdg = "SDG"
    case sek = "SEK"
    case sgd = "SGD"
    case shp = "SHP"
    case sll = "SLL"
    case sos = "SOS"
    case srd = "SRD"
    case ssp = "SSP"
    case std = "STD"
    case syp = "SYP"
    case szl = "SZL"
    case thb = "THB"
    case tjs = "TJS"
    case tmm = "TMM"
    case tnd = "TND"
    case top = "TOP"
    case `try` = "TRY"
    case ttd = "TTD"
    case twd = "TWD"
    case tzs = "TZS"
    case uah = "UAH"
    case ugx = "UGX"
    case usd = "USD"
    case uyu = "UYU"
    case uzs = "UZS"
    case vef = "VEF"
    case vnd = "VND"
    case vuv = "VUV"
    case wst = "WST"
    case xaf = "XAF"
    case xcd = "XCD"
    case xof = "XOF"
    case xpf = "XPF"
    case xxx = "XXX"
    case yer = "YER"
    case zar = "ZAR"
    case zmw = "ZMW"
}
