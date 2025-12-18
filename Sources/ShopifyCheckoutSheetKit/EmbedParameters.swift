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

enum EmbedQueryParamKey {
    static let embed = "embed"
}

enum EmbedFieldKey {
    static let `protocol` = "protocol"
    static let branding = "branding"
    static let library = "library"
    static let platform = "platform"
    static let entry = "entry"
    static let colorScheme = "colorscheme"
    static let recovery = "recovery"
    static let entryPoint = "entrypoint"
    static let authentication = "authentication"
}

enum EmbedFieldValue {
    static let brandingApp = "app"
    static let brandingShop = "shop"
    static let entrySheet = "sheet"
    static let entryWallet = "wallet"
    static let entryShopPay = "shop-pay"
    static let recoveryTrue = "true"
    static let redacted = "[REDACTED]"
}

enum EmbedParamBuilder {
    static func build(
        isRecovery: Bool = false,
        entryPoint: MetaData.EntryPoint?,
        sourceComponents: URLComponents? = nil,
        options: CheckoutOptions? = nil,
        includeAuthentication: Bool = true
    ) -> String {
        let configuration = ShopifyCheckoutSheetKit.configuration
        let colorScheme = configuration.colorScheme
        let brandingValue = branding(for: colorScheme)
        let colorSchemeValue = colorSchemeParameter(for: colorScheme)
        let libraryVersion = trimmedLibraryVersion()
        let platformValue = platformParameter(for: configuration.platform)
        let entryPointValue = entryPoint?.rawValue
        let entryValue = entryParameter(for: entryPoint, components: sourceComponents)

        var fields: [(String, String?)] = [
            (EmbedFieldKey.protocol, MetaData.schemaVersion),
            (EmbedFieldKey.branding, brandingValue),
            (EmbedFieldKey.library, "CheckoutKit/\(libraryVersion)"),
            (EmbedFieldKey.platform, platformValue),
            (EmbedFieldKey.entry, entryValue),
            (EmbedFieldKey.colorScheme, colorSchemeValue)
        ]

        if isRecovery {
            fields.append((EmbedFieldKey.recovery, EmbedFieldValue.recoveryTrue))
        }

        if let entryPointValue {
            fields.append((EmbedFieldKey.entryPoint, entryPointValue))
        }

        if includeAuthentication, case let .token(authToken) = options?.authentication {
            fields.append((EmbedFieldKey.authentication, authToken))
        }

        return fields
            .compactMap { key, value in
                guard let value, !value.isEmpty else { return nil }
                return "\(key)=\(value)"
            }
            .joined(separator: ",")
    }

    private static func branding(for colorScheme: Configuration.ColorScheme) -> String {
        switch colorScheme {
        case .web:
            return EmbedFieldValue.brandingShop
        default:
            return EmbedFieldValue.brandingApp
        }
    }

    private static func colorSchemeParameter(for colorScheme: Configuration.ColorScheme) -> String? {
        switch colorScheme {
        case .web:
            return nil
        case .automatic:
            return "auto"
        default:
            return colorScheme.rawValue
        }
    }

    private static func trimmedLibraryVersion() -> String {
        MetaData.version.split(separator: "-").first.map(String.init) ?? MetaData.version
    }

    private static func platformParameter(for platform: Platform?) -> String {
        guard let platform else { return "swift" }

        switch platform {
        case .reactNative:
            return "react-native-swift"
        }
    }

    private static func entryParameter(
        for entryPoint: MetaData.EntryPoint?,
        components: URLComponents?
    ) -> String {
        guard entryPoint == .acceleratedCheckouts else {
            return EmbedFieldValue.entrySheet
        }

        let payment = components?.queryItems?
            .first(where: { $0.name == "payment" })?
            .value?
            .lowercased()

        return payment == "shop_pay" ? EmbedFieldValue.entryShopPay : EmbedFieldValue.entryWallet
    }
}

extension URL {
    private func embedQueryValue() -> String? {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return nil
        }

        return components.queryItems?.first(where: { $0.name == EmbedQueryParamKey.embed })?.value
    }

    func hasEmbedParam() -> Bool {
        embedQueryValue() != nil
    }

    func embedParamMatches(isRecovery: Bool, entryPoint: MetaData.EntryPoint?, options: CheckoutOptions? = nil) -> Bool {
        guard
            let components = URLComponents(url: self, resolvingAgainstBaseURL: false),
            let embedValue = components.queryItems?.first(where: { $0.name == EmbedQueryParamKey.embed })?.value
        else {
            return false
        }

        // Build expected value without authentication for comparison
        // (auth tokens may be stripped from loaded URLs for security)
        let expectedValue = EmbedParamBuilder.build(
            isRecovery: isRecovery,
            entryPoint: entryPoint,
            sourceComponents: components,
            options: options,
            includeAuthentication: false
        )

        let embedValueWithoutAuth = stripAuthenticationFromEmbed(embedValue)

        return embedValueWithoutAuth == expectedValue
    }

    private func stripAuthenticationFromEmbed(_ embedValue: String) -> String {
        embedValue
            .components(separatedBy: ",")
            .filter { !$0.starts(with: "\(EmbedFieldKey.authentication)=") }
            .joined(separator: ",")
    }

    func needsEmbedUpdate(isRecovery: Bool, entryPoint: MetaData.EntryPoint?, options: CheckoutOptions? = nil) -> Bool {
        guard hasEmbedParam() else {
            return true
        }

        return !embedParamMatches(isRecovery: isRecovery, entryPoint: entryPoint, options: options)
    }

    func withEmbedParam(
        isRecovery: Bool = false,
        entryPoint: MetaData.EntryPoint?,
        options: CheckoutOptions? = nil,
        includeAuthentication: Bool = true
    ) -> URL {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return self
        }

        var queryItems = components.queryItems ?? []
        let expectedValue = EmbedParamBuilder.build(
            isRecovery: isRecovery,
            entryPoint: entryPoint,
            sourceComponents: components,
            options: options,
            includeAuthentication: includeAuthentication
        )

        if let index = queryItems.firstIndex(where: { $0.name == EmbedQueryParamKey.embed }) {
            queryItems[index] = URLQueryItem(name: EmbedQueryParamKey.embed, value: expectedValue)
            components.queryItems = queryItems
            return components.url ?? self
        }

        queryItems.append(URLQueryItem(name: EmbedQueryParamKey.embed, value: expectedValue))
        components.queryItems = queryItems
        return components.url ?? self
    }
}
