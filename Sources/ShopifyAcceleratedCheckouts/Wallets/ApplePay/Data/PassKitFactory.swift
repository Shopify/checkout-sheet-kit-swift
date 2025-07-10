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

import PassKit

@available(iOS 17.0, *)
class PassKitFactory {
    static let shared = PassKitFactory()

    private struct DeliveryOptionWithGroupType {
        let option: StorefrontAPI.CartDeliveryOption
        let groupType: StorefrontAPI.CartDeliveryGroupType
    }

    func getDeliveryOptionHandle(
        groups: [StorefrontAPI.CartDeliveryGroup],
        by deliveryOptionHandle: StorefrontAPI.Types.ID
    ) -> StorefrontAPI.Types.ID? {
        /// The `deliveryOptionHandle` is the `handle` from a `CartDeliveryOption`.
        /// This function finds the `id` of the `CartDeliveryGroup` that contains it.
        groups.first { group in
            group.deliveryOptions.contains { $0.handle == deliveryOptionHandle.rawValue }
        }?.id
    }

    ///     Creates an array of `PKShippingMethod` objects from an array of `CartDeliveryGroup` objects.
    ///     This function calculates the cartesian product of all delivery options across the given delivery groups
    ///     and maps each combination to a `PKShippingMethod`.
    ///
    ///     The function combines the properties of the delivery options in each combination:
    ///     - The `amount` is the sum of the amounts of all options in the combination.
    ///     - The `identifier` is a comma-separated string of the handles of the options.
    ///     - The `label` is an " and "-separated string of the titles of the options.
    ///     - The `detail` is an " and "-separated string of the descriptions of the options.
    ///
    ///     - Parameters:
    ///        - deliveryGroups: An array of `Storefront.CartDeliveryGroup` to generate shipping methods from.
    ///
    ///     - Returns: An array of `PKShippingMethod` representing all possible shipping combinations.
    ///
    ///     See: https://github.com/Shopify/portable-wallets/blob/main/src/components/ApplePayButton/helpers/map-to-apple-pay-shipping-methods.ts
    ///
    func createShippingMethods(
        deliveryGroups: [StorefrontAPI.CartDeliveryGroup]?
    ) -> [PKShippingMethod] {
        guard let deliveryGroups, !deliveryGroups.isEmpty else { return [] }

        let deliveryOptionsWithGroupType: [[DeliveryOptionWithGroupType]] =
            deliveryGroups.map { group in
                group.deliveryOptions
                    .filter { $0.deliveryMethodType == .shipping }
                    .map { option in
                        DeliveryOptionWithGroupType(option: option, groupType: group.groupType)
                    }
            }

        let deliveryOptionCombinations = cartesian(deliveryOptionsWithGroupType)

        let builtDeliveryOptions =
            deliveryOptionCombinations
                .compactMap { deliveryOptions -> PKShippingMethod? in
                    guard let first = deliveryOptions.first else {
                        return nil
                    }

                    let aggregate = deliveryOptions.dropFirst().reduce(
                        into: (
                            amount: first.option.estimatedCost.amount,
                            titles: [first.option.title],
                            descriptions: [first.option.description]
                        )
                    ) { memo, current in
                        memo.amount += current.option.estimatedCost.amount
                        memo.descriptions.append(current.option.description)

                        if current.groupType == .oneTimePurchase {
                            memo.titles.insert(current.option.title, at: 0)
                        } else {
                            memo.titles.append(current.option.title)
                        }
                    }

                    let title = aggregate.titles.compactMap { $0 }.joined(separator: " and ")
                    let description = aggregate.descriptions.compactMap { $0 }.joined(
                        separator: " and ")
                    let handle = deliveryOptions.map { $0.option.handle }.joined(separator: ",")

                    let shippingMethod = PKShippingMethod(
                        label: title,
                        amount: NSDecimalNumber(decimal: aggregate.amount)
                    )

                    shippingMethod.detail = description
                    shippingMethod.identifier = handle
                    return shippingMethod
                }

        return builtDeliveryOptions
    }

    /// Represents a discount allocation for display purposes
    struct DiscountAllocationInfo {
        let code: String?
        let amount: Decimal
        let currencyCode: String

        init(code: String? = nil, amount: Decimal, currencyCode: String) {
            self.code = code
            self.amount = amount
            self.currencyCode = currencyCode
        }
    }

    ///   Gets all discount allocations for line items, including applicable discount codes
    ///   that are not already accounted for in cart or line item allocations.
    ///
    ///   - Parameter cart: The cart to get discount allocations from
    ///   - Returns: An array of DiscountAllocationInfo representing all discounts
    ///   - Throws: ShopifyAcceleratedCheckouts.Error if cart is nil
    ///
    ///   See: https://github.com/Shopify/portable-wallets/blob/main/src/components/ApplePayButton/helpers/get-discount-allocations-for-line-items.ts
    ///
    func createDiscountAllocations(cart: StorefrontAPI.Cart?) throws
        -> [DiscountAllocationInfo]
    {
        guard let cart else {
            throw ShopifyAcceleratedCheckouts.Error.invariant(message: "cart is nil")
        }

        let currencyCode = cart.cost.totalAmount.currencyCode

        /// Get all discount allocations from line items
        let lineItemDiscountAllocations = cart.lines.nodes.flatMap { $0.discountAllocations }

        /// Find discount codes that are applicable but not already accounted for
        let applicableOtherDiscountCodes = cart.discountCodes.filter { discountCode in
            guard discountCode.applicable else { return false }

            /// Check if not in cart discount allocations
            let allocations =
                (lineItemDiscountAllocations + cart.discountAllocations)
                    .contains { allocation in
                        if case let .code(codeAllocation) = allocation {
                            return codeAllocation.code == discountCode.code
                        }
                        return false
                    }

            return !allocations
        }

        /// Map applicable discount codes to synthetic discount allocations with 0 amount
        /// These are typically shipping discounts that don't show up in other allocations
        let shippingDiscounts: [DiscountAllocationInfo] =
            applicableOtherDiscountCodes
                .map { discountCode in
                    DiscountAllocationInfo(
                        code: discountCode.code,
                        amount: 0,
                        currencyCode: currencyCode
                    )
                }

        /// Convert cart discount allocations
        let cartDiscounts: [DiscountAllocationInfo] = cart.discountAllocations
            .compactMap { allocation in
                let code: String? =
                    if case let .code(codeAllocation) = allocation {
                        codeAllocation.code
                    } else {
                        nil
                    }

                let (discountedAmount, currencyCode) =
                    switch allocation {
                    case let .automatic(auto):
                        (auto.discountedAmount.amount, auto.discountedAmount.currencyCode)
                    case let .code(code):
                        (code.discountedAmount.amount, code.discountedAmount.currencyCode)
                    case let .custom(custom):
                        (custom.discountedAmount.amount, custom.discountedAmount.currencyCode)
                    }

                return DiscountAllocationInfo(
                    code: code,
                    amount: discountedAmount,
                    currencyCode: currencyCode
                )
            }

        /// Convert line item discount allocations
        let productDiscounts: [DiscountAllocationInfo] =
            lineItemDiscountAllocations
                .compactMap { allocation in
                    let code: String? =
                        if case let .code(codeAllocation) = allocation {
                            codeAllocation.code
                        } else {
                            nil
                        }

                    let (discountedAmount, currencyCode) =
                        switch allocation {
                        case let .automatic(auto):
                            (auto.discountedAmount.amount, auto.discountedAmount.currencyCode)
                        case let .code(code):
                            (code.discountedAmount.amount, code.discountedAmount.currencyCode)
                        case let .custom(custom):
                            (custom.discountedAmount.amount, custom.discountedAmount.currencyCode)
                        }

                    return DiscountAllocationInfo(
                        code: code,
                        amount: discountedAmount,
                        currencyCode: currencyCode
                    )
                }

        /// Return combined array: shipping discounts + cart discounts + product discounts
        return shippingDiscounts + cartDiscounts + productDiscounts
    }

    ///   Computes the cartesian product of a 2D array. The cartesian product is the set of all possible
    ///   ordered combinations of elements from the input arrays.
    ///
    ///   - Parameter arrays: A 2D array of elements of type `T`.
    ///   - Returns: A 2D array representing the cartesian product of the input arrays.
    ///
    ///   ### Example:
    ///   Given the input:
    ///   ```swift
    ///   let arrays = [[1, 2], ["A", "B"]]
    ///   ```
    ///   The function will return:
    ///   ```swift
    ///   [
    ///       [1, "A"],
    ///       [1, "B"],
    ///       [2, "A"],
    ///       [2, "B"]
    ///   ]
    ///   ```
    ///
    private func cartesian<T>(_ arrays: [[T]]) -> [[T]] {
        arrays.reduce([[]]) { memo, array in
            memo.flatMap { leftItem in
                array.map { rightItem in
                    leftItem + [rightItem]
                }
            }
        }
    }

    ///   Maps cart data to Apple Pay line items with detailed breakdown including discounts.
    ///   This is the Swift equivalent of the TypeScript mapToApplePayLineItems function.
    ///
    ///   - Parameters:
    ///      - cart: The cart to create line items from
    ///      - shippingMethod: The selected shipping method (optional)
    ///      - merchantName: The merchant name for the total line
    ///   - Returns: An array of PKPaymentSummaryItem representing the detailed breakdown
    ///
    func mapToApplePayLineItems(
        cart: StorefrontAPI.Cart?,
        shippingMethod _: PKShippingMethod? = nil,
        merchantName: String
    ) -> [PKPaymentSummaryItem] {
        guard let cart else {
            print("cart is nil.")
            return []
        }

        var lineItems: [PKPaymentSummaryItem] = []

        // 1. Subtotal (sum of all line items before discounts)
        // https://github.com/Shopify/portable-wallets/blob/main/src/utils/get-subtotal-from-line-items.ts#L17
        let subtotal = getSubtotalFromLineItems(cart: cart)

        if subtotal > 0 {
            lineItems.append(
                PKPaymentSummaryItem(
                    label: "order_summary.subtotal".localizedString,
                    amount: NSDecimalNumber(decimal: subtotal),
                    type: .final
                )
            )
        }

        /// 2. Shipping (if selected)
        lineItems.insert(contentsOf: buildDeliveryLineItems(cart: cart), at: lineItems.count)

        /// 3. Duties (if applicable)
        if let dutyAmount = cart.cost.totalDutyAmount?.amount, dutyAmount > 0 {
            lineItems.append(
                PKPaymentSummaryItem(
                    label: "order_summary.duties".localizedString,
                    amount: NSDecimalNumber(decimal: dutyAmount),
                    type: .final
                )
            )
        }

        /// 4. Taxes
        if let taxAmount = cart.cost.totalTaxAmount?.amount {
            lineItems.append(
                PKPaymentSummaryItem(
                    label: "order_summary.taxes".localizedString,
                    amount: NSDecimalNumber(decimal: taxAmount),
                    type: .final
                )
            )
        }

        /// 5. Discount allocations
        do {
            let discountAllocations = try createDiscountAllocations(cart: cart)

            // Group discounts by code (or create a general discount line for non-code discounts)
            var discountsByCode: [String?: Decimal] = [:]

            for discount in discountAllocations {
                let key = discount.code ?? "order_summary.discount".localizedString
                discountsByCode[key, default: 0] += discount.amount
            }

            // Add discount line items (as negative amounts)
            for (code, amount) in discountsByCode where amount > 0 {
                lineItems.append(
                    PKPaymentSummaryItem(
                        label: code ?? "Discount",
                        amount: NSDecimalNumber(decimal: -amount),
                        type: .final
                    )
                )
            }
        } catch {
            print("Error creating discount allocations: \(error)")
        }

        /// 6. Total (with merchant name)
        lineItems.append(
            PKPaymentSummaryItem(
                label: merchantName,
                amount: NSDecimalNumber(decimal: cart.cost.totalAmount.amount),
                type: .final
            )
        )

        return lineItems
    }

    ///   Helper function to get the subtotal from line items
    ///   Equivalent to getSubtotalLineFromLineItems in TypeScript
    ///
    private func getSubtotalFromLineItems(cart: StorefrontAPI.Cart) -> Decimal {
        return cart.lines.nodes.reduce(Decimal(0)) { total, lineItem in
            total + lineItem.cost.subtotalAmount.amount
        }
    }

    ///   Helper function to convert cart delivery groups to Apple Pay line items
    ///
    private func buildDeliveryLineItems(cart: StorefrontAPI.Cart) -> [PKPaymentSummaryItem] {
        let hasSubscription = cart.deliveryGroups.nodes.contains { $0.groupType == .subscription }

        return cart.deliveryGroups.nodes.map { group in
            var label = "order_summary.shipping".localizedString

            if hasSubscription {
                label =
                    group.groupType == .subscription
                        ? "order_summary.shipping_subscription".localizedString
                        : "order_summary.shipping_one_time_purchase".localizedString
            }

            return PKPaymentSummaryItem(
                label: label,
                amount: NSDecimalNumber(
                    decimal: group.selectedDeliveryOption?.estimatedCost.amount ?? 0),
                type: .final
            )
        }
    }
}
