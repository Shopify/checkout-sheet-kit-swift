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

enum BridgeError: Swift.Error {
    case invalidBridgeEvent(Swift.Error? = nil)
    case unencodableInstrumentation(Swift.Error? = nil)
}

protocol CheckoutBridgeProtocol {
    static func instrument(_ webView: WKWebView, _ instrumentation: InstrumentationPayload)
    static func sendMessage(_ webView: WKWebView, messageName: String, messageBody: String?)
}

enum CheckoutBridge: CheckoutBridgeProtocol {
    static let messageHandler = "EmbeddedCheckoutProtocolConsumer"
    static func instrument(_ webView: WKWebView, _ instrumentation: InstrumentationPayload) {
        if let payload = instrumentation.toBridgeEvent() {
            sendMessage(webView, messageName: "instrumentation", messageBody: payload)
        }
    }

    static func sendMessage(_ webView: WKWebView, messageName: String, messageBody: String?) {
        let dispatchMessageBody: String
        if let body = messageBody {
            dispatchMessageBody = "'\(messageName)', \(body)"
        } else {
            dispatchMessageBody = "'\(messageName)'"
        }
        let script = dispatchMessageTemplate(body: dispatchMessageBody)
        webView.evaluateJavaScript(script)
    }

    static func sendResponse(_ webView: WKWebView, messageBody: String) {
        DispatchQueue.main.async {
            let script = """
            (function() {
                try {
                    if (window && typeof window.postMessage === 'function') {
                        window.postMessage(\(messageBody), '*');
                    } else if (window && window.console && window.console.error) {
                        window.console.error('window.postMessage is not available.');
                    }
                } catch (error) {
                    if (window && window.console && window.console.error) {
                        window.console.error('Failed to post message to checkout', error);
                    }
                }
            })();
            """

            webView.evaluateJavaScript(script)
        }
    }

    static func decode(_ message: WKScriptMessage) throws -> Any? {

        do {
            guard let body = message.body as? String, let data = body.data(using: .utf8) else {
                throw BridgeError.invalidBridgeEvent()
            }
            struct MethodExtractor: Decodable {
                let method: String
            }
            
            let extractor = try JSONDecoder().decode(MethodExtractor.self, from: data)
            
            guard
                let webview = message.webView,
                let request = try EventRegistry.decode(
                    for: extractor.method,
                    from: data,
                    webview: webview
                )
            else {
                let envelope = try JSONDecoder().decode(UnsupportedEnvelope.self, from: data)
                return UnsupportedRequest(id: envelope.id, actualMethod: envelope.method)
            }
            
            return request
        } catch DecodingError.keyNotFound(let key, let context){
            OSLogger.shared.info(
                "CheckoutBridge.decode: \(context.debugDescription)\n\n Event Body:\(message.body)"
            )
        } catch {
            OSLogger.shared .info(
                "CheckoutBridge.decode: \(error.localizedDescription)\n\n\t \(message.body)"
            )
        }
        return nil
    }

    static func dispatchMessageTemplate(body: String) -> String {
        return """
        if (window.MobileCheckoutSdk && window.MobileCheckoutSdk.dispatchMessage) {
        	window.MobileCheckoutSdk.dispatchMessage(\(body));
        } else {
        	window.addEventListener('mobileCheckoutBridgeReady', function () {
        		window.MobileCheckoutSdk.dispatchMessage(\(body));
        	}, {passive: true, once: true});
        }
        """
    }
}

// Handle unsupported methods
struct UnsupportedEnvelope: Decodable {
    let id: String
    let method: String
}

struct InstrumentationPayload: Codable {
    var name: String
    var value: Int
    var type: InstrumentationType
    var tags: [String: String] = [:]
}

enum InstrumentationType: String, Codable {
    case histogram
}

extension InstrumentationPayload {
    func toBridgeEvent() -> String? {
        SdkToWebEvent(detail: self).toJson()
    }
}

struct SdkToWebEvent<T: Codable>: Codable {
    var detail: T
}

extension SdkToWebEvent {
    func toJson() -> String? {
        do {
            let jsonData = try JSONEncoder().encode(self)
            return String(data: jsonData, encoding: .utf8)
        } catch {
            print(#function, BridgeError.unencodableInstrumentation(error))
        }

        return nil
    }
}
