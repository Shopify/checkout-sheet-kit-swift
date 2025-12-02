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

/// Abstract base class for all RPC message implementations.
///
/// This class contains all shared behavior between requests (bidirectional, with id)
/// and notifications (unidirectional, without id). Subclasses specialize for each type:
/// - `BaseRPCRequest` for request events (checkout.addressChangeStart, etc.)
/// - `BaseRPCNotification` for notification events (checkout.start, checkout.complete)
///
/// This base class eliminates code duplication and provides a single source of truth
/// for common RPC message behavior.
public class BaseRPCMessage<P: Decodable>: RPCMessage {
    public typealias Params = P

    /// The JSON-RPC version (always "2.0")
    public var jsonrpc: String { "2.0" }

    /// Whether this is a notification - subclasses must override
    public var isNotification: Bool {
        fatalError("Subclasses must override isNotification")
    }

    /// The parameters from the RPC message.
    /// Public - external developers access state via params namespace.
    public let params: Params

    /// Weak reference to the WebView for sending responses
    internal weak var webview: WKWebView?

    /// Subclasses must override this to provide their method name
    public class var method: String {
        fatalError("Subclasses must override method")
    }

    /// Internal initializer used by subclasses
    /// - Parameters:
    ///   - params: The decoded parameters for this message
    ///   - webview: Optional webview reference (set by registry after decoding)
    internal init(params: Params, webview: WKWebView? = nil) {
        self.params = params
        self.webview = webview
    }

    /// Required initializer for RPCMessage protocol
    /// Subclasses must implement this to handle wire-format decoding
    /// - Parameters:
    ///   - id: Optional id from JSON (present for requests, nil for notifications)
    ///   - params: The decoded parameters
    public required init(id _: String?, params: Params) {
        self.params = params
        webview = nil
    }
}

// MARK: - TypeErasedRPCDecodable conformance

extension BaseRPCMessage: TypeErasedRPCDecodable {
    static func decodeErased(from data: Data) throws -> any RPCMessage {
        return try JSONDecoder().decode(Self.self, from: data)
    }
}
