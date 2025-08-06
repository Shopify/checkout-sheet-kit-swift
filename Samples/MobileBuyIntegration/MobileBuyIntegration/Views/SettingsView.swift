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

import Combine
import ShopifyCheckoutSheetKit
import SwiftUI

struct SettingsView: View {
    @ObservedObject var config: AppConfiguration = appConfiguration

    @State private var preloadingEnabled = ShopifyCheckoutSheetKit.configuration.preloading.enabled
    @State private var logs: [String?] = LogReader.shared.readLogs() ?? []
    @State private var selectedColorScheme = ShopifyCheckoutSheetKit.configuration.colorScheme
    @State private var colorScheme: ColorScheme = .light
    @State private var privacyConsent: Configuration.PrivacyConsent = .none
    @State private var isEncodingConsent = false
    @State private var encodedConsentResult: String?
    @State private var encodingError: String?

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Features")) {
                    Toggle("Preload checkout", isOn: $preloadingEnabled)
                        .onChange(of: preloadingEnabled) { newValue in
                            ShopifyCheckoutSheetKit.configuration.preloading.enabled = newValue
                        }
                    Toggle("Prefill buyer information", isOn: $config.useVaultedState)
                }

                Section(header: Text("Universal Links")) {
                    Toggle("Handle Checkout URLs", isOn: $config.universalLinks.checkout)
                    Toggle("Handle Cart URLs", isOn: $config.universalLinks.cart)
                    Toggle("Handle Product URLs", isOn: $config.universalLinks.products)
                    Toggle("Handle all Universal Links", isOn: $config.universalLinks.handleAllURLsInApp)

                    Text("By default, the app will only handle the selections above and route everything else to Safari. Enabling the \"Handle all Universal Links\" setting will route all Universal Links to this app.")
                        .font(.caption)
                }

                Section(header: Text("Theme")) {
                    ForEach(Configuration.ColorScheme.allCases, id: \.self) { scheme in
                        ColorSchemeView(scheme: scheme, isSelected: scheme == selectedColorScheme)
                            .background(Color.clear)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedColorScheme = scheme
                                ShopifyCheckoutSheetKit.configuration.colorScheme = scheme
                                ShopifyCheckoutSheetKit.configuration.tintColor = scheme.tintColor
                                ShopifyCheckoutSheetKit.configuration.backgroundColor = scheme.backgroundColor
                                NotificationCenter.default.post(name: .colorSchemeChanged, object: nil)
                            }
                    }
                }

                Section(header: Text("Privacy Consent Signals")) {
                    Toggle("Marketing", isOn: consentBinding(for: .marketing))
                    Toggle("Analytics", isOn: consentBinding(for: .analytics))
                    Toggle("Preferences", isOn: consentBinding(for: .preferences))
                    Toggle("Sale of Data", isOn: consentBinding(for: .saleOfData))

                    HStack {
                        Button("Encode Consent") {
                            Task {
                                await encodeConsent()
                            }
                        }
                        .foregroundColor(.blue)
                        .disabled(isEncodingConsent)

                        Spacer()
                    }

                    if let encoded = encodedConsentResult {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Encoded Consent:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(encoded)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.primary)
                                    .textSelection(.enabled)
                            }
                            .padding(.vertical, 4)
                            Spacer()
                            Button("Clear") {
                                clearEncodedConsent()
                            }
                            .foregroundColor(.red)
                            .font(.caption)
                        }
                    }

                    if let error = encodingError {
                        Text("Error: \(error)")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                Section(header: Text("Logs")) {
                    NavigationLink(destination: WebPixelsEventsView()) {
                        Text("Web pixel events")
                    }
                    NavigationLink(destination: LogsView()) {
                        Text("Logs")
                    }
                }

                Section(header: Text("Version")) {
                    HStack {
                        Text("Sample app version")
                        Spacer()
                        Text(currentVersion())
                            .font(.system(size: 14))
                            .foregroundStyle(.gray)
                    }
                    HStack {
                        Text("Checkout Sheet Kit version")
                        Spacer()
                        Text(ShopifyCheckoutSheetKit.version)
                            .font(.system(size: 14))
                            .foregroundStyle(.gray)
                    }
                }
            }
            .listStyle(GroupedListStyle())
            .navigationTitle("Settings")
            .onAppear {
                logs = LogReader.shared.readLogs() ?? []
                privacyConsent = ShopifyCheckoutSheetKit.configuration.privacyConsent ?? .none
                encodedConsentResult = ShopifyCheckoutSheetKit.currentEncodedPrivacyConsent
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
        .onAppear {
            switch ShopifyCheckoutSheetKit.configuration.colorScheme {
            case .light:
                colorScheme = .light
            case .dark:
                colorScheme = .dark
            default:
                colorScheme = .light
            }
        }
    }

    private func consentBinding(for consentType: Configuration.PrivacyConsent) -> Binding<Bool> {
        Binding(
            get: {
                privacyConsent.contains(consentType)
            },
            set: { newValue in
                if newValue {
                    privacyConsent.insert(consentType)
                } else {
                    privacyConsent.remove(consentType)
                }
                ShopifyCheckoutSheetKit.configuration.privacyConsent = privacyConsent
                ShopifyCheckoutSheetKit.clearEncodedPrivacyConsent()
                encodedConsentResult = nil
            }
        )
    }

    private func currentVersion() -> String {
        return "\(InfoDictionary.shared.version) (\(InfoDictionary.shared.buildNumber))"
    }

    private func encodeConsent() async {
        isEncodingConsent = true
        encodingError = nil

        do {
            let encoded = try await ShopifyCheckoutSheetKit.encodePrivacyConsent()
            await MainActor.run {
                encodedConsentResult = encoded
                encodingError = nil
                print("[SettingsView] Privacy consent encoded: \(encoded ?? "nil")")
            }
        } catch {
            await MainActor.run {
                encodedConsentResult = nil
                encodingError = error.localizedDescription
                print("[SettingsView] Failed to encode consent: \(error.localizedDescription)")
            }
        }

        isEncodingConsent = false
    }

    private func clearEncodedConsent() {
        ShopifyCheckoutSheetKit.clearEncodedPrivacyConsent()
        encodedConsentResult = nil
        encodingError = nil
        print("[SettingsView] Cleared encoded consent")
    }
}

struct ColorSchemeView: View {
    let scheme: Configuration.ColorScheme
    let isSelected: Bool

    var body: some View {
        HStack {
            Text(scheme.prettyTitle)
            Spacer()
            if isSelected {
                Text("✓")
            }
        }
    }
}

extension Configuration.ColorScheme {
    var prettyTitle: String {
        switch self {
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        case .automatic:
            return "Automatic"
        case .web:
            return "Web"
        }
    }

    var tintColor: UIColor {
        switch self {
        case .web:
            return UIColor(red: 0.18, green: 0.16, blue: 0.22, alpha: 1.00)
        default:
            return UIColor(red: 0.09, green: 0.45, blue: 0.69, alpha: 1.00)
        }
    }

    var backgroundColor: UIColor {
        switch self {
        case .web:
            return ColorPalette.backgroundColor
        default:
            return .systemBackground
        }
    }
}

#Preview {
    SettingsView()
}
