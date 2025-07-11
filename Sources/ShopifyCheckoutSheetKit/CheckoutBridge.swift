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

protocol CheckoutBridge {
	func sendMessage(message: String, completionHandler: ((Result<String, Error>) -> Void)?)
	func sendMessage(message: String, payload: [String: Any], completionHandler: ((Result<String, Error>) -> Void)?)
	func sendMessage(message: String, payload: Any, completionHandler: ((Result<String, Error>) -> Void)?)
	func decodeEvent(from body: String) -> [String: Any]?
	var userAgent: String { get }
	func setUserAgent(in webView: WKWebView)
	func dispatchMessage() -> String
	func normalizedColorScheme() -> String
	func messageHandlerName() -> String
	func readyEventName() -> String
	func javascriptInterfaceName() -> String
	func protocolVersion() -> String
	func libraryVersion() -> String
	func embedParams() -> [String: String]
}

internal class DefaultCheckoutBridge: CheckoutBridge {
	private let configuration: Configuration
	private let isRecovery: Bool

	internal init(configuration: Configuration, logger: Logger = NoOpLogger(), isRecovery: Bool = false) {
		self.configuration = configuration
		self.isRecovery = isRecovery
	}

	private func canSerializeToJSON(_ object: Any) -> Bool {
		return JSONSerialization.isValidJSONObject(object)
	}

	private func sendMessageWithPayload(_ message: String, payload: Any, completionHandler: ((Result<String, Error>) -> Void)?) {
		guard let webView = configuration.webView else {
			completionHandler?(.failure(CheckoutError.webViewNotAvailable))
			return
		}

		// Check if payload can be serialized to JSON
		if !canSerializeToJSON(payload) {
			// If serialization fails, fall back to empty object and call completion with error
			let javascriptCall = "\(dispatchMessage())(\"\(message)\", {})"
			webView.evaluateJavaScript(javascriptCall) { _, _ in
				completionHandler?(.failure(NSError(domain: "JSONSerialization", code: 3840, userInfo: [NSLocalizedDescriptionKey: "Circular reference detected"])))
			}
			return
		}

		do {
			let payloadData = try JSONSerialization.data(withJSONObject: payload, options: [])
			let payloadString = String(data: payloadData, encoding: .utf8) ?? "{}"
			let javascriptCall = "\(dispatchMessage())(\"\(message)\", \(payloadString))"
			webView.evaluateJavaScript(javascriptCall) { result, error in
				if let error = error {
					completionHandler?(.failure(error))
				} else if let result = result as? String {
					completionHandler?(.success(result))
				} else {
					completionHandler?(.success(""))
				}
			}
		} catch {
			// If JSON serialization fails, fall back to empty object and call completion with error
			let javascriptCall = "\(dispatchMessage())(\"\(message)\", {})"
			webView.evaluateJavaScript(javascriptCall) { _, _ in
				completionHandler?(.failure(error))
			}
		}
	}

	internal func sendMessage(message: String, completionHandler: ((Result<String, Error>) -> Void)? = nil) {
		guard let webView = configuration.webView else {
			completionHandler?(.failure(CheckoutError.webViewNotAvailable))
			return
		}

		let javascriptCall = "\(dispatchMessage())(\"\(message)\")"
		webView.evaluateJavaScript(javascriptCall) { result, error in
			if let error = error {
				completionHandler?(.failure(error))
			} else if let result = result as? String {
				completionHandler?(.success(result))
			} else {
				completionHandler?(.success(""))
			}
		}
	}

	internal func sendMessage(message: String, payload: [String: Any], completionHandler: ((Result<String, Error>) -> Void)? = nil) {
		sendMessageWithPayload(message, payload: payload, completionHandler: completionHandler)
	}

	internal func sendMessage(message: String, payload: Any, completionHandler: ((Result<String, Error>) -> Void)? = nil) {
		sendMessageWithPayload(message, payload: payload, completionHandler: completionHandler)
	}

	internal func decodeEvent(from body: String) -> [String: Any]? {
		guard let data = body.data(using: .utf8) else { return nil }
		return try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
	}

	internal var userAgent: String {
		if isRecovery {
			return "MobileCheckoutSDK/\(libraryVersion()) (iOS) CheckoutSheetProtocol/\(protocolVersion()) \(normalizedColorScheme())"
		} else {
			return "CheckoutKit/\(libraryVersion()) (iOS) CheckoutSheetProtocol/\(protocolVersion()) \(normalizedColorScheme())"
		}
	}

	internal func setUserAgent(in webView: WKWebView) {
		webView.customUserAgent = userAgent
	}

	internal func dispatchMessage() -> String {
		return "window.Shopify.CheckoutSheetProtocol.postMessage"
	}

	internal func normalizedColorScheme() -> String {
		switch configuration.colorScheme {
		case .automatic:
			return "auto"
		case .light:
			return "light"
		case .dark:
			return "dark"
		}
	}

	internal func messageHandlerName() -> String {
		return "checkoutSheetProtocol"
	}

	internal func readyEventName() -> String {
		return "checkoutSheetProtocolReady"
	}

	internal func javascriptInterfaceName() -> String {
		return "window.Shopify.CheckoutSheetProtocol"
	}

	internal func protocolVersion() -> String {
		return "2025-04"
	}

	internal func libraryVersion() -> String {
		return "4.0.0"
	}

	internal func embedParams() -> [String: String] {
		return [
			"embed": "mobile_checkout_sdk",
			"version": libraryVersion(),
			"protocol": protocolVersion(),
			"theme": normalizedColorScheme()
		]
	}
}
