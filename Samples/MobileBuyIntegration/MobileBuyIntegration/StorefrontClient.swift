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

import ApolloAPI
import Foundation

public struct StorefrontURL {
    public let url: URL

    private let slug = "([\\w\\d_-]+)"

    init(from url: URL) {
        self.url = url
    }

    public func isThankYouPage() -> Bool {
        return url.path.range(of: "/thank[-_]you", options: .regularExpression) != nil
    }

    public func isCheckout() -> Bool {
        return url.path.contains("/checkout")
    }

    public func isCart() -> Bool {
        return url.path.contains("/cart")
    }

    public func isCollection() -> Bool {
        return url.path.range(of: "/collections/\(slug)", options: .regularExpression) != nil
    }

    public func isProduct() -> Bool {
        return url.path.range(of: "/products/\(slug)", options: .regularExpression) != nil
    }

    public func getProductSlug() -> String? {
        guard isProduct() else { return nil }

        let pattern = "/products/([\\w_-]+)"
        if let match = url.path.range(
            of: pattern, options: .regularExpression, range: nil, locale: nil
        ) {
            return url.path[match].components(separatedBy: "/").last
        }
        return nil
    }
}

@MainActor
class StorefrontInputFactory {
    static let shared = StorefrontInputFactory()

    private let vaultedContactInfo: InfoDictionary = .shared

    enum Errors: Error {
        case invariant(String)
    }

    public func createCartInput(_ items: [String] = [], customerAccessToken: String? = nil) -> Storefront.CartInput {
        let lines: GraphQLNullable<[Storefront.CartLineInput]> = .some(
            items.map { Storefront.CartLineInput(merchandiseId: $0) }
        )

        switch appConfiguration.buyerIdentityMode {
        case .guest:
            return Storefront.CartInput(lines: lines)

        case .hardcoded:
            let deliveryAddress = Storefront.CartDeliveryAddressInput(
                address1: .some(vaultedContactInfo.address1),
                address2: .some(vaultedContactInfo.address2),
                city: .some(vaultedContactInfo.city),
                company: .some(""),
                countryCode: .some(GraphQLEnum(
                    Storefront.CountryCode(rawValue: vaultedContactInfo.country) ?? .us
                )),
                firstName: .some(vaultedContactInfo.firstName),
                lastName: .some(vaultedContactInfo.lastName),
                phone: .some(vaultedContactInfo.phone),
                provinceCode: .some(vaultedContactInfo.province),
                zip: .some(vaultedContactInfo.zip)
            )

            let buyerIdentity = Storefront.CartBuyerIdentityInput(
                email: .some(vaultedContactInfo.email),
                customerAccessToken: customerAccessToken.map { .some($0) } ?? .none
            )

            let delivery = Storefront.CartDeliveryInput(
                addresses: .some([
                    Storefront.CartSelectableAddressInput(
                        address: Storefront.CartAddressInput(
                            deliveryAddress: .some(deliveryAddress)
                        ),
                        selected: .some(true),
                        oneTimeUse: .some(true)
                    )
                ])
            )

            return Storefront.CartInput(
                lines: lines,
                buyerIdentity: .some(buyerIdentity),
                delivery: .some(delivery)
            )

        case .customerAccount:
            guard let token = customerAccessToken else {
                return Storefront.CartInput(lines: lines)
            }
            return Storefront.CartInput(
                lines: lines,
                buyerIdentity: .some(
                    Storefront.CartBuyerIdentityInput(
                        customerAccessToken: .some(token)
                    )
                )
            )
        }
    }
}
