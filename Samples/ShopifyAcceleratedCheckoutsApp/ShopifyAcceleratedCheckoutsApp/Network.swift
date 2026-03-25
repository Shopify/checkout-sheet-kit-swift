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

import Apollo
import ApolloAPI
import Foundation
import ShopifyAcceleratedCheckouts

typealias Cart = Storefront.CartCreateMutation.Data.CartCreate.Cart
typealias CartLine = Storefront.CartCreateMutation.Data.CartCreate.Cart.Lines.Node
typealias CartProductVariant = Storefront.CartCreateMutation.Data.CartCreate.Cart.Lines.Node
    .Merchandise.AsProductVariant
typealias CartProductPrice = Storefront.CartCreateMutation.Data.CartCreate.Cart.Lines.Node
    .Merchandise.AsProductVariant.Price
typealias CartLineTotalAmount = Storefront.CartCreateMutation.Data.CartCreate.Cart.Lines.Node.Cost
    .TotalAmount
typealias CartTotalAmount = Storefront.CartCreateMutation.Data.CartCreate.Cart.Cost.TotalAmount
typealias Products = Storefront.GetProductsQuery.Data.Products
typealias Product = Storefront.GetProductsQuery.Data.Products.Node
typealias ProductVariants = Storefront.GetProductsQuery.Data.Products.Node.Variants
typealias ProductVariant = Storefront.GetProductsQuery.Data.Products.Node.Variants.Node
typealias ProductPrice = Storefront.GetProductsQuery.Data.Products.Node.Variants.Node.Price

class Network {
    static let shared = Network()

    /// Get the device's language code mapped to Shopify's LanguageCode enum
    private func getLanguageCode() -> GraphQLEnum<Storefront.LanguageCode> {
        if let languageCode = Locale.current.language.languageCode?.identifier {
            let code = languageCode.uppercased()

            // Handle special cases
            switch code {
            case "ZH":
                if let scriptCode = Locale.current.language.script?.identifier {
                    return GraphQLEnum(scriptCode == "Hans" ? Storefront.LanguageCode.zhCn : Storefront.LanguageCode.zhTw)
                }
                return GraphQLEnum(Storefront.LanguageCode.zhCn)
            case "PT":
                if let regionCode = Locale.current.language.region?.identifier {
                    return GraphQLEnum(regionCode == "BR" ? Storefront.LanguageCode.ptBr : Storefront.LanguageCode.ptPt)
                }
                return GraphQLEnum(Storefront.LanguageCode.pt)
            default:
                // Try to map directly to Storefront.LanguageCode
                if let mappedCode = Storefront.LanguageCode(rawValue: code) {
                    return GraphQLEnum(mappedCode)
                }

                // Try with just the first two characters
                let baseLanguage = String(code.prefix(2))
                if let mappedCode = Storefront.LanguageCode(rawValue: baseLanguage) {
                    return GraphQLEnum(mappedCode)
                }
            }
        }

        return GraphQLEnum(Storefront.LanguageCode.en) // Default to English
    }

    private(set) lazy var apollo: ApolloClient = {
        let urlString =
            "https://\(EnvironmentVariables.storefrontDomain)/api/\(EnvironmentVariables.apiVersion)/graphql.json"
        guard let url = URL(string: urlString) else {
            fatalError("Invalid GraphQL endpoint URL: \(urlString)")
        }

        let transport = RequestChainNetworkTransport(
            interceptorProvider: StorefrontInterceptorProvider(),
            endpointURL: url
        )

        return ApolloClient(networkTransport: transport)
    }()

    func getProducts() async -> Products? {
        print("Network: Starting product fetch from \(EnvironmentVariables.storefrontDomain)")

        let countryCode = GraphQLEnum(Storefront.CountryCode(rawValue: Locale.current.region?.identifier ?? "US") ?? .us)
        let languageCode = getLanguageCode()

        do {
            let response = try await Network.shared.apollo.fetch(query: Storefront.GetProductsQuery(
                country: countryCode,
                language: languageCode
            ))
            print("Network: Successfully fetched products")
            if let errors = response.errors {
                print("Network: GraphQL errors: \(errors)")
            }
            return response.data?.products
        } catch {
            print("Network: Failed to fetch products - \(error.localizedDescription)")
            return nil
        }
    }

    func createCart(
        merchandiseQuantities: [MerchandiseID: Quantity],
        configuration: ShopifyAcceleratedCheckouts.Configuration? = nil
    ) async -> Cart? {
        let lines = merchandiseQuantities.map { merchandiseId, quantity in
            Storefront.CartLineInput(
                quantity: .some(quantity),
                merchandiseId: merchandiseId
            )
        }

        var buyerIdentity: Storefront.CartBuyerIdentityInput?
        if let customer = configuration?.customer {
            let emailInput: GraphQLNullable<String> = customer.email ?? .none
            let phoneInput: GraphQLNullable<String> = customer.phoneNumber ?? .none

            buyerIdentity = Storefront.CartBuyerIdentityInput(
                email: emailInput,
                phone: phoneInput
            )
        }

        let input = Storefront.CartInput(
            lines: .some(lines),
            buyerIdentity: buyerIdentity ?? .none
        )

        let countryCode = GraphQLEnum(Storefront.CountryCode(rawValue: Locale.current.region?.identifier ?? "US") ?? .us)
        let languageCode = getLanguageCode()

        let mutation = Storefront.CartCreateMutation(
            input: input,
            country: countryCode,
            language: languageCode
        )

        do {
            let response = try await Network.shared.apollo.perform(mutation: mutation)
            return response.data?.cartCreate?.cart
        } catch {
            print(error)
            return nil
        }
    }
}

struct StorefrontInterceptorProvider: InterceptorProvider {
    func graphQLInterceptors(
        for operation: some GraphQLOperation
    ) -> [any GraphQLInterceptor] {
        DefaultInterceptorProvider.shared.graphQLInterceptors(for: operation) + [
            AuthorizationInterceptor()
        ]
    }
}

struct AuthorizationInterceptor: GraphQLInterceptor {
    func intercept<Request: GraphQLRequest>(
        request: Request,
        next: NextInterceptorFunction<Request>
    ) async throws -> InterceptorResultStream<Request> {
        var authenticatedRequest = request
        authenticatedRequest.additionalHeaders["X-Shopify-Storefront-Access-Token"] = EnvironmentVariables.storefrontAccessToken
        return try await next(authenticatedRequest)
    }
}
