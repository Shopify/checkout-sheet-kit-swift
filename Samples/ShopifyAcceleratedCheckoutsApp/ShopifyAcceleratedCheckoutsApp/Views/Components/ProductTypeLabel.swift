//
//  ProductTypeLabel.swift
//  ShopifyAcceleratedCheckoutsApp
//

import SwiftUI

struct ProductTypeLabel: View {
    let requiresShipping: Bool

    var productType: String {
        requiresShipping ? "Physical" : "Digital"
    }

    var systemImage: String {
        requiresShipping ? "shippingbox" : "arrow.down.circle"
    }

    var color: Color {
        requiresShipping ? .blue : .green
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
            Text(productType)
        }
        .foregroundColor(color)
    }
}
