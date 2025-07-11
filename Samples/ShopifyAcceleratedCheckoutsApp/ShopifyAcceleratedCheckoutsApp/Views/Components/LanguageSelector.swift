//
//  LanguageSelector.swift
//  ShopifyAcceleratedCheckoutsApp
//

import SwiftUI

struct LanguageSelector: View {
    @Binding var locale: String
    let availableLocales: [(name: String, isoCode: String)]
    let onLocaleChange: (String) -> Void

    var body: some View {
        Menu {
            ForEach(availableLocales, id: \.isoCode) { localeOption in
                Button {
                    onLocaleChange(localeOption.isoCode)
                } label: {
                    HStack {
                        Text(localeOption.name)
                        Spacer()
                        if locale == localeOption.isoCode {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Label("Language", systemImage: "globe")
        }
    }
}
