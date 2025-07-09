//
//  ErrorHandler_Warnings.swift
//  ShopifyAcceleratedCheckouts
//

import Foundation
import PassKit

extension ErrorHandler {
    static func map(
        warningType: StorefrontAPI.WarningType,
        cart: StorefrontAPI.Types.Cart?
    ) -> PaymentSheetAction {
        switch warningType {
        case .outOfStock:
            return .interrupt(reason: .outOfStock, checkoutURL: cart?.checkoutUrl.url)
        case .notEnoughStock:
            return .interrupt(reason: .notEnoughStock, checkoutURL: cart?.checkoutUrl.url)
        }
    }
}
