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
import Foundation

class StorefrontClient {

	static let shared = StorefrontClient()

	private let client: Graph.Client

	private init() {
		guard
			let infoPlist = Bundle.main.infoDictionary,
			let domain = infoPlist["StorefrontDomain"] as? String,
			let token = infoPlist["StorefrontAccessToken"] as? String
		else {
			fatalError("unable to load storefront configuration")
		}

		client = Graph.Client(shopDomain: domain, apiKey: token)

		/// Set the caching policy (1 hour)
		client.cachePolicy = .cacheFirst(expireIn: 60 * 60)
	}

	typealias QueryResultHandler = (Result<Storefront.QueryRoot, Error>) -> Void

	func execute(query: Storefront.QueryRootQuery, handler: @escaping QueryResultHandler) {
		let task = client.queryGraphWith(query) { query, error in
			if let root = query {
				handler(.success(root))
			} else {
				handler(.failure(error ?? URLError(.unknown)))
			}
		}

		task.resume()
	}

	typealias MutationResultHandler = (Result<Storefront.Mutation, Error>) -> Void

	func execute(mutation: Storefront.MutationQuery, handler: @escaping MutationResultHandler) {
		let task = client.mutateGraphWith(mutation) { mutation, error in
			if let root = mutation {
				handler(.success(root))
			} else {
				handler(.failure(error ?? URLError(.unknown)))
			}
		}

		task.resume()
	}
}

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
		if let match = url.path.range(of: pattern, options: .regularExpression, range: nil, locale: nil) {
			let slug = url.path[match].components(separatedBy: "/").last
			return slug
		}
		return nil
	}
}
