//
//  VariantTitle.swift
//  ShopifyAcceleratedCheckoutsApp
//

import SwiftUI

struct VariantTitle: View {
    let title: String
    let font: Font
    let prefix: String

    init(title: String, font: Font = .caption, prefix: String = "Variant: ") {
        self.title = title
        self.font = font
        self.prefix = prefix
    }

    var body: some View {
        if title != "Default Title" {
            Text("\(prefix)\(title)")
                .font(font)
                .foregroundColor(.secondary)
        }
    }
}
