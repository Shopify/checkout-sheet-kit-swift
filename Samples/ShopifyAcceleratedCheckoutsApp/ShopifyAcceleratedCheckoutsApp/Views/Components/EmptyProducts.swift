//
//  EmptyProducts.swift
//  ShopifyAcceleratedCheckoutsApp
//

import SwiftUI

struct EmptyProducts: View {
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Text("No products available")
                .foregroundColor(.secondary)

            Button("Retry", action: onRetry)
                .foregroundColor(.accentColor)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}
