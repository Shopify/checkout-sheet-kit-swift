//
//  ShopifyAcceleratedCheckoutsApp.swift
//  ShopifyAcceleratedCheckoutsApp
//

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
