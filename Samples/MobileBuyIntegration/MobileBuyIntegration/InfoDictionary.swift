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

/**
 * Contains all of the values from the `info.plist`
 */
final class InfoDictionary: Sendable {
    static let shared = InfoDictionary()

    /// Required
    let address1, address2, city, country, firstName, lastName, province, zip,
        email, phone, domain, accessToken, version, buildNumber, merchantIdentifier: String

    // Customer Account API (optional)
    let customerAccountApiClientId: String?
    let customerAccountApiShopId: String?

    // Embedded Checkout Protocol (optional)
    let ecAuthToken: String?

    var customerAccountApiRedirectUri: String? {
        guard let shopId = customerAccountApiShopId, !shopId.isEmpty else {
            return nil
        }
        return "shop.\(shopId).app://callback"
    }

    init() {
        guard
            let infoPlist = Bundle.main.infoDictionary,
            let address1 = infoPlist["Address1"] as? String,
            let address2 = infoPlist["Address2"] as? String,
            let city = infoPlist["City"] as? String,
            let country = infoPlist["Country"] as? String,
            let firstName = infoPlist["FirstName"] as? String,
            let lastName = infoPlist["LastName"] as? String,
            let province = infoPlist["Province"] as? String,
            let zip = infoPlist["Zip"] as? String,
            let email = infoPlist["Email"] as? String,
            let phone = infoPlist["Phone"] as? String,
            let domain = infoPlist["StorefrontDomain"] as? String,
            let accessToken = infoPlist["StorefrontAccessToken"] as? String,
            let merchantIdentifier = infoPlist["StorefrontMerchantIdentifier"] as? String,
            let version = infoPlist["CFBundleShortVersionString"] as? String,
            let buildNumber = infoPlist["CFBundleVersion"] as? String
        else {
            fatalError("Missing required configuration. Check your info.plist.")
        }

        self.address1 = address1
        self.address2 = address2
        self.city = city
        self.country = country
        self.firstName = firstName
        self.lastName = lastName
        self.province = province
        self.zip = zip
        self.email = email
        self.phone = phone
        self.domain = domain
        self.accessToken = accessToken
        self.version = version
        self.buildNumber = buildNumber
        self.merchantIdentifier = merchantIdentifier

        // Customer Account API configuration (optional)
        customerAccountApiClientId = infoPlist["CustomerAccountApiClientId"] as? String
        customerAccountApiShopId = infoPlist["CustomerAccountApiShopId"] as? String

        // Embedded Checkout Protocol configuration (optional)
        ecAuthToken = infoPlist["EcAuthToken"] as? String
    }
}

extension URL {
    func appendingEcParams() -> URL {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: false)
        var queryItems = components?.queryItems ?? []
        queryItems.append(URLQueryItem(name: "ec_version", value: "2026-01-11"))
        queryItems.append(URLQueryItem(name: "ec_delegate", value: "fulfillment.address_change,payment.instruments_change,payment.credential"))
        if let token = InfoDictionary.shared.ecAuthToken, !token.isEmpty {
            Self.validateJWTExpiration(token)
            queryItems.append(URLQueryItem(name: "ec_auth", value: token))
        }
        components?.queryItems = queryItems
        return components?.url ?? self
    }

    private static func validateJWTExpiration(_ token: String) {
        let segments = token.split(separator: ".")
        guard segments.count == 3 else { return }

        var base64 = String(segments[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 { base64.append("=") }

        guard let data = Data(base64Encoded: base64),
              let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let exp = payload["exp"] as? TimeInterval
        else { return }

        if Date().timeIntervalSince1970 >= exp {
            fatalError("EC_AUTH_TOKEN expired at \(Date(timeIntervalSince1970: exp)). Renew it in Storefront.xcconfig.")
        }
    }
}
