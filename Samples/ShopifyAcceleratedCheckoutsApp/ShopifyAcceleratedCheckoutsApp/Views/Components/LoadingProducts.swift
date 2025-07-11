//
//  LoadingProducts.swift
//  ShopifyAcceleratedCheckoutsApp
//

import SwiftUI

struct LoadingProducts: View {
    var body: some View {
        HStack {
            Spacer()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.2)
                .padding()
            Text("Loading products...")
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.vertical, 40)
    }
}
