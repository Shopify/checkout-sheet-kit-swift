import Foundation

public protocol CheckoutCommunicationProtocol: Sendable {
    func process(_ message: String) async -> String?
}
