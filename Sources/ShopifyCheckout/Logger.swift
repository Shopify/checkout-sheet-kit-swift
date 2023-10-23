public protocol Logger {
	func log(_ message: String, info: [String: String?])
}

internal func log(_ message: String, _ info: [String: String?] = [:]) {
	configuration.debug.logger?.log("[ShopifyCheckout] \(message)", info: info)
}
