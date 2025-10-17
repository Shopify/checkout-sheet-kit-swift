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

/// Parameters for error events - array of error events
public struct CheckoutErrorParams: Decodable {
    public let errors: [CheckoutErrorEvent]

    public init(from decoder: Decoder) throws {
        // The params is an array directly
        let container = try decoder.singleValueContainer()
        self.errors = try container.decode([CheckoutErrorEvent].self)
    }
}

/// Request for checkout error events
public final class CheckoutErrorRequest: BaseRPCRequest<CheckoutErrorParams, EmptyResponse> {
    public override static var method: String { "error" }

    /// Convenience getter to access the first error
    public var firstError: CheckoutErrorEvent? {
        return params.errors.first
    }
}