//
//  SettingsView.swift
//  ShopifyAcceleratedCheckoutsApp
//

import ShopifyAcceleratedCheckouts
import SwiftUI

struct SettingsView: View {
    @AppStorage("includeEmail") var includeEmail: Bool = true
    @AppStorage("includePhone") var includePhone: Bool = true
    @AppStorage("locale") var locale: String = "en"
    @Binding var applePayConfiguration: ShopifyAcceleratedCheckouts.ApplePayConfiguration

    private let availableLocales: [(name: String, isoCode: String)] = [
        ("English", "en"),
        ("English (US)", "en-US"),
        ("French", "fr-FR")
    ]

    var body: some View {
        Form {
            Section("Language") {
                Picker("Language", selection: $locale) {
                    ForEach(availableLocales, id: \.isoCode) { localeOption in
                        Text(localeOption.name)
                            .tag(localeOption.isoCode)
                    }
                }
                .pickerStyle(.menu)

                Text("Configures localization for fallback if ApplePay not supported")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Apple Pay Contact Fields") {
                Toggle("Request Email", isOn: $includeEmail)
                Toggle("Request Phone", isOn: $includePhone)

                if !includeEmail, !includePhone {
                    Text("Note: At least one contact field is recommended for Apple Pay")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }

            Section {
                Text("These settings will apply to new checkouts and persist between app launches")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}
