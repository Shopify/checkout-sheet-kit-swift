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
        shopDomain: EnvironmentVariables.storefrontDomain,
        storefrontAccessToken: EnvironmentVariables.storefrontAccessToken,
        customer: ShopifyAcceleratedCheckouts.Customer(email: nil)
    )

    @State var applePayConfiguration: ShopifyAcceleratedCheckouts.ApplePayConfiguration

    init() {
        // Initialize with default values
        let initialIncludeEmail =
            UserDefaults.standard.object(forKey: "includeEmail") as? Bool ?? true
        let initialIncludePhone =
            UserDefaults.standard.object(forKey: "includePhone") as? Bool ?? true

        var fields: [ShopifyAcceleratedCheckouts.RequiredContactFields] = []
        if initialIncludeEmail {
            fields.append(.email)
        }
        if initialIncludePhone {
            fields.append(.phone)
        }

        _applePayConfiguration = State(
            initialValue: ShopifyAcceleratedCheckouts.ApplePayConfiguration(
                merchantIdentifier: "merchant.com.shopify.example.ShopifyAcceleratedCheckoutsApp",
                supportedNetworks: [.amex, .discover, .masterCard, .visa],
                contactFields: fields
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
            updateApplePayConfiguration()
        }
        .onChange(of: includePhone) { _, _ in
            updateApplePayConfiguration()
        }
    }

    private func updateApplePayConfiguration() {
        var fields: [ShopifyAcceleratedCheckouts.RequiredContactFields] = []
        if includeEmail {
            fields.append(.email)
        }
        if includePhone {
            fields.append(.phone)
        }

        applePayConfiguration = ShopifyAcceleratedCheckouts.ApplePayConfiguration(
            merchantIdentifier: "merchant.com.shopify.example.ShopifyAcceleratedCheckoutsApp",
            supportedNetworks: [.amex, .discover, .masterCard, .visa],
            contactFields: fields
        )
    }
}
