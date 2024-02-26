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

struct GraphQLResponse<Root: Decodable>: Decodable {
	let data: Root
}

struct QueryRoot: Decodable {
	let products: Connection<Product>
}

struct MutationRoot: Decodable {
	let cartCreate: CartCreatePayload
}

struct Connection<Node: Decodable>: Decodable {
	let nodes: [Node]
}

struct Product: Decodable {
	let title: String
	let featuredImage: Image?
	let variants: Connection<ProductVariant>
	let vendor: String
}

struct ProductVariant: Decodable {
	let id: String
	let title: String
	let price: Money
}

struct Image: Decodable {
	let url: URL
}

struct Money: Decodable {
	let amount: String

	let currencyCode: String

	func formattedString() -> String? {
		let decimal = Decimal(string: amount) ?? 0
		let formatter = NumberFormatter()
		formatter.numberStyle = .currency
		formatter.currencyCode = currencyCode
		return formatter.string(from: NSDecimalNumber(decimal: decimal))
	}
}

struct CartCreatePayload: Decodable {
	let cart: Cart
}

struct Cart: Decodable {
	let checkoutUrl: URL
}
