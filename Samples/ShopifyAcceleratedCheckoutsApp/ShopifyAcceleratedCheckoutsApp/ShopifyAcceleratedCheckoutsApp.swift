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
    @AppStorage("requireEmail") var requireEmail: Bool = true
    @AppStorage("requirePhone") var requirePhone: Bool = true

    @State var configuration = ShopifyAcceleratedCheckouts.Configuration(
        storefrontDomain: EnvironmentVariables.storefrontDomain,
        storefrontAccessToken: EnvironmentVariables.storefrontAccessToken,
        customer: ShopifyAcceleratedCheckouts.Customer(email: nil, phoneNumber: nil)
    )

    @State var applePayConfiguration: ShopifyAcceleratedCheckouts.ApplePayConfiguration =
        createApplePayConfiguration()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                CartBuilderView(configuration: $configuration)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            SettingsButton(applePayConfiguration: $applePayConfiguration)
                        }
                    }
                    .id("\(requireEmail)-\(requirePhone)")
            }
        }
        .environment(\.locale, Locale(identifier: locale))
        .environment(configuration)
        .environment(applePayConfiguration)
        .onChange(of: requireEmail) { updateApplePayConfiguration() }
        .onChange(of: requirePhone) { updateApplePayConfiguration() }
    }

    private func updateApplePayConfiguration() {
        applePayConfiguration = createApplePayConfiguration(
            requireEmail: requireEmail,
            requirePhone: requirePhone
        )
    }
}

private func createApplePayConfiguration(
    requireEmail: Bool = UserDefaults.standard.object(forKey: "includeEmail") as? Bool ?? true,
    requirePhone: Bool = UserDefaults.standard.object(forKey: "includePhone") as? Bool ?? true
) -> ShopifyAcceleratedCheckouts.ApplePayConfiguration {
    var fields: [ShopifyAcceleratedCheckouts.RequiredContactFields] = []

    if requireEmail { fields.append(.email) }
    if requirePhone { fields.append(.phone) }

    return ShopifyAcceleratedCheckouts.ApplePayConfiguration(
        merchantIdentifier: "merchant.com.shopify.example.ShopifyAcceleratedCheckoutsApp",
        supportedNetworks: [.amex, .discover, .masterCard, .visa],
        contactFields: fields
    )
}
