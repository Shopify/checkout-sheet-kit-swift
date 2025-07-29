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
import UIKit

package enum Theme {
    // Shop Pay Accelerated Checkout Button
    package static let shopPayButtonColor = UIColor(red: 0.36, green: 0.28, blue: 0.90, alpha: 1.0)
    package static let shopPayButtonTextColor = UIColor.white
    package static let shopPayButtonTextFont = UIFont.systemFont(ofSize: 16, weight: .medium)

    // Apple Pay Accelerated Checkout Button
    package static let applePayButtonColor = UIColor.black
    package static let applePayButtonTextColor = UIColor.white
    package static let applePayButtonTextFont = UIFont.systemFont(ofSize: 16, weight: .medium)

    // Accelerated Checkout Button defaults
    package static let acceleratedCheckoutButtonCornerRadius = 8.0
}
