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

/// Options for configuring checkout presentation and behavior for an individual checkout session.
public struct CheckoutOptions {
    /// Authentication configuration, allowing identification the application initiating checkout and application of any app sepcific customizations.
    public var authentication: Authentication = .none

    /// Entry point metadata for tracking checkout context (internal use only).
    package var entryPoint: MetaData.EntryPoint?

    /// Initializes checkout options.
    /// - Parameter authentication: Authentication configuration for the checkout session.
    public init(authentication: Authentication = .none) {
        self.authentication = authentication
        entryPoint = nil
    }

    /// Package-level initializer for internal use (e.g., AcceleratedCheckouts).
    /// - Parameters:
    ///   - authentication: Authentication configuration for the checkout session.
    ///   - entryPoint: Entry point metadata for tracking.
    package init(authentication: Authentication = .none, entryPoint: MetaData.EntryPoint?) {
        self.authentication = authentication
        self.entryPoint = entryPoint
    }

    /// Authentication options for checkout.
    public enum Authentication {
        /// No authentication - checkout will run without app authentication.
        case none

        /// Token-based authentication using a JWT token.
        /// - Parameter token: A valid JWT token string.
        case token(String)
    }
}
