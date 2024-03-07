// swiftlint:disable all

//
//  Client.swift
//  Storefront
//
//  Created by Shopify.
//  Copyright (c) 2017 Shopify Inc. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation
import Buy
import Pay

final class Client {
	
	static let shopDomain = "shop1.shopify.shopify-wallets-g1yd.jose-alvarez.eu.spin.dev"
	static let apiKey     = "389f14488519bd3a56c855d7ec8f489b"
	static let merchantID = "merchant.com.your.id"
	static let locale   = Locale(identifier: "en-US")
	
	var checkoutUrl: URL?
	
	static let shared = Client()
	
	private let client: Graph.Client = Graph.Client(shopDomain: Client.shopDomain, apiKey: Client.apiKey, locale: Client.locale)
	
	private init() {
		self.client.cachePolicy = .cacheFirst(expireIn: 3600)
	}
	
	@discardableResult
	func fetchShopName(completion: @escaping (String?) -> Void) -> Task {
		
		let query = ClientQuery.queryForShopName()
		let task  = self.client.queryGraphWith(query) { (query, error) in
			if let query = query {
				completion(query.shop.name)
			} else {
				print("Failed to fetch shop name: \(String(describing: error))")
				completion(nil)
			}
		}
		
		task.resume()
		return task
	}
	
	@discardableResult
	func fetchShopURL(completion: @escaping (URL?) -> Void) -> Task {
		
		let query = ClientQuery.queryForShopURL()
		let task  = self.client.queryGraphWith(query) { (query, error) in
			if let query = query {
				completion(query.shop.primaryDomain.url)
			} else {
				print("Failed to fetch shop url: \(String(describing: error))")
				completion(nil)
			}
		}
		
		task.resume()
		return task
	}
	
	@discardableResult
	func createCheckout(with cartItems: [BaseCartLine], completion: @escaping (Storefront.Checkout?) -> Void) -> Task {
		let mutation = ClientQuery.mutationForCreateCheckout(with: cartItems)
		let task     = self.client.mutateGraphWith(mutation) { response, error in
			print(error?.localizedDescription ?? "")
			
			completion(response?.checkoutCreate?.checkout)
		}
		
		task.resume()
		return task
	}
	
	@discardableResult
	func pollForReadyCheckout(_ id: String, completion: @escaping (Storefront.Checkout?) -> Void) -> Task {

		let retry = Graph.RetryHandler<Storefront.QueryRoot>(endurance: .finite(30)) { response, error -> Bool in
			print(error?.localizedDescription ?? "")
			return (response?.node as? Storefront.Checkout)?.ready ?? false == false
		}
		
		let query = ClientQuery.queryForCheckout(id)
		let task  = client.queryGraphWith(query, cachePolicy: .networkOnly, retryHandler: retry) { response, error in
			print(error?.localizedDescription ?? "")
			
			if let checkout = response?.node as? Storefront.Checkout {
				completion(checkout)
			} else {
				completion(nil)
			}
		}
		
		task.resume()
		return task
	}
	
	func completeCheckout(_ checkout: Storefront.Checkout, billingAddress: PayAddress, applePayToken token: String, idempotencyToken: String, completion: @escaping (Storefront.Payment?) -> Void) {
		
		let mutation = ClientQuery.mutationForCompleteCheckoutUsingApplePay(checkout, billingAddress: billingAddress, token: token, idempotencyToken: idempotencyToken)
		let task     = self.client.mutateGraphWith(mutation) { response, error in
			print(error?.localizedDescription ?? "")
			
			if let payment = response?.checkoutCompleteWithTokenizedPaymentV3?.payment {
				
				print("Payment created, fetching status...")
				self.fetchCompletedPayment(payment.id.rawValue) { paymentViewModel in
					completion(paymentViewModel)
				}
				
			} else {
				completion(nil)
			}
		}
		
		task.resume()
	}
	
	func fetchCompletedPayment(_ id: String, completion: @escaping (Storefront.Payment?) -> Void) {
		
		let retry = Graph.RetryHandler<Storefront.QueryRoot>(endurance: .finite(30)) { response, error -> Bool in
			print(error?.localizedDescription ?? "")
			
			if let payment = response?.node as? Storefront.Payment {
				print("Payment not ready yet, retrying...")
				return !payment.ready
			} else {
				return false
			}
		}
		
		let query = ClientQuery.queryForPayment(id)
		let task  = self.client.queryGraphWith(query, retryHandler: retry) { query, error in
			
			if let payment = query?.node as? Storefront.Payment {
				print("Payment error: \(payment.errorMessage ?? "none")")
				completion(payment)
			} else {
				completion(nil)
			}
		}
		
		task.resume()
	}
	
	@discardableResult
	func updateCheckout(_ id: GraphQL.ID, updatingCompleteShippingAddress address: PayAddress, completion: @escaping (Storefront.Checkout?) -> Void) -> Task {
		let mutation = ClientQuery.mutationForUpdateCheckout(id, updatingCompleteShippingAddress: address)
		let task     = self.client.mutateGraphWith(mutation) { response, error in
			print(error?.localizedDescription ?? "")
			
			if let checkout = response?.checkoutShippingAddressUpdateV2?.checkout,
				let _ = checkout.shippingAddress {
				completion(checkout)
			} else {
				completion(nil)
			}
		}
		
		task.resume()
		return task
	}
	
	@discardableResult
	func updateCartBuyerIdentity(_ id: GraphQL.ID, updatingCartBuyerIdentity address: PayAddress, _ cartId: GraphQL.ID, _ countryCode: Storefront.CountryCode, completion: @escaping (GraphQL.ID?) -> Void) -> Task {
		let mutation = ClientQuery.mutationForUpdateCheckout(id, updatingCartBuyerIdentity: address, cartId, countryCode)
		let task     = self.client.mutateGraphWith(mutation) { response, error in
			print(error?.localizedDescription ?? "")
			
			if let cartId = response?.cartBuyerIdentityUpdate?.cart?.id {
				completion(cartId)
			} else {
				completion(nil)
			}
		}
		
		task.resume()
		return task
	}
	
	@discardableResult
	func updateCheckout(_ id: GraphQL.ID, updatingEmail email: String, completion: @escaping (Storefront.Checkout?) -> Void) -> Task {
		let mutation = ClientQuery.mutationForUpdateCheckout(id, updatingEmail: email)
		let task     = self.client.mutateGraphWith(mutation) { response, error in
			print(error?.localizedDescription ?? "")
			
			if let checkout = response?.checkoutEmailUpdateV2?.checkout,
				let _ = checkout.email {
				completion(checkout)
			} else {
				completion(nil)
			}
		}
		
		task.resume()
		return task
	}
	
	@discardableResult
	func fetchShippingRatesForCheckout(_ id: GraphQL.ID, completion: @escaping ((checkout: Storefront.Checkout, rates: [Storefront.ShippingRate])?) -> Void) -> Task {
		
		let retry = Graph.RetryHandler<Storefront.QueryRoot>(endurance: .finite(30)) { response, error -> Bool in
			print(error?.localizedDescription ?? "")
			
			if let checkout = response?.node as? Storefront.Checkout {
				return checkout.availableShippingRates?.ready ?? false == false || checkout.ready == false
			} else {
				return false
			}
		}
		
		let query = ClientQuery.queryShippingRatesForCheckout(id)
		let task  = self.client.queryGraphWith(query, cachePolicy: .networkOnly, retryHandler: retry) { response, error in
			print(error?.localizedDescription ?? "")
			
			if let response = response,
				let checkout = response.node as? Storefront.Checkout {
				completion((checkout, checkout.availableShippingRates!.shippingRates!))
			} else {
				completion(nil)
			}
		}
		
		task.resume()
		return task
	}
	
	@discardableResult
	func updateCheckout(_ id: GraphQL.ID, updatingShippingRate shippingRate: Storefront.ShippingRate, completion: @escaping (Storefront.Checkout?) -> Void) -> Task {
		let mutation = ClientQuery.mutationForUpdateCheckout(id, updatingShippingRate: shippingRate)
		let task     = self.client.mutateGraphWith(mutation) { response, error in
			print(error?.localizedDescription ?? "")
			
			if let checkout = response?.checkoutShippingLineUpdate?.checkout,
				let _ = checkout.shippingLine {
				completion(checkout)
			} else {
				completion(nil)
			}
		}
		
		task.resume()
		return task
	}
	
	// ----------------------------------
	//  MARK: - Collections -
	//
	/*@discardableResult
	func fetchCollections(limit: Int = 25, after cursor: String? = nil, productLimit: Int = 25, productCursor: String? = nil, completion: @escaping (PageableArray<CollectionViewModel>?) -> Void) -> Task {
		
		let query = ClientQuery.queryForCollections(limit: limit, after: cursor, productLimit: productLimit, productCursor: productCursor)
		let task  = self.client.queryGraphWith(query) { (query, error) in
			if let query = query {
				let collections = PageableArray(
					with:     query.collections.edges,
					pageInfo: query.collections.pageInfo
				)
				completion(collections)
			} else {
				print("Failed to load collections: \(String(describing: error))")
				completion(nil)
			}
		}
		
		task.resume()
		return task
	}*/
	
	/*
	// ----------------------------------
	//  MARK: - Products -
	//
	@discardableResult
	func fetchProducts(in collection: CollectionViewModel, limit: Int = 25, after cursor: String? = nil, completion: @escaping (PageableArray<ProductViewModel>?) -> Void) -> Task {
		
		let query = ClientQuery.queryForProducts(in: collection, limit: limit, after: cursor)
		let task  = self.client.queryGraphWith(query) { (query, error) in
			error.debugPrint()
			
			if let query = query,
				let collection = query.node as? Storefront.Collection {
				
				let products = PageableArray(
					with:     collection.products.edges,
					pageInfo: collection.products.pageInfo
				)
				completion(products)
				
			} else {
				print("Failed to load products in collection (\(collection.model.node.id.rawValue)): \(String(describing: error))")
				completion(nil)
			}
		}
		
		task.resume()
		return task
	}
	
	// ----------------------------------
	//  MARK: - Discounts -
	//
	@discardableResult
	func applyDiscount(_ discountCode: String, to checkoutID: String, completion: @escaping (CheckoutViewModel?) -> Void) -> Task {
		let mutation = ClientQuery.mutationForApplyingDiscount(discountCode, to: checkoutID)
		let task     = self.client.mutateGraphWith(mutation) { response, error in
			error.debugPrint()
			
			completion(response?.checkoutDiscountCodeApplyV2?.checkout?.viewModel)
		}
		
		task.resume()
		return task
	}
	
	// ----------------------------------
	//  MARK: - Gift Cards -
	//
	@discardableResult
	func applyGiftCard(_ giftCardCode: String, to checkoutID: String, completion: @escaping (CheckoutViewModel?) -> Void) -> Task {
		let mutation = ClientQuery.mutationForApplyingGiftCard(giftCardCode, to: checkoutID)
		let task     = self.client.mutateGraphWith(mutation) { response, error in
			error.debugPrint()
			
			completion(response?.checkoutGiftCardsAppend?.checkout?.viewModel)
		}
		
		task.resume()
		return task
	}
	
	// ----------------------------------
	//  MARK: - Checkout -
	//
	
	
	@discardableResult
	func updateCheckout(_ id: String, updatingPartialShippingAddress address: PayPostalAddress, completion: @escaping (CheckoutViewModel?) -> Void) -> Task {
		let mutation = ClientQuery.mutationForUpdateCheckout(id, updatingPartialShippingAddress: address)
		let task     = self.client.mutateGraphWith(mutation) { response, error in
			error.debugPrint()
			
			if let checkout = response?.checkoutShippingAddressUpdateV2?.checkout,
				let _ = checkout.shippingAddress {
				completion(checkout.viewModel)
			} else {
				completion(nil)
			}
		}
		
		task.resume()
		return task
	}
	
	@discardableResult
	func updateCheckout(_ id: String, associatingCustomer accessToken: String, completion: @escaping (CheckoutViewModel?) -> Void) -> Task {
		
		let mutation = ClientQuery.mutationForUpdateCheckout(id, associatingCustomer: accessToken)
		let task     = self.client.mutateGraphWith(mutation) { (mutation, error) in
			error.debugPrint()
			
			if let checkout = mutation?.checkoutCustomerAssociateV2?.checkout {
				completion(checkout.viewModel)
			} else {
				completion(nil)
			}
		}
		
		task.resume()
		return task
	}
	
}


// ----------------------------------
//  MARK: - GraphError -
//
extension Optional where Wrapped == Graph.QueryError {
	
	func debugPrint() {
		switch self {
		case .some(let value):
			print("Graph.QueryError: \(value)")
		case .none:
			break
		}
	}
	 */
}
	
// swiftlint:enable all
