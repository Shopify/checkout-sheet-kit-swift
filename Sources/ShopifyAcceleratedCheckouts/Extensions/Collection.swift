//
//  Collection.swift
//  ShopifyAcceleratedCheckouts
//
//  Created by Kieran Barrie Osgood on 05/06/2025.
//

extension Collection {
    // Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
