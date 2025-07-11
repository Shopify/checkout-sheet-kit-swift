//
//  ProductImage.swift
//  ShopifyAcceleratedCheckoutsApp
//

import SwiftUI

struct ProductImage: View {
    let imageUrl: String?
    let size: CGFloat

    init(imageUrl: String?, size: CGFloat = 60) {
        self.imageUrl = imageUrl
        self.size = size
    }

    var body: some View {
        if let imageUrlString = imageUrl,
           let url = URL(string: imageUrlString)
        {
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: size, height: size)
                    .overlay(
                        ProgressView()
                            .scaleEffect(0.5)
                    )
            }
        } else {
            // Placeholder for products without images
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.1))
                .frame(width: size, height: size)
                .overlay(
                    Image(systemName: "photo")
                        .foregroundColor(.gray.opacity(0.5))
                        .font(size > 60 ? .title3 : .body)
                )
        }
    }
}
