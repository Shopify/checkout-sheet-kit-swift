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

import ShopifyAcceleratedCheckouts
import ShopifyCheckoutSheetKit
import SwiftUI

@main
struct ShopifyAcceleratedCheckoutsApp: App {
    @AppStorage(AppStorageKeys.requireEmail.rawValue) var requireEmail: Bool = true
    @AppStorage(AppStorageKeys.requirePhone.rawValue) var requirePhone: Bool = true
    @AppStorage(AppStorageKeys.locale.rawValue) var locale: String = "en"
    @AppStorage(AppStorageKeys.logLevel.rawValue) var logLevel: LogLevel = .all
    @AppStorage(AppStorageKeys.email.rawValue) var email: String = ""
    @AppStorage(AppStorageKeys.phone.rawValue) var phone: String = ""

    var configuration: ShopifyAcceleratedCheckouts.Configuration {
        .init(
            storefrontDomain: EnvironmentVariables.storefrontDomain,
            storefrontAccessToken: EnvironmentVariables.storefrontAccessToken,
            customer: ShopifyAcceleratedCheckouts.Customer(email: email, phoneNumber: phone)
        )
    }

    var applePayConfiguration: ShopifyAcceleratedCheckouts.ApplePayConfiguration {
        createApplePayConfiguration(requireEmail: requireEmail, requirePhone: requirePhone)
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                CartBuilderView(configuration: configuration)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            SettingsButton()
                        }
                    }
                    .id("\(requireEmail)-\(requirePhone)")
                    .onChange(of: email) { _ in updateConfiguration() }
                    .onChange(of: phone) { _ in updateConfiguration() }
            }
            .onAppear {
                ShopifyAcceleratedCheckouts.logLevel = logLevel
            }
            .environmentObject(configuration)
            .environmentObject(applePayConfiguration)
        }
        .environment(\.locale, Locale(identifier: locale))
    }

    private func updateConfiguration() {
        configuration.customer = ShopifyAcceleratedCheckouts.Customer(
            email: email.isEmpty ? nil : email,
            phoneNumber: phone.isEmpty ? nil : phone
        )
    }
}

private func createApplePayConfiguration(
    requireEmail: Bool,
    requirePhone: Bool
) -> ShopifyAcceleratedCheckouts.ApplePayConfiguration {
    var fields: [ShopifyAcceleratedCheckouts.RequiredContactFields] = []

    if requireEmail { fields.append(.email) }
    if requirePhone { fields.append(.phone) }

    return ShopifyAcceleratedCheckouts.ApplePayConfiguration(
        merchantIdentifier: "merchant.com.shopify.example.ShopifyAcceleratedCheckoutsApp",
        contactFields: fields
    )
}
