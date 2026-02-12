import Foundation

public protocol CheckoutCommunicationProtocol: Sendable {
    func handleMessage(_ message: String) async -> String?
}
