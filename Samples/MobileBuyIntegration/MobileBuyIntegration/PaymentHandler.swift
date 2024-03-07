/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 A shared class for handling payments across an app and its related extensions.
 */

import UIKit
import PassKit
import ShopifyCheckoutSheetKit
import Buy
import Pay

typealias PaymentCompletionHandler = (Bool) -> Void

class PaymentHandler: NSObject {
	
	var paymentController: PKPaymentAuthorizationController?
	var paymentSummaryItems = [PKPaymentSummaryItem]()
	var paymentStatus = PKPaymentAuthorizationStatus.failure
	var completionHandler: PaymentCompletionHandler!
	var checkout: Storefront.Checkout!
	var shippingRates: [Storefront.ShippingRate]!
	
	static let supportedNetworks: [PKPaymentNetwork] = [
		.amex,
		.discover,
		.masterCard,
		.visa
	]
	
	class func applePayStatus() -> (canMakePayments: Bool, canSetupCards: Bool) {
		return (PKPaymentAuthorizationController.canMakePayments(),
				PKPaymentAuthorizationController.canMakePayments(usingNetworks: supportedNetworks))
	}
	
	func shippingMethodCalculator() -> [PKShippingMethod] {
		var shippingMethods: [PKShippingMethod] = []
		
		for rate in self.shippingRates {
			let shippingMethod = PKShippingMethod(label: rate.title, amount: NSDecimalNumber(decimal: rate.price.amount))
			shippingMethod.identifier = rate.handle
			shippingMethods.append(shippingMethod)
		}
		
		return shippingMethods
	}
	
	func startPayment(completion: @escaping PaymentCompletionHandler) {
		let cart = CartManager.shared.cart!
		let lines = cart.lines.nodes
		
		Client.shared.createCheckout(with: lines) { checkout in
			guard let checkout = checkout else {
				print("Failed to create checkout.")
				return
			}
			self.checkout = checkout
			self.completionHandler = completion
			
			//print("Getting shipping rates...")
			//Client.shared.fetchShippingRatesForCheckout(checkout.id) { result in
			//self.shippingRates = result?.rates
			self.paymentSummaryItems = []
			
			for line in lines {
				let variant = line.merchandise as? Storefront.ProductVariant
				let summaryItem = PKPaymentSummaryItem(label: variant!.product.title, amount: NSDecimalNumber(decimal: line.cost.totalAmount.amount), type: .final)
				self.paymentSummaryItems.append(summaryItem)
			}
			
			let tax = PKPaymentSummaryItem(label: "Tax", amount: NSDecimalNumber(decimal: cart.cost.totalTaxAmount?.amount ?? 0), type: .final)
			let total = PKPaymentSummaryItem(label: "Total", amount: NSDecimalNumber(decimal: cart.cost.totalAmount.amount), type: .final)
			self.paymentSummaryItems.append(tax)
			self.paymentSummaryItems.append(total)
			
			let paymentRequest = PKPaymentRequest()
			paymentRequest.paymentSummaryItems = self.paymentSummaryItems
			paymentRequest.merchantIdentifier = "merchant.com.shopify.example.MobileBuyIntegration.ApplePay"
			paymentRequest.merchantCapabilities = .capability3DS
			paymentRequest.countryCode = "US"
			paymentRequest.currencyCode = "USD"
			paymentRequest.supportedNetworks = PaymentHandler.supportedNetworks
			paymentRequest.shippingType = .delivery
			//paymentRequest.shippingMethods = self.shippingMethodCalculator()
			paymentRequest.requiredShippingContactFields = [.name, .postalAddress]
			
			print("Checkout ID: ", checkout.id)
			print("Checkout URL: ", checkout.webUrl)
			
			// Display the payment request.
			self.paymentController = PKPaymentAuthorizationController(paymentRequest: paymentRequest)
			self.paymentController?.delegate = self
			self.paymentController?.present(completion: { (presented: Bool) in
				if presented {
					debugPrint("Presented payment controller")
				} else {
					debugPrint("Failed to present payment controller")
					self.completionHandler(false)
				}
			})
			//}
		}
	}
	
	
}

extension PaymentHandler: PKPaymentAuthorizationControllerDelegate {
	
	public func paymentAuthorizationController(_ controller: PKPaymentAuthorizationController, didSelectShippingMethod shippingMethod: PKShippingMethod, completion: @escaping (PKPaymentAuthorizationStatus, [PKPaymentSummaryItem]) -> Void) {
		print("Selecting shipping rate...")
		
		let shippingRate = self.shippingRates.filter {
			$0.handle == shippingMethod.identifier!
		}.first
		
		Client.shared.updateCheckout(checkout.id, updatingShippingRate: shippingRate!) { updatedCheckout in
			print("Selected shipping rate.")
			self.checkout = updatedCheckout
			completion(PKPaymentAuthorizationStatus.success, self.paymentSummaryItems)
		}
	}
	
	func paymentAuthorizationController(_ controller: PKPaymentAuthorizationController, didSelectShippingContact contact: PKContact, handler completion: @escaping (PKPaymentRequestShippingContactUpdate) -> Void) {
		
		print("Selected shipping address")
		let result    = PKPaymentRequestShippingContactUpdate(errors: nil, paymentSummaryItems: self.paymentSummaryItems, shippingMethods: [])
		
		guard let postalAddress = contact.postalAddress else {
			result.status = PKPaymentAuthorizationStatus.failure
			completion(result)
			return
		}
		
		let payPostalAddress = PayPostalAddress(city: postalAddress.city, country: postalAddress.country, countryCode: postalAddress.isoCountryCode, province: postalAddress.state, zip: postalAddress.postalCode)
		
		guard self.checkout.requiresShipping else {
			print("Checkout doesn't require shipping. Updating address...")
			
			self.updateShippingAddress(shippingContact: contact) {
				result.status = PKPaymentAuthorizationStatus.success
				completion(result)
			}
			return
		}
		
		self.updateShippingAddress(shippingContact: contact) {
			print("Getting shipping rates...")
			Client.shared.fetchShippingRatesForCheckout(self.checkout.id) { graphQLresult in
				self.shippingRates = graphQLresult?.rates
				result.shippingMethods = self.shippingMethodCalculator()
				result.status = PKPaymentAuthorizationStatus.success
				completion(result)
			}
		}
	}
	
	func paymentAuthorizationController(_ controller: PKPaymentAuthorizationController, didAuthorizePayment payment: PKPayment, handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
		var status = PKPaymentAuthorizationStatus.success
		
		let paymentData =  payment.token.paymentData
		
		let shippingContact = payment.shippingContact
		let contactLines = shippingContact!.postalAddress!.street.components(separatedBy: .newlines)
		
		
		let shippingAddress = PayAddress(
			addressLine1: contactLines.count > 0 ? contactLines[0] : nil,
			addressLine2: contactLines.count > 1 ? contactLines[1] : nil,
			city: shippingContact?.postalAddress?.city,
			country: shippingContact?.postalAddress?.country,
			province: shippingContact?.postalAddress?.state,
			zip: shippingContact?.postalAddress?.postalCode,
			firstName: shippingContact?.name?.givenName,
			lastName: shippingContact?.name?.familyName,
			phone: shippingContact?.phoneNumber?.stringValue,
			email: "jose.alvarez@shopify.com"
		)
		let email = "jose.alvarez@shopify.com"
		let token = String(data: paymentData, encoding: .utf8)!
		
		/*print("Updating checkout shipping address...")
		Client.shared.updateCheckout(self.checkout.id, updatingCompleteShippingAddress: shippingAddress) { updatedCheckout in
			guard let _ = updatedCheckout else {
				self.paymentStatus = PKPaymentAuthorizationStatus.failure
				completion(PKPaymentAuthorizationResult(status: PKPaymentAuthorizationStatus.failure, errors: nil))
				return
			}
			
			print("Updating checkout email...")
			Client.shared.updateCheckout(self.checkout.id, updatingEmail: email) { updatedCheckout in
				guard let _ = updatedCheckout else {
					self.paymentStatus = PKPaymentAuthorizationStatus.failure
					completion(PKPaymentAuthorizationResult(status: PKPaymentAuthorizationStatus.failure, errors: nil))
					return
				}
				
				print("Checkout email updated: \(email)")
				
				
				Client.shared.pollForReadyCheckout(self.checkout.id.rawValue) { readyCheckout in
					print("Checkout is ready...")
					print("Completing checkout...")
					
					Client.shared.completeCheckout(self.checkout, billingAddress: shippingAddress, applePayToken: token, idempotencyToken: UUID().uuidString) { payment in
						if let payment = payment, self.checkout.paymentDue.amount == payment.amount.amount {
							print("Checkout completed successfully.")
							print(self.checkout.webUrl)
						} else {
							print("Checkout failed to complete.")
							status = PKPaymentAuthorizationStatus.failure
						}
						
						self.paymentStatus = status
						completion(PKPaymentAuthorizationResult(status: status, errors: nil))
					}
				}
			}
		 
			
			
			
		}*/
		
		Client.shared.updateCartBuyerIdentity(self.checkout.id, updatingCartBuyerIdentity: shippingAddress, CartManager.shared.cart!.id, Storefront.CountryCode.us) { updatedCart in
			guard let _ = updatedCart else {
				self.paymentStatus = PKPaymentAuthorizationStatus.failure
				completion(PKPaymentAuthorizationResult(status: PKPaymentAuthorizationStatus.failure, errors: nil))
				return
			}
			
			completion(PKPaymentAuthorizationResult(status: PKPaymentAuthorizationStatus.success, errors: nil))
		}
	}
	
	func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
		controller.dismiss {
			// The payment sheet doesn't automatically dismiss once it has finished. Dismiss the payment sheet.
			DispatchQueue.main.async {
				if self.paymentStatus == .success {
					self.completionHandler!(true)
				} else {
					self.completionHandler!(false)
				}
			}
		}
	}
	
	func updateShippingAddress(shippingContact: PKContact, completion: @escaping () -> Void) -> Task {
		let contactLines = shippingContact.postalAddress!.street.components(separatedBy: .newlines)
		
		
		let shippingAddress = PayAddress(
			addressLine1: contactLines.count > 0 ? contactLines[0] : nil,
			addressLine2: contactLines.count > 1 ? contactLines[1] : nil,
			city: shippingContact.postalAddress?.city,
			country: shippingContact.postalAddress?.country,
			province: shippingContact.postalAddress?.state,
			zip: shippingContact.postalAddress?.postalCode,
			firstName: shippingContact.name?.givenName,
			lastName: shippingContact.name?.familyName,
			phone: shippingContact.phoneNumber?.stringValue,
			email: "jose.alvarez@shopify.com"
		)
		
		print("Updating checkout shipping address...")
		return Client.shared.updateCheckout(self.checkout.id, updatingCompleteShippingAddress: shippingAddress) { updatedCheckout in
			self.checkout = updatedCheckout
			return completion()
		}
	}
}

extension PayAddress {
	
	init(with contact: PKContact) {
		
		var line1: String?
		var line2: String?
		
		if let address = contact.postalAddress {
			let street = address.street
			if !street.isEmpty {
				let lines  = street.components(separatedBy: .newlines)
				line1      = lines.count > 0 ? lines[0] : nil
				line2      = lines.count > 1 ? lines[1] : nil
			}
		}
		
		self.init(
			addressLine1: line1,
			addressLine2: line2,
			city:         contact.postalAddress?.city,
			country:      contact.postalAddress?.country,
			province:     contact.postalAddress?.state,
			zip:          contact.postalAddress?.postalCode,
			firstName:    contact.name?.givenName,
			lastName:     contact.name?.familyName,
			phone:        contact.phoneNumber?.stringValue,
			email:        contact.emailAddress
		)
	}
}


