/*
 MIT License

 Copyright 2023 - Present, Shopify Inc.

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

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
