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

/// Base class for all RPC request implementations
internal class BaseRPCRequest<P: Decodable, R: Codable>: RPCRequest {
    typealias Params = P
    typealias ResponsePayload = R

    let id: String
    let params: Params
    weak var webview: WKWebView?

    /// Subclasses must override this to provide their method name
    class var method: String {
        fatalError("Subclasses must override method")
    }

    /// Required initializer that all RPC requests must implement
    required init(id: String, params: Params) {
        self.id = id
        self.params = params
        webview = nil
    }
}

// MARK: - TypeErasedRPCDecodable conformance

extension BaseRPCRequest: TypeErasedRPCDecodable {
    static func decodeErased(from data: Data) throws -> any RPCRequest {
        return try JSONDecoder().decode(Self.self, from: data)
    }
}
