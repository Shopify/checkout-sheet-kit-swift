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
import ShopifyAcceleratedCheckouts
import ShopifyCheckoutSheetKit
import SwiftUI

enum AppStorageKeys: String {
    case acceleratedCheckoutsLogLevel
    case checkoutSheetKitLogLevel
}

struct SettingsView: View {
    @ObservedObject var config: AppConfiguration = appConfiguration

    @AppStorage(AppStorageKeys.checkoutSheetKitLogLevel.rawValue)
    var checkoutSheetKitLogLevel: LogLevel = .all {
        didSet {
            ShopifyCheckoutSheetKit.configure {
                $0.logLevel = checkoutSheetKitLogLevel
            }
        }
    }

    @AppStorage(AppStorageKeys.acceleratedCheckoutsLogLevel.rawValue)
    var acceleratedCheckoutsLogLevel: LogLevel = .all {
        didSet {
            ShopifyAcceleratedCheckouts.logLevel = acceleratedCheckoutsLogLevel
        }
    }

    @State private var preloadingEnabled = ShopifyCheckoutSheetKit.configuration.preloading.enabled
    @State private var logs: [String?] = LogReader.shared.readLogs() ?? []
    @State private var selectedColorScheme = ShopifyCheckoutSheetKit.configuration.colorScheme
    @State private var colorScheme: ColorScheme = .light
    @State private var checkoutURL: String = ""

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

                Section(header: Text("Debug")) {
                    TextField("Checkout URL", text: $checkoutURL)
                        .textContentType(.URL)
                        .autocapitalization(.none)
                        .keyboardType(.URL)
                    Button("Present") {
                        if let url = URL(string: checkoutURL) {
                            CheckoutController.shared?.present(checkout: url)
                        }
                    }
                    .disabled(checkoutURL.isEmpty)
                }

                Section(header: Text("Universal Links")) {
                    Toggle("Handle Checkout URLs", isOn: $config.universalLinks.checkout)
                    Toggle("Handle Cart URLs", isOn: $config.universalLinks.cart)
                    Toggle("Handle Product URLs", isOn: $config.universalLinks.products)
                    Toggle(
                        "Handle all Universal Links",
                        isOn: $config.universalLinks.handleAllURLsInApp
                    )

                    Text(
                        "By default, the app will only handle the selections above and route everything else to Safari. Enabling the \"Handle all Universal Links\" setting will route all Universal Links to this app."
                    )
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
                                ShopifyCheckoutSheetKit.configuration.backgroundColor =
                                    scheme.backgroundColor
                                NotificationCenter.default.post(
                                    name: .colorSchemeChanged, object: nil
                                )
                            }
                    }
                }

                Section(header: Text("Logging")) {
                    Picker(
                        "Accelerated Checkouts",
                        selection: Binding(
                            get: { acceleratedCheckoutsLogLevel },
                            set: { acceleratedCheckoutsLogLevel = $0 }
                        )
                    ) {
                        ForEach(LogLevel.allCases, id: \.self) { level in
                            Text(
                                level.rawValue.capitalized(with: Locale.current)
                            ).tag(level)
                        }
                    }
                    .pickerStyle(.menu)

                    Picker(
                        "Checkout Sheet Kit",
                        selection: Binding(
                            get: { checkoutSheetKitLogLevel },
                            set: { checkoutSheetKitLogLevel = $0 }
                        )
                    ) {
                        ForEach(LogLevel.allCases, id: \.self) { level in
                            Text(
                                level.rawValue.capitalized(with: Locale.current)
                            ).tag(level)
                        }
                    }
                    .pickerStyle(.menu)

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

    private func currentVersion() -> String {
        return "\(InfoDictionary.shared.version) (\(InfoDictionary.shared.buildNumber))"
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
