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
    static let messageHandler = "mobileCheckoutSdk"

    static var applicationName: String {
        return applicationName(entryPoint: nil)
    }

    static func applicationName(entryPoint: MetaData.EntryPoint?) -> String {
        let colorScheme = ShopifyCheckoutSheetKit.configuration.colorScheme
        let platform = mapPlatform(ShopifyCheckoutSheetKit.configuration.platform)

        return UserAgent.string(
            type: .standard,
            colorScheme: colorScheme,
            platform: platform,
            entryPoint: entryPoint
        )
    }

    static var recoveryAgent: String {
        return recoveryAgent(entryPoint: nil)
    }

    static func recoveryAgent(entryPoint: MetaData.EntryPoint?) -> String {
        let colorScheme = ShopifyCheckoutSheetKit.configuration.colorScheme
        let platform = mapPlatform(ShopifyCheckoutSheetKit.configuration.platform)

        return UserAgent.string(
            type: .recovery,
            colorScheme: colorScheme,
            platform: platform,
            entryPoint: entryPoint
        )
    }

    private static func mapPlatform(_ platform: Platform?) -> MetaData.Platform? {
        guard let platform else { return nil }
        switch platform {
        case .reactNative:
            return .reactNative
        }
    }

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

    static func decode(_ message: WKScriptMessage) throws -> WebEvent {
        guard let body = message.body as? String, let data = body.data(using: .utf8) else {
            throw BridgeError.invalidBridgeEvent()
        }

        do {
            return try JSONDecoder().decode(WebEvent.self, from: data)
        } catch {
            throw BridgeError.invalidBridgeEvent(error)
        }
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

extension CheckoutBridge {
    enum WebEvent: Decodable {
        /// Error types
        case checkoutExpired(message: String?, code: CheckoutErrorCode)
        case checkoutUnavailable(message: String?, code: CheckoutErrorCode)
        case configurationError(message: String?, code: CheckoutErrorCode)

        /// Success
        case checkoutComplete(event: CheckoutCompletedEvent)

        /// Presentational
        case checkoutModalToggled(modalVisible: Bool)

        /// Eventing
        case webPixels(event: PixelEvent?)

        /// Address Change Intent
        case addressChangeIntent(event: AddressChangeRequest)

        /// Generic
        case unsupported(String)

        enum CodingKeys: String, CodingKey {
            case name
            case body
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            let name = try container.decode(String.self, forKey: .name)

            switch name {
            case "completed":
                let checkoutCompletedEvent = CheckoutCompletedEventDecoder().decode(from: container, using: decoder)
                self = .checkoutComplete(event: checkoutCompletedEvent)
            case "error":
                let errorDecoder = CheckoutErrorEventDecoder()
                let error = errorDecoder.decode(from: container, using: decoder)
                let code = CheckoutErrorCode.from(error.code)

                switch error.group {
                case .configuration:
                    self = .configurationError(message: error.reason, code: code)
                case .unrecoverable:
                    self = .checkoutUnavailable(message: error.reason, code: code)
                case .expired:
                    self = .checkoutExpired(message: error.reason, code: CheckoutErrorCode.from(error.code))
                default:
                    self = .unsupported(name)
                }
            case "checkoutBlockingEvent":
                let modalVisible = try container.decode(String.self, forKey: .body)
                self = .checkoutModalToggled(modalVisible: Bool(modalVisible)!)
            case "webPixels":
                let webPixelsDecoder = WebPixelsEventDecoder()
                let event = try webPixelsDecoder.decode(from: container, using: decoder)
                self = .webPixels(event: event)
            case "addressChangeIntent":
                let addressChangeIntentDecoder = CheckoutAddressChangeIntentDecoder()
                let event = try addressChangeIntentDecoder.decode(from: container, using: decoder)
                self = .addressChangeIntent(event: event)
            default:
                self = .unsupported(name)
            }
        }
    }
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
