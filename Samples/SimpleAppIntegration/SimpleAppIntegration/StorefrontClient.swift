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
	private let address1: String
	private let address2: String
	private let city: String
	private let country: String
	private let firstName: String
	private let lastName: String
	private let province: String
	private let zip: String

	private init() {
		guard
			let infoPlist = Bundle.main.infoDictionary,
			let domain = infoPlist["StorefrontDomain"] as? String,
			let token = infoPlist["StorefrontAccessToken"] as? String,
			let Address1 = infoPlist["ADDRESS_1"] as? String,
			let Address2 = infoPlist["ADDRESS_2"] as? String,
			let City = infoPlist["CITY"] as? String,
			let Country = infoPlist["COUNTRY"] as? String,
			let FirstName = infoPlist["FIRST_NAME"] as? String,
			let LastName = infoPlist["LAST_NAME"] as? String,
			let Province = infoPlist["PROVINCE"] as? String,
			let Zip = infoPlist["ZIP"] as? String
		else {
			fatalError("unable to load storefront configuration")
		}

		self.requestURL = URL(string: "https://\(domain)/api/2023-07/graphql")!
		self.accessToken = token
		self.address1 = address1
		self.address2 = address2
		self.city = city
		self.country = country
		self.firstName = firstName
		self.lastName = lastName
		self.province = province
		self.zip = zip

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
