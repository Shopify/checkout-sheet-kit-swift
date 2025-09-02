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

@preconcurrency import Buy
import Combine
import Foundation
import PassKit
import ShopifyCheckoutSheetKit

@MainActor
class CartManager: ObservableObject {
    static let shared = CartManager(client: .shared)
    private static let ContextDirective = Storefront.InContextDirective(
        country: Storefront.CountryCode.inferRegion()
    )

    // MARK: Properties

    private let client: StorefrontClient
    public var redirectUrl: URL?

    @Published var cart: Storefront.Cart?
    @Published var isDirty: Bool = false

    // MARK: Initializers

    init(client: StorefrontClient) {
        self.client = client
    }

    public func preloadCheckout() {
        /// Only preload checkout if cart is dirty, meaning it has changes since checkout was last preloaded
        if let url = cart?.checkoutUrl, isDirty {
            ShopifyCheckoutSheetKit.preload(checkout: url)
            markCartAsReady()
        }
    }

    /// The cart is "ready" when ShopifyCheckoutSheetKit.preload(checkoutUrl) has been called
    /// The dirty state will be set to false to prevent  preloading again
    func markCartAsReady() {
        isDirty = false
    }

    // MARK: Cart Actions

    /**
     * Creates cart if no cart.id present, or adds line items to pre-existing cart
     * Non-idempotent - subsequent calls for existing cartLine items will increase quantity by 1
     */
    func performCartLinesAdd(variant: GraphQL.ID) async throws -> Storefront.Cart {
        guard let cartId = cart?.id else {
            return try await performCartCreate(items: [variant])
        }

        let lines = [Storefront.CartLineInput.create(merchandiseId: variant)]

        let mutation = Storefront.buildMutation(
            inContext: CartManager.ContextDirective
        ) {
            $0.cartLinesAdd(cartId: cartId, lines: lines) {
                $0.cart { $0.cartManagerFragment() }
                    .userErrors { $0.code().message() }
            }
        }

        do {
            guard let payload = try await client.executeAsync(mutation: mutation).cartLinesAdd
            else { throw CartManager.Errors.payloadUnwrap }

            guard payload.userErrors.isEmpty else {
                throw CartManager.Errors.invariant(
                    message: CartManager.userErrorMessage(errors: payload.userErrors)
                )
            }

            guard let cart = payload.cart else {
                throw Errors.invariant(message: "cart returned nil")
            }

            self.cart = cart
            isDirty = true

            return cart
        } catch {
            throw Errors.apiErrors(requestName: "cartLinesAdd", message: "\(error)")
        }
    }

    func performCartLinesUpdate(id: GraphQL.ID, quantity: Int32) async throws -> Storefront.Cart {
        guard let cartId = cart?.id else {
            return try await performCartCreate(items: [id])
        }

        let lines = [
            Storefront.CartLineUpdateInput.create(id: id, quantity: Input(orNull: quantity))
        ]

        let mutation = Storefront.buildMutation(
            inContext: CartManager.ContextDirective
        ) {
            $0.cartLinesUpdate(cartId: cartId, lines: lines) {
                $0.cart { $0.cartManagerFragment() }
                    .userErrors { $0.code().message() }
            }
        }

        do {
            guard
                let payload = try await client.executeAsync(mutation: mutation).cartLinesUpdate
            else { throw CartManager.Errors.payloadUnwrap }

            guard payload.userErrors.isEmpty else {
                throw CartManager.Errors.invariant(
                    message: CartManager.userErrorMessage(errors: payload.userErrors)
                )
            }

            guard let cart = payload.cart else {
                throw Errors.invariant(message: "cart returned nil")
            }

            self.cart = cart
            isDirty = true

            return cart
        } catch {
            throw Errors.apiErrors(requestName: "cartLinesUpdate", message: "\(error)")
        }
    }

    func performBuyerIdentityUpdate(
        contact: PKContact,
        partial _: Bool
    ) async throws -> Storefront.Cart {
        guard let cartId = cart?.id else {
            throw Errors.invariant(message: "cart.id should be defined")
        }

        guard let address = contact.postalAddress else {
            throw Errors.invariant(message: "contact.postalAddress is nil")
        }

        let shippingAddress = StorefrontInputFactory.shared.createMailingAddressInput(
            contact: contact,
            address: address
        )

        let deliveryAddressPreferencesInput = Input(
            orNull: [
                Storefront.DeliveryAddressInput.create(
                    deliveryAddress: Input(orNull: shippingAddress))
            ]
        )

        let buyerIdentityInput = StorefrontInputFactory.shared.createCartBuyerIdentityInput(
            // During ApplePay `contact.emailAddress` is nil until `didAuthorizePayment`
            email: contact.emailAddress,
            deliveryAddressPreferencesInput: deliveryAddressPreferencesInput
        )

        let mutation = Storefront.buildMutation(
            inContext: CartManager.ContextDirective
        ) {
            $0.cartBuyerIdentityUpdate(
                cartId: cartId,
                buyerIdentity: buyerIdentityInput
            ) {
                $0.cart { $0.cartManagerFragment() }.userErrors { $0.code().message() }
            }
        }

        do {
            guard
                let payload = try await client.executeAsync(mutation: mutation)
                .cartBuyerIdentityUpdate
            else { throw CartManager.Errors.payloadUnwrap }

            guard payload.userErrors.isEmpty else {
                throw CartManager.Errors.invariant(
                    message: CartManager.userErrorMessage(errors: payload.userErrors)
                )
            }

            guard let cart = payload.cart else {
                throw Errors.invariant(message: "returned cart is nil")
            }

            self.cart = cart
            isDirty = true

            return cart
        } catch {
            throw Errors.apiErrors(requestName: "cartBuyerIdentityUpdate", message: "\(error)")
        }
    }

    private func performCartCreate(items: [GraphQL.ID] = []) async throws -> Storefront.Cart {
        let input = StorefrontInputFactory.shared.createCartInput(items)

        let mutation = Storefront.buildMutation(inContext: CartManager.ContextDirective) {
            $0.cartCreate(input: input) {
                $0.cart { $0.cartManagerFragment() }
                    .userErrors { $0.code().message() }
            }
        }

        do {
            guard let payload = try await client.executeAsync(mutation: mutation).cartCreate
            else { throw CartManager.Errors.payloadUnwrap }

            guard payload.userErrors.isEmpty else {
                throw CartManager.Errors.invariant(
                    message: CartManager.userErrorMessage(errors: payload.userErrors)
                )
            }

            guard let cart = payload.cart else {
                throw Errors.invariant(message: "cart returned nil")
            }

            self.cart = cart
            isDirty = true

            return cart
        } catch {
            throw Errors.apiErrors(requestName: "cartCreate", message: "\(error)")
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

    static func userErrorMessage(errors: [Storefront.CartUserError]) -> String {
        return "userErrors should be [], received: \(String(describing: errors))"
    }
}
