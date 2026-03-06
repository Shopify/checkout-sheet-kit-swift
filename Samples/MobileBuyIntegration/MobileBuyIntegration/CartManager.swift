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

@preconcurrency import Apollo
@preconcurrency import ApolloAPI
import Combine
import Foundation
import PassKit
import ShopifyCheckoutSheetKit

protocol UserErrorDisplayable {
    var message: String { get }
}

extension Storefront.CartUserErrorFragment: UserErrorDisplayable {}
extension Storefront.CartCreateMutation.Data.CartCreate.UserError: UserErrorDisplayable {}
extension Storefront.CartLinesAddMutation.Data.CartLinesAdd.UserError: UserErrorDisplayable {}
extension Storefront.CartLinesUpdateMutation.Data.CartLinesUpdate.UserError: UserErrorDisplayable {}

@MainActor
class CartManager: ObservableObject {
    static let shared = CartManager()

    // MARK: Properties

    public var redirectUrl: URL?

    @Published var cart: Storefront.CartFragment?
    @Published var isDirty: Bool = false

    // MARK: Initializers

    init() {}

    public func preloadCheckout() {
        if let url = cart?.checkoutURL, isDirty {
            ShopifyCheckoutSheetKit.preload(checkout: url)
            markCartAsReady()
        }
    }

    func markCartAsReady() {
        isDirty = false
    }

    // MARK: Cart Actions

    func performCartLinesAdd(variant: String) async throws -> Storefront.CartFragment {
        guard let cartId = cart?.id else {
            return try await performCartCreate(items: [variant])
        }

        let lines = [Storefront.CartLineInput(merchandiseId: variant)]
        let network = Network.shared

        let mutation = Storefront.CartLinesAddMutation(
            cartId: cartId,
            lines: lines,
            country: network.countryCode,
            language: network.languageCode
        )

        do {
            let data = try await performMutation(mutation)

            guard let payload = data.cartLinesAdd else {
                throw CartManager.Errors.payloadUnwrap
            }

            guard payload.userErrors.isEmpty else {
                throw CartManager.Errors.invariant(
                    message: CartManager.userErrorMessage(errors: payload.userErrors)
                )
            }

            guard let cartData = payload.cart?.fragments.cartFragment else {
                throw Errors.invariant(message: "cart returned nil")
            }

            cart = cartData
            isDirty = true

            return cartData
        } catch let error as Errors {
            throw error
        } catch {
            throw Errors.apiErrors(requestName: "cartLinesAdd", message: "\(error)")
        }
    }

    func performCartLinesUpdate(id: String, quantity: Int) async throws -> Storefront.CartFragment {
        guard let cartId = cart?.id else {
            return try await performCartCreate(items: [id])
        }

        let lines = [
            Storefront.CartLineUpdateInput(id: id, quantity: .some(quantity))
        ]

        let network = Network.shared

        let mutation = Storefront.CartLinesUpdateMutation(
            cartId: cartId,
            lines: lines,
            country: network.countryCode,
            language: network.languageCode
        )

        do {
            let data = try await performMutation(mutation)

            guard let payload = data.cartLinesUpdate else {
                throw CartManager.Errors.payloadUnwrap
            }

            guard payload.userErrors.isEmpty else {
                throw CartManager.Errors.invariant(
                    message: CartManager.userErrorMessage(errors: payload.userErrors)
                )
            }

            guard let cartData = payload.cart?.fragments.cartFragment else {
                throw Errors.invariant(message: "cart returned nil")
            }

            cart = cartData
            isDirty = true

            return cartData
        } catch let error as Errors {
            throw error
        } catch {
            throw Errors.apiErrors(requestName: "cartLinesUpdate", message: "\(error)")
        }
    }

    private func performCartCreate(items: [String] = []) async throws -> Storefront.CartFragment {
        var customerAccessToken: String?
        if CustomerAccountManager.shared.isAuthenticated {
            customerAccessToken = try? await CustomerAccountManager.shared.getValidAccessToken()
        }
        let input = StorefrontInputFactory.shared.createCartInput(items, customerAccessToken: customerAccessToken)
        let network = Network.shared

        let mutation = Storefront.CartCreateMutation(
            input: input,
            country: network.countryCode,
            language: network.languageCode
        )

        do {
            let data = try await performMutation(mutation)

            guard let payload = data.cartCreate else {
                throw CartManager.Errors.payloadUnwrap
            }

            guard payload.userErrors.isEmpty else {
                throw CartManager.Errors.invariant(
                    message: CartManager.userErrorMessage(errors: payload.userErrors)
                )
            }

            guard let cartData = payload.cart?.fragments.cartFragment else {
                throw Errors.invariant(message: "cart returned nil")
            }

            cart = cartData
            isDirty = true

            return cartData
        } catch let error as Errors {
            throw error
        } catch {
            throw Errors.apiErrors(requestName: "cartCreate", message: "\(error)")
        }
    }

    private func performMutation<T: GraphQLMutation>(_ mutation: T) async throws -> T.Data {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<T.Data, Error>) in
            Network.shared.apollo.perform(mutation: mutation) { result in
                switch result {
                case let .success(response):
                    if let data = response.data {
                        continuation.resume(returning: data)
                    } else if let errors = response.errors {
                        continuation.resume(
                            throwing: Errors.apiErrors(
                                requestName: String(describing: T.self),
                                message: errors.map { $0.message ?? "" }.joined(separator: ", ")
                            )
                        )
                    } else {
                        continuation.resume(throwing: Errors.payloadUnwrap)
                    }
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func resetCart() {
        cart = nil
        isDirty = false
    }
}

extension CartManager {
    enum Errors: LocalizedError {
        case missingPostalAddress, invalidPaymentData,
             invalidBillingAddress, payloadUnwrap
        case apiErrors(requestName: String, message: String)
        case invariant(message: String)

        var failureReason: String? {
            switch self {
            case .missingPostalAddress:
                return "Postal Address is nil"
            case .invalidPaymentData:
                return "Invalid Payment Data"
            case .invalidBillingAddress:
                return "Mapping billing address failed"
            case .payloadUnwrap:
                return "Request Payload failed to unwrap"
            case let .apiErrors(requestName, message):
                return "Request: \(requestName) Failed. Message: \(message)"
            case let .invariant(message):
                return "invariant failed: \(message)"
            }
        }

        var recoverySuggestion: String? {
            switch self {
            case .missingPostalAddress:
                return "Check `PKContact.postalAddress`"
            case .invalidPaymentData:
                return "Decoding failed - check the PKPayment"
            case .invalidBillingAddress:
                return "Ensure `billingContact.postalAddress` is not nil"
            case .payloadUnwrap:
                return "Check the previous request was executed"
            case let .apiErrors(requestName, _):
                return "Check the API payload for more details: \(requestName)"
            case .invariant:
                return "Resolve preconditions before continuing"
            }
        }
    }

    static func userErrorMessage(errors: [some UserErrorDisplayable]) -> String {
        return "userErrors should be [], received: \(errors.map { $0.message }.joined(separator: ", "))"
    }
}
