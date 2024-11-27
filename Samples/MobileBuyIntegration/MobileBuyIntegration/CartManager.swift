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

import Buy
import Combine
import Foundation
import PassKit
import ShopifyCheckoutSheetKit

struct Contact {
    let address1, address2, city, country, firstName, lastName, province, zip,
        email, phone: String

    enum Errors: Error {
        case missingConfiguration
    }

    init() throws {
        guard
            let infoPlist = Bundle.main.infoDictionary,
            let address1 = infoPlist["Address1"] as? String,
            let address2 = infoPlist["Address2"] as? String,
            let city = infoPlist["City"] as? String,
            let country = infoPlist["Country"] as? String,
            let firstName = infoPlist["FirstName"] as? String,
            let lastName = infoPlist["LastName"] as? String,
            let province = infoPlist["Province"] as? String,
            let zip = infoPlist["Zip"] as? String,
            let email = infoPlist["Email"] as? String,
            let phone = infoPlist["Phone"] as? String
        else {
            throw Contact.Errors.missingConfiguration
        }

        self.address1 = address1
        self.address2 = address2
        self.city = city
        self.country = country
        self.firstName = firstName
        self.lastName = lastName
        self.province = province
        self.zip = zip
        self.email = email
        self.phone = phone
    }
}

enum CartManagerError: LocalizedError {
    case missingConfiguration, missingPostalAddress, invalidPaymentData,
        invalidBillingAddress

    var failureReason: String? {
        switch self {
        case .missingConfiguration:
            return "Missing Storefront config"
        case .missingPostalAddress:
            return "Postal Address is nil"
        case .invalidPaymentData:
            return "Invalid Payment Data"
        case .invalidBillingAddress:
            return "Mapping billing address failed"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .missingConfiguration:
            return "Check MobileBuyIntegration/Resources/Storefront.xcconfig"
        case .missingPostalAddress:
            return "Check `PKContact.postalAddress`"
        case .invalidPaymentData:
            return "Decoding failed - check the PKPayment"
        case .invalidBillingAddress:
            return "Ensure `billingContact.postalAddress` is not nil"
        }
    }
}

class CartManager {
    static let shared = CartManager(client: .shared)
    private static let ContextDirective = Storefront.InContextDirective(
        country: Storefront.CountryCode.inferRegion()
    )

    // MARK: Properties

    @Published
    var cart: Storefront.Cart?
    private let client: StorefrontClient
    private let domain: String
    private let accessToken: String
    // TODO: address/user = Contact? Think of cross platform name
    private let vaultedContactInfo: Contact

    // MARK: Initializers
    init(client: StorefrontClient) {
        guard
            let infoPlist = Bundle.main.infoDictionary,
            let domain = infoPlist["StorefrontDomain"] as? String,
            let accessToken = infoPlist["StorefrontAccessToken"] as? String
        else {
            fatalError(
                CartManagerError.missingConfiguration.localizedDescription
            )
        }

        do {
            self.vaultedContactInfo = try Contact()
        } catch let error {
            fatalError(error.localizedDescription)
        }

        self.client = client
        self.domain = domain
        self.accessToken = accessToken
    }

    // MARK: Cart Actions

    func addItem(
        variant: GraphQL.ID,
        completionHandler: ((Storefront.Cart?) -> Void)?
    ) {
        performCartLinesAdd(item: variant) { result in
            switch result {
            case .success(let cart):
                self.cart = cart
            case .failure(let error):
                print(error)
            }
            completionHandler?(self.cart)
        }
    }

    func updateQuantity(
        variant: GraphQL.ID, quantity: Int32,
        completionHandler: ((Storefront.Cart?) -> Void)?
    ) {
        performCartUpdate(id: variant, quantity: quantity) { result in
            switch result {
            case .success(let cart):
                self.cart = cart
            case .failure(let error):
                print(error)
            }
            completionHandler?(self.cart)
        }
    }

    enum AddressType {
        case postal, billing
    }

    private func mapCNPostalAddress(
        contact: PKContact
    ) throws -> Storefront.MailingAddressInput {
        guard let address = contact.postalAddress else {
            throw CartManagerError.missingPostalAddress
        }

        return Storefront.MailingAddressInput.create(
            address1: Input(orNull: address.street),
            address2: Input(orNull: address.subLocality),
            city: Input(orNull: address.city),
            //            company: Input(orNull: ""),
            country: Input(orNull: address.country),
            firstName: Input(orNull: contact.name?.givenName ?? ""),
            lastName: Input(orNull: contact.name?.familyName ?? ""),
            phone: Input(orNull: contact.phoneNumber?.stringValue ?? ""),
            province: Input(orNull: address.state),
            zip: Input(orNull: address.postalCode)
        )
    }

    func updateDeliveryAddress(
        contact: PKContact,
        partial: Bool,
        completionHandler: ((Storefront.Cart?) -> Void)?
    ) throws {
        do {
            let shippingAddress = try mapCNPostalAddress(contact: contact)

            performCartDeliveryAddressUpdate(shippingAddress: shippingAddress) {
                switch $0 {
                case .success(let cart):
                    self.cart = cart
                case .failure(let error):
                    print("performCartDeliveryAddressUpdate: \(error)")
                }
                completionHandler?(self.cart)
            }
        } catch let error {
            print("Failed to update delivery address with error: \(error)")
        }
    }

    func selectShippingMethodUpdate(
        deliveryOptionHandle: String,
        completionHandler: ((Storefront.Cart) -> Void)?
    ) {
        guard let deliveryGroupId = cart?.deliveryGroups.nodes.first?.id else {
            return print("No delivery group selected")
        }

        performCartShippingMethodUpdate(
            deliveryGroupId: deliveryGroupId,
            deliveryOptionHandle: deliveryOptionHandle
        ) { result in
            switch result {
            case .success:
                #warning("UPDATE self.cart")
            case .failure(let error):
                print(error)
            }

        }
    }

    func resetCart() {
        self.cart = nil
    }

    typealias CartResultHandler = (Result<Storefront.Cart, Error>) -> Void

    private func performCartLinesAdd(
        item: GraphQL.ID,
        handler: @escaping CartResultHandler
    ) {
        guard let cartId = cart?.id else {
            return performCartCreate(items: [item], handler: handler)
        }

        let lines = [Storefront.CartLineInput.create(merchandiseId: item)]

        let mutation = Storefront.buildMutation(
            inContext: CartManager.ContextDirective
        ) {
            $0.cartLinesAdd(lines: lines, cartId: cartId) {
                $0.cart { $0.cartManagerFragment() }
            }
        }

        client.execute(mutation: mutation) { result in
            #warning("accessing cart in this if could throw")

            if case .success(let result) = result,
                let cart = result.cartLinesAdd?.cart
            {
                handler(.success(cart))
            } else {
                handler(.failure(URLError(.unknown)))
            }
        }
    }

    // TODO: Move this to a DI param for CartManager - Cart shouldn't know about vaulted
    private func getCountryCode() -> Storefront.CountryCode {
        if appConfiguration.useVaultedState {
            let code = Storefront.CountryCode(
                rawValue: self.vaultedContactInfo.country
            )
            return code ?? .ca
        }

        return Storefront.CountryCode.inferRegion()
    }

    private func performCartCreate(
        items: [GraphQL.ID] = [],
        handler: @escaping CartResultHandler
    ) {
        let input =
            appConfiguration.useVaultedState
            ? createVaultedCartInput(items)
            : createDefaultCartInput(items)

        let mutation = Storefront.buildMutation(
            inContext: CartManager.ContextDirective
        ) {
            $0.cartCreate(input: input) {
                $0.cart { $0.cartManagerFragment() }
            }
        }

        client.execute(mutation: mutation) { result in
            #warning("accessing cart in this if could throw")

            if case .success(let mutation) = result,
                let cart = mutation.cartCreate?.cart
            {
                handler(.success(cart))
            } else {
                handler(.failure(URLError(.unknown)))
            }
        }
    }

    private func performCartUpdate(
        id: GraphQL.ID,
        quantity: Int32,
        handler: @escaping CartResultHandler
    ) {
        guard let cartId = cart?.id else {
            return performCartCreate(items: [id], handler: handler)
        }

        let lines = [
            Storefront.CartLineUpdateInput.create(
                id: id, quantity: Input(orNull: quantity))
        ]

        let mutation = Storefront.buildMutation(
            inContext: CartManager.ContextDirective
        ) {
            $0.cartLinesUpdate(cartId: cartId, lines: lines) {
                $0.cart { $0.cartManagerFragment() }
            }
        }

        client.execute(mutation: mutation) { result in
            #warning("accessing cart in this if could throw")

            if case .success(let result) = result,
                let cart = result.cartLinesUpdate?.cart
            {
                handler(.success(cart))
            } else {
                handler(.failure(URLError(.unknown)))
            }
        }
    }

    private func performCartDeliveryAddressUpdate(
        shippingAddress: Storefront.MailingAddressInput,
        handler: @escaping CartResultHandler
    ) {
        guard let cartId = cart?.id else {
            return print("no cart")
        }

        let deliveryAddressPreferencesInput = Input(
            orNull: [
                Storefront.DeliveryAddressInput.create(
                    deliveryAddress: Input(orNull: shippingAddress))
            ]
        )

        let buyerIdentityInput = Storefront.CartBuyerIdentityInput.create(
            email: Input(orNull: vaultedContactInfo.email),
            deliveryAddressPreferences: deliveryAddressPreferencesInput
        )

        let mutation = Storefront.buildMutation(
            inContext: CartManager.ContextDirective
        ) {
            $0.cartBuyerIdentityUpdate(
                cartId: cartId,
                buyerIdentity: buyerIdentityInput
            ) {
                $0.cart { $0.cartManagerFragment() }
            }
        }

        client.execute(mutation: mutation) { result in
            #warning("accessing cart in this if could throw")

            if case .success(let mutationResult) = result,
                let cart = mutationResult.cartBuyerIdentityUpdate?.cart
            {
                handler(.success(cart))
            } else {
                handler(.failure(URLError(.unknown)))
            }
        }
    }

    private func executeGraphQL(
        with queryString: String,
        handler: @escaping (Result<Data, Error>) -> Void
    ) {
        guard
            let requestURL = URL(
                string: "https://\(self.domain)/api/unstable/graphql")
        else {
            return print(
                "executeGraphQL: URL construction failed for domain: \(self.domain)."
            )
        }

        var request = URLRequest(url: requestURL)

        request.setValue(
            "multipart/mixed; boundary=graphql", forHTTPHeaderField: "Accept")

        request.setValue(
            "application/graphql",
            forHTTPHeaderField: "Content-Type"
        )
        request.setValue(
            self.accessToken,
            forHTTPHeaderField: "X-Shopify-Storefront-Access-Token"
        )

        request.httpMethod = "POST"
        request.httpBody = queryString.data(using: .utf8)

        let task = URLSession.shared.dataTask(with: request) {
            _data, _, error in
            DispatchQueue.main.async {
                guard
                    let data = _data,
                    error == nil
                else {
                    return handler(.failure(error ?? URLError(.unknown)))
                }
                handler(.success(data))
            }
        }

        task.resume()
    }

    func isValidJSON(_ string: String) -> Bool {
        guard let data = string.data(using: .utf8) else { return false }

        do {
            _ = try JSONSerialization.jsonObject(with: data, options: [])
            return true
        } catch {
            return false
        }
    }

    func performCartPrepareForCompletion(
        handler: @escaping (Result<Bool, Error>) -> Void
    ) {
        guard let cartId = cart?.id else {
            return print("performCartPrepareForCompletion: Cart isn't created")
        }

        let mutationString = createCartPrepareForCompletionMutation(
            cartId: cartId
        )

        executeGraphQL(with: mutationString) {
            if case .success(let data) = $0 {
                let responseString = String(data: data, encoding: .utf8)
                print(
                    "performCartPrepareForCompletion \(String(describing: responseString))"
                )
                handler(.success(true))
            } else {
                handler(.failure(URLError(.unknown)))
            }
        }
    }

    private func performCartShippingMethodUpdate(
        deliveryGroupId: GraphQL.ID,
        deliveryOptionHandle: String,
        handler: @escaping (Result<Storefront.Cart, Error>) -> Void
    ) {
        guard let cartId = cart?.id else {
            return print("performCartShippingMethodUpdate: Cart isn't created")
        }

        let cartSelectedDeliveryOptionInput =
            Storefront.CartSelectedDeliveryOptionInput(
                deliveryGroupId: deliveryGroupId,
                deliveryOptionHandle: deliveryOptionHandle
            )

        let mutation = Storefront.buildMutation(
            inContext: CartManager.ContextDirective
        ) {
            $0.cartSelectedDeliveryOptionsUpdate(
                cartId: cartId,
                selectedDeliveryOptions: [cartSelectedDeliveryOptionInput]
            ) {
                $0.cart { $0.cartManagerFragment() }
            }
        }

        client.execute(mutation: mutation) { result in
            #warning("accessing cart in this if could throw")
            if case .success(let mutationResult) = result,
                let cart = mutationResult.cartSelectedDeliveryOptionsUpdate?
                    .cart
            {
                handler(.success(cart))
            } else {
                handler(.failure(URLError(.unknown)))
            }
        }
    }

    func updateCartPaymentMethod(
        payment: PKPayment,
        completion: @escaping (Result<Storefront.Cart, Error>) -> Void
    ) throws {
        guard
            let cartId = cart?.id,
            let billingContact = payment.billingContact,
            let totalAmount = cart?.cost.totalAmount
        else {
            fatalError("updateCartPaymentMethod: Pre-requisites not met")
        }

        let paymentToken = try? JSONDecoder().decode(
            PaymentToken.self,
            from: payment.token.paymentData
        )

        guard let paymentToken else {
            print(
                "Decoding failed: .paymentData = \(payment.token.paymentData)"
            )
            throw CartManagerError.invalidPaymentData
        }

        //            let decodedData = Data(base64Encoded: payment.token.paymentData)!
        //            let decodedString = String(data: decodedData, encoding: .utf8)
        //            let paymentToken = try JSONDecoder().decode(
        //                PaymentToken.self,
        //                from: (decodedString?.data(using: .utf8)!)!
        //            )

        let header = Storefront.ApplePayWalletHeaderInput.create(
            ephemeralPublicKey: paymentToken.paymentData.header
                .ephemeralPublicKey,
            publicKeyHash: paymentToken.paymentData.header.publicKeyHash,
            transactionId: paymentToken.paymentData.header.transactionID,
            applicationData: Input(
                orNull: paymentToken.paymentData.header.applicationData
            )
        )

        let billingAddress = try? mapCNPostalAddress(contact: billingContact)
        guard let billingAddress else {
            print(
                "Invalid Billing Address: .billingAddress = \(String(describing: billingContact.postalAddress))"
            )
            throw CartManagerError.invalidBillingAddress
        }

        let applePayWalletContent = Storefront.ApplePayWalletContentInput
            .create(
                billingAddress: billingAddress,
                data: paymentToken.paymentData.data,
                header: header,
                signature: paymentToken.paymentData.signature,
                version: paymentToken.paymentData.version,
                lastDigits: Input(
                    orNull: paymentToken
                        .paymentMethod
                        .displayName
                        .components(separatedBy: " ")
                        .last
                )
            )

        let walletPaymentMethod = Storefront.CartWalletPaymentMethodInput
            .create(
                applePayWalletContent: Input(orNull: applePayWalletContent)
            )

        let payment: Storefront.CartPaymentInput = Storefront
            .CartPaymentInput
            .create(
                amount: Storefront.MoneyInput.create(
                    amount: totalAmount.amount,
                    currencyCode: totalAmount.currencyCode
                ),
                walletPaymentMethod: Input(orNull: walletPaymentMethod)
            )

        let mutation = Storefront.buildMutation(
            inContext: CartManager.ContextDirective
        ) {
            $0.cartPaymentUpdate(cartId: cartId, payment: payment) {
                $0.cart {
                    $0.cartManagerFragment()
                }
            }
        }

        client.execute(mutation: mutation) {
            guard
                case .success(let result) = $0,
                let _cart = result.cartPaymentUpdate?.cart
            else {
                return completion(.failure(URLError(.unknown)))
            }

            completion(.success(_cart))
        }
    }

    private func createDefaultCartInput(_ items: [GraphQL.ID])
        -> Storefront.CartInput
    {
        return Storefront.CartInput.create(
            lines: Input(
                orNull: items.map {
                    Storefront.CartLineInput.create(merchandiseId: $0)
                }
            )
        )
    }

    private func createVaultedCartInput(_ items: [GraphQL.ID] = [])
        -> Storefront.CartInput
    {
        let deliveryAddress = Storefront.MailingAddressInput.create(
            address1: Input(orNull: vaultedContactInfo.address1),
            address2: Input(orNull: vaultedContactInfo.address2),
            city: Input(orNull: vaultedContactInfo.city),
            company: Input(orNull: ""),
            country: Input(orNull: vaultedContactInfo.country),
            firstName: Input(orNull: vaultedContactInfo.firstName),
            lastName: Input(orNull: vaultedContactInfo.lastName),
            phone: Input(orNull: vaultedContactInfo.phone),
            province: Input(orNull: vaultedContactInfo.province),
            zip: Input(orNull: vaultedContactInfo.zip)
        )

        let deliveryAddressPreferences = [
            Storefront.DeliveryAddressInput.create(
                deliveryAddress: Input(orNull: deliveryAddress))
        ]

        return Storefront.CartInput.create(
            lines: Input(
                orNull: items.map {
                    Storefront.CartLineInput.create(merchandiseId: $0)
                }),
            buyerIdentity: Input(
                orNull: Storefront.CartBuyerIdentityInput.create(
                    email: Input(orNull: vaultedContactInfo.email),
                    deliveryAddressPreferences: Input(
                        orNull: deliveryAddressPreferences)
                ))
        )
    }
}

extension Storefront.CartQuery {
    @discardableResult
    func cartManagerFragment() -> Storefront.CartQuery {
        self.id()
            .checkoutUrl()
            .totalQuantity()
            .deliveryGroups(first: 10) {
                $0.nodes {
                    $0.id()
                        .deliveryOptions {
                            $0.handle()
                                .title()
                                .code()
                                .deliveryMethodType()
                                .description()
                                .estimatedCost {
                                    $0.amount()
                                        .currencyCode()
                                }
                        }
                }
            }
            .lines(first: 250) {
                $0.nodes {
                    $0.id()
                        .quantity()
                        .merchandise {
                            $0.onProductVariant {
                                $0.id()
                                    .title()
                                    .price {
                                        $0.amount()
                                            .currencyCode()
                                    }
                                    .product {
                                        $0.title()
                                            .vendor()
                                            .featuredImage {
                                                $0.url()
                                            }
                                    }
                            }
                        }
                        .cost {
                            $0.totalAmount {
                                $0.amount()
                                    .currencyCode()
                            }
                        }
                }
            }
            .totalQuantity()
            .cost {
                $0.totalAmount {
                    $0.amount()
                        .currencyCode()
                }
                .subtotalAmount {
                    $0.amount()
                        .currencyCode()
                }
                .totalTaxAmount {
                    $0.amount()
                        .currencyCode()
                }
            }
    }
}

func createCartPrepareForCompletionMutation(cartId: GraphQL.ID) -> String {
    return """
          mutation @inContext(country: \(Storefront.CountryCode.inferRegion().rawValue.uppercased())) {
            cartPrepareForCompletion(cartId: "\(cartId.rawValue)") {
                result {
                  __typename
                  ... on CartStatusReady {
                    cart {
                      ...CartFragment
                    }
                  }
                  ... on CartStatusNotReady {
                    cart {
                      ...CartFragment
                    }
                    errors {
                      code
                      message
                    }
                  }
                  ... on CartThrottled {
                    pollAfter
                  }
                }
                
                userErrors {
                  field
                  code
                  message
                }
          }
        }

        fragment CartFragment on Cart {
            deliveryGroups(first: 10) {
                edges {
                  node {
                    deliveryOptions {
                      title
                      handle
                      code
                      deliveryMethodType
                      description
                      estimatedCost {
                        amount
                      }
                    }
                    selectedDeliveryOption {
                      title
                      handle
                      estimatedCost {
                        amount
                        currencyCode
                      }
                    }
                  }
                }
            }
            cost {
              totalAmount {
                amount
                currencyCode
              }
              subtotalAmount {
                amount
                currencyCode
              }
              totalTaxAmount {
                amount
                currencyCode
              }
            }
          }
        """
}

// MARK: - PaymentToken Decoders
struct PaymentToken: Codable {
    let paymentData: PaymentData
    let paymentMethod: PaymentMethod
    let transactionIdentifier: String
}

struct PaymentData: Codable {
    let data: String
    let header: Header
    let signature, version: String
}

struct Header: Codable {
    let ephemeralPublicKey, publicKeyHash, transactionID,
        applicationData: String

    enum CodingKeys: String, CodingKey {
        case ephemeralPublicKey, publicKeyHash, applicationData
        case transactionID = "transactionId"
    }
}

struct PaymentMethod: Codable {
    let displayName, network, type: String
}
