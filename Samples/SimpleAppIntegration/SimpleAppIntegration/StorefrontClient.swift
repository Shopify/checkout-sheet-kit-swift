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

import Foundation

class StorefrontClient {

	static let shared = StorefrontClient()

	private let requestURL: URL

	private let accessToken: String

	private init() {
		guard
			let infoPlist = Bundle.main.infoDictionary,
			let domain = infoPlist["StorefrontDomain"] as? String,
			let token = infoPlist["StorefrontAccessToken"] as? String
		else {
			fatalError("unable to load storefront configuration")
		}

		requestURL = URL(string: "https://\(domain)/api/2023-07/graphql")!
		accessToken = token
	}

	typealias ProductResultHandler = (Result<Product, Error>) -> Void

	func product(_ handler: @escaping ProductResultHandler) {
		let query = """
		query FetchVariants {
			products(first: 10) {
				nodes {
					title
					featuredImage {
						url
					}
					vendor
					variants(first: 10) {
						nodes {
							id
							title
							price {
								amount
								currencyCode
							}
						}
					}
				}
			}
		}
		"""

		perform(query: query) {
			let result = $0.flatMap { data in
				Result {
					try JSONDecoder().decode(GraphQLResponse<QueryRoot>.self, from: data)
				}
			}

			if case .success(let response) = result, let product = response.data.products.nodes.randomElement() {
				handler(.success(product))
			} else {
				handler(.failure(URLError(.unknown)))
			}
		}
	}

	typealias CartResultHandler = (Result<Cart, Error>) -> Void

	func createCart(variant: ProductVariant, _ handler: @escaping CartResultHandler) {
		let query = """
		mutation Foo {
			cartCreate(input: { lines: { merchandiseId: "\(variant.id)" } }) {
				cart {
					checkoutUrl
				}
			}
		}
		"""

		perform(query: query) {
			let result = $0.flatMap { data in
				Result {
					try JSONDecoder().decode(GraphQLResponse<MutationRoot>.self, from: data)
				}
			}

			if case .success(let response) = result {
				handler(.success(response.data.cartCreate.cart))
			} else {
				handler(.failure(URLError(.unknown)))
			}
		}
	}

	private func perform(query: String, handler: @escaping (Result<Data, Error>) -> Void) {
		var request = URLRequest(url: requestURL)

		request.setValue("application/json", forHTTPHeaderField: "Accept")
		request.setValue("application/graphql", forHTTPHeaderField: "Content-Type")
		request.setValue(accessToken, forHTTPHeaderField: "X-Shopify-Storefront-Access-Token")

		request.httpMethod = "POST"
		request.httpBody = query.data(using: .utf8)

		let task = URLSession.shared.dataTask(with: request) { data, _, error in
			DispatchQueue.main.async {
				if let responseData = data {
					handler(.success(responseData))
				} else {
					handler(.failure(error ?? URLError(.unknown)))
				}
			}
		}

		task.resume()
	}
}
