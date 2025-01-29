//
//  PaymentFactory.swift
//  MobileBuyIntegration
//
//  Created by Kieran Barrie Osgood on 29/01/2025.
//

import Buy
import PassKit

class PaymentFactory {
    static let shared = PaymentFactory()

    public func mapToPaymentSummaryItems(
        cart: Storefront.Cart?,
        shippingMethod: PKShippingMethod?
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

    // TODO: Move this to group with other mappers
    public func mapToPKShippingMethods(
        firstDeliveryGroup: Storefront.CartDeliveryGroup
    ) -> [PKShippingMethod] {
        firstDeliveryGroup
            .deliveryOptions.compactMap {
                guard
                    let title = $0.title,
                    let description = $0.description
                else {
                    print("Invalid deliveryOption to map shipping method")
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
}
