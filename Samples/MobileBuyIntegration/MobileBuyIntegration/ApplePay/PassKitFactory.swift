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
import PassKit

class PassKitFactory {
    static let shared = PassKitFactory()

    public func createPaymentRequest(
        paymentSummaryItems: [PKPaymentSummaryItem]
    ) -> PKPaymentRequest {
        let paymentRequest = PKPaymentRequest()

        paymentRequest.merchantIdentifier = ApplePayHandler.MerchantId
        paymentRequest.supportedNetworks = ApplePayHandler.SupportedNetworks

        paymentRequest.countryCode = ApplePayHandler.CountryCode
        paymentRequest.currencyCode = ApplePayHandler.CurrencyCode
        paymentRequest.merchantCapabilities = .capability3DS

        paymentRequest.shippingType = .delivery
        paymentRequest.shippingMethods = createDefaultShippingMethod()

        paymentRequest.requiredShippingContactFields = [.name, .postalAddress, .emailAddress]
        paymentRequest.requiredBillingContactFields = [.name, .postalAddress, .emailAddress]

        paymentRequest.paymentSummaryItems = paymentSummaryItems

        return paymentRequest
    }

    func createPaymentSummaryItems() -> [PKPaymentSummaryItem] {
        guard let cart = CartManager.shared.cart else { return [] }

        var paymentSummaryItems: [PKPaymentSummaryItem] = []

        for line in cart.lines.nodes {
            guard let variant = line.merchandise as? Storefront.ProductVariant else {
                continue
            }

            paymentSummaryItems.append(
                .init(
                    label: variant.product.title,
                    amount: NSDecimalNumber(decimal: line.cost.totalAmount.amount),
                    type: .final
                )
            )
        }

        paymentSummaryItems.append(
            .init(
                label: "Tax",
                amount: NSDecimalNumber(decimal: cart.cost.totalTaxAmount?.amount ?? 0),
                type: .final
            )
        )

        paymentSummaryItems.append(
            .init(
                label: "Total",
                amount: NSDecimalNumber(decimal: cart.cost.totalAmount.amount),
                type: .final
            )
        )

        return paymentSummaryItems
    }

    func createDefaultShippingMethod() -> [PKShippingMethod] {
        #warning("Missing selectedDeliveryOption will throw out of this guard")
        guard
            let selectedDeliveryOption = CartManager.shared.cart?.deliveryGroups
            .nodes.first?.selectedDeliveryOption,
            let title = selectedDeliveryOption.title
        else { return [] }

        let shippingCollection = PKShippingMethod(
            label: title,
            amount: NSDecimalNumber(
                decimal: selectedDeliveryOption.estimatedCost.amount)
        )
        shippingCollection.detail = selectedDeliveryOption.description
        shippingCollection.identifier = selectedDeliveryOption.handle

        return [shippingCollection]
    }

    public func createShippingMethods(
        firstDeliveryGroup: Storefront.CartDeliveryGroup
    ) -> [PKShippingMethod] {
        return firstDeliveryGroup.deliveryOptions.compactMap {
            guard let title = $0.title, let description = $0.description else {
                print("Invalid deliveryOption to map shipping method")
                return nil
            }

            let shippingMethod = PKShippingMethod(
                label: title,
                amount: NSDecimalNumber(string: "\($0.estimatedCost.amount)")
            )

            shippingMethod.detail = description
            shippingMethod.identifier = $0.handle

            return shippingMethod
        }
    }

    public func createPaymentSummaryItems(
        cart: Storefront.Cart?, shippingMethod: PKShippingMethod?
    ) -> [PKPaymentSummaryItem] {
        guard let cart, !cart.lines.nodes.isEmpty else {
            return []
        }

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
