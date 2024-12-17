/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A shared class for handling payments across an app and its related extensions.
*/

import Buy
import PassKit
import ShopifyCheckoutSheetKit
import UIKit

typealias PaymentCompletionHandler = (Bool, URL) -> Void

class PaymentHandler: NSObject {
    // MARK: Properties
    var paymentController: PKPaymentAuthorizationController?
    var paymentSummaryItems = [PKPaymentSummaryItem]()
    /**
     * Starts as nil when no payment status has been made
     * Question: Should be reset to nil when starting a new payment process?
     */
    var paymentStatus: PKPaymentAuthorizationStatus? = nil
    var paymentCompletionHandler: PaymentCompletionHandler?

    static let supportedNetworks: [PKPaymentNetwork] = [
        .amex,
        .discover,
        .masterCard,
        .visa,
    ]

    class func applePayStatus() -> (canMakePayments: Bool, canSetupCards: Bool) {
        return (
            PKPaymentAuthorizationController.canMakePayments(),
            PKPaymentAuthorizationController.canMakePayments(
                usingNetworks: supportedNetworks
            )
        )
    }

    // Define the shipping methods.
    func shippingMethodCalculator() -> [PKShippingMethod] {
        // Calculate the pickup date.
        let today = Date()
        let calendar = Calendar.current

        //        let shippingStart = calendar.date(byAdding: .day, value: 3, to: today)!
        //        let shippingEnd = calendar.date(byAdding: .day, value: 5, to: today)!

        //        let startComponents = calendar.dateComponents(
        //            [.calendar, .year, .month, .day], from: shippingStart)
        //        let endComponents = calendar.dateComponents(
        //            [.calendar, .year, .month, .day], from: shippingEnd)

        #warning("Missing selectedDeliveryOption will throw out of this guard")
        guard
            let selectedDeliveryOption = CartManager.shared.cart?.deliveryGroups
                .nodes.first?.selectedDeliveryOption,
            let title = selectedDeliveryOption.title
        else {
            return []
            // TODO: not fatal, but useful whilst we get this setup the first time
            //            fatalError("Could not calculate shipping amount.")
        }

        let shippingCollection = PKShippingMethod(
            label: title,
            amount: NSDecimalNumber(
                decimal: selectedDeliveryOption.estimatedCost.amount)
        )
        shippingCollection.detail = "Collect at our store"
        shippingCollection.identifier = "PICKUP"

        return [shippingCollection]
    }

    func startPayment(completion: @escaping PaymentCompletionHandler) {
        self.paymentCompletionHandler = completion

        guard let cart = CartManager.shared.cart else {
            return print("ERROR - No cart available")
        }

        let lines = cart.lines.nodes
        paymentSummaryItems = []

        for line in lines {
            let variant = line.merchandise as? Storefront.ProductVariant
            let summaryItem = PKPaymentSummaryItem(
                label: variant!.product.title,
                amount: NSDecimalNumber(decimal: line.cost.totalAmount.amount),
                type: .final)
            paymentSummaryItems.append(summaryItem)
        }

        let tax = PKPaymentSummaryItem(
            label: "Tax",
            amount: NSDecimalNumber(
                decimal: cart.cost.totalTaxAmount?.amount ?? 0), type: .final)
        let total = PKPaymentSummaryItem(
            label: "Total",
            amount: NSDecimalNumber(decimal: cart.cost.totalAmount.amount),
            type: .final)
        paymentSummaryItems.append(tax)
        paymentSummaryItems.append(total)

        // Create a payment request.
        let paymentRequest = PKPaymentRequest()

        paymentRequest.merchantIdentifier =
            "merchant.com.shopify.example.MobileBuyIntegration.ApplePay"
        paymentRequest.merchantCapabilities = .capability3DS
        paymentRequest.countryCode = "US"
        paymentRequest.currencyCode = "USD"
        paymentRequest.supportedNetworks = PaymentHandler.supportedNetworks
        paymentRequest.shippingType = .delivery
        paymentRequest.shippingMethods = shippingMethodCalculator()

        paymentRequest.requiredShippingContactFields = [.name, .postalAddress]
        paymentRequest.requiredBillingContactFields = [.name, .postalAddress]

        let recurringPaymentSummaryItem = PKRecurringPaymentSummaryItem(
            label: paymentSummaryItems[0].label,
            amount: paymentSummaryItems[0].amount)
        recurringPaymentSummaryItem.intervalUnit = .month
        recurringPaymentSummaryItem.intervalCount = 1
        paymentSummaryItems.append(recurringPaymentSummaryItem)

        let recurringPaymentRequest = PKRecurringPaymentRequest(
            paymentDescription: "Monthly subscription",
            regularBilling: recurringPaymentSummaryItem,
            managementURL: URL(string: "https://shopify.com/")!)

        paymentRequest.recurringPaymentRequest = recurringPaymentRequest

        paymentRequest.paymentSummaryItems = paymentSummaryItems

        // Display the payment request.
        paymentController = PKPaymentAuthorizationController(
            paymentRequest: paymentRequest)
        paymentController?.delegate = self
        paymentController?.present(completion: { (presented: Bool) in
            if presented {
                debugPrint("Presented payment controller")
            } else {
                debugPrint("Failed to present payment controller")
                guard let checkoutUrl = CartManager.shared.cart?.checkoutUrl else {
                    return
                }
                self.paymentCompletionHandler?(false, checkoutUrl)
            }
        })
    }
}

// Set up PKPaymentAuthorizationControllerDelegate conformance.

extension PaymentHandler: PKPaymentAuthorizationControllerDelegate {
    func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didSelectShippingMethod shippingMethod: PKShippingMethod,
        handler completion: @escaping (PKPaymentRequestShippingMethodUpdate) ->
            Void
    ) {
        guard let identifier = shippingMethod.identifier else {
            return print("missing shipping method identifier")
        }

        print("identifier \(identifier)")

        CartManager.shared
            .selectShippingMethodUpdate(deliveryOptionHandle: identifier) {
                cart in
                guard let cart else {
                    // NOTE: this can throw when the delivery groups change their handle and
                    // the api fails to accept our post with selecting the handle
                    fatalError("Bad Cart")
                }

                let paymentRequestShippingContactUpdate =
                    PKPaymentRequestShippingMethodUpdate(
                        paymentSummaryItems: self.mapToPaymentSummaryItems(
                            cart: cart,
                            shippingMethod: shippingMethod
                        )
                    )

                CartManager.shared.performCartPrepareForCompletion { result in
                    if case .success = result {
                        completion(paymentRequestShippingContactUpdate)
                    }
                }
            }
    }

    // TODO: Move this to group with other mappers
    private func mapToPKShippingMethods(
        firstDeliveryGroup: Storefront.CartDeliveryGroup
    ) -> [PKShippingMethod] {
        firstDeliveryGroup
            .deliveryOptions.compactMap {
                guard
                    let title = $0.title,
                    let description = $0.description
                else {
                    print(
                        "Invalid deliveryOption to map shipping method"
                    )
                    return nil
                }
                let shippingMethod = PKShippingMethod(
                    label: title,
                    amount: NSDecimalNumber(
                        string: "\($0.estimatedCost.amount)"
                    )
                )

                shippingMethod.detail = description
                shippingMethod.identifier = $0.handle

                return shippingMethod
            }
    }

    func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didSelectShippingContact contact: PKContact,
        handler completion: @escaping (PKPaymentRequestShippingContactUpdate) ->
            Void
    ) {
        do {
            try CartManager.shared.updateDeliveryAddress(
                contact: contact,
                partial: true
            ) { result in
                guard
                    let cart = result,
                    let firstDeliveryGroup = cart.deliveryGroups.nodes.first
                else {
                    return print(
                        "[didSelectShippingContact][updateDeliveryAddress] Invalid success response"
                    )
                }

                let shippingMethods = self.mapToPKShippingMethods(
                    firstDeliveryGroup: firstDeliveryGroup
                )

                CartManager.shared.performCartPrepareForCompletion { result in
                    if case .failure(let error) = result {
                        print(
                            "[didSelectShippingContact][performCartPrepareForCompletion] error \(error)"
                        )
                    }

                    completion(
                        PKPaymentRequestShippingContactUpdate(
                            errors: [],
                            paymentSummaryItems: self.mapToPaymentSummaryItems(
                                cart: cart,
                                shippingMethod: nil
                            ),
                            shippingMethods: shippingMethods
                        )
                    )
                }
            }
        } catch let error {
            print(
                "[didSelectShippingContact] error: \(error)"
            )
        }

    }

    func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didAuthorizePayment payment: PKPayment,
        handler completion: @escaping (PKPaymentAuthorizationResult) -> Void
    ) {

        // Perform basic validation on the provided contact information.
        guard payment.shippingContact?.postalAddress?.isoCountryCode == "US"
        else {
            self.paymentStatus = .failure
            return completion(
                .init(
                    status: .failure,
                    errors: [
                        PKPaymentRequest
                            .paymentShippingAddressUnserviceableError(
                                withLocalizedDescription:
                                    "Address must be in the United States to use Apple Pay in the Sample App"
                            ),
                        PKPaymentRequest.paymentShippingAddressInvalidError(
                            withKey: CNPostalAddressCountryKey,
                            localizedDescription: "Invalid country"
                        ),
                    ]
                )
            )
        }

        CartManager.shared.updateCartPaymentMethod(payment: payment) {
            updateCartPaymentMethodResult in
            switch updateCartPaymentMethodResult {
            case .success:
                print("[didAuthorizePayment][updateCartPaymentMethod][success]")
                CartManager.shared.submitForCompletion {
                    submitForCompletionResult in
                    switch submitForCompletionResult {
                    case .success:
                        print("[didAuthorizePayment][submitForCompletion][success]")
                        self.paymentStatus = .success
                        return completion(.init(status: .success, errors: nil))
                    case .failure(let error):
                        print("[didAuthorizePayment][submitForCompletion][failure] \(error)")
                        self.paymentStatus = .failure
                        return completion(.init(status: .failure, errors: [error]))
                    }
                }
            case .failure(let error):
                print("[didAuthorizePayment][updateCartPaymentMethod][failure]: \(error)")
                self.paymentStatus = .failure
                return completion(.init(status: .failure, errors: [error]))
            }
        }
    }

    func paymentAuthorizationControllerDidFinish(
        _ controller: PKPaymentAuthorizationController
    ) {
        controller.dismiss {
            // The payment sheet doesn't automatically dismiss once it has finished. Dismiss the payment sheet.
            DispatchQueue.main.async {
                guard
                    let paymentStatus = self.paymentStatus?.rawValue as? NSNumber,
                    let url = CartManager.shared.cart?.checkoutUrl
                else {
                    print(
                        "Failed to map payment status to URL \(String(describing: CartManager.shared.cart))"
                    )
                    return
                }
                self.paymentCompletionHandler?(
                    Bool(truncating: paymentStatus),
                    url
                )

                // Reset state after closing sheet
                self.paymentStatus = nil
                self.paymentCompletionHandler = nil
            }
        }
    }

    private func mapToPaymentSummaryItems(
        cart: Storefront.Cart,
        shippingMethod: PKShippingMethod?
    ) -> [PKPaymentSummaryItem] {
        var paymentSummaryItems: [PKPaymentSummaryItem] = cart.lines.nodes
            .compactMap {
                guard
                    let variant = $0.merchandise as? Storefront.ProductVariant
                else {
                    print("variant missing from merchandise")
                    return nil
                }

                return .init(
                    label: variant.product.title,
                    amount: NSDecimalNumber(
                        decimal: $0.cost.totalAmount.amount
                    ),
                    type: .final
                )
            }

        if let amount = shippingMethod?.amount {
            paymentSummaryItems.append(
                .init(label: "Shipping", amount: amount, type: .final)
            )
        }

        // Null and 0 mean different things
        if let amount = cart.cost.totalTaxAmount?.amount {
            paymentSummaryItems.append(
                .init(
                    label: "Tax",
                    amount: NSDecimalNumber(decimal: amount),
                    type: .final
                )
            )
        }

        paymentSummaryItems.append(
            .init(
                label: "Total",
                amount: NSDecimalNumber(decimal: cart.cost.totalAmount.amount),
                type: .final
            )
        )

        return paymentSummaryItems
    }
}