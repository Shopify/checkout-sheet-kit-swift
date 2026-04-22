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

final class Network: Sendable {
    static let shared = Network()

    private static func getLanguageCode() -> GraphQLEnum<Storefront.LanguageCode> {
        if let languageCode = Locale.current.language.languageCode?.identifier {
            let code = languageCode.uppercased()
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
                if let mappedCode = Storefront.LanguageCode(rawValue: code) {
                    return GraphQLEnum(mappedCode)
                }
                let baseLanguage = String(code.prefix(2))
                if let mappedCode = Storefront.LanguageCode(rawValue: baseLanguage) {
                    return GraphQLEnum(mappedCode)
                }
            }
        }
        return GraphQLEnum(Storefront.LanguageCode.en)
    }

    var countryCode: GraphQLEnum<Storefront.CountryCode> {
        GraphQLEnum(Storefront.CountryCode(rawValue: Locale.current.region?.identifier ?? "US") ?? .us)
    }

    var languageCode: GraphQLEnum<Storefront.LanguageCode> {
        Network.getLanguageCode()
    }

    let apollo: ApolloClient

    init() {
        let urlString = "https://\(InfoDictionary.shared.domain)/api/\(InfoDictionary.shared.apiVersion)/graphql.json"
        guard let url = URL(string: urlString) else {
            fatalError("Invalid GraphQL endpoint URL: \(urlString)")
        }

        let store = ApolloStore()
        let transport = RequestChainNetworkTransport(
            urlSession: URLSession.shared,
            interceptorProvider: StorefrontInterceptorProvider(),
            store: store,
            endpointURL: url
        )
        apollo = ApolloClient(networkTransport: transport, store: store)
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
        authenticatedRequest.additionalHeaders["X-Shopify-Storefront-Access-Token"] = InfoDictionary.shared.accessToken
        return await next(authenticatedRequest)
    }
}
