//
//  ErrorHandler_CartPrepareForCompletion.swift
//  ShopifyAcceleratedCheckouts
//

import Foundation
import PassKit

extension ErrorHandler {
    static func map(payload: StorefrontAPI.CartPrepareForCompletionPayload) -> PaymentSheetAction {
        guard let result = payload.result else { return PaymentSheetAction.interrupt(reason: .other) }
        switch result {
        case .notReady:
            return PaymentSheetAction.interrupt(reason: .cartNotReady)
        case .throttled:
            return PaymentSheetAction.interrupt(reason: .cartThrottled)
        case .ready:
            // No-op: error handler not called for success result
            print("ErrorHandler: map: received unexpected result type from Cart API on prepare")
            return PaymentSheetAction.interrupt(reason: .other)
        }
    }
}
