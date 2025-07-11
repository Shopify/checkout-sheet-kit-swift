//
//  Animation+View.swift
//  ShopifyAcceleratedCheckoutsApp
//

import SwiftUI

extension Animation {
    /// Standard spring animation for quantity changes
    static var quantityChange: Animation {
        .spring(response: 0.3, dampingFraction: 0.7)
    }

    /// Standard spring animation for general UI updates
    static var standard: Animation {
        .spring(response: 0.3, dampingFraction: 0.8)
    }
}

extension View {
    /// Animate changes to quantity values
    func animateQuantityChange(value: some Equatable) -> some View {
        animation(.quantityChange, value: value)
    }
}
