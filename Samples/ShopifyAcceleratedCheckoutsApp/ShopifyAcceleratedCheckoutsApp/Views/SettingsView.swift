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

enum AppStorageKeys: String {
    case requireEmail
    case requirePhone
    case locale
    case logLevel
}

struct SettingsView: View {
    @AppStorage(AppStorageKeys.requireEmail.rawValue) var requireEmail: Bool = true
    @AppStorage(AppStorageKeys.requirePhone.rawValue) var requirePhone: Bool = true
    @AppStorage(AppStorageKeys.locale.rawValue) var locale: String = "en"
    @AppStorage(AppStorageKeys.logLevel.rawValue) var logLevel: LogLevel = LogLevel.all {
        didSet {
            ShopifyAcceleratedCheckouts.logLevel = logLevel
        }
    }

    private let availableLocales: [(name: String, isoCode: String)] = [
        ("English", "en"),
        ("English (US)", "en-US"),
        ("French", "fr-FR"),
    ]

    var body: some View {
        Form {
            Section("Logging") {
                Picker(
                    "Log Level",
                    /// Binding used instead of $logLevel due to property observers (didSet)
                    /// are not called on published values such as @AppStorage
                    selection: Binding(
                        get: { logLevel },
                        set: { logLevel = $0 }
                    )
                ) {
                    ForEach(LogLevel.allCases, id: \.self) { level in
                        Text(
                            level.rawValue.capitalized(with: Locale.current)
                        ).tag(level)
                    }
                }
                .pickerStyle(.menu)

                Text("Controls the level of logging for Accelerated Checkouts operations")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

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
                Toggle("Request Email", isOn: $requireEmail)
                Toggle("Request Phone", isOn: $requirePhone)

                if !requireEmail, !requirePhone {
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
