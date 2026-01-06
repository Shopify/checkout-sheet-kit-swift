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

/// Event triggered when the primary action state changes.
/// Provides information about the current state (enabled/disabled/loading) and action type (review/pay).
///
/// This event is useful for implementing "Bring Your Own Pay Button" (BYOPB) experiences,
/// where the app needs to maintain its own button UI that reflects the checkout state.
///
/// The button is enabled when all of the following conditions are met:
/// - Contact email or phone exists
/// - Shipping address is complete (if required)
/// - Payment method exists
/// - No blocking extensions are active
public struct CheckoutPrimaryActionChangeEvent: CheckoutNotification {
    public static let method = "checkout.primaryActionChange"

    /// The current state of the primary action button
    public let state: PrimaryActionState

    /// The action the button will perform when clicked
    public let action: PrimaryAction

    /// The current cart state
    public let cart: Cart

    /// Represents the state of the primary action button
    public enum PrimaryActionState: String, Codable {
        /// Button is enabled and ready for user interaction
        case enabled

        /// Button is disabled (checkout incomplete or validation errors)
        case disabled

        /// Button is in loading state (processing an action)
        case loading
    }

    /// Represents the action that will be performed when the button is clicked
    public enum PrimaryAction: String, Codable {
        /// Navigate to review page (when confirmation page is enabled)
        case review

        /// Submit payment and complete checkout
        case pay
    }
}
