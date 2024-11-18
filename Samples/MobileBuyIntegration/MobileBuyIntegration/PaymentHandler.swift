/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A shared class for handling payments across an app and its related extensions.
*/

import UIKit
import PassKit
import ShopifyCheckoutSheetKit
import Buy

typealias PaymentCompletionHandler = (Bool) -> Void

class PaymentHandler: NSObject {

	var paymentController: PKPaymentAuthorizationController?
	var paymentSummaryItems = [PKPaymentSummaryItem]()
	var paymentStatus = PKPaymentAuthorizationStatus.failure
	var completionHandler: PaymentCompletionHandler!

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

	// Define the shipping methods.
	func shippingMethodCalculator() -> [PKShippingMethod] {
		// Calculate the pickup date.
		let today = Date()
		let calendar = Calendar.current

		let shippingStart = calendar.date(byAdding: .day, value: 3, to: today)!
		let shippingEnd = calendar.date(byAdding: .day, value: 5, to: today)!

		let startComponents = calendar.dateComponents([.calendar, .year, .month, .day], from: shippingStart)
		let endComponents = calendar.dateComponents([.calendar, .year, .month, .day], from: shippingEnd)

		let shippingCollection = PKShippingMethod(label: "Pick up", amount: NSDecimalNumber(string: "0.00"))
		shippingCollection.detail = "Collect at our store"
		shippingCollection.identifier = "PICKUP"

		return [shippingCollection]
	}

	func startPayment(completion: @escaping PaymentCompletionHandler) {
		completionHandler = completion

		let cart = CartManager.shared.cart!
		let lines = cart.lines.nodes
		paymentSummaryItems = []

		for line in lines {
			let variant = line.merchandise as? Storefront.ProductVariant
			let summaryItem = PKPaymentSummaryItem(label: variant!.product.title, amount: NSDecimalNumber(decimal: line.cost.totalAmount.amount), type: .final)
			paymentSummaryItems.append(summaryItem)
		}

		let tax = PKPaymentSummaryItem(label: "Tax", amount: NSDecimalNumber(decimal: cart.cost.totalTaxAmount?.amount ?? 0), type: .final)
		let total = PKPaymentSummaryItem(label: "Total", amount: NSDecimalNumber(decimal: cart.cost.totalAmount.amount), type: .final)
		paymentSummaryItems.append(tax)
		paymentSummaryItems.append(total)

		// Create a payment request.
		let paymentRequest = PKPaymentRequest()

		paymentRequest.merchantIdentifier = "merchant.com.shopify.example.MobileBuyIntegration.ApplePay"
		paymentRequest.merchantCapabilities = .capability3DS
		paymentRequest.countryCode = "US"
		paymentRequest.currencyCode = "USD"
		paymentRequest.supportedNetworks = PaymentHandler.supportedNetworks
		paymentRequest.shippingType = .delivery
		paymentRequest.shippingMethods = shippingMethodCalculator()
		paymentRequest.requiredShippingContactFields = [.name, .postalAddress]

		let recurringPaymentSummaryItem = PKRecurringPaymentSummaryItem(label: paymentSummaryItems[0].label, amount: paymentSummaryItems[0].amount)
		recurringPaymentSummaryItem.intervalUnit = .month
		recurringPaymentSummaryItem.intervalCount = 1
		paymentSummaryItems.append(recurringPaymentSummaryItem)

		let recurringPaymentRequest = PKRecurringPaymentRequest(paymentDescription: "Monthly subscription", regularBilling: recurringPaymentSummaryItem, managementURL: URL(string: "https://shopify.com/")!)

		paymentRequest.recurringPaymentRequest = recurringPaymentRequest

		paymentRequest.paymentSummaryItems = paymentSummaryItems

		// Display the payment request.
		paymentController = PKPaymentAuthorizationController(paymentRequest: paymentRequest)
		paymentController?.delegate = self
		paymentController?.present(completion: { (presented: Bool) in
			if presented {
				debugPrint("Presented payment controller")
			} else {
				debugPrint("Failed to present payment controller")
				self.completionHandler(false)
			}
		})
		}
}

// Set up PKPaymentAuthorizationControllerDelegate conformance.

extension PaymentHandler: PKPaymentAuthorizationControllerDelegate {

    func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didSelectShippingContact contact: PKContact,
        handler completion: @escaping (PKPaymentRequestShippingContactUpdate) -> Void
    ){
        if contact.postalAddress?.isoCountryCode == "US" {
            print(
                "Address: \(contact.postalAddress?.isoCountryCode)"
            )
        }

        completion(.init())
    }

	func paymentAuthorizationController(_ controller: PKPaymentAuthorizationController, didAuthorizePayment payment: PKPayment, handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {


		// Perform basic validation on the provided contact information.
		var errors = [Error]()
		var status = PKPaymentAuthorizationStatus.success
		if payment.shippingContact?.postalAddress?.isoCountryCode != "US" {
			let pickupError = PKPaymentRequest.paymentShippingAddressUnserviceableError(withLocalizedDescription: "Address must be in the United States to use Apple Pay in the Sample App")
			let countryError = PKPaymentRequest.paymentShippingAddressInvalidError(withKey: CNPostalAddressCountryKey, localizedDescription: "Invalid country")
			errors.append(pickupError)
			errors.append(countryError)
			status = .failure
		}

		self.paymentStatus = status
		completion(PKPaymentAuthorizationResult(status: status, errors: errors))
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
}
