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

    static func sendProtocolMessage(_ webView: WKWebView, _ message: String) {
        webView.evaluateJavaScript("window.postMessage(\(message), '*')")
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
