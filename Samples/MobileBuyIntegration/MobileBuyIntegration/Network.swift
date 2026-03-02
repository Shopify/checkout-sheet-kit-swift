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

final class Network: @unchecked Sendable {
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
        let client = URLSessionClient()
        let cache = InMemoryNormalizedCache()
        let store = ApolloStore(cache: cache)
        let provider = NetworkInterceptorProvider(client: client, store: store)

        let urlString = "https://\(InfoDictionary.shared.domain)/api/\(InfoDictionary.shared.apiVersion)/graphql.json"
        guard let url = URL(string: urlString) else {
            fatalError("Invalid GraphQL endpoint URL: \(urlString)")
        }

        let transport = RequestChainNetworkTransport(interceptorProvider: provider, endpointURL: url)
        apollo = ApolloClient(networkTransport: transport, store: store)
    }
}

class AuthorizationInterceptor: ApolloInterceptor {
    public var id: String = UUID().uuidString

    func interceptAsync<Operation: GraphQLOperation>(
        chain: RequestChain,
        request: HTTPRequest<Operation>,
        response: HTTPResponse<Operation>?,
        completion: @escaping (Result<GraphQLResult<Operation.Data>, Error>) -> Void
    ) {
        request.addHeader(name: "X-Shopify-Storefront-Access-Token", value: InfoDictionary.shared.accessToken)
        chain.proceedAsync(request: request, response: response, interceptor: self, completion: completion)
    }
}

class NetworkInterceptorProvider: DefaultInterceptorProvider {
    override func interceptors(for operation: some GraphQLOperation) -> [ApolloInterceptor] {
        var interceptors = super.interceptors(for: operation)
        interceptors.insert(AuthorizationInterceptor(), at: 0)
        return interceptors
    }
}
