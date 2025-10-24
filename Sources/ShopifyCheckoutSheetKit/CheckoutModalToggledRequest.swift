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
import WebKit

/// Parameters for modal toggle events - contains visibility state
public struct CheckoutModalToggledParams: Decodable {
    public let modalVisible: Bool

    public init(from decoder: Decoder) throws {
        // The params is a string "true" or "false" directly
        let container = try decoder.singleValueContainer()
        let visibleString = try container.decode(String.self)
        modalVisible = Bool(visibleString) ?? false
    }

    public init(modalVisible: Bool) {
        self.modalVisible = modalVisible
    }
}

/// Request for checkout modal toggle events
public final class CheckoutModalToggledRequest: BaseRPCRequest<CheckoutModalToggledParams, EmptyResponse> {
    override public static var method: String { "checkoutBlockingEvent" }
}
