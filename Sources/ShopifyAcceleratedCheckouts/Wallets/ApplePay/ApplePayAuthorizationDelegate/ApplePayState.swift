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

@available(iOS 17.0, *)
enum ApplePayState: Equatable {
    static func == (lhs: ApplePayState, rhs: ApplePayState) -> Bool {
        return String(describing: lhs.self) == String(describing: rhs.self)
    }

    /// Initial state - Ready to start a payment request
    /// The delegate is idle and waiting for a payment request to be initiated
    case idle

    /// Payment request has been initiated and is being prepared
    /// Next state: presented (if successful) or reset (if presentation fails)
    case startPaymentRequest

    /// Apple Pay sheet is currently visible to the user
    /// The user can interact with the payment sheet (select shipping, change payment method, etc.)
    case appleSheetPresented

    /// Payment was interrupted due to a validation violation Apple Pay sheet cannot handle
    /// Prior to the payment authorization
    /// This occurs when cart api detects an issue that requires CSK intervention
    /// (e.g., out of stock items)
    case interrupt(
        /// The payment sheet will be interrupted and the user will be redirected to the checkout
        /// with the interrupt reason as a query parameter
        reason: ErrorHandler.InterruptReason
    )

    /// The user has authenticated (Face ID/Touch ID) and confirmed the payment
    /// Next step: Submit the payment to Shopify for processing
    case paymentAuthorized(payment: PKPayment)

    /// Payment authorization failed after user authorized the payment
    /// This could be due to authentication failure, network issues, or processing errors
    case paymentAuthorizationFailed(error: Error)

    /// Payment has been successfully submitted to Shopify
    /// The cart has been converted to a checkout/order and we have a redirect URL
    /// This does not indicate that the payment has been processed successfully
    case cartSubmittedForCompletion(
        /// URL after a SubmitSuccess from cartSubmitForCompletion
        /// Should render the Thank You Page if payment processing etc. succeeds
        /// Will render Checkout if any error causes the order creation to fail
        redirectURL: URL
    )

    /// Unexpected error occurred - falling back to CSK
    /// Used for errors that are non recoverable in the Apple Pay sheet and require CSK recovery
    case unexpectedError(error: Error)

    /// Use this when when ApplePay cannot handle the error, and CSK cannot be used as a fallback
    /// e.g. cart query / cartCreate fails, so we don't have a checkoutURL to show CSK
    case terminalError(error: Error)

    /// Presenting CheckoutSheetKit (CSK)
    /// Entering this state after `cartSubmittedForCompletion` will show the Thank You Page if payment is succesful
    /// Otherwise this will present checkout as a fallback
    case presentingCSK(url: URL?)

    /// Transition to completed at terminal points in the flow
    /// If all work processing is done, transition to completed, to activate final side effects
    /// where the delegate will relinquish responsibility
    ///
    /// Terminal states that lead here:
    /// 1. Payment was successfully authorized and CSK was presented
    /// 2. User cancelled the sheet (dismissed)
    /// 3. SDK encountered an error and needed CSK fallback
    /// 4. Payment was interrupted for business logic reasons
    ///
    /// Note: Payment may still fail during payment processing - it is then CSK's responsibility to handle it
    case completed

    /// Reset to initial state
    /// Clears all transient data and prepares for a new payment flow
    /// Then transitions to idle
    case reset

    /// Validates whether this state can transition to the given next state
    /// - Parameter nextState: The proposed next state
    /// - Returns: true if the transition is valid, false otherwise
    func canTransition(to nextState: ApplePayState) -> Bool {
        switch (self, nextState) {
        case (.idle, .startPaymentRequest),
             /// Occurs when TYP is dismissed, as state will transition to idle before closure
             (.idle, .completed),

             (.startPaymentRequest, .appleSheetPresented),
             /// Failing to construct paymentRequest or present payment sheet
             (.startPaymentRequest, .reset),

             (.appleSheetPresented, .paymentAuthorized),
             (.appleSheetPresented, .paymentAuthorizationFailed),
             (.appleSheetPresented, .interrupt),
             /// User cancels the sheet
             (.appleSheetPresented, .completed),

             (.paymentAuthorized, .cartSubmittedForCompletion),
             (.paymentAuthorized, .paymentAuthorizationFailed),
             (.paymentAuthorized, .interrupt),

             (.paymentAuthorizationFailed, .completed),
             (.paymentAuthorizationFailed, .reset),

             (.cartSubmittedForCompletion, .completed),

             (.interrupt, .completed),

             (.unexpectedError, .completed),
             (.unexpectedError, .terminalError),

             (.terminalError, .completed),

             (.presentingCSK, .completed),

             (.completed, .presentingCSK),
             (.completed, .reset),

             (.reset, .idle):
            return true

        // Allow transitions to error states from any state
        case (_, .unexpectedError),
             (_, .terminalError):
            return true

        default:
            return false
        }
    }
}
