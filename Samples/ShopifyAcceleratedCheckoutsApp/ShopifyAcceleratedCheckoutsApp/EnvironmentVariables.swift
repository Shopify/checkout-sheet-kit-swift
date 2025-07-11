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

public enum EnvironmentVariables {
    enum Keys {
        static let storefrontAccessToken = "STOREFRONT_ACCESS_TOKEN"
        static let storefrontDomain = "STOREFRONT_DOMAIN"
        static let apiVersion = "API_VERSION"
    }

    private static func getKey(for key: String) -> String {
        guard let value = EnvironmentVariables.infoDictionary[key] as? String else {
            fatalError("Environment variable \(key) must be set in the Storefront.xcconfig file")
        }
        return value
    }

    private static let infoDictionary: [String: Any] = {
        guard let dict = Bundle.main.infoDictionary else {
            fatalError("Plist file not found")
        }
        return dict
    }()

    public static let storefrontAccessToken: String = getKey(for: Keys.storefrontAccessToken)

    public static let storefrontDomain: String = getKey(for: Keys.storefrontDomain)

    public static let apiVersion: String = getKey(for: Keys.apiVersion)
}
