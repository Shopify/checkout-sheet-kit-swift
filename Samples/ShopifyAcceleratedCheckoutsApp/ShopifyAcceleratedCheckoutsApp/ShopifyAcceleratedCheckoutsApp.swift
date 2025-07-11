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

import PassKit
import ShopifyAcceleratedCheckouts
import SwiftUI

@main
struct ShopifyAcceleratedCheckoutsApp: App {
    @AppStorage("locale") var locale: String = "en"
    @AppStorage("includeEmail") var includeEmail: Bool = true
    @AppStorage("includePhone") var includePhone: Bool = true

    @State var configuration = ShopifyAcceleratedCheckouts.Configuration(
        storefrontDomain: EnvironmentVariables.storefrontDomain,
        storefrontAccessToken: EnvironmentVariables.storefrontAccessToken,
        customer: ShopifyAcceleratedCheckouts.Customer(email: nil, phoneNumber: nil)
    )

    @State var applePayConfiguration: ShopifyAcceleratedCheckouts.ApplePayConfiguration

    init() {
        // Initialize with default values
        let initialIncludeEmail =
            UserDefaults.standard.object(forKey: "includeEmail") as? Bool ?? true
        let initialIncludePhone =
            UserDefaults.standard.object(forKey: "includePhone") as? Bool ?? true

        _applePayConfiguration = State(
            wrappedValue: createApplePayConfiguration(
                includeEmail: initialIncludeEmail, includePhone: initialIncludePhone
            ))
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                CartBuilderView(configuration: $configuration)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            SettingsButton(applePayConfiguration: $applePayConfiguration)
                        }
                    }
                    .id("\(includeEmail)-\(includePhone)")
            }
        }
        .environment(\.locale, Locale(identifier: locale))
        .environment(configuration)
        .environment(applePayConfiguration)
        .onChange(of: includeEmail) { _, _ in
            applePayConfiguration = createApplePayConfiguration(
                includeEmail: includeEmail,
                includePhone: includePhone
            )
        }
        .onChange(of: includePhone) { _, _ in
            applePayConfiguration = createApplePayConfiguration(
                includeEmail: includeEmail,
                includePhone: includePhone
            )
        }
    }
}

private func createApplePayConfiguration(includeEmail: Bool, includePhone: Bool)
    -> ShopifyAcceleratedCheckouts.ApplePayConfiguration
{
    var fields: [ShopifyAcceleratedCheckouts.RequiredContactFields] = []

    if includeEmail { fields.append(.email) }
    if includePhone { fields.append(.phone) }

    return ShopifyAcceleratedCheckouts.ApplePayConfiguration(
        merchantIdentifier: "merchant.com.shopify.example.ShopifyAcceleratedCheckoutsApp",
        supportedNetworks: [.amex, .discover, .masterCard, .visa],
        contactFields: fields
    )
}
