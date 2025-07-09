//
//  View.swift
//  ShopifyAcceleratedCheckouts
//

import SwiftUI

public struct IsVisibleModifier: ViewModifier {
    let isVisible: Bool

    public func body(content: Content) -> some View {
        ZStack {
            if isVisible { content }
        }
    }
}

public extension View {
    func isVisible(when: Bool) -> some View {
        modifier(
            IsVisibleModifier(isVisible: when)
        )
    }
}
