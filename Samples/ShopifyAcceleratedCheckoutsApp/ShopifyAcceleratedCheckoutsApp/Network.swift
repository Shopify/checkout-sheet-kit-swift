//
//  Network.swift
//  ShopifyAcceleratedCheckoutsApp
//
//  Created by Kieran Barrie Osgood on 30/06/2025.
//

import Apollo
import ApolloAPI
import Foundation

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
        let client = URLSessionClient()
        let cache = InMemoryNormalizedCache()
        let store = ApolloStore(cache: cache)
        let provider = NetworkInterceptorProvider(client: client, store: store)

        let urlString =
            "https://\(EnvironmentVariables.storefrontDomain)/api/\(EnvironmentVariables.apiVersion)/graphql.json"
        guard let url = URL(string: urlString) else {
            fatalError("Invalid GraphQL endpoint URL: \(urlString)")
        }

        let transport = RequestChainNetworkTransport(
            interceptorProvider: provider, endpointURL: url
        )

        return ApolloClient(networkTransport: transport, store: store)
    }()

    func getProducts(
        completionHandler: @escaping (Products?) -> Void
    ) {
        print("Network: Starting product fetch from \(EnvironmentVariables.storefrontDomain)")

        // Get device locale for @inContext directive
        let countryCode = GraphQLEnum(Storefront.CountryCode(rawValue: Locale.current.region?.identifier ?? "US") ?? .us)
        let languageCode = getLanguageCode()

        Network.shared.apollo.fetch(query: Storefront.GetProductsQuery(
            country: countryCode,
            language: languageCode
        )) { result in
            switch result {
            case let .success(response):
                print("Network: Successfully fetched products")
                if let errors = response.errors {
                    print("Network: GraphQL errors: \(errors)")
                }
                completionHandler(response.data?.products)
            case let .failure(error):
                print("Network: Failed to fetch products - \(error.localizedDescription)")
                completionHandler(nil)
            }
        }
    }

    func createCart(
        merchandiseQuantities: [MerchandiseID: Quantity],
        completionHandler: @escaping (Cart?) -> Void
    ) {
        let lines = merchandiseQuantities.map { merchandiseId, quantity in
            Storefront.CartLineInput(
                quantity: .some(quantity),
                merchandiseId: merchandiseId
            )
        }

        let input = Storefront.CartInput(lines: .some(lines))

        // Get device locale for @inContext directive
        let countryCode = GraphQLEnum(Storefront.CountryCode(rawValue: Locale.current.region?.identifier ?? "US") ?? .us)
        let languageCode = getLanguageCode()

        let mutation = Storefront.CartCreateMutation(
            input: input,
            country: countryCode,
            language: languageCode
        )

        Network.shared.apollo.perform(mutation: mutation) {
            switch $0 {
            case let .success(response):
                completionHandler(response.data?.cartCreate?.cart)
            case let .failure(error):
                print(error)
                completionHandler(nil)
            }
        }
    }
}

class AuthorizationInterceptor: ApolloInterceptor {
    public var id: String = UUID().uuidString

    func interceptAsync<Operation>(
        chain: RequestChain,
        request: HTTPRequest<Operation>,
        response: HTTPResponse<Operation>?,
        completion: @escaping (Result<GraphQLResult<Operation.Data>, Error>) -> Void
    ) where Operation: GraphQLOperation {
        request.addHeader(
            name: "X-Shopify-Storefront-Access-Token",
            value: EnvironmentVariables.storefrontAccessToken
        )

        chain.proceedAsync(
            request: request,
            response: response,
            interceptor: self,
            completion: completion
        )
    }
}

class NetworkInterceptorProvider: DefaultInterceptorProvider {
    override func interceptors(for operation: some GraphQLOperation) -> [ApolloInterceptor] {
        var interceptors = super.interceptors(for: operation)
        interceptors.insert(AuthorizationInterceptor(), at: 0)
        return interceptors
    }
}
