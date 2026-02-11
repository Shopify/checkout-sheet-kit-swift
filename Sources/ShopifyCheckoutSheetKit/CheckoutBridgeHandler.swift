import Foundation

public protocol CheckoutBridgeHandler: Sendable {
    var readyMessage: String? { get }
    func handleMessage(_ message: String) async -> String?
}
