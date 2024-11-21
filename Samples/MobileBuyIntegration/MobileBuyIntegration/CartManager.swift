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

class CartManager {

    static let shared = CartManager(client: .shared)

    // MARK: Properties

    @Published
    var cart: Storefront.Cart?

    private let client: StorefrontClient
    private let address1: String
    private let address2: String
    private let city: String
    private let country: String
    private let firstName: String
    private let lastName: String
    private let province: String
    private let zip: String
    private let email: String
    private let phone: String
    private let domain: String
    private let accessToken: String

    // MARK: Initializers
    init(client: StorefrontClient) {
        self.client = client
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
            let phone = infoPlist["Phone"] as? String,
            let domain = infoPlist["StorefrontDomain"] as? String,
            let accessToken = infoPlist["StorefrontAccessToken"] as? String
        else {
            fatalError("unable to load storefront configuration")
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
        self.domain = domain
        self.accessToken = accessToken
    }

    // MARK: Cart Actions

    func addItem(variant: GraphQL.ID, completionHandler: (() -> Void)?) {
        performCartLinesAdd(item: variant) { result in
            switch result {
            case .success(let cart):
                self.cart = cart
            case .failure(let error):
                print(error)
            }
            completionHandler?()
        }
    }

    func updateQuantity(
        variant: GraphQL.ID, quantity: Int32,
        completionHandler: ((Storefront.Cart?) -> Void)?
    ) {
        performCartUpdate(
            id: variant, quantity: quantity,
            handler: { result in
                switch result {
                case .success(let cart):
                    self.cart = cart
                case .failure(let error):
                    print(error)
                }
                completionHandler?(self.cart)
            })
    }

    func updateDeliveryAddress(
        contact: PKContact, partial: Bool,
        completionHandler: ((Storefront.Cart?) -> Void)?
    ) {
        let postalAddress = contact.postalAddress

        // TODO: We should guard better the optionality
        let shippingAddress =
            partial
            ? Storefront.MailingAddressInput.create(
                city: Input(orNull: postalAddress?.city ?? ""),
                country: Input(orNull: postalAddress?.country ?? ""),
                province: Input(orNull: postalAddress?.state ?? ""),
                zip: Input(orNull: postalAddress?.postalCode ?? "")
            )
            : Storefront.MailingAddressInput.create(
                address1: Input(orNull: postalAddress?.street ?? ""),
                address2: Input(orNull: postalAddress?.subLocality ?? ""),
                city: Input(orNull: postalAddress?.city ?? ""),
                company: Input(orNull: ""),
                country: Input(orNull: postalAddress?.country ?? ""),
                firstName: Input(orNull: contact.name?.givenName ?? ""),
                lastName: Input(orNull: contact.name?.familyName ?? ""),
                phone: Input(orNull: contact.phoneNumber?.stringValue ?? ""),
                province: Input(orNull: postalAddress?.state ?? ""),
                zip: Input(orNull: postalAddress?.postalCode ?? "")
            )

        performCartDeliveryAddressUpdate(
            shippingAddress: shippingAddress,
            handler: { result in
                switch result {
                case .success(let cart):
                    self.cart = cart
                case .failure(let error):
                    print("performCartDeliveryAddressUpdate: \(error)")
                }
                completionHandler?(self.cart)
            })
    }

    func selectShippingMethodUpdate(
        deliveryOptionHandle: String,
        completionHandler: ((Storefront.Cart?) -> Void)?
    ) {
        guard let deliveryGroupId = cart?.deliveryGroups.nodes.first?.id else {
            print("No delivery group selected")
            return
        }
        performCartShippingMethodUpdate(
            deliveryGroupId: deliveryGroupId,
            deliveryOptionHandle: deliveryOptionHandle
        ) { result in
            switch result {
            case .success(let specialCart):
                print("Waitings for cart to reload")
                /**
                  TODO: Here we're trying to make a manual request to fetch cart and then set that back with deferred data
                  alternatively we can refetch the cart afterwards (redundant request, but itll be typed correctly)
                 */
                //                self.cart = specialCart
                self.waitAndReloadCart()
                print("Cart reloaded")
            case .failure(let error):
                print(error)
            }

            completionHandler?(self.cart)
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
            performCartCreate(items: [item], handler: handler)
            return
        }

        let lines = [Storefront.CartLineInput.create(merchandiseId: item)]

        let mutation = Storefront.buildMutation(
            inContext: .init(country: Storefront.CountryCode.inferRegion())
        ) {
            $0.cartLinesAdd(lines: lines, cartId: cartId) {
                $0.cart { $0.cartManagerFragment() }
            }
        }

        client.execute(mutation: mutation) { result in
            guard
                case .success(let mutation) = result,
                let cart = mutation.cartLinesAdd?.cart
            else {
                handler(.failure(URLError(.unknown)))
                return
            }

            handler(.success(cart))
        }
    }

    private func getCountryCode() -> Storefront.CountryCode {
        if appConfiguration.useVaultedState {
            let code = Storefront.CountryCode(rawValue: self.country)
            return code ?? .ca
        }

        return Storefront.CountryCode.inferRegion()
    }

    private func performCartCreate(
        items: [GraphQL.ID] = [],
        handler: @escaping CartResultHandler
    ) {
        let input =
            (appConfiguration.useVaultedState)
            ? vaultedStateCart(items)
            : defaultCart(items)

        let countryCode = getCountryCode()

        let mutation = Storefront.buildMutation(
            inContext: Storefront.InContextDirective(country: countryCode)
        ) {
            $0
                .cartCreate(input: input) {
                    $0
                        .cart { $0.cartManagerFragment() }
                }
        }

        client.execute(mutation: mutation) { result in
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
        id: GraphQL.ID, quantity: Int32, handler: @escaping CartResultHandler
    ) {
        let lines = [
            Storefront.CartLineUpdateInput.create(
                id: id, quantity: Input(orNull: quantity))
        ]

        if let cartID = cart?.id {
            let mutation = Storefront.buildMutation(
                inContext: Storefront.InContextDirective(
                    country: Storefront.CountryCode.inferRegion())
            ) {
                $0
                    .cartLinesUpdate(cartId: cartID, lines: lines) {
                        $0
                            .cart { $0.cartManagerFragment() }
                    }
            }

            client.execute(mutation: mutation) { result in
                if case .success(let mutation) = result,
                    let cart = mutation.cartLinesUpdate?.cart
                {
                    handler(.success(cart))
                } else {
                    handler(.failure(URLError(.unknown)))
                }
            }
        } else {
            performCartCreate(items: [id], handler: handler)
        }
    }

    private func performCartDeliveryAddressUpdate(
        shippingAddress: Storefront.MailingAddressInput,
        handler: @escaping CartResultHandler
    ) {
        let deliveryAddressPreferences = [
            Storefront.DeliveryAddressInput.create(
                deliveryAddress: Input(orNull: shippingAddress))
        ]

        let buyerIdentityInput = Storefront.CartBuyerIdentityInput.create(
            email: Input(orNull: email),
            deliveryAddressPreferences: Input(
                orNull: deliveryAddressPreferences
            )
        )

        guard let cartID = cart?.id else {
            return print()
        }

        let mutation = Storefront.buildMutation(
            inContext: Storefront.InContextDirective(
                country: Storefront.CountryCode.inferRegion())
        ) {
            $0
                .cartBuyerIdentityUpdate(
                    cartId: cartID, buyerIdentity: buyerIdentityInput
                ) {
                    $0
                        .cart { $0.cartManagerFragment() }
                }
        }

        client.execute(mutation: mutation) { result in
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
                string: "https://\(self.domain)/api/unstable/graphql"
            )
        else {
            print("bad url")
            return
        }

        var request = URLRequest(url: requestURL)

        request.setValue(
            "multipart/mixed; boundary=graphql", forHTTPHeaderField: "Accept")
        //        request.setValue(
        //            "application/json",
        //            forHTTPHeaderField: "Accept"
        //        )
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
                    handler(.failure(error ?? URLError(.unknown)))
                    return
                }
                handler(.success(data))
            }
        }

        task.resume()
    }

    func isValidJSON(_ string: String) -> Bool {
        guard let data = string.data(using: .utf8) else { return false }

        do {
            // Attempt to serialize the data to a JSON object
            _ = try JSONSerialization.jsonObject(with: data, options: [])
            return true
        } catch {
            // If an error is thrown, the string is not valid JSON
            return false
        }
    }

    private func performCartShippingMethodUpdate(
        deliveryGroupId: GraphQL.ID,
        deliveryOptionHandle: String,
        handler: @escaping (Result<DeferredCart, Error>) -> Void
    ) {
        guard let cartID = cart?.id else {
            return print("performCartShippingMethodUpdate: Cart isn't created")
        }

        let mutationString = createCartSelectedDeliveryOptionsUpdateQuery(
            cartID: cartID, deliveryGroupId: deliveryGroupId,
            deliveryOptionHandle: deliveryOptionHandle)

        executeGraphQL(with: mutationString) {
            let result = $0.flatMap { data in
                Result {
                    try JSONDecoder().decode(Root.self, from: data)
                }
            }

            if case .success(let successResult) = result {
                let cart = successResult.data.cartSelectedDeliveryOptionsUpdate
                    .cart
                handler(.success(cart))
            } else {
                handler(.failure(URLError(.unknown)))

                let result = $0.flatMap { data in
                    let responseString = String(data: data, encoding: .utf8)
                    let chunks = responseString?.components(
                        separatedBy: "\r\n\r\n"
                    ).filter { self.isValidJSON($0) }

                    return Result {
                        try JSONDecoder().decode(
                            DeliveryOption
                                .self, from: data)
                    }
                }
            }
        }
    }

    private func waitAndReloadCart(after delayInSeconds: UInt32 = 1) {
        guard let cartId = cart?.id else { return }

        let context = Storefront.InContextDirective(
            country: Storefront.CountryCode.inferRegion())
        let query = Storefront.buildQuery(inContext: context) {
            $0
                .cart(id: cartId) { $0.cartManagerFragment() }
        }

        sleep(delayInSeconds)

        client.execute(query: query) { result in
            if case .success(let queryResult) = result {
                self.cart = queryResult.cart
            }
        }
    }

    private func defaultCart(_ items: [GraphQL.ID]) -> Storefront.CartInput {
        return Storefront.CartInput.create(
            lines: Input(
                orNull: items.map({
                    Storefront.CartLineInput.create(merchandiseId: $0)
                }))
        )
    }

    private func vaultedStateCart(_ items: [GraphQL.ID] = [])
        -> Storefront.CartInput
    {
        let deliveryAddress = Storefront.MailingAddressInput.create(
            address1: Input(orNull: address1),
            address2: Input(orNull: address2),
            city: Input(orNull: city),
            company: Input(orNull: ""),
            country: Input(orNull: country),
            firstName: Input(orNull: firstName),
            lastName: Input(orNull: lastName),
            phone: Input(orNull: phone),
            province: Input(orNull: province),
            zip: Input(orNull: zip))

        let deliveryAddressPreferences = [
            Storefront.DeliveryAddressInput.create(
                deliveryAddress: Input(orNull: deliveryAddress))
        ]

        return Storefront.CartInput.create(
            lines: Input(
                orNull: items.map({
                    Storefront.CartLineInput.create(merchandiseId: $0)
                })),
            buyerIdentity: Input(
                orNull: Storefront.CartBuyerIdentityInput.create(
                    email: Input(orNull: email),
                    deliveryAddressPreferences: Input(
                        orNull: deliveryAddressPreferences)
                ))
        )
    }
}

extension Storefront.CartQuery {
    @discardableResult
    func cartManagerFragment() -> Storefront.CartQuery {
        self
            .id()
            .checkoutUrl()
            .totalQuantity()
            .deliveryGroups(first: 10) {
                $0
                    .nodes {
                        $0
                            .id()
                            .deliveryOptions {
                                $0
                                    .handle()
                                    .title()
                                    .code()
                                    .deliveryMethodType()
                                    .description()
                                    .estimatedCost {
                                        $0
                                            .amount()
                                            .currencyCode()
                                    }
                            }
                    }
            }
            .lines(first: 250) {
                $0
                    .nodes {
                        $0
                            .id()
                            .quantity()
                            .merchandise {
                                $0
                                    .onProductVariant {
                                        $0
                                            .id()
                                            .title()
                                            .price({
                                                $0
                                                    .amount()
                                                    .currencyCode()
                                            })
                                            .product {
                                                $0
                                                    .title()
                                                    .vendor()
                                                    .featuredImage {
                                                        $0
                                                            .url()
                                                    }
                                            }
                                    }
                            }
                            .cost {
                                $0
                                    .totalAmount({
                                        $0
                                            .amount()
                                            .currencyCode()
                                    })
                            }
                    }
            }
            .totalQuantity()
            .cost {
                $0
                    .totalAmount({
                        $0
                            .amount()
                            .currencyCode()
                    })
                    .subtotalAmount {
                        $0
                            .amount()
                            .currencyCode()
                    }
                    .totalTaxAmount {
                        $0
                            .amount()
                            .currencyCode()
                    }
            }
    }
}

//func createCartSelectedDeliveryOptionsUpdateQuery(
//    cartID: GraphQL.ID,
//    deliveryGroupId: GraphQL.ID,
//    deliveryOptionHandle: String
//) -> String {
//    return """
//        fragment DeliveryGroups on Cart {
//            deliveryGroups(first: 10, withCarrierRates: true) {
//                edges {
//                  node {
//                    deliveryOptions {
//                      title
//                      handle
//                      code
//                      deliveryMethodType
//                      description
//                      estimatedCost {
//                        amount
//                      }
//                    }
//                    selectedDeliveryOption {
//                      title
//                      handle
//                      estimatedCost {
//                        amount
//                        currencyCode
//                      }
//                    }
//                  }
//                }
//              }
//          }
//
//          mutation @inContext(country: \(Storefront.CountryCode.inferRegion().rawValue.uppercased())) {
//            cartSelectedDeliveryOptionsUpdate(
//              cartId: "\(cartID.rawValue)",
//              selectedDeliveryOptions: [{
//                    deliveryGroupId: "\(deliveryGroupId.rawValue)",
//                    deliveryOptionHandle: "\(deliveryOptionHandle)"
//                }]
//            ) {
//              cart {
//                ... DeliveryGroups @defer
//                cost {
//                  totalAmount {
//                    amount
//                    currencyCode
//                  }
//                  subtotalAmount {
//                    amount
//                    currencyCode
//                  }
//                  totalTaxAmount {
//                    amount
//                    currencyCode
//                  }
//                }
//              }
//            }
//          }
//        """
//}
//
func createCartSelectedDeliveryOptionsUpdateQuery(
    cartID: GraphQL.ID,
    deliveryGroupId: GraphQL.ID,
    deliveryOptionHandle: String
) -> String {
    return """
          mutation @inContext(country: \(Storefront.CountryCode.inferRegion().rawValue.uppercased())) {
            cartSelectedDeliveryOptionsUpdate(
              cartId: "\(cartID.rawValue)",
              selectedDeliveryOptions: [{
                    deliveryGroupId: "\(deliveryGroupId.rawValue)", 
                    deliveryOptionHandle: "\(deliveryOptionHandle)"
                }]
            ) {
            ... @defer {
                  cart {
                    deliveryGroups(first: 10, withCarrierRates: true) {
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
                }
              }
          }
        """
}

// TODO: Update these to include deferred/indicate not storefont
struct DeferredDeliveryGroups: Codable {
    let incremental: [Incremental]
    let hasNext: Bool
}
// MARK: - Incremental
struct Incremental: Codable {
    let path: [String]
    let data: DataClass
}

// MARK: - DeliveryGroups
struct DeliveryGroups: Codable {
    let edges: [Edge]
}

// MARK: - Edge
struct Edge: Codable {
    let node: Node
}

// MARK: - DeliveryOption
struct DeliveryOption: Codable {
    let title, handle, code, deliveryMethodType: String
    let description: String
    let estimatedCost: DeliveryOptionEstimatedCost
}

// MARK: - Node
struct Node: Codable {
    let deliveryOptions: [DeliveryOption]
    let selectedDeliveryOption: SelectedDeliveryOption
}

// MARK: - DeliveryOptionEstimatedCost
struct DeliveryOptionEstimatedCost: Codable {
    let amount: String
}

// MARK: - SelectedDeliveryOption
struct SelectedDeliveryOption: Codable {
    let title, handle: String
    let estimatedCost: SelectedDeliveryOptionEstimatedCost
}

// MARK: - SelectedDeliveryOptionEstimatedCost
struct SelectedDeliveryOptionEstimatedCost: Codable {
    let amount, currencyCode: String
}

// MARK: - Root
struct Root: Codable {
    let data: DataClass
    let extensions: Extensions
}

// MARK: - DataClass
struct DataClass: Codable {
    let cartSelectedDeliveryOptionsUpdate: CartSelectedDeliveryOptionsUpdate
}

// MARK: - CartSelectedDeliveryOptionsUpdate
struct CartSelectedDeliveryOptionsUpdate: Codable {
    let cart: DeferredCart
}

// MARK: - Cart
struct DeferredCart: Codable {
    let checkoutUrl: String
    let cost: Cost
    let deliveryGroups: DeliveryGroups
    let id: String
    let lines: Lines
    let totalQuantity: Int
}

// MARK: - Cost
struct Cost: Codable {
    let subtotalAmount: Amount
    let totalAmount: Amount
    let totalTaxAmount: Amount?
}

// MARK: - Amount
struct Amount: Codable {
    let amount: String
    let currencyCode: String
}

// MARK: - DeliveryGroup
struct DeliveryGroup: Codable {
    let deliveryOptions: [DeliveryOption]
    let id: String
}

// MARK: - Lines
struct Lines: Codable {
    let nodes: [CartLine]
}

// MARK: - CartLine
struct CartLine: Codable {
    let typename: String
    let cost: LineCost
    let id: String
    let merchandise: Merchandise
    let quantity: Int

    enum CodingKeys: String, CodingKey {
        case typename = "__typename"
        case cost, id, merchandise, quantity
    }
}

// MARK: - LineCost
struct LineCost: Codable {
    let totalAmount: Amount
}

// MARK: - Merchandise
struct Merchandise: Codable {
    let typename: String
    let id: String
    let price: Amount
    let product: Product
    let title: String

    enum CodingKeys: String, CodingKey {
        case typename = "__typename"
        case id, price, product, title
    }
}

// MARK: - Product
struct Product: Codable {
    let featuredImage: FeaturedImage
    let title: String
    let vendor: String
}

// MARK: - FeaturedImage
struct FeaturedImage: Codable {
    let url: String
}

// MARK: - Extensions
struct Extensions: Codable {
    let context: Context
}

// MARK: - Context
struct Context: Codable {
    let country: String
    let language: String
}
